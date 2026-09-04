import Foundation

class RegistrationPageVM: ObservableObject {
    @Published var user: User
    @Published var showSettings: Bool
    @Published var showAddNew: Bool
    @Published var showDetail: Bool
    var showingRegistration: Registration?
    init() {
        self.user = User.instance
        self.showSettings = false
        self.showAddNew = false
        self.showDetail = false
        // initliaze other classes
        Task {
            try? await ContactManager.instance.loadFromCoreData()
        }
    }

    func setShowingDetail(reg: Registration) {
        showingRegistration = reg
        showDetail = true
    }

    func reloadRegistrations() {
        do {
            try user.loadMoreFromDataBase()
            objectWillChange.send()
        } catch {
            print("Error refreshing")
        }
    }
}
