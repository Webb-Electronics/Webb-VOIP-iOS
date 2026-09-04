import AVFoundation
import CallKit
import Foundation
import linphonesw

/// States representing the call status for callkit's call.
///  - Parameter pending: The call is ready to be answered or declined
///  - Parameter ongoing: The call is answered and streaming
///  - Parameter partial: The call is received from APN but not from linphone core
///  - Parameter partialAccepted: The call is received from APN and answered by user but not from the linphone core
///  - Parameter partialDenied: The call is received from APN and declined by user but not from the linphone core
private enum CallKitStatus {
    case pending, ongoing, partial, partialAccepted, partialDenied

    static func isPartial(_ status: CallKitStatus) -> Bool {
        [partial, partialAccepted, partialDenied].contains(status)
    }
}

/// CallKit class to represent a callkit's call
private class CallKitCall: Identifiable {
    let uuid: UUID = .init()
    /// The Linphone Call object
    var call: Call?
    var currentStatus: CallKitStatus = .pending
    init(call: Call? = nil) {
        self.call = call
    }
}

/// Centrally managed class to report calls to the callkit
class CallKitCore: NSObject {
    private let mCallController = CXCallController()
    private let provider: CXProvider

    private let core: LinphoneEngineCore
    private var currentCalls: [CallKitCall] = []

    /// Initialize with the linphoneEngineCore, you should not create your own instance, this is already called by the LinphoneEngineCore class
    /// - Parameter core: the core provided
    init(core: LinphoneEngineCore) {
        let providerConfiguration = CXProviderConfiguration()
        providerConfiguration.supportsVideo = true
        providerConfiguration.supportedHandleTypes = [.generic]

        providerConfiguration.maximumCallsPerCallGroup = 5
        providerConfiguration.maximumCallGroups = 2
        // to not show in system call history
        providerConfiguration.includesCallsInRecents = false

        self.provider = CXProvider(configuration: providerConfiguration)
        self.core = core
        super.init()
        provider.setDelegate(self, queue: nil)
    }

