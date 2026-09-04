import Foundation

class ContactPageVM: ObservableObject {
    @Published var showEdit = false
    @Published var contacts: [Contact: ContactPhoneBook] = [:]
    @Published var errorLoading = false
    @Published var showDetailed: Bool = false
    @Published var errorDialOut = false
    var detailedContact: Contact?

    init() {
        if !ContactManager.instance.initialized {
            Task {
                try? await ContactManager.instance.loadFromCoreData()
                DispatchQueue.main.async {
                    self.reloadContacts()
                }
            }

        } else {
            reloadContacts()
        }
    }

    func reloadContacts() {
        guard ContactManager.instance.initialized else {
            errorLoading = true
            return
        }
        contacts.removeAll()
        for pb in ContactManager.instance.phoneBooks {
            for contact in pb.contacts {
                contacts[contact] = pb
            }
        }
    }

    func getCurrentList() -> [Contact] {
        Array(contacts.keys).sorted { c1, c2 in
            c1.name < c2.name
        }
    }

    func updateDetailContact(_ contact: Contact? = nil, show: Bool = true) {
        detailedContact = contact
        showDetailed = show
    }

    func getRegistrations() -> ([Registration], [Registration])? {
        guard let dContact = detailedContact else {
            return nil
        }
        return contacts[dContact]?.getAssociatedRegistrations()
    }
}

class ManageContactListSheetVM: ObservableObject {
    @Published var newUrl: String = ""
    @Published var loading: Bool = false
    @Published var error: String = ""
    @Published var phoneBooks: [ContactPhoneBook]

    init() {
        self.phoneBooks = ContactManager.instance.phoneBooks
    }

    func addPhoneBook() async {
        updateUIVar(loading: true)
        do {
            try await ContactManager.instance.addPhoneBook(url: newUrl)
            updateUIVar(phoneBooks: ContactManager.instance.phoneBooks)
        } catch {
            updateUIVar(error: "Error adding phonebook")
            print(error)
        }
        updateUIVar(loading: false, newURL: "")
    }

    func removePhoneBook(index: IndexSet) {
        do {
            let currentPhoneBooks = index.map { self.phoneBooks[$0] }.first
            guard let currentPhoneBook = currentPhoneBooks else {
                print("empty")
                updateUIVar(error: "Error parsing phonebooks")
                return
            }
            try ContactManager.instance.removePhoneBook(cpb: currentPhoneBook)
            updateUIVar(removingPhoneBook: index)
        } catch {
            print(error)
            updateUIVar(error: "Error removing phonebook")
        }
    }

    private func updateUIVar(loading: Bool? = nil, error: String? = nil, phoneBooks: [ContactPhoneBook]? = nil, newURL: String? = nil, removingPhoneBook: IndexSet? = nil) {
        DispatchQueue.main.async {
            if let loading {
                self.loading = loading
            }
            if let error {
                self.error = error
            }
            if let phoneBooks {
                self.phoneBooks = phoneBooks
            }
            if let newURL {
                self.newUrl = newURL
            }

            if let indexset = removingPhoneBook {
                self.phoneBooks.remove(atOffsets: indexset)
            }
        }
    }
}
