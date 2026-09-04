import Foundation
import UIKit

/// The State of the call to determine by UI to show respective pages
enum CallState {
    case connecting, connected, incoming
}

/// The Data object that contains the callers name and the current state of the call
struct CallInformation {
    var callState: CallState
    var callingName: String?

    var displayName: String {
        guard let callingName, !callingName.isEmpty else {
            return "Unrecongnized Caller"
        }
        return callingName
    }

    mutating func updateState(_ newState: CallState) {
        callState = newState
    }
}

/// The singleton object that contains everything you need for call situations extracted from LinphoneCore
class PersistentCallStatus: ObservableObject {
    static let instance = PersistentCallStatus()

    /// Check / set if mic is enbaled
    var micMuted: Bool {
        get {
            (try? LinphoneEngineCore.instance().microphoneMuted) ?? true
        }
        set {
            try? LinphoneEngineCore.instance().microphoneMuted = newValue
        }
    }

    /// returns the current video device
    var cameraSource: String? {
        get {
            try? LinphoneEngineCore.instance().cameraSource
        }
        set {
            if let newValue {
                try? LinphoneEngineCore.instance().cameraSource = newValue
            }
            requiresUpdate()
        }
    }

    /// get the list of avilable video devices
    var cameraSourceList: [String] {
        (try? LinphoneEngineCore.instance().cameraSourceList) ?? []
    }

    /// get/set the current audio device
    var audioDevice: AudioCommunicationDevice? {
        get {
            try? LinphoneEngineCore.instance().audioOutputSouce
        }
        set {
            guard let newValue else { return }
            if newValue.inputCapable {
                try? LinphoneEngineCore.instance().audioInputSource = newValue
            }
            if newValue.outputCapable {
                try? LinphoneEngineCore.instance().audioOutputSouce = newValue
            }
            requiresUpdate()
        }
    }

    /// get the list of avilable audio devices
    var audioDeviceList: [AudioCommunicationDevice] {
        (try? LinphoneEngineCore.instance().audioSourceList) ?? []
    }

    /// set the CallViewSupplier to provide video streams (remote and local)
    var callViewSupplier: CallViewSupplier? {
        didSet {
            try? LinphoneEngineCore.instance().callViewSupplier = callViewSupplier ?? CallViewSupplier()
        }
    }

    /// Dictionary of call's UUID vs CallInformation, will be set from LinphoneCore
    var callStates: [UUID: CallInformation] = [:] {
        didSet {
            if callStates.isEmpty {
                callViewSupplier = nil
                userInMinimizedCallScreen = false
            }
            requiresUpdate()
        }
    }

    /// True if the user is in minized call
    var userInMinimizedCallScreen: Bool = false {
        didSet {
            requiresUpdate()
        }
    }

    /// Check if call in video call
    /// - Parameter uuid: the uuid of the call
    /// - Returns: true if in video
    func isCallInVideoCall(_ uuid: UUID) throws -> Bool {
        guard
            callStates.contains(where: { (key: UUID, _: CallInformation) in
                key == uuid
            })
        else {
            throw GeneralError.runtimeError("No such key in current list of call states")
        }

        return try LinphoneEngineCore.instance().isCallInVideoCall(uuid)
    }

    /// terminate a call through UUID
    /// - Parameter uuid: the UUID of the call trying to terminate
    func terminateCall(_ uuid: UUID) throws {
        guard
            callStates.contains(where: { (key: UUID, _: CallInformation) in
                key == uuid
            })
        else {
            throw GeneralError.runtimeError("No such key in current list of call states")
        }
        callViewSupplier = nil
        try LinphoneEngineCore.instance().endCall(uuid)
    }

    /// Send DTMF String to call
    /// - Parameters:
    ///   - uuid: the call's UUID
    ///   - digits: the digits to send
    func sendDTMF(_ uuid: UUID, digits: String) throws {
        guard
            callStates.contains(where: { (key: UUID, _: CallInformation) in
                key == uuid
            })
        else {
            throw GeneralError.runtimeError("No such key in current list of call states")
        }
        try LinphoneEngineCore.instance().sendDTMFAction(uuid, digits: digits)
    }

    /// Invite another person into this call
    /// - Parameters:
    ///   - uuid: the call to invite in
    ///   - digits: the invitee's number
    func inviteToConference(_ uuid: UUID, digits: String) throws {
        let possibleName = try? ContactManager.instance.findContactName(digits)
        try LinphoneEngineCore.instance().inviteToCall(uuid, participantDialCode: digits, participantName: possibleName)
    }

    /// Transfer the call to another person, this will end the call
    /// - Parameters:
    ///   - uuid: the call to tranfer from
    ///   - digits: the digits to transfer to
    func transferCall(_ uuid: UUID, digits: String) throws {
        try LinphoneEngineCore.instance().transferCall(uuid, transfereeDialCode: digits)
    }

    /// pause / resume the call
    /// - Parameters:
    ///   - uuid: call to pause / resume
    ///   - pause: true if to pause. false if to resume
    func pauseCall(_ uuid: UUID, pause: Bool) throws {
        try LinphoneEngineCore.instance().pauseCall(uuid, pause: pause)
    }

    /// check if a call is paused
    /// - Parameter uuid: uuid of the call
    /// - Returns: true if call is paused, false if call is not
    func getCallPaused(_ uuid: UUID) throws -> Bool {
        try LinphoneEngineCore.instance().callPaused(uuid)
    }

    /// Notify that there is a UI Change, should only be called from Data layer
    func requiresUpdate() {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    private init() {}
}

/// The CallView of preview and remote windows
struct CallViewSupplier {
    var previewWindow: UIView?
    var remoteWindow: UIView?
}

/// The object representation of an audio Device
struct AudioCommunicationDevice: Hashable {
    var id: String
    var name: String
    /// if it can act to take inputs
    var inputCapable: Bool
    /// if it can act to play as outputs
    var outputCapable: Bool

    /// Set this object as the audio device
    func setAduio() {
        PersistentCallStatus.instance.audioDevice = self
    }
}
