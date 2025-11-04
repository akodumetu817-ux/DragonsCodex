//
//  PopupWebViewController.swift
//  YourNewService
//

import UIKit
import WebKit

final class PopupWebViewController: UIViewController {

    // MARK: - Public
    var initialRequest: URLRequest?
    var webConfig: WKWebViewConfiguration?

    // MARK: - UI
    private var webView: WKWebView!
    private let closeButton = UIButton(type: .system)
    private let toolbar = UIToolbar()

    // MARK: - Init
    init(configuration: WKWebViewConfiguration? = nil, initialRequest: URLRequest? = nil) {
        self.webConfig = configuration
        self.initialRequest = initialRequest
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🚀 PopupWebViewController: viewDidLoad")

        view.backgroundColor = .systemBackground
        setupWebView()
        setupCloseButton()
        setupToolbar()

        if let request = initialRequest {
            webView.load(request)
            print("🌐 PopupWebViewController: load \(request.url?.absoluteString ?? "")")
        }
    }
    
    private func setupWebView() {
        print("✅ PopupWebViewController: setupWebView()")

        let cfg = webConfig ?? WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.defaultWebpagePreferences.allowsContentJavaScript = true
        cfg.applicationNameForUserAgent = "" // чистый UA

        webView = WKWebView(frame: .zero, configuration: cfg)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.customUserAgent = MyConstants.webUserAgent // Safari UA для Google Auth
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.verticalScrollIndicatorInsets = view.safeAreaInsets

        view.addSubview(webView)
        view.addSubview(toolbar)

        toolbar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // toolbar снизу в пределах safe area
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbar.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),

            // webView над toolbar и в пределах safe area
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: toolbar.topAnchor)
        ])
    }

    
    
    private func setupCloseButton() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .gray
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
                closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
                closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
                closeButton.heightAnchor.constraint(equalToConstant: 32),
                closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor)
            ])

        print("✅ PopupWebViewController: close button set")
    }

    private func setupToolbar() {
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        let backItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"),
            style: .plain,
            target: self,
            action: #selector(goBack)
        )
        let forwardItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.forward"),
            style: .plain,
            target: self,
            action: #selector(goForward)
        )
        let flex = UIBarButtonItem(systemItem: .flexibleSpace)
        toolbar.items = [backItem, flex, forwardItem]

        view.addSubview(toolbar)

        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbar.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.06) // ≤ 6% экрана
        ])

        print("✅ PopupWebViewController: toolbar set (back/forward)")
    }

    // MARK: - Actions
    @objc private func closeTapped() {
        print("❎ PopupWebViewController: close")
        dismiss(animated: true)
        view.removeFromSuperview()
        removeFromParent()
    }

    @objc private func goBack() {
        if webView.canGoBack {
            webView.goBack()
            print("↩️ PopupWebViewController: goBack")
        } else {
            print("⚠️ PopupWebViewController: cannot goBack")
        }
    }

    @objc private func goForward() {
        if webView.canGoForward {
            webView.goForward()
            print("↪️ PopupWebViewController: goForward")
        } else {
            print("⚠️ PopupWebViewController: cannot goForward")
        }
    }
}

// MARK: - WK delegates
extension PopupWebViewController: WKNavigationDelegate, WKUIDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("✅ PopupWebViewController: didFinish \(webView.url?.absoluteString ?? "")")
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel); return
        }
        let scheme = url.scheme?.lowercased() ?? ""
        if scheme != "http" && scheme != "https" {
            print("🔗 PopupWebView: external scheme \(scheme) → open via UIApplication")
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    /// Если внутри попапа откроют ещё одно окно — остаёмся в том же контроллере
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        print("🪟 PopupWebViewController: nested popup requested")
        return webView // рендерим в текущем попапе
    }
}
