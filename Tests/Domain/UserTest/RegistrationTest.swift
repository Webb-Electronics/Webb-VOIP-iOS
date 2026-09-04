//
//  RegistrationTest.swift
//  WebbCompanionTests
//
//  Created by Webb on 2024-03-15.
//
@testable import WebbVoip
import XCTest

final class RegistrationTest: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try ApplicationDataStack.instance.removeAllContainers()
    }

    let reg = Registration(url: "pbx.example.com", username: "user", password: "password", transport: .udp)
    // This covers register(), unregister() and updateWithNewData()
    func testRegistration() throws {
        XCTAssertEqual(reg.registrationStatus, .unregistered)
        do {
            try reg.register()
        } catch {
            XCTFail("Failed to register: \(error)")
        }
        let exp = expectation(description: "Test after 5 seconds")
        let result = XCTWaiter.wait(for: [exp], timeout: 5.0)
        if result == XCTWaiter.Result.timedOut {
            var newRegData = RegistrationData()
            newRegData.password = "another password"
            newRegData.url = "test"
            newRegData.username = "test2"
            newRegData.transport = .tls
            if reg.registrationStatus == .registered {
                XCTAssertThrowsError(try reg.updateWithNewData(reg: newRegData))
                do {
                    try reg.unregister()
                } catch {
                    XCTFail("Failed to unregister: \(error)")
                }
            }
            XCTAssertEqual(reg.registrationStatus, .unregistered)
            var anotherNewRegData = RegistrationData()
            XCTAssertThrowsError(try reg.updateWithNewData(reg: anotherNewRegData))
            anotherNewRegData.url = "newpbx.example.com"
            anotherNewRegData.password = "newpassword"
            anotherNewRegData.username = "newuser"
            anotherNewRegData.transport = .tls
            try? reg.updateWithNewData(reg: anotherNewRegData)
            XCTAssertEqual(reg.url, "newpbx.example.com")
            XCTAssertEqual(reg.username, "newuser")
            XCTAssertEqual(reg.password, "newpassword")
            XCTAssertEqual(reg.transport, .tls)
        } else {
            XCTFail("Delay interrupted")
        }

        // try User.instance.removeRegistration(registration: reg)
    }

    func testSetAsDefault() throws {
        if reg.registrationStatus == .registered {
            do {
                try reg.setAsDefault()
            } catch {
                XCTFail("Failed to setAsDefault: \(error)")
            }
            XCTAssertEqual(reg.url, try LinphoneEngineCore.instance().getDefaultAccount()?.url)
            XCTAssertEqual(reg.username, try LinphoneEngineCore.instance().getDefaultAccount()?.username)
            XCTAssertEqual(reg.transport, try LinphoneEngineCore.instance().getDefaultAccount()?.transport)
        } else {
            XCTAssertThrowsError(try reg.setAsDefault())
        }
    }

    func testDial() throws {
        let to_dial = ""
        if reg.registrationStatus == .registered {
            do {
                try reg.dial(number: to_dial)
                XCTAssertThrowsError(try reg.dial(number: to_dial))
                try LinphoneEngineCore.instance().endCall(reg.id)
                XCTAssertNoThrow(try reg.dial(number: to_dial))
                try LinphoneEngineCore.instance().endCall(reg.id)
            } catch {
                XCTFail("Failed to dial: \(error)")
            }
            XCTAssertEqual(reg.url, try LinphoneEngineCore.instance().getDefaultAccount()?.url)

        } else {
            XCTAssertThrowsError(try reg.dial(number: to_dial))
        }
    }

    func testCreateSIPAccountWithoutRegistration() throws {
        reg.createSIPAccountWithoutRegistration()
        XCTAssertNotEqual(reg.registrationStatus, .registered)
    }

    func testToString() throws {
        let compare_str = "url: \(reg.url), username: \(reg.username), password: \(reg.password), transport: \(reg.transport), registrationStatus: \(reg.registrationStatus)"
        XCTAssertEqual(compare_str, reg.toString())
    }

    // Test registration UI
    func testNewRegistrationData() throws {
        let ori_reg = Registration(url: "pbx.example.com", username: "user", password: "password", transport: .tls)
        let new_data = RegistrationData(registration: ori_reg)
        XCTAssertEqual(new_data.url, ori_reg.url)
        XCTAssertEqual(new_data.username, ori_reg.username)
        XCTAssertEqual(new_data.password, ori_reg.password)
        XCTAssertEqual(new_data.transport, ori_reg.transport)
        let new_reg = Registration(newData: new_data)
        XCTAssertEqual(new_reg, ori_reg)
        XCTAssertEqual(new_reg.url, ori_reg.url)
        XCTAssertEqual(new_reg.username, ori_reg.username)
        XCTAssertEqual(new_reg.password, ori_reg.password)
        XCTAssertEqual(new_reg.transport, ori_reg.transport)
    }
}
