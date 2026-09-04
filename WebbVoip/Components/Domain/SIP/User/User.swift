import Foundation

enum UserException: Error {
    case registrationAlreadyExist
    case registrationNotExist
    case registrationNotValid
}

class User: Identifiable {
    static let instance = User()
    var autoCameraOff: Bool {
        get {
            UserDefaultsConfigurator.instance.cameraAutoOff
        }
        set {
            UserDefaultsConfigurator.instance.cameraAutoOff = newValue
        }
    }

    var onlyAudioCall: Bool {
        get {
            UserDefaultsConfigurator.instance.defaultAudioOnly
        }
        set {
            UserDefaultsConfigurator.instance.defaultAudioOnly = newValue
        }
    }

    private(set) var allRegistrations: [Registration] = []
    private(set) var defaultRegistration: Registration?

    /// Add new registration to current list
    /// - Parameter registration: new registration
    func addRegistration(registration: Registration) throws {
        if allRegistrations.contains(registration) {
            throw UserException.registrationAlreadyExist
        }
        if registration.username.isEmpty || registration.url.isEmpty {
            throw UserException.registrationNotValid
        }
        try ApplicationDataStack.instance.addRegistrationData(registration: RegistrationData(registration: registration))
        allRegistrations.append(registration)
    }

    /// Remove registration from current list
    /// - Parameter registration: registration to be removed
    func removeRegistration(registration: Registration) throws {
        try? registration.unregister()
        if registration.registrationStatus != .unregistered {
            throw RegistrationException.statusIsNotUnregistered
        }
        if !allRegistrations.contains(registration) {
            throw UserException.registrationNotExist
        }
        if defaultRegistration == registration {
            defaultRegistration = nil
        }
        try? ApplicationDataStack.instance.deleteRegistrationData(registration: RegistrationData(registration: registration))
        allRegistrations.removeAll(where: { $0 == registration })
    }

    /// set the registration to default
    /// - Parameter reg: the registration to set to default
    func setDefaultRegistration(reg: Registration?) {
        do {
            try reg?.setAsDefault()
        } catch {
            print("Not changing as encountered an error")
        }
        defaultRegistration = reg
    }

    /// Load non-existed registration listing to allRegistrations
    func loadMoreFromDataBase() throws {
        ApplicationDataStack.instance.retriveMissingRegistrationData(registrations: &allRegistrations)
    }

    private init() {
        do {
            self.allRegistrations = try LinphoneEngineCore.instance().getCurrentRegistrations()
            try loadMoreFromDataBase()
            if let defaultedRegData = try LinphoneEngineCore.instance().getDefaultAccount() {
                self.defaultRegistration = allRegistrations.filter { reg in
                    defaultedRegData.equivalent(reg: reg)
                }.first
            }
        } catch {
            print("something went wrong")
        }
    }
}
