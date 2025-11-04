import Foundation

enum DeviceIDProvider {
    static func persistedLowerUUID() -> String {
        if let v = UserDefaults.standard.string(forKey: MyConstants.udidKey) { return v }
        let u = UUID().uuidString.lowercased()
        UserDefaults.standard.set(u, forKey: MyConstants.udidKey)
        print("🆔 Persisted UUID v4 lower = \(u)")
        return u
    }
}
