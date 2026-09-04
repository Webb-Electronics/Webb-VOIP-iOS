import CloudKit
import CoreData
import Foundation

/// Singleton class to store data via coredata and eventually sync across iCloud
class ApplicationDataStack: ObservableObject {
    static let instance = ApplicationDataStack()

    // Create a persistent container as a lazy variable to defer instantiation until its first use.
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        // Pass the data model filename to the container’s initializer.
        let container = NSPersistentCloudKitContainer(name: "ApplicationData")
        // Load any persistent stores, which creates a store if none exists.
        container.loadPersistentStores { _, error in
            if let error {
                // Handle the error appropriately. However, it's useful to use
                // `fatalError(_:file:line:)` during development.
//                fatalError("Failed to load persistent stores: \(error.localizedDescription)")
                print("Failed to load persistent stores: \(error.localizedDescription)")
            }
        }

        return container
    }()

//    public func startAutomaticMergeChanges(onChangeFunction _: () -> Void) {
//        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
//        persistentContainer.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
//    }

    private init() {}

    /// save data if there is any changes
    private func save() throws {
        if persistentContainer.viewContext.hasChanges {
            try persistentContainer.viewContext.save()
        }
    }
}

// MARK: Registration related functions

extension ApplicationDataStack {
    /// Add to the registrations in-place where it exists here in the database but not in the memory
    /// - Parameter registrations: pointer of Registration list, will be modified in-place
    func retriveMissingRegistrationData(registrations: inout [Registration]) {
        let fr = CDRegistration.fetchRequest()
        do {
            let fetchResult = try persistentContainer.viewContext.fetch(fr)
            for incompleteRegistration in fetchResult where !registrations.contains(where: { cdr in
                cdr.username == incompleteRegistration.username &&
                    cdr.url == incompleteRegistration.url &&
                    cdr.password == incompleteRegistration.password &&
                    cdr.transport.rawValue == incompleteRegistration.transport
            }) {
                registrations.append(Registration(newData: RegistrationData(cdr: incompleteRegistration)))
            }
        } catch {
            print("error getting registrations, exiting with no appened result")
        }
    }

    /// Add new reigstration to database, duplicated will not be added and will throw an error
    /// - Parameter registration: new registration
    func addRegistrationData(registration: RegistrationData) throws {
        let fetchRequest = CDRegistration.fetchRequest()
        let fetchResult = try persistentContainer.viewContext.fetch(fetchRequest).filter { cdr in
            registration.username == cdr.username &&
                registration.password == cdr.password &&
                registration.url == cdr.url &&
                registration.transport.rawValue == cdr.transport
        }
        guard fetchResult.isEmpty else {
            throw GeneralError.runtimeError("Registration already exist")
        }
        let newRegistration = CDRegistration(context: persistentContainer.viewContext)
        newRegistration.username = registration.username
        newRegistration.password = registration.password
        newRegistration.url = registration.url
        newRegistration.transport = registration.transport.rawValue
        try save()
    }

    /// Update an existing registration's database instance
    /// - Parameters:
    ///   - currentData: the dataset to be changed
    ///   - newData: new data to be loaded
    func saveRegistrationData(currentData: RegistrationData, newData: RegistrationData) throws {
        let fetchRequest = CDRegistration.fetchRequest()
        let fetchResult = try persistentContainer.viewContext.fetch(fetchRequest).filter { cdr in
            currentData.username == cdr.username &&
                currentData.password == cdr.password &&
                currentData.url == cdr.url &&
                currentData.transport.rawValue == cdr.transport
        }
        if fetchResult.count > 1 {
            print("Should only return 1 result, but returned multiple, deleting excessing entries")
            // delete all but one
            for i in 1 ..< fetchResult.count {
                persistentContainer.viewContext.delete(fetchResult[i])
            }
        }
        if let registration = fetchResult.first {
            registration.username = newData.username
            registration.password = newData.password
            registration.url = newData.url
            registration.transport = newData.transport.rawValue
            try save()
        } else {
            throw GeneralError.runtimeError("No Registration Entry Found")
        }
    }

    /// Delete an registration from current database
    /// - Parameter registration: registration to delete
    func deleteRegistrationData(registration: RegistrationData) throws {
        let fetchRequest = CDRegistration.fetchRequest()
        let fetchResult = try persistentContainer.viewContext.fetch(fetchRequest).filter { cdr in
            registration.username == cdr.username &&
                registration.password == cdr.password &&
                registration.url == cdr.url &&
                registration.transport.rawValue == cdr.transport
        }
        guard !fetchResult.isEmpty else {
            throw GeneralError.runtimeError("No data found to delete")
        }

        for data in fetchResult {
            persistentContainer.viewContext.delete(data)
        }
        try save()
    }
}

// MARK: Phone book related funcitons

extension ApplicationDataStack {
    /// get list of phone book URL
    /// - Returns: list of strings
    func retrievePhoneBookURL() -> [String] {
        let fetchRequest = CDContactPhoneList.fetchRequest()

        let fetchResult = try? persistentContainer.viewContext.fetch(fetchRequest)
        guard let fetchResult else { return [] }

        var result: [String] = []
        for phoneBookURL in fetchResult {
            if let url = phoneBookURL.url {
                result.append(url)
            } else {
                persistentContainer.viewContext.delete(phoneBookURL)
            }
        }
        try? save()
        return result
    }

    /// Add a phone book's url to the database
    /// - Parameter url: url to add
    func addPhoneBookURL(url: String) throws {
        let fetchRequest = CDContactPhoneList.fetchRequest()
        let fetchResult = try persistentContainer.viewContext.fetch(fetchRequest)
        guard
            !fetchResult.contains(where: { cpl in
                cpl.url == url
            })
        else {
            throw GeneralError.runtimeError("already exist")
        }
        let newEntry = CDContactPhoneList(context: persistentContainer.viewContext)
        newEntry.url = url
        try save()
    }

    /// delete a phone book's URL from database
    /// - Parameter url: URL to delete
    func deletePhoneBookURL(url: String) throws {
        let fetchRequest = CDContactPhoneList.fetchRequest()
        let fetchResult = try persistentContainer.viewContext.fetch(fetchRequest).filter { pl in
            pl.url == url
        }
        guard !fetchResult.isEmpty else {
            throw GeneralError.runtimeError("No data found to delete")
        }

        for data in fetchResult {
            persistentContainer.viewContext.delete(data)
        }
        try save()
    }
}

// add other entities in extensions
