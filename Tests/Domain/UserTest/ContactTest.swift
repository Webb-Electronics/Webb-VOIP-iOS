@testable import WebbVoip
import XCTest

final class ContactTest: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try ApplicationDataStack.instance.removeAllContainers()
    }

    func testContactStruct() {
        let contactStruct = Contact(name: "name1", dialTarget: ["123", "234", "345"])
        XCTAssertNotNil(contactStruct)
    }
}

final class ContactManagerTest: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try ApplicationDataStack.instance.removeAllContainers()
    }

    func testContactManager() async throws {
        let cmInstance = ContactManager.instance
        do {
            try await cmInstance.loadFromCoreData()
        } catch {
            XCTFail("Failed to cm loadFromCoreData: \(error)")
        }
        XCTAssertNil(try cmInstance.findContactName("123"))
    }
}
