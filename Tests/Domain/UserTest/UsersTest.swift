@testable import WebbVoip
import XCTest

final class UsersTest: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try ApplicationDataStack.instance.removeAllContainers()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAutoCameraOff() {
        let userObj = User.instance
        userObj.autoCameraOff = false
        userObj.autoCameraOff = true
        XCTAssertTrue(userObj.autoCameraOff)
    }

    func testOnlyAudioCall() {
        let userObj = User.instance
        userObj.onlyAudioCall = false
        userObj.onlyAudioCall = true
        XCTAssertTrue(userObj.onlyAudioCall)
    }

    func testAddRegistration() throws {
        let userObj = User.instance
        let emptyUsername = Registration(url: "pbx.example.com", username: "", password: "password", transport: .tls)
        let emptyURL = Registration(url: "", username: "user", password: "password", transport: .tls)
        let reg = Registration(url: "pbx.example.com", username: "user", password: "password", transport: .tls)
        XCTAssertThrowsError(try userObj.addRegistration(registration: emptyUsername))
        XCTAssertThrowsError(try userObj.addRegistration(registration: emptyURL))
        if reg.registrationStatus == .registered {
            do {
                try userObj.addRegistration(registration: reg)
            } catch {
                XCTFail("Failed to add register: \(error)")
            }
            XCTAssertThrowsError(try userObj.addRegistration(registration: reg))
        }
    }

    func testRemoveRegistration() throws {
        let userObj = User.instance
        let reg = Registration(url: "no url", username: "user", password: "password", transport: .tls)
        if reg.registrationStatus == .registered {
            do {
                try userObj.removeRegistration(registration: reg)
            } catch {
                XCTFail("Failed to Remove Registration: \(error)")
            }
            XCTAssertThrowsError(try userObj.removeRegistration(registration: reg))
        } else {
            XCTAssertThrowsError(try userObj.removeRegistration(registration: reg))
        }
    }
}
