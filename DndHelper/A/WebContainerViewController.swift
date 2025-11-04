import UIKit
import WebKit

final class WebContainerViewController: UIViewController {

    private let targetURL: URL
    private var webView: WKWebView!

    init(url: URL) {
        self.targetURL = url
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide    // можно .fade
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        view.backgroundColor = .black
        setupWebView()
        webView.load(URLRequest(url: targetURL))
        print("🌐 WebView load: \(targetURL)")
    }

    
    private func setupWebView() {
        print("✅ WebContainerViewController: setupWebView()")

        // --- Конфигурация WKWebView
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.applicationNameForUserAgent = "" // чистый UA без приписки

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.customUserAgent = MyConstants.webUserAgent // Safari UA для Google Auth
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.verticalScrollIndicatorInsets = view.safeAreaInsets

        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

}

extension WebContainerViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = action.request.url else { decisionHandler(.cancel); return }
        let scheme = url.scheme?.lowercased() ?? ""
        if scheme != "http" && scheme != "https" {
            print("🔗 External scheme \(scheme) → open system: \(url.absoluteString)")
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            FirebaseLogger.logEvent(uuid: StartGateService.shared.sessionUUID,
                                    name: "external_scheme",
                                    payload: ["url": url.absoluteString, "scheme": scheme])
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        FirebaseLogger.logEvent(uuid: StartGateService.shared.sessionUUID,
                                name: "webview_did_finish",
                                payload: ["url": webView.url?.absoluteString ?? ""])
        print("✅ didFinish: \(webView.url?.absoluteString ?? "")")
    }
}

extension WebContainerViewController: WKUIDelegate {
    /// Открытие дочерних окон/попапов — через отдельный VC
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {

        guard navigationAction.targetFrame == nil else { return nil }

        let popup = PopupWebViewController(configuration: configuration,
                                           initialRequest: navigationAction.request)
        popup.modalPresentationStyle = .overFullScreen
        present(popup, animated: true) {
            print("🪟 Popup presented")
            FirebaseLogger.logEvent(uuid: StartGateService.shared.sessionUUID,
                                    name: "popup_presented",
                                    payload: ["request": navigationAction.request.url?.absoluteString ?? ""])
        }
        // Возвращаем nil, т.к. мы сами показали новый веб-контроллер
        return nil
    }
    
    // MARK: - JS dialogs (alert / confirm / prompt)
    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let ac = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(ac, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let ac = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(ac, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let ac = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        ac.addTextField { $0.text = defaultText }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(ac.textFields?.first?.text)
        })
        present(ac, animated: true)
    }
}
