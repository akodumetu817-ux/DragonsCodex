import UIKit
import SwiftUI

final class LaunchViewController: UIViewController {

    private let spinner = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkGray
        
        if let cached = UserDefaults.standard.string(forKey: MyConstants.finalURLCacheKey),
           let url = URL(string: cached) {
            print("⚡️ Using cached final URL: \(cached)")
            openWebView(with: url)
            return
        }

        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        spinner.startAnimating()

        print("🚀 LaunchVC: fetchConfig()")
        StartGateService.shared.fetchConfig { [weak self] result in
            DispatchQueue.main.async {
                self?.spinner.stopAnimating()
                switch result {
                case .success(let url):
                    print("✅ LaunchVC: open WebView \(url)")
                    FirebaseLogger.logEvent(uuid: StartGateService.shared.sessionUUID,
                                            name: "open_webview",
                                            payload: ["url": url.absoluteString])
                    self?.openWebView(with: url)

                case .failure(let error):
                    print("⚠️ LaunchVC: config error \(error.localizedDescription), open App")
                    FirebaseLogger.logEvent(uuid: StartGateService.shared.sessionUUID,
                                            name: "open_app_fallback",
                                            payload: ["error": error.localizedDescription])
                    self?.openApp()
                }
            }
        }
    }

    private func openWebView(with url: URL) {
        print("➡️ Открываем WebView (все ориентации)")
        OrientationManager.shared.mask = .all // или .allButUpsideDown
        let vc = WebContainerViewController(url: url)
        setRoot(vc)
        UIViewController.attemptRotationToDeviceOrientation()
    }

    private func openApp() {
        print("➡️ Открываем заглушку (портрет)")
        OrientationManager.shared.mask = .portrait
        let hosting = UIHostingController(rootView: MainTabView())
        setRoot(hosting)

        // мягко попросим систему применить ограничение
        UIViewController.attemptRotationToDeviceOrientation()
    }

    private func setRoot(_ vc: UIViewController) {
        print("➡️ LaunchVC setRoot: \(type(of: vc))")
        (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController = vc
    }
}



