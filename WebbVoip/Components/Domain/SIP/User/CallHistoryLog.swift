import Foundation

enum CallHistoryType {
    case incoming
    case outgoing
    case missedIncoming
    case missedOutgoing
}

struct CallHistoryLog: Identifiable, Hashable {
    let id = UUID()
    let displayFrom: String
    let displayTo: String
    let time: Date
    let isVideo: Bool
    let callType: CallHistoryType
    let numberToDialBack: String?

    var displayLocal: String {
        if callType == .incoming || callType == .missedIncoming {
            return displayTo
        }
        return displayFrom
    }

    init(displayFrom: String, displayTo: String, time: Date, isVideo: Bool, callType: CallHistoryType, numberToDialBack: String?) {
        self.displayFrom = displayFrom
        self.displayTo = displayTo
        self.time = time
        self.isVideo = isVideo
        self.callType = callType
        self.numberToDialBack = numberToDialBack
    }

    static func getParsedCallLogs() -> [CallHistoryLog] {
        (try? LinphoneEngineCore.instance().parseCallLogs()) ?? []
    }
}
