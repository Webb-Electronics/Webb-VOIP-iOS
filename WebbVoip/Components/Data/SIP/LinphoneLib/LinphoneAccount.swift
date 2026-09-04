// import Foundation
import linphonesw

/// some linphone account error to be thrown by LinphoneAccount class
enum LinPhoneError: Error {
    case phoneNotRegistered
    case phoneIsRegistered
}

/// A class representing each Linphone account in the core, to be created by registration
class LinphoneAccount: Hashable {
    let username: String
    let password: String
    let domain: String
    var status: RegistrationStatus {
        didSet {
            updateStatusFunc(status)
        }
    }

    let updateStatusFunc: (RegistrationStatus) -> Void
    let transportType: SIPTransportProtocol

    /// Initialize the Linphone account with current registration
    /// - Parameter registration: the registration object passed in
    init(registration: Registration, updater: @escaping (RegistrationStatus) -> Void) {
        self.username = registration.username
        self.password = registration.password
        self.domain = registration.url
        self.status = registration.registrationStatus
        self.updateStatusFunc = updater
        self.transportType = registration.transport
    }

    /// Register to the linphone engine
    func register() throws {
        if status == .registered {
            throw LinPhoneError.phoneIsRegistered
        }
        try LinphoneEngineCore.instance().addAccount(acc: self)
    }

    /// Unregister to the linphone engine
    func unregister() throws {
        try LinphoneEngineCore.instance().removeAccount(acc: self)
    }

    deinit {
        if self.status != .unregistered {
            do {
                try unregister()
            } catch {
                print("Error de-init")
            }
        }
    }

    static func == (lhs: LinphoneAccount, rhs: LinphoneAccount) -> Bool {
        lhs.domain == rhs.domain && lhs.username == rhs.username
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(username)
        hasher.combine(domain)
    }

    /// set itself as the default, to be called by registration object
    func setAsDefault() throws {
        try LinphoneEngineCore.instance().setDefaultAccount(acc: self)
    }

    /// Dial out to others
    /// - Parameters:
    ///   - audioOnly: if only audio transimission
    ///   - number: the actual number to dial
    ///   - displayName: the display name for the number dialed
    func dial(audioOnly: Bool, number: String, displayName: String? = nil) throws {
        try LinphoneEngineCore.instance().dial(useAccount: self, audioOnly: audioOnly, number: number, displayName: displayName)
    }
}