    /// When the call received by the APN
    /// - Parameter callerID: the tempory caller's ID defined by APN's payload or default
    /// - Returns the UUID generated
    public func partialCall(callerID: String) -> UUID {
        let currentCall = CallKitCall()
        currentCall.currentStatus = .partial
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: callerID)
        update.supportsGrouping = true
        update.supportsUngrouping = true
        if core.inConferenceCall { // if a new call is accepted while a conference is in progress, the linphone library will crash.
            try? core.unjoinAllCalls()
        }
        provider.reportNewIncomingCall(with: currentCall.uuid, update: update, completion: { _ in }) // Report to CallKit a call is incoming
        currentCalls.append(currentCall)
        return currentCall.uuid
    }

    /// This will cancel all calls marked partial, partial answered, partial denied
    /// - Parameter uuid: The UUID to cancel
    public func cancelPartialCall(_ uuid: UUID) {
        let call = currentCalls.first { ckc in
            CallKitStatus.isPartial(ckc.currentStatus) && ckc.uuid == uuid
        }
        if let call {
            let terminateAction = CXEndCallAction(call: call.uuid)
            let transaction = CXTransaction(action: terminateAction)
            mCallController.request(transaction, completion: { _ in
                PersistentCallStatus.instance.callStates.removeValue(forKey: call.uuid)
                self.currentCalls.removeAll { ck in
                    call.uuid == ck.uuid
                }
            })
        }
    }

    /// create a regular outgoing call
    /// - Parameters:
    ///   - newCall: the new call object from linphone lib
    ///   - name: The recipent's name to be displayed
    /// - Returns: The Call UUID get created
    public func startOutgoingCall(newCall: Call, name: String) -> UUID {
        let currentCall = CallKitCall(call: newCall)
        currentCall.currentStatus = .ongoing
        let handle = CXHandle(type: .generic, value: name)
        let startCallAction = CXStartCallAction(call: currentCall.uuid, handle: handle)
        let transaction = if
            let toAssociateUUID = currentCalls.first(where: { ckc in
                ckc.call?.conference != nil
            })?.uuid
        {
            CXTransaction(actions: [startCallAction, CXSetGroupCallAction(call: currentCall.uuid, callUUIDToGroupWith: toAssociateUUID)])
        } else {
            CXTransaction(action: startCallAction)
        }
        mCallController.request(transaction) { _ in }
        currentCalls.append(currentCall)
        return currentCall.uuid
    }

    /// The handler to handle status and other stuff for callkit when Linphone Library's delegate change
    /// - Parameters:
    ///   - call: Call object passed in
    ///   - callState: The Call Status
    /// - Returns: The UUID get modified
    public func handleCallStatusChange(call: Call, callState: Call.State) -> UUID? {
        switch callState {
        case .IncomingReceived, .PushIncomingReceived:
            if let partial = getFirstPartialCall() {
                return updatePartialCall(call: call, currentCall: partial)
            } else {
                return incomingCall(newCall: call)
            }

        case .Released, .End, .Error:
            guard
                let uuid = currentCalls.first(where: { ckc in
                    ckc.call?.getCobject == call.getCobject
                })?.uuid
            else {
                return nil
            }
            try? sendCallEndAction(uuid)
            return uuid
        case .Connected:
            guard
                let callkitObject = currentCalls.first(where: { ckc in
                    ckc.call?.getCobject == call.getCobject
                })
            else {
                return nil
            }
            if call.dir == .Outgoing {
                provider.reportOutgoingCall(with: callkitObject.uuid, connectedAt: Date())
            }

            return callkitObject.uuid
        case .OutgoingInit, .OutgoingRinging, .OutgoingProgress, .OutgoingEarlyMedia:
            if
                !currentCalls.contains(where: { ckc in
                    ckc.call?.getCobject == call.getCobject
                })
            {
                return startOutgoingCall(newCall: call, name: call.remoteAddress?.displayName ?? call.remoteAddress?.username ?? "Unknown")
            }
            fallthrough
        default:
            return currentCalls.first { ckc in
                ckc.call?.getCobject == call.getCobject
            }?.uuid
        }
    }

    private func getFirstPartialCall() -> CallKitCall? { // returns the previously created call object from APN
        // we don't really care which CallID is associated with which actual call for now as it doesn't matter until the actual call comes in
        let partialDeniedCall = currentCalls.filter { ckc in
            ckc.currentStatus == .partialDenied
        }.first
        let partialAcceptedCall = currentCalls.filter { ckc in
            ckc.currentStatus == .partialAccepted
        }.first
        let partialCall = currentCalls.filter { ckc in
            ckc.currentStatus == .partial
        }.first
        return partialDeniedCall ?? partialAcceptedCall ?? partialCall
    }

    private func updatePartialCall(call: Call, currentCall: CallKitCall) -> UUID? {
        currentCall.call = call
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: call.remoteAddress?.displayName ?? call.remoteAddress?.username ?? "Unknown Dialer")
        provider.reportCall(with: currentCall.uuid, updated: update)
        if currentCall.currentStatus == .partial {
            currentCall.currentStatus = .pending
        } else if currentCall.currentStatus == .partialAccepted {
            currentCall.currentStatus = .ongoing
            core.configureAudioSession()
            do {
                if let call = currentCall.call {
                    try core.acceptCall(call: call)
                }
            } catch {
                print("error accepting the call")
            }
        } else if currentCall.currentStatus == .partialDenied {
            try? call.decline(reason: .Declined)
            currentCalls.removeAll { ckc in
                ckc.uuid == currentCall.uuid
            }
            return nil
        }
        return currentCall.uuid
    }

    private func incomingCall(newCall: Call) -> UUID {
        let currentCall = CallKitCall(call: newCall)
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: newCall.remoteAddress?.displayName ?? newCall.remoteAddress?.username ?? "Unknown Dialer")
        update.supportsGrouping = true
        update.supportsUngrouping = true
        if core.inConferenceCall { // if a new call is accepted while a conference is in progress, the linphone library will crash.
            try? core.unjoinAllCalls()
        }
        provider.reportNewIncomingCall(with: currentCall.uuid, update: update, completion: { _ in
            if newCall.conference != nil {
                let action = CXSetGroupCallAction(call: currentCall.uuid, callUUIDToGroupWith: self.currentCalls.first(where: { ckc in
                    ckc.call?.conference?.isIn == true && ckc.uuid != currentCall.uuid
                })?.uuid)
                self.mCallController.request(CXTransaction(action: action)) { err in
                    dump(err)
                }
            }
        }) // Report to CallKit a call is incoming

        currentCalls.append(currentCall)
        return currentCall.uuid
    }

    /// Call a callkit action to mute / unmute the microphone
    /// - Parameter isMuted: set if the microphone is muted
    public func muteMicrophone(isMuted: Bool) {
        for call in currentCalls where call.currentStatus == .ongoing {
            let muteAction = CXSetMutedCallAction(call: call.uuid, muted: isMuted)
            let transaction = CXTransaction(action: muteAction)
            mCallController.request(transaction, completion: { _ in })
        }
    }

    /// Notify the callkit object that the call is going to finish
    /// - Parameter uuid: the UUID of the call
    public func sendCallEndAction(_ uuid: UUID) throws {
        guard
            currentCalls.first(where: { ckc in
                ckc.uuid == uuid
            }) != nil
        else {
            throw GeneralError.runtimeError("No such call exist")
        }
        let terminateAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: terminateAction)
        mCallController.request(transaction, completion: { err in
            if err != nil {
                self.currentCalls.filter { ckc in
                    ckc.uuid == uuid
                }.forEach { ckc in
                    try? ckc.call?.terminate()
                }
            }
        })
    }

    /// Send DTMF Action and sync the callkit
    /// - Parameters:
    ///   - uuid: the UUID of the call
    ///   - digits: digits to send
    public func sendDTMFAction(_ uuid: UUID, digits: String) throws {
        guard
            currentCalls.first(where: { ckc in
                ckc.uuid == uuid
            }) != nil
        else {
            throw GeneralError.runtimeError("No such call exist")
        }
        let dtmfAction = CXPlayDTMFCallAction(call: uuid, digits: digits, type: .singleTone)
        let transaction = CXTransaction(action: dtmfAction)
        mCallController.request(transaction) { _ in
        }
    }

    /// update the call with new name
    /// - Parameters:
    ///   - callUUID: the uuid of the call
    ///   - participantName: new name
    /// - Returns: the call object associated
    public func updateNameForCall(_ callUUID: UUID, participantName: String) throws -> Call {
        guard
            let ckc = currentCalls.first(where: { ckc in
                ckc.uuid == callUUID
            })
        else {
            throw GeneralError.runtimeError("No call with such ID")
        }

        guard let call = ckc.call else {
            throw GeneralError.runtimeError("No call asscoiated yet")
        }

        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: participantName)
        provider.reportCall(with: ckc.uuid, updated: update)
        return call
    }

    /// Send a Call Kit request to pause / resume a call
    /// - Parameters:
    ///   - callUUID: the call UUID
    ///   - pause: pause if true, resume if false
    public func pauseCall(_ callUUID: UUID, pause: Bool) throws {
        guard
            let ckc = currentCalls.first(where: { ckc in
                ckc.uuid == callUUID
            })
        else {
            throw GeneralError.runtimeError("No call with such ID")
        }

        guard let call = ckc.call else {
            throw GeneralError.runtimeError("No call asscoiated yet")
        }
        let currentPaused = call.state == .Paused || call.state == .Pausing
        guard currentPaused != pause else {
            throw GeneralError.runtimeError("already paused")
        }
        if !pause, !core.inConferenceCall {
            currentCalls.filter { ckc in
                !(ckc.call?.state == .Paused || ckc.call?.state == .Pausing)
            }.forEach { ckc in
                let pa = CXSetHeldCallAction(call: ckc.uuid, onHold: true)
                let transaction = CXTransaction(action: pa)
                mCallController.request(transaction, completion: { _ in })
            }
        }

        let pauseAction = CXSetHeldCallAction(call: callUUID, onHold: pause)
        let transaction = CXTransaction(action: pauseAction)
        mCallController.request(transaction, completion: { _ in })
    }

    /// check if call is paused
    /// - Parameter callUUID: the call uuid
    /// - Returns: true if paused
    public func callPaused(_ callUUID: UUID) throws -> Bool {
        guard
            let ckc = currentCalls.first(where: { ckc in
                ckc.uuid == callUUID
            })
        else {
            throw GeneralError.runtimeError("No call with such ID")
        }

        guard let call = ckc.call else {
            throw GeneralError.runtimeError("No call asscoiated yet")
        }
        return call.state == .Paused || call.state == .Pausing
    }

    /// Check if the number try to dial is already in a call
    /// - Parameter target: the target number
    /// - Returns: true if there is not already in a call, false if it is.
    public func isTargetInCall(target: String) -> Bool {
        currentCalls.contains { ckc in
            ckc.call?.remoteAddress?.username == target
        }
    }

    /// ungroup the call, and when ungroup is done it will call callBackFunc
    /// - Parameter afterUngroup: the call back function after
    public func ungroupAllCalls(_ afterUngroup: (() -> Void)? = nil) {
        var actions: [CXAction] = []
        for ckc in currentCalls {
            actions.append(CXSetGroupCallAction(call: ckc.uuid, callUUIDToGroupWith: nil))
        }
        mCallController.requestTransaction(with: actions) { err in
            dump(err)
            if let afterUngroup {
                afterUngroup()
            }
        }
    }

    /// To check if a call is in video
    /// - Parameter uuid: the call's uuid
    /// - Returns: true if in video
    public func checkCallInVideoCall(_ uuid: UUID) throws -> Bool {
        guard
            let call = currentCalls.first(where: { ckc in
                ckc.uuid == uuid
            })?.call
        else {
            throw GeneralError.runtimeError("No Such Call")
        }
        return (call.remoteParams?.videoEnabled == true || call.params?.videoEnabled == true)
    }
}

