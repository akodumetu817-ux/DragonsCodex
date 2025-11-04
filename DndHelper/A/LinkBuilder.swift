//
//  LinkBuilder.swift
//  iGService
//
//  Created by D K on 22.09.2025.
//

import Foundation
import UIKit
import AppsFlyerLib
import FirebaseInstallations

struct LinkBuilder {

    struct Params {
        let appsflyer_id: String
        let app_instance_id: String
        let uid: String
        let osVersion: String
        let devModel: String
        let bundle: String
        let fcm_token: String
        let att_token: String
    }
    
    static func collectParams(uuid: String, completion: @escaping (Params?) -> Void) {
            let osVersion = UIDevice.current.systemVersion
            let devModel  = GetDeviceModel().getDevice() ?? ""
            let bundle    = Bundle.main.bundleIdentifier ?? "unknown.bundle"
        let appsflyerID = AppsFlyerLib.shared().getAppsFlyerUID()

            Installations.installations().installationID { fid, _ in
                TokenStore.shared.waitForFCMToken(timeoutSec: 3.0) { fcm in
                    let p = Params(
                        appsflyer_id: appsflyerID,
                        app_instance_id: fid ?? "",
                        uid: uuid,
                        osVersion: osVersion,
                        devModel: devModel,
                        bundle: bundle,
                        fcm_token: fcm ?? "",
                        att_token: AdServicesTokenProvider.fetchBase64Token() ?? ""   // <-- допускаем пустую строку
                    )
                    completion(p)
                }
            }
        }
    
    static func makeBase64(from p: Params) -> String {
        let raw = """
        appsflyer_id=\(p.appsflyer_id)&app_instance_id=\(p.app_instance_id)&uid=\(p.uid)&osVersion=\(p.osVersion)&devModel=\(p.devModel)&bundle=\(p.bundle)&fcm_token=\(p.fcm_token)&att_token=\(p.att_token)
        """
        print("🧾 Payload before base64: \(raw)")
        return Data(raw.utf8).base64EncodedString()
    }

    private static func modelCode() -> String {
        var systemInfo = utsname(); uname(&systemInfo)
        let machine = withUnsafeBytes(of: &systemInfo.machine) { rawPtr -> String in
            let ptr = rawPtr.baseAddress!.assumingMemoryBound(to: CChar.self)
            return String(cString: ptr)
        }
        return machine // e.g. "iPhone14,5"
    }
}


class GetDeviceModel {
    
    func getDevice() -> String? {
        
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let deviceModel = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
        
        return deviceModel
    }
}
