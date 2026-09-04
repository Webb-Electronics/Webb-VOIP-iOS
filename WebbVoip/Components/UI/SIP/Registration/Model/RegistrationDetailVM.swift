import Foundation

class RegistrationDetailVM: ObservableObject {
    var currentUser: User = .instance
    @Published var newData: RegistrationData

    init() {
        self.newData = RegistrationData()
    }

    init(reg: Registration) {
        self.newData = RegistrationData(registration: reg)
    }
}

class AddNewRegistrationDetailSheetVM: RegistrationDetailVM {
    @Published var showInvalidEntry = false
    @Published var showAlreadyExist = false
    @Published var loading = false
    var registration: Registration?
    func register() throws {
        guard let reg = registration else {
            showInvalidEntry = true
            throw GeneralError.runtimeError("Error")
        }
        do {
            try reg.register()
        } catch {
            showInvalidEntry = true
            throw GeneralError.runtimeError("Error")
        }
    }

    func saveData() throws {
        registration = Registration(newData: newData)
        guard let reg = registration else {
            showInvalidEntry = true
            throw GeneralError.runtimeError("Error")
        }
        do {
            try currentUser.addRegistration(registration: reg)
        } catch UserException.registrationAlreadyExist {
            showAlreadyExist = true
            throw GeneralError.runtimeError("Error")
        } catch {
            showInvalidEntry = true
            throw GeneralError.runtimeError("Error")
        }
    }
}

enum ExistingRegistrationDetailSheetField {
    case username
    case password
    case url
}

class ExistingRegistrationDetailSheetVM: RegistrationDetailVM {
    @Published var registerFailed = false
    @Published var saveDataFailed = false
    @Published var operationFailed = false
    func getContact(_ reg: Registration) -> [Contact] {
        var all: [Contact] = []
        for pb in ContactManager.instance.phoneBooks where ContactPhoneBook.checkUrlMightAssociate(pb, reg: reg) {
            all += pb.contacts
        }
        return all
    }

    func newDataAlreadyExist(currentData: Registration) -> Bool {
        currentUser.allRegistrations.filter { reg in
            reg.id != currentData.id
        }.contains { reg in
            newData.equivalent(reg: reg)
        }
    }

    func render() {
        objectWillChange.send()
    }
}
