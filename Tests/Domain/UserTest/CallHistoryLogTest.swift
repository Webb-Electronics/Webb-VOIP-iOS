@testable import WebbVoip
import XCTest

final class CallHistoryLogTest: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try ApplicationDataStack.instance.removeAllContainers()
    }

    func testInit() {
        let dateNtime = NSDate() as Date
        let callHistoryLog = CallHistoryLog(displayFrom: "me", displayTo: "you", time: dateNtime, isVideo: false, callType: CallHistoryType.incoming, numberToDialBack: "303")
        XCTAssertEqual(callHistoryLog.displayFrom, "me")
        XCTAssertEqual(callHistoryLog.displayTo, "you")
        XCTAssertEqual(callHistoryLog.time, dateNtime)
        XCTAssertFalse(callHistoryLog.isVideo)
        XCTAssertEqual(callHistoryLog.callType, CallHistoryType.incoming)
        XCTAssertEqual(callHistoryLog.numberToDialBack, "303")
    }

    func testDislayLocal() {
        let dateNtime = NSDate() as Date
        let callHistoryLog = CallHistoryLog(displayFrom: "me", displayTo: "you", time: dateNtime, isVideo: false, callType: CallHistoryType.outgoing, numberToDialBack: "303")
        let displayFrom = callHistoryLog.displayLocal
        XCTAssertEqual(displayFrom, "me")
    }
}
