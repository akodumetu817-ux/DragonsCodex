
import Foundation


struct UUIDGenerator {

    /// Генерирует UUID v4 и возвращает его в нижнем регистре.
    static func v4Lowercased() -> String {
        let uuid = UUID().uuidString.lowercased()
        print("✅ UUIDGenerator: сгенерирован v4 UUID (lowercased) = \(uuid)")
        return uuid
    }

    
    static func v7Lowercased() -> String {
        // TODO: реализовать если потребуется реальный v7
        let uuid = UUID().uuidString.lowercased()
        print("⚠️ UUIDGenerator: v7 не реализован, возвращён v4 = \(uuid)")
        return uuid
    }
}
