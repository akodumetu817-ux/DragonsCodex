
import Foundation


final class RedirectHandler: NSObject, URLSessionDelegate, URLSessionTaskDelegate {

    private var redirectChain: [URL] = []
    private let completion: (String) -> Void

    /// - Parameter completion: вызывается с финальным URL (в виде строки)
    init(completion: @escaping (String) -> Void) {
        self.completion = completion
    }

    /// Отслеживаем каждый редирект и добавляем его в цепочку
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {

        if let url = request.url {
            redirectChain.append(url)
            print("➡️ RedirectHandler: редирект на \(url.absoluteString)")
        }
        completionHandler(request) // продолжаем редирект
    }

    /// Когда загрузка завершена (с ошибкой или без) — возвращаем финальный URL
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
