import Foundation

class GeneralSettingsVM: ObservableObject {
    let registrations: [Registration]
    @Published var registrationDefault: Registration {
        didSet {
            User.instance.setDefaultRegistration(reg: registrationDefault)
        }
    }

    @Published var onlyAudioCall = false {
        didSet {
            User.instance.onlyAudioCall = onlyAudioCall
        }
    }

    @Published var autoCameraOff = false {
        didSet {
            User.instance.autoCameraOff = autoCameraOff
        }
    }

    init() {
        self.registrations = User.instance.allRegistrations.filter {
            $0.registrationStatus == .registered
        }
        self.registrationDefault = User.instance.defaultRegistration ?? (registrations.isEmpty ? Registration() : registrations[0])
        self.onlyAudioCall = User.instance.onlyAudioCall
        self.autoCameraOff = User.instance.autoCameraOff
    }
}
