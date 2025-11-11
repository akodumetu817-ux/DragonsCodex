
import Foundation


struct UUIDGenerator {

    static func v4Lowercased() -> String {
        let uuid = UUID().uuidString.lowercased()
        print("✅ UUIDGenerator: сгенерирован v4 UUID (lowercased) = \(uuid)")
        return uuid
    }

    
    static func v7Lowercased() -> String {
        let uuid = UUID().uuidString.lowercased()
        print("⚠️ UUIDGenerator: v7 не реализован, возвращён v4 = \(uuid)")
        return uuid
    }
}
