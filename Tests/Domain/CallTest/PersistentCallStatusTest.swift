//
//  PersistentCallStatusTest.swift
//  WebbCompanionTests
//
//  Created by Webb on 2024-03-15.
//
@testable import WebbVoip
import XCTest

final class PersistentCallStatusTest: XCTestCase {
    // all commented out since virtual machine does not have such physical accessories
    let persistentCallStatusObj = PersistentCallStatus.instance

    func testMicMuted() throws {
        persistentCallStatusObj.micMuted = false
        persistentCallStatusObj.micMuted = true
        XCTAssertTrue(persistentCallStatusObj.micMuted)
    }

    func testInVideoCall() throws {
        XCTAssertThrowsError(
            try persistentCallStatusObj.isCallInVideoCall(UUID())
        ) { err in
            XCTAssertEqual(err.localizedDescription, "The operation couldn’t be completed. (WebbVoipTests.GeneralError error 0.)")
        }
    }

    func testTerminateCall() throws {
        let reg = Registration(url: "pbx.example.com", username: "user", password: "password", transport: .udp)
        if reg.registrationStatus == .registered {
            do {
                let num = ""
                try reg.dial(number: num)
                try persistentCallStatusObj.terminateCall(reg.id)
            } catch {
                XCTFail("Failed to terminate call(s): \(error)")
            }
        } else {
            XCTAssertThrowsError(try persistentCallStatusObj.terminateCall(reg.id))
        }
    }

    func testInviteToConference() throws {
        let reg = Registration(url: "pbx.example.com", username: "user", password: "password", transport: .udp)
        if reg.registrationStatus == .registered {
            do {
                let num = ""
                try persistentCallStatusObj.inviteToConference(reg.id, digits: num)
            } catch {
                XCTFail("Failed to invite to conference: \(error)")
            }
        }
    }

    func testTransferCall() throws {
        let reg = Registration(url: "pbx.example.com", username: "user", password: "password", transport: .udp)
        if reg.registrationStatus == .registered {
            do {
                let num = ""
                try persistentCallStatusObj.transferCall(reg.id, digits: num)
            } catch {
                XCTFail("Failed to transfer call call(s): \(error)")
            }
        }
    }

    func testPauseCall() throws {
        let reg = Registration(url: "pbx.example.com", username: "user", password: "password", transport: .udp)
        if reg.registrationStatus == .registered {
            do {
                try persistentCallStatusObj.pauseCall(reg.id, pause: true)
            } catch {
                XCTFail("Failed to pause call: \(error)")
            }
        }
    }
}
