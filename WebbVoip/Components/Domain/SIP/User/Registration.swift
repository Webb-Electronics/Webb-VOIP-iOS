import Foundation

/// The type of registration status
enum RegistrationStatus {
    case registered
    case unregistered
    case registering
}

/// The types of transportation protol to be used in most of the case, except in linphone
enum SIPTransportProtocol: String, CaseIterable {
    case udp = "UDP"
    case tls = "TLS"

    static func fromRawValue(value: Int) -> SIPTransportProtocol {
        switch value {
        case 2:
            .tls
        default:
            .udp
        }
    }
}

/// The general error class that throws a runtime error, usually called by data layer
enum GeneralError: Error {
    case runtimeError(String)
}

/// Exceptions thrown by Registration class
enum RegistrationException: Error {
    case statusIsNotUnregistered
    case alreadyUnregistered
    case valueInvalid
}

///  Registration Data Class, as a struct, to hold the changable data, later on loaded as a registration
struct RegistrationData {
    var url: String = ""
    var username: String = ""
    var password: String = ""
    var transport: SIPTransportProtocol = .udp

    /// Init the struct with a registration, mainly used by an existing registration
    /// - Parameter registration: the registration object to be passed in
    init(registration: Registration) {
        self.url = registration.url
        self.username = registration.username
        self.password = registration.password
        self.transport = registration.transport
    }

    /// To create an empty, default data
    init() {}
    /// Initilize with CDRegistration class from coredata
    /// - Parameter cdr: CDRegistration object
    init(cdr: CDRegistration) {
        self.url = cdr.url ?? ""
        self.username = cdr.username ?? ""
        self.password = cdr.password ?? ""
        self.transport = SIPTransportProtocol(rawValue: cdr.transport ?? "UDP") ?? .udp
    }

    /// To check if the current data has the same data to a registration
    /// - Parameter reg: the registration to be compared with
    /// - Returns: if it's the same
    func equivalent(reg: Registration) -> Bool {
        transport == reg.transport && url == reg.url && username == reg.username && password == reg.password
    }
}

/// The general registration class
class Registration: Identifiable, Hashable, ObservableObject {
    let id = UUID()
    private(set) var url: String
    private(set) var username: String
    private(set) var password: String
    private(set) var transport: SIPTransportProtocol
    private(set) var sipAccount: LinphoneAccount?
    /// Whenever the registration status is changed, it will call objectWillChange.send()
    private(set) var registrationStatus: RegistrationStatus {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
            if registrationStatus == .registered {
                Task {
                    try? await NetworkNotificationServerAPI.register(dialCode: username, serverDomain: url)
                }
            }
        }
    }

    /// The PhoneBook's name if exist, nil if doesn't
    var realName: String? {
        try? ContactManager.instance.findContactName(username, reg: self)
    }

    /// Register to the sip server
    func register() throws {
        if registrationStatus != .unregistered {
            throw RegistrationException.statusIsNotUnregistered
        }
        createSIPAccountWithoutRegistration()
        if let sa = sipAccount {
            try sa.register()
        }
    }

    /// unregister to the sip server
    func unregister() throws {
        try sipAccount?.unregister()
        sipAccount = nil
        Task {
            try? await NetworkNotificationServerAPI.unregister(dialCode: username, serverDomain: url)
        }
    }

    /// Set itself as the default registration to be used
    func setAsDefault() throws {
        if registrationStatus != .registered {
            throw RegistrationException.valueInvalid
        }
        try sipAccount?.setAsDefault()
    }

    /// Dial out action
    /// - Parameter number: Number to dial
    func dial(number: String) throws {
        if registrationStatus != .registered {
            throw RegistrationException.valueInvalid
        }
        // add display name that matches the contact list

        try sipAccount?.dial(
            audioOnly: User.instance.onlyAudioCall,
            number: number,
            displayName: try? ContactManager.instance.findContactName(number, reg: self)
        )
    }

    /// Create the LinphoneAccount object without doing register(), mainly used by the LinphoneEngineCore Object to create registration linkage
    func createSIPAccountWithoutRegistration() {
        if let sa = sipAccount {
            try? sa.unregister()
        }
        sipAccount = LinphoneAccount(registration: self, updater: { newRegistrationStatus in
            self.registrationStatus = newRegistrationStatus
        })
    }

    /// Functions to get a combined string of current registration info, mainly used in debugs
    /// - Returns: String that represents the registration's info
    func toString() -> String {
        "url: \(url), username: \(username), password: \(password), transport: \(transport), registrationStatus: \(registrationStatus)"
    }

    /// Empty registration initializer, can pass in argument to change info
    /// - Parameters:
    ///   - url: the domain of the server
    ///   - username: the username
    ///   - password: password
    ///   - transport: SIPTransportProtocol either udp or tls
    init(url: String = "", username: String = "", password: String = "", transport: SIPTransportProtocol = .udp) {
        self.url = url
        self.username = username
        self.password = password
        self.transport = transport
        self.registrationStatus = .unregistered
    }

    /// initalize with the RegistrationData struct
    /// - Parameter newData: the data object passed in
    init(newData: RegistrationData) {
        self.url = newData.url
        self.username = newData.username
        self.password = newData.password
        self.transport = newData.transport
        self.registrationStatus = .unregistered
    }

    static func == (lhs: Registration, rhs: Registration) -> Bool {
        lhs.username == rhs.username && lhs.url == rhs.url && lhs.transport == rhs.transport && lhs.password == rhs.password
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    private func throwErrorIfInvalid(reg: RegistrationData) throws {
        if registrationStatus != .unregistered {
            throw RegistrationException.statusIsNotUnregistered
        }
        if reg.url.isEmpty || reg.username.isEmpty {
            throw RegistrationException.valueInvalid
        }
    }

    /// to update multiple info at once
    /// - Parameter reg: new data in RegistrationData object
    func updateWithNewData(reg: RegistrationData) throws {
        try throwErrorIfInvalid(reg: reg)
        let currentRegData = RegistrationData(registration: self)
        url = reg.url
        username = reg.username
        transport = reg.transport
        password = reg.password
        objectWillChange.send()
        try ApplicationDataStack.instance.saveRegistrationData(currentData: currentRegData, newData: reg)
    }
}
