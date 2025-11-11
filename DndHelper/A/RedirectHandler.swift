
import Foundation


final class RedirectHandler: NSObject, URLSessionDelegate, URLSessionTaskDelegate {

    private var redirectChain: [URL] = []
    private let completion: (String) -> Void

    init(completion: @escaping (String) -> Void) {
        self.completion = completion
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {

        if let url = request.url {
            redirectChain.append(url)
            print("➡️ RedirectHandler: редирект на \(url.absoluteString)")
        }
        completionHandler(request)
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {

        let finalURL = redirectChain.last?.absoluteString ??
                       task.originalRequest?.url?.absoluteString ?? ""

        if let error = error {
            print("⚠️ RedirectHandler: загрузка завершена с ошибкой: \(error.localizedDescription)")
        }
        print("✅ RedirectHandler: финальный URL = \(finalURL)")

        completion(finalURL)
    }
}