// MARK: CXProviderDelegate

extension CallKitCore: CXProviderDelegate {
    func provider(_: CXProvider, perform action: CXEndCallAction) { // end button pressed
        do {
            if
                let call = currentCalls.first(where: { ckc in
                    ckc.uuid == action.callUUID
                })
            {
                if CallKitStatus.isPartial(call.currentStatus) {
                    call.currentStatus = .partialDenied
                    action.fulfill()
                    return
                }

                if let hangingupCall = call.call {
                    switch hangingupCall.state {
                    case .End, .Released: // do nothing, already ended
                        break
                    case .IncomingReceived, .PushIncomingReceived: // the call is not answered, so decline
                        try call.call?.decline(reason: Reason.Declined)
                    default: // any other state, terminate the call
                        if let conf = call.call?.conference {
                            _ = conf.terminate()
                        }
                        try call.call?.terminate()
                    }
                    // remove the mapping
                    currentCalls.removeAll { cCall in
                        cCall.uuid == action.callUUID
                    }
                }
            }
        } catch {
            print("error ending call")
        }
        action.fulfill()
    }

    func provider(_: CXProvider, perform action: CXAnswerCallAction) { // answer button pressed
        let ccl = currentCalls.filter { ckc in
            ckc.uuid == action.callUUID
        }
        if let currentCall = ccl.first {
            if currentCall.currentStatus == .partial { // if a partial call already created by the APN
                let update = CXCallUpdate()
                update.remoteHandle = CXHandle(type: .generic, value: "Connecting ...")
                provider.reportCall(with: action.callUUID, updated: update)
                currentCall.currentStatus = .partialAccepted
                PersistentCallStatus.instance.callStates[action.callUUID]?.updateState(.connecting)
                action.fulfill()
                return
            }
            do {
                currentCall.currentStatus = .ongoing
                core.configureAudioSession()
                guard let linCall = currentCall.call else {
                    throw GeneralError.runtimeError("Call is nil")
                }
                try core.acceptCall(call: linCall)
            } catch {
                action.fail()
                print("not able to accept")
            }
            action.fulfill()
        }
    }

