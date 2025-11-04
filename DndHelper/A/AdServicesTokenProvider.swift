

import Foundation
import AdServices

struct AdServicesTokenProvider {

    /// Возвращает base64-строку токена или nil, если токен недоступен.
    static func fetchBase64Token() -> String? {
        print("⏳ AdServicesTokenProvider: начинаем получение att_token")

        guard #available(iOS 14.3, *) else {
            print("⚠️ iOS < 14.3: AdServices недоступен")
            return nil
        }

        do {
            let token = try AAAttribution.attributionToken()
            guard let data = token.data(using: .utf8) else {
                print("❌ Не удалось конвертировать токен в Data")
                return nil
            }
            let base64 = data.base64EncodedString()
            print("✅ AdServicesTokenProvider: получен att_token (base64) длиной \(base64.count) символов")
            return base64
        } catch {
            print("❌ Ошибка получения AdServices token: \(error.localizedDescription)")
            return nil
        }
    }
}
