import Foundation

class CallHistoryPageVM: ObservableObject {
    @Published var callLogs: [CallHistoryLog]

    init() {
        self.callLogs = CallHistoryLog.getParsedCallLogs()
    }

    func reloadLogs() {
        callLogs = CallHistoryLog.getParsedCallLogs()
        objectWillChange.send()
    }
}

class CallHistoryLogListItemVM: ObservableObject {
    let log: CallHistoryLog
    @Published var errorDial = false
    @Published var showCallSheet = false

    init(log: CallHistoryLog) {
        self.log = log
    }

    func getRegistrations() -> ([Registration], [Registration]) {
        ([], User.instance.allRegistrations.filter { reg in
            reg.registrationStatus == .registered
        })
    }
}
