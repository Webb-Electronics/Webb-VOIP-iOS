import Foundation

enum CurrentApplicationDisplayState {
    case notInCall, connectingCall, inCall, minimizedInCall
}

class SipContainerVM: ObservableObject {
    let pcm: PersistentCallStatus = .instance
    var allVMs: [CallPageVM] = []
    var callPageVM: CallPageVM?

    var isVideoCall: Bool {
        if let uuid = callPageVM?.callingUUID {
            return (try? pcm.isCallInVideoCall(uuid)) ?? false
        }
        return false
    }

    func getCurrentPageState() -> CurrentApplicationDisplayState {
        removeAndAddNewVM()
        if
            !allVMs.contains(where: { callVm in
                callVm.callingUUID == callPageVM?.callingUUID
            })
        {
            callPageVM = nil
        }
        if
            let uuid = pcm.callStates.first(where: { (_: UUID, value: CallInformation) in
                value.callState == .connecting
            })?.key
        {
            callPageVM = allVMs.first(where: { cpv in
                cpv.callingUUID == uuid
            })
            return .connectingCall
        }
        if
            let uuid = pcm.callStates.first(where: { (_: UUID, value: CallInformation) in
                value.callState == .connected
            })?.key
        {
            callPageVM = allVMs.first(where: { cpv in
                cpv.callingUUID == uuid
            })
            if pcm.userInMinimizedCallScreen {
                return .minimizedInCall
            }
            return .inCall
        }
        callPageVM = nil
        return .notInCall
    }

    func updateCallingPageVM(newVM: CallPageVM) {
        callPageVM = newVM
    }

    private func removeAndAddNewVM() { // this is to preserve the old VM while sync with the PersistentCallStatus.callStates
        let listOfUUIDCurrent = allVMs.map { vm in
            vm.callingUUID
        }
        let listOfUUIDToSync = pcm.callStates.filter { ele in
            ele.value.callState != .incoming
        }.map { (key: UUID, _: CallInformation) in
            key
        }
        let toRemove = listOfUUIDCurrent.filter { uuid in
            !listOfUUIDToSync.contains(uuid)
        }
        let toAdd = listOfUUIDToSync.filter { uuid in
            !listOfUUIDCurrent.contains(uuid)
        }
        for uuid in toRemove {
            allVMs.removeAll { vm in
                vm.callingUUID == uuid
            }
        }
        for uuid in toAdd {
            allVMs.append(CallPageVM(callingUUID: uuid))
        }
    }
}
