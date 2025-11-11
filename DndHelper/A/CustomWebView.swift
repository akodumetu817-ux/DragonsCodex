import SwiftUI
import WebKit
import UIKit

// MARK: - Coordinator

final class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate {
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool

    /// Главный + все "попапные" WKWebView поверх него
    var webViewStack: [WKWebView] = []

    init(canGoBack: Binding<Bool>, canGoForward: Binding<Bool>) {
        _canGoBack = canGoBack
        _canGoForward = canGoForward
    }

    // Обновляем состояния кнопок
    func updateNavigationButtons(for webView: WKWebView) {
        canGoBack = webView.canGoBack || webViewStack.count > 1
        canGoForward = webView.canGoForward
    }

    // Навигация завершена
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateNavigationButtons(for: webView)
        // TODO: log webview_did_finish здесь при необходимости
        // FirebaseLogger.logEvent(..., name: "webview_did_finish", payload: ["url": webView.url?.absoluteString ?? ""])
    }

    // Разрешение навигации
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
    {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel); return
        }

        // Разрешённые "внутренние" схемы
        let scheme = (url.scheme ?? "").lowercased()
        let internalSchemes: Set<String> = ["http", "https", "about", "srcdoc", "blob", "data", "javascript", "file"]

        if internalSchemes.contains(scheme) {
            decisionHandler(.allow)
            return
        }

        // Иное — наружу
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        // TODO: log external scheme при необходимости
        // FirebaseLogger.logEvent(..., name: "external_scheme", payload: ["url": url.absoluteString, "scheme": scheme])
        decisionHandler(.cancel)
    }

    // JS alert
    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void)
    {
        let ac = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        webView.window?.rootViewController?.present(ac, animated: true)
    }

    // window.open
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView?
    {
        // Фильтр поддельных about:blank/srcdoc/data/blob без реальных попапов
        let isRealPopup =
            (windowFeatures.width?.intValue ?? 0) > 0 ||
            (windowFeatures.height?.intValue ?? 0) > 0 ||
            (navigationAction.request.url?.absoluteString.contains("popup") == true)

        let lower = navigationAction.request.url?.absoluteString.lowercased() ?? ""
        let isSyntheticBlank = lower.isEmpty ||
                               lower == "about:blank" ||
                               lower == "about:srcdoc" ||
                               lower.hasPrefix("data:") ||
                               lower.hasPrefix("blob:")

        if !isRealPopup && isSyntheticBlank {
            return nil
        }

        // Создаём верхний WKWebView и кладём поверх
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        popup.navigationDelegate = self
        popup.uiDelegate = self
        popup.allowsBackForwardNavigationGestures = true

        webView.addSubview(popup)
        webView.bringSubviewToFront(popup)

        webViewStack.append(popup)
        updateNavigationButtons(for: popup)
        return popup
    }

    /// Закрывает самый верхний WKWebView из стека (когда назад уже некуда)
    func closeTopWebView() {
        guard webViewStack.count > 1 else { return }
        let top = webViewStack.removeLast()
        top.removeFromSuperview()
        if let visible = webViewStack.last {
            updateNavigationButtons(for: visible)
        }
    }
}

// MARK: - Representable

struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    let customUserAgent: String?

    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var webView: WKWebView?

    // Позволяет прокинуть извне уже созданный координатор (обычно не нужен)
    var externalCoordinator: WebViewCoordinator?

    func makeCoordinator() -> WebViewCoordinator {
        externalCoordinator ?? WebViewCoordinator(canGoBack: $canGoBack, canGoForward: $canGoForward)
    }

    func makeUIView(context: Context) -> WKWebView {
        let prefs = WKPreferences()
        prefs.javaScriptCanOpenWindowsAutomatically = true

        let cfg = WKWebViewConfiguration()
        cfg.defaultWebpagePreferences.allowsContentJavaScript = true
        cfg.allowsInlineMediaPlayback = true
        cfg.preferences = prefs
        cfg.applicationNameForUserAgent = "Version/17.2 Mobile/15E148 Safari/604.1"

        let wk = WKWebView(frame: .zero, configuration: cfg)
        wk.allowsBackForwardNavigationGestures = true
        wk.scrollView.delegate = context.coordinator
        wk.navigationDelegate = context.coordinator
        wk.uiDelegate = context.coordinator
        if let ua = customUserAgent { wk.customUserAgent = ua }

        wk.load(URLRequest(url: url))

        // Инициализируем стек
        context.coordinator.webViewStack = [wk]
        DispatchQueue.main.async { webView = wk }
        return wk
    }

    func updateUIView(_ uiView: WKWebView, context: Context) { }
}

// MARK: - Public SwiftUI view

struct CustomWebView: View {
    let main_link: String
    var customUserAgent: String? = nil // передай MyConstants.webUserAgent при желании

    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var innerWebView: WKWebView?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                if let url = URL(string: main_link) {
                    WebViewRepresentable(
                        url: url,
                        customUserAgent: customUserAgent,
                        canGoBack: $canGoBack,
                        canGoForward: $canGoForward,
                        webView: $innerWebView
                    )
                    .ignoresSafeArea(edges: .bottom)
                } else {
                    Text("Некорректный URL")
                        .foregroundColor(.white)
                        .padding(.top, 40)
                }

                // Панель навигации
                HStack {
                    Button {
                        if let coord = (innerWebView?.navigationDelegate as? WebViewCoordinator),
                           let top = coord.webViewStack.last {
                            if top.canGoBack {
                                top.goBack()
                            } else if coord.webViewStack.count > 1 {
                                coord.closeTopWebView()
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(canGoBack ? .white : .gray)
                            .imageScale(.large)
                    }
                    .disabled(!canGoBack)
                    .padding(.horizontal)
                    .padding(.top, 12)

                    Spacer()

                    Button {
                        if let coord = (innerWebView?.navigationDelegate as? WebViewCoordinator) {
                            coord.webViewStack.last?.goForward()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(canGoForward ? .white : .gray)
                            .imageScale(.large)
                    }
                    .disabled(!canGoForward)
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
                .frame(height: 20)
                .background(Color.black)
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}
