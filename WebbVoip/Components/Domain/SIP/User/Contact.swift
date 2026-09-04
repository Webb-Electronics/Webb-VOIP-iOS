import Foundation

/// The Contact base data type, containing the name and list of dialing target, immutable
struct Contact: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let dialTarget: [String]

    /// Initialize the contact class
    /// - Parameters:
    ///   - name: The name of the contact
    ///   - dialTarget: list of strings of dial targets
    init(name: String, dialTarget: [String]) {
        self.name = name
        self.dialTarget = dialTarget
    }
}

/// The Contact phone book object, contains a list of contacts
class ContactPhoneBook: Hashable {
    private let id = UUID()
    /// the URL of the phone book
    private(set) var url: String
    /// Name of the phonebook
    private(set) var name: String
    private(set) var contacts: [Contact]

    private init(url: String, data: (String, [Contact])) {
        self.url = url
        (self.name, self.contacts) = data
    }

    /// Create the phone book using a URL
    /// - Parameter url: the phone book's URL, support fanvil, yealink, grandstream, vital pbx formats
    /// - Returns: The Contact Phone Book object
    static func fromURL(url: String) async throws -> ContactPhoneBook {
        try await ContactPhoneBook(url: url, data: NetworkPhoneBookAPI.retrieveData(url: url))
    }

    static func == (lhs: ContactPhoneBook, rhs: ContactPhoneBook) -> Bool {
        lhs.url == rhs.url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// get the registration (only registered) that has similarities in its URL
    /// - Returns: (List of Registrations that has associations, List of Registration that has no associations))
    func getAssociatedRegistrations() -> ([Registration], [Registration]) {
        let onlineRegistrations = User.instance.allRegistrations.filter { reg in
            reg.registrationStatus == .registered
        }
        let sameHostOnlineRegs = onlineRegistrations.filter { reg in
            ContactPhoneBook.checkUrlMightAssociate(self, reg: reg)
        }

        let otherHostOnlineRegs = onlineRegistrations.filter { reg in
            !sameHostOnlineRegs.contains(reg)
        }
        return (sameHostOnlineRegs, otherHostOnlineRegs)
    }

    /// Check if the registration is associated with the phone book
    /// - Parameters:
    ///   - checkPhoneBook: the phone book
    ///   - reg: the registration to check
    /// - Returns: boolean if it's true
    static func checkUrlMightAssociate(_ checkPhoneBook: ContactPhoneBook, reg: Registration) -> Bool {
        var toCompareString = ""
        let splitString = reg.url.split(separator: "/")
        if reg.url.contains("://") {
            toCompareString = String(splitString.first ?? "")
        } else if splitString.count > 2 {
            toCompareString = String(splitString[2])
        } else {
            toCompareString = reg.url
        }
        return checkPhoneBook.url.contains(toCompareString)
    }
}

/// Singleton object to manage all phonebooks, Call loadFromCoreData to sync with database
class ContactManager {
    private(set) var phoneBooks: [ContactPhoneBook] = []
    /// if the Contact Manager has initilized with loadFromCoreData
    private(set) var initialized = false

    static let instance = ContactManager()

    /// Load data from the database
    func loadFromCoreData() async throws {
        let coreDataURLs = ApplicationDataStack.instance.retrievePhoneBookURL()
        var phoneBooks: [ContactPhoneBook] = []
        for phoneBookUrl in coreDataURLs {
            try await phoneBooks.append(ContactPhoneBook.fromURL(url: phoneBookUrl))
        }
        self.phoneBooks = phoneBooks
        initialized = true
    }

    /// Add a phone book, and save to database
    /// - Parameter url: the URL of the phone book
    func addPhoneBook(url: String) async throws {
        guard initialized else {
            throw GeneralError.runtimeError("Class has not been init, call loadFromCoreData")
        }
        guard
            !phoneBooks.contains(where: { cpb in
                cpb.url == url
            })
        else {
            throw GeneralError.runtimeError("same url already exist")
        }
        try await phoneBooks.append(ContactPhoneBook.fromURL(url: url))
        try ApplicationDataStack.instance.addPhoneBookURL(url: url)
    }

    /// Remove an existing phone book
    /// - Parameter cpb: the Contact Phone Book Object
    func removePhoneBook(cpb: ContactPhoneBook) throws {
        guard initialized else {
            throw GeneralError.runtimeError("Class has not been init, call loadFromCoreData")
        }

        guard
            phoneBooks.contains(where: { dcpb in
                dcpb.url == cpb.url
            })
        else {
            throw GeneralError.runtimeError("phone book is not saved")
        }
        phoneBooks.removeAll { dcpb in
            dcpb.url == cpb.url
        }
        try ApplicationDataStack.instance.deletePhoneBookURL(url: cpb.url)
    }

    /// find potential String of the name for given number
    /// - Parameters:
    ///   - number: the number to search
    ///   - reg: the registration to give priority
    /// - Returns: The potential name, nullable
    func findContactName(_ number: String, reg: Registration? = nil) throws -> String? {
        guard initialized else {
            throw GeneralError.runtimeError("Class has not been init, call loadFromCoreData")
        }
        var pbs = phoneBooks
        if let reg {
            pbs = phoneBooks.filter { cpb in
                ContactPhoneBook.checkUrlMightAssociate(cpb, reg: reg)
            }
        }
        for pb in pbs {
            for contact in pb.contacts where contact.dialTarget.contains(number) {
                return contact.name
            }
        }
        return nil
    }

    /// Get every contact avilable
    /// - Returns: all contacts, empty if not initialized
    func getAllContacts() -> [Contact] {
        phoneBooks.flatMap { cpb in
            cpb.contacts
        }
    }

    private init() {}
}