    func provider(_: CXProvider, perform action: CXSetHeldCallAction) {
        if
            let call = currentCalls.first(where: { ckc in
                ckc.uuid == action.callUUID
            })?.call
        {
            do {
                if action.isOnHold {
                    try call.pause()
                } else {
                    try call.resume()
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        action.fulfill()
    }

    func provider(_: CXProvider, perform action: CXSetGroupCallAction) {
        guard let call2ID = action.callUUIDToGroupWith else {
            action.fulfill()
            return
        }
        let call = currentCalls.first { ckc in
            ckc.uuid == call2ID
        }
        if let call = call?.call {
            try? core.joinAllCallToConference(call)
        }
        action.fulfill()
    }

    func provider(_: CXProvider, perform action: CXStartCallAction) {
        print("new start call action")
        action.fulfill()
    }

    func provider(_: CXProvider, perform action: CXSetMutedCallAction) {
        if core.microphoneMuted != action.isMuted {
            print("call is now muted: ", action.isMuted)
            core.microphoneMuted = action.isMuted
        }
        action.fulfill()
    }

    func provider(_: CXProvider, perform action: CXPlayDTMFCallAction) { // DTMF
        print("DTMF pressed: ", action.digits)
        if
            let call = currentCalls.filter({ ckc in
                ckc.uuid == action.callUUID
            }).first
        {
            if call.call?.state == .StreamsRunning {
                do {
                    guard let dtmfPressed = action.digits.utf8CString.first else {
                        return
                    }
                    try call.call?.sendDtmf(dtmf: dtmfPressed)
                } catch {
                    action.fail()
                    print("error sending dtmf")
                    return
                }
            }
        }
        action.fulfill()
    }

    func provider(_: CXProvider, timedOutPerforming _: CXAction) {}
    func providerDidReset(_: CXProvider) {}

    func provider(_: CXProvider, didActivate _: AVAudioSession) {
        core.setActivateAudioSession(actived: true)
    }

    func provider(_: CXProvider, didDeactivate _: AVAudioSession) {
        if
            currentCalls.contains(where: { ckc in
                ckc.currentStatus == .ongoing
            })
        {
            return
        }
        core.setActivateAudioSession(actived: false)
    }
}
