import Foundation

/// The Class to store phone base configuration, key-value based, automatically configured into compute values
class UserDefaultsConfigurator {
    private let defaults = UserDefaults.standard
    static let instance = UserDefaultsConfigurator()

    /// Start with audio call only defaultly
    var defaultAudioOnly: Bool {
        get {
            defaults.bool(forKey: "StartAudioOnlySession")
        }
        set {
            defaults.setValue(newValue, forKey: "StartAudioOnlySession")
        }
    }

    /// Turn off camera when joining a video call
    var cameraAutoOff: Bool {
        get {
            defaults.bool(forKey: "CameraAutoOff")
        }
        set {
            defaults.setValue(newValue, forKey: "CameraAutoOff")
        }
    }

    /// current APN Token, if changed registeredToken will be cleared
    var userApnToken: String {
        get {
            defaults.string(forKey: "APN") ?? ""
        }
        set {
            if newValue != userApnToken {
                registeredTokens = []
            }
            defaults.setValue(newValue, forKey: "APN")
        }
    }

    /// registered Token for a list of dial codes
    var registeredTokens: [String] {
        get {
            defaults.array(forKey: "RegisteredTokens") as? [String] ?? []
        }
        set {
            defaults.setValue(newValue, forKey: "RegisteredTokens")
        }
    }

    private init() {}
}
