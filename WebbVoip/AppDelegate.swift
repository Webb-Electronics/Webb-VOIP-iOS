import Foundation
import PushKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        setupPushKit()
        return true
    }

    func setupPushKit() {
        print("*** setupPushKit")
        let voipRegistry = PKPushRegistry(queue: .main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]
    }
}

// MARK: PKPushRegistryDelegate

extension AppDelegate: PKPushRegistryDelegate {
    func pushRegistry(_: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for _: PKPushType) {
        print("*** pushRegistry: didUpdate pushCredentials")
        let deviceToken = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        print("*** device token: \(deviceToken)")
        UserDefaultsConfigurator.instance.userApnToken = deviceToken
    }

    func pushRegistry(_: PKPushRegistry, didInvalidatePushTokenFor _: PKPushType) {
        print("*** didInvalidatePushTokenFor")
    }

    func pushRegistry(_: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for _: PKPushType) {
        print("*** didReceiveIncomingPushWith")
        let dictionary = payload.dictionaryPayload as NSDictionary
        try? LinphoneEngineCore.instance().showCallkitWithPartialInfo(callerName: dictionary["caller"] as? String)
    }
}
