import Foundation
import SwiftUI

private let AUDIO_DEVICE_SYSTEM_ICONS = [
    "Speaker": "iphone.gen3.radiowaves.left.and.right",
    "MicrophoneBuiltIn": "iphone",
    "iPhone Microphone": "iphone",
]

private let AUDIO_DEVICE_NAMES = [
    "Speaker": "iPhone Speaker",
    "MicrophoneBuiltIn": "iPhone Microphone",
]

private let CAMERA_DEVICE_SYSTEM_ICONS = [
    "StaticImage: Static picture": "video.slash.fill",
    "AV Capture: com.apple.avfoundation.avcapturedevice.built-in_video:1": "person.fill",
    "AV Capture: com.apple.avfoundation.avcapturedevice.built-in_video:0": "arrow.triangle.2.circlepath.camera.fill",
]

private let CAMERA_DEVICE_NAMES = [
    "StaticImage: Static picture": "Camera Off",
    "AV Capture: com.apple.avfoundation.avcapturedevice.built-in_video:1": "Front Camera",
    "AV Capture: com.apple.avfoundation.avcapturedevice.built-in_video:0": "Back Camera",
]

class CallPageVM {
    let callingUUID: UUID
    let startTime: Date
    var callingText: String

    init(callingUUID: UUID) {
        self.callingUUID = callingUUID
        self.callingText = PersistentCallStatus.instance.callStates[self.callingUUID]?.displayName ?? "Unknown"
        self.startTime = Date()
    }

    func endCall() {
        do {
            try PersistentCallStatus.instance.terminateCall(callingUUID)
        } catch {
            print(error.localizedDescription)
        }
    }
}

class AudioCallPageVM: ObservableObject {
    private let allPageVMs: [CallPageVM]
    private(set) var callPageVM: CallPageVM
    private let updaterFunc: (CallPageVM) -> Void
    @Published var showDialPad: Bool = false
    @Published var showConferenceInviteSheet: Bool = false
    @Published var showCallTransferSheet: Bool = false
    @Published var dtmfToSend = "" {
        willSet {
            if newValue.count > dtmfToSend.count {
                sendDTMF(String(newValue[dtmfToSend.endIndex...]))
            }
        }
    }

    @Published var errorDialCode = false

    var paused: Bool {
        get {
            (try? PersistentCallStatus.instance.getCallPaused(callPageVM.callingUUID)) ?? true
        }
        set {
            try? PersistentCallStatus.instance.pauseCall(callPageVM.callingUUID, pause: newValue)
        }
    }

    var currentUUID: UUID {
        get {
            callPageVM.callingUUID
        }
        set {
            if
                let vmToSet = allPageVMs.first(where: { vm in
                    vm.callingUUID == newValue
                })
            {
                callPageVM = vmToSet
                updaterFunc(vmToSet)
                objectWillChange.send()
            }
        }
    }

    var allUUID: [UUID] {
        allPageVMs.map { vm in
            vm.callingUUID
        }
    }

    var minimizeVideo: Bool {
        get {
            PersistentCallStatus.instance.userInMinimizedCallScreen
        }
        set {
            PersistentCallStatus.instance.userInMinimizedCallScreen = newValue
        }
    }

    var micMuted: Bool {
        get {
            PersistentCallStatus.instance.micMuted
        }
        set {
            PersistentCallStatus.instance.micMuted = newValue
        }
    }

    var availableSpeakers: [AudioCommunicationDevice] {
        PersistentCallStatus.instance.audioDeviceList.filter { acd in
            acd.outputCapable
        }.filter { acd in
            acd.name != "Audio Queue Device"
        }
    }

    var currentSpeaker: AudioCommunicationDevice? {
        get {
            PersistentCallStatus.instance.audioDevice
        }
        set {
            newValue?.setAduio()
        }
    }

    var allContacts: [Contact] {
        ContactManager.instance.getAllContacts()
    }

    func sendDTMF(_ dtmf: String) {
        do {
            try PersistentCallStatus.instance.sendDTMF(callPageVM.callingUUID, digits: dtmf)
        } catch {
            print(error.localizedDescription)
        }
    }

    func inviteToConference(_ target: String) {
        do {
            try PersistentCallStatus.instance.inviteToConference(callPageVM.callingUUID, digits: target)
        } catch {
            errorDialCode = true
            print(error.localizedDescription)
        }
    }

    func transferCall(_ target: String) {
        do {
            try PersistentCallStatus.instance.transferCall(callPageVM.callingUUID, digits: target)
        } catch {
            errorDialCode = true
            print(error.localizedDescription)
        }
    }

    func queryCallPaused(_ uuid: UUID) -> Bool {
        (try? PersistentCallStatus.instance.getCallPaused(uuid)) ?? true
    }

    static func getCallerName(_ uuid: UUID) -> String {
        PersistentCallStatus.instance.callStates[uuid]?.displayName ?? "Unknown Name"
    }

    static func translateAudioDeviceName(_ nativeName: String) -> String {
        AUDIO_DEVICE_NAMES[nativeName] ?? nativeName
    }

    static func imageAudioDeviceName(_ name: String) -> String {
        AUDIO_DEVICE_SYSTEM_ICONS[name] ?? "cable.coaxial"
    }

    init(callPageVM: CallPageVM, allVM: [CallPageVM], updater: @escaping (CallPageVM) -> Void) {
        self.callPageVM = callPageVM
        self.allPageVMs = allVM
        self.updaterFunc = updater
    }
}

class VideoCallPageVM: AudioCallPageVM {
    func updateCallViewSupplier(_ view: UIView, remote: Bool = true) {
        var oldViewSupplier = CallViewSupplier()
        if let viewSupplier = PersistentCallStatus.instance.callViewSupplier {
            oldViewSupplier = viewSupplier
        }
        if remote {
            oldViewSupplier.remoteWindow = view
        } else {
            oldViewSupplier.previewWindow = view
        }
        PersistentCallStatus.instance.callViewSupplier = oldViewSupplier
    }

    var availableCameras: [String] {
        PersistentCallStatus.instance.cameraSourceList
    }

    var currentCamera: String? {
        get {
            PersistentCallStatus.instance.cameraSource
        }
        set {
            PersistentCallStatus.instance.cameraSource = newValue
        }
    }

    static func translateCameraDeviceName(_ nativeName: String) -> String {
        CAMERA_DEVICE_NAMES[nativeName] ?? nativeName
    }

    static func imageCameraDeviceName(_ name: String) -> String {
        CAMERA_DEVICE_SYSTEM_ICONS[name] ?? "cable.coaxial"
    }
}

extension Date {
    func passedTime(from date: Date) -> String {
        let difference = Calendar.current.dateComponents([.minute, .second], from: date, to: self)
        let strMin = String(format: "%02d", difference.minute ?? 00)
        let strSec = String(format: "%02d", difference.second ?? 00)
        return "\(strMin):\(strSec)"
    }
}
