
import Foundation
import FirebaseDatabase

struct FirebaseLogger {

    private static let dbRef = Database.database().reference()

    static func logSession(uuid: String, attToken: String?) {
        print("⏳ FirebaseLogger: пишем сессию \(uuid) в Firebase")

        let sessionData: [String: Any] = [
            "uuid": uuid,
            "att_token": attToken ?? "",
            "timestamp": ServerValue.timestamp()
        ]

        dbRef.child("sessions").child(uuid).setValue(sessionData) { error, _ in
            if let error = error {
                print("❌ FirebaseLogger: ошибка записи сессии: \(error.localizedDescription)")
            } else {
                print("✅ FirebaseLogger: сессия \(uuid) успешно записана")
            }
        }
    }

    static func logEvent(uuid: String, name: String, payload: [String: Any]? = nil) {
        print("⏳ FirebaseLogger: пишем событие \(name) для сессии \(uuid)")

        var eventData: [String: Any] = [
            "event_name": name,
            "timestamp": ServerValue.timestamp()
        ]
        if let payload = payload {
            eventData["payload"] = payload
        }

        dbRef.child("sessions")
             .child(uuid)
             .child("events")
             .childByAutoId()
             .setValue(eventData) { error, _ in
                 if let error = error {
                     print("❌ FirebaseLogger: ошибка записи события \(name): \(error.localizedDescription)")
                 } else {
                     print("✅ FirebaseLogger: событие \(name) успешно записано")
                 }
             }
    }
}
