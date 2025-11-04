import UIKit
import Firebase
import FirebaseMessaging
import AppsFlyerLib
import AppTrackingTransparency


@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        print("🚀 AppDelegate start")
        FirebaseApp.configure()
        
      
        
         UNUserNotificationCenter.current().delegate = self
         UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
         print("🔔 Push permission: \(granted)")
             DispatchQueue.main.async {
                 UIApplication.shared.registerForRemoteNotifications()
                 
                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                     self.requestTrackingAuthorization()
                       }
             }
         }
         Messaging.messaging().delegate = TokenStore.shared
         
        
        TokenStore.shared.start()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        print("✅ Firebase configured")
        
        
        AppsFlyerLib.shared().appsFlyerDevKey = "P8Cmc5f5JjkNjQ3haoGbWS"
        AppsFlyerLib.shared().appleAppID     = "6754596120"
        AppsFlyerLib.shared().delegate       = self
       // AppsFlyerLib.shared().isDebug        = true // пока тестируешь
        
       
        
        AppsFlyerLib.shared().start()
        
        // Генерация UUID + AdServices token
        let uuid = DeviceIDProvider.persistedLowerUUID()
        let att = AdServicesTokenProvider.fetchBase64Token()
        
        // Лог сессии в Realtime DB
        FirebaseLogger.logSession(uuid: uuid, attToken: att)
        
        // Передадим контекст в StartGateService (чтобы логировать дальнейшие события)
        StartGateService.shared.configureSession(uuid: uuid, attToken: att)
        
        // Окно и стартовый VC
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = LaunchViewController()
        window?.makeKeyAndVisible()
        print("✅ UIWindow + LaunchViewController set")

        
        return true
    }
    
    private func requestATTAndStartSDKs() {
        guard #available(iOS 14.5, *) else {
            // На iOS < 14.5 ATT нет — просто стартуем SDK
            startSDKsWithCurrentPrivacyState()
            return
        }

        ATTrackingManager.requestTrackingAuthorization { status in
            // status: .authorized / .denied / .notDetermined / .restricted
            DispatchQueue.main.async {
                self.startSDKsWithCurrentPrivacyState()
            }
        }
    }

    private func startSDKsWithCurrentPrivacyState() {
        if #available(iOS 14.5, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            switch status {
            case .authorized:
              print("auth")
            default:
                print("default")
            }
        }

        // Теперь можно стартовать SDK
        AppsFlyerLib.shared().start()
        // остальной ваш старт (Firebase Analytics можно оставить — он не требует ATT для базовой аналитики)
    }
    
    private func requestTrackingAuthorization() {
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    switch status {
                    case .authorized:
                        print("123 ✅ Tracking разрешён")
                    case .denied:
                        print("13 ❌ Пользователь отказал")
                    case .restricted:
                        print("123 ⚠️ Ограничено настройками")
                    case .notDetermined:
                        print("123 ⌛ Пользователь ещё не сделал выбор")
                    @unknown default:
                        break
                    }
                }
            } else {
                // На iOS ниже 14 ATT не требуется
                print("123 ATT недоступен, можно сразу использовать IDFA")
            }
        }
    
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        let m = OrientationManager.shared.mask
        print("🧭 supportedInterfaceOrientations → \(m)")
        return m
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("✅ APNs token set for FirebaseMessaging")
    }
    
}

final class OrientationManager {
    static let shared = OrientationManager()
    private init() {}
    
    var mask: UIInterfaceOrientationMask = .all
}

extension AppDelegate: MessagingDelegate, UNUserNotificationCenterDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("✅ FCM token: \(fcmToken ?? "nil")")
        // отправь на свой backend если нужно
    }
}

extension AppDelegate: AppsFlyerLibDelegate {
    func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
        print("✅ AppsFlyer conversion data: \(conversionInfo)")
    }
    func onConversionDataFail(_ error: Error) {
        print("❌ AppsFlyer conversion error: \(error.localizedDescription)")
    }
}
