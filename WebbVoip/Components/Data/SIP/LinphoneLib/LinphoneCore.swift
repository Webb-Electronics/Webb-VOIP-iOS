import Foundation
import linphonesw

let APP_GROUP_ID: String = "group.ca.webb.mobile.companionapp.voip.ios"
/// The Singleton class that handles all data processing between this app and linphonesw module, can be used by singleton.get or instance
class LinphoneEngineCore {
    static let singleton: Result<LinphoneEngineCore, Error> = Result {
        try LinphoneEngineCore()
    }

    private let mCore: Core

    private var allAccounts: [LinphoneAccount: Account] = [:]

    private var callKit: CallKitCore?

    private(set) var inConferenceCall = false {
        didSet {
            if oldValue, !inConferenceCall {
                callKit?.ungroupAllCalls()
            }
        }
    }

    private init() throws {
        LoggingService.Instance.logLevel = LogLevel.Error
        let optionalConfig = Config.newForSharedCore(appGroupId: APP_GROUP_ID, configFilename: "linphoneCoreConfig", factoryConfigFilename: "")
        guard let config = optionalConfig else {
            throw GeneralError.runtimeError("unable to start core")
        }
        try self.mCore = Factory.Instance.createSharedCoreWithConfig(config: config, systemContext: nil, appGroupId: APP_GROUP_ID, mainCore: true)
        mCore.callkitEnabled = true
        self.callKit = CallKitCore(core: self)
        addDelegate()
        try mCore.start()
    }

    /// Get the singleton object
    /// - Returns: The singleton object of the Core
    public static func instance() throws -> LinphoneEngineCore {
        try singleton.get()
    }

    /// Add an linphone account object to the Core engine, will create a AccountProduct object and add to the dict
    /// - Parameter acc: the account passed in
    public func addAccount(acc: LinphoneAccount) throws {
        if allAccounts.keys.contains(acc) {
            throw GeneralError.runtimeError("Already Exists Linphone Account, Check your code")
        }
        let transport: TransportType = matchSIPTransportationProtocol(status: acc.transportType)
        let authInfo = try Factory.Instance.createAuthInfo(
            username: acc.username,
            userid: nil,
            passwd: acc.password,
            ha1: nil,
            realm: nil,
            domain: acc.domain
        )
        let accountParams = try mCore.createAccountParams()
        let identity = try Factory.Instance.createAddress(addr: String("sip:" + acc.username + "@" + acc.domain))
        identity.password = acc.password
        try identity.setDomain(newValue: acc.domain)
        try identity.setUsername(newValue: acc.username)
        try identity.setTransport(newValue: transport)
        try accountParams.setIdentityaddress(newValue: identity)
        let address = try Factory.Instance.createAddress(addr: String("sip:" + acc.domain))
        try address.setTransport(newValue: transport)
        try accountParams.setServeraddress(newValue: address)
        accountParams.registerEnabled = true
        accountParams.pushNotificationAllowed = true
        accountParams.remotePushNotificationAllowed = true
        accountParams.pushNotificationConfig?.provider = "apns.dev"
        if transport == .Tls, let natPolicy = try NetworkPolicyMaker.createPolicy(mCore, domain: acc.domain) {
            accountParams.natPolicy = natPolicy
        }
        let account = try mCore.createAccount(params: accountParams)
        mCore.addAuthInfo(info: authInfo)
        try mCore.addAccount(account: account)

        allAccounts[acc] = account
        print("current all account: ", allAccounts.count)
    }

    /// To remove a linphone account object, and stop all communication with the server
    /// - Parameter acc: the Linphone account object you want to delete
    public func removeAccount(acc: LinphoneAccount) throws {
        guard let data = allAccounts[acc] else {
            throw GeneralError.runtimeError("Account does not exist")
        }
        guard let accountToRemove = mCore.getAccountByIdkey(idkey: data.params?.idkey) else {
            throw GeneralError.runtimeError("Account does not exist")
        }
        mCore.removeAccount(account: accountToRemove)
        acc.status = .unregistered
        allAccounts.removeValue(forKey: acc)
        if allAccounts.isEmpty {
            mCore.clearAccounts()
        }

        print("current all account: ", allAccounts.count)
    }

    /// Set the default LinphoneAccount object
    /// - Parameter acc: The default account
    public func setDefaultAccount(acc: LinphoneAccount) throws {
        guard let data = allAccounts[acc] else {
            throw GeneralError.runtimeError("Account does not exist")
        }
        guard let accToSet = mCore.getAccountByIdkey(idkey: data.params?.idkey) else {
            throw GeneralError.runtimeError("Account does not exist")
        }
        mCore.defaultAccount = accToSet
    }

    /// To set the audio session
    /// - Parameter actived: boolean if it's activated
    public func setActivateAudioSession(actived: Bool) {
        mCore.activateAudioSession(activated: actived)
    }

    /// To configure the audio session, call right before accepting the call
    public func configureAudioSession() {
        mCore.configureAudioSession()
    }

    /// Get the list of registration that linphone keeps track of
    /// - Returns: List of Registration Objects
    public func getCurrentRegistrations() -> [Registration] {
        var regs: [Registration] = []
        for acc in mCore.accountList {
            let username = acc.params?.identityAddress?.username ?? ""
            let url = acc.params?.identityAddress?.domain ?? ""
            let password = acc.params?.identityAddress?.password ?? ""
            if username.isEmpty || url.isEmpty || password.isEmpty {
                mCore.removeAccount(account: acc)
                continue
            }
            let transport = SIPTransportProtocol.fromRawValue(value: acc.params?.identityAddress?.transport.rawValue ?? 0)
            let newReg = Registration(url: url, username: username, password: password, transport: transport)
            newReg.createSIPAccountWithoutRegistration()
            guard let linphoneAccObj = newReg.sipAccount else {
                mCore.removeAccount(account: acc)
                continue
            }

            allAccounts[linphoneAccObj] = acc
            regs.append(newReg)
        }
        return regs
    }

    /// Get the default account (Data only) in the Linphone lib
    /// - Returns: RegistrationData struct or nil
    public func getDefaultAccount() -> RegistrationData? {
        guard let defaultAcc = mCore.defaultAccount else {
            return nil
        }
        var newRegData = RegistrationData()
        newRegData.username = defaultAcc.params?.identityAddress?.username ?? ""
        newRegData.url = defaultAcc.params?.identityAddress?.domain ?? ""
        newRegData.password = defaultAcc.params?.identityAddress?.password ?? ""
        newRegData.transport = SIPTransportProtocol.fromRawValue(value: defaultAcc.params?.identityAddress?.transport.rawValue ?? 0)
        if newRegData.username.isEmpty || newRegData.url.isEmpty || newRegData.password.isEmpty {
            mCore.defaultAccount = nil
            return nil
        }
        return newRegData
    }

    /// Show the Callkit with only parial information, to be called by APN
    /// - Parameter callerName: the tempory caller's name
    public func showCallkitWithPartialInfo(callerName: String?) {
        if let uuidToAdd = callKit?.partialCall(callerID: callerName ?? "Incoming Call") {
            PersistentCallStatus.instance.callStates[uuidToAdd] = CallInformation(callState: .incoming, callingName: callerName)
            let task = DispatchWorkItem {
                self.cancelPartialCallKit(uuidToAdd)
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10, execute: task)
        }
    }

    /// This is to cancel all calls that doesn't receive in the callkit
    public func cancelPartialCallKit(_ uuid: UUID) {
        callKit?.cancelPartialCall(uuid)
    }

    private func matchSIPTransportationProtocol(status: SIPTransportProtocol) -> TransportType {
        switch status {
        case .tls:
            TransportType.Tls
        case .udp:
            TransportType.Udp
        }
    }

    private func addDelegate() {
        let mRegistrationDelegate = CoreDelegateStub(
            onCallStateChanged: onCallStageChanged,
            onCallLogUpdated: onCallLogUpdated,
            onConferenceStateChanged: onConferenceStateChanged,
            onAccountRegistrationStateChanged: onAccountRegistrationStateChanged
        )
        mCore.addDelegate(delegate: mRegistrationDelegate)
    }
}

// MARK: delegates functions

private extension LinphoneEngineCore {
    private func getCallName(call: Call, uuidChanged: UUID) -> String? {
        if let cn = PersistentCallStatus.instance.callStates[uuidChanged]?.callingName, !cn.isEmpty {
            cn
        } else if let dn = call.remoteAddress?.displayName {
            dn
        } else if let un = call.remoteAddress?.username {
            un
        } else {
            nil
        }
    }

    func onCallStageChanged(_: Core, call: Call, callState: Call.State, _: String) {
        if let uuidChanged = callKit?.handleCallStatusChange(call: call, callState: callState) {
            let showingName = getCallName(call: call, uuidChanged: uuidChanged)
            switch callState {
            case .OutgoingInit, .OutgoingRinging, .OutgoingProgress:
                PersistentCallStatus.instance.callStates[uuidChanged] = CallInformation(callState: .connecting, callingName: showingName)
            case .IncomingReceived, .PushIncomingReceived, .IncomingEarlyMedia:
                let toChangeState: CallState = if
                    let storedState = PersistentCallStatus.instance.callStates[uuidChanged]?.callState,
                    storedState == .connected || storedState == .connecting
                {
                    storedState
                } else {
                    .incoming
                }
                PersistentCallStatus.instance.callStates[uuidChanged] = CallInformation(callState: toChangeState, callingName: showingName)
            case .Idle, .End, .Error, .Released:
                PersistentCallStatus.instance.callStates.removeValue(forKey: uuidChanged)
            case .Updating, .UpdatedByRemote, .EarlyUpdating, .EarlyUpdatedByRemote, .Paused, .Pausing, .Resuming, .PausedByRemote:
                PersistentCallStatus.instance.requiresUpdate()
            default:
                PersistentCallStatus.instance.callStates[uuidChanged] = CallInformation(callState: .connected, callingName: showingName)
            }
        }
    }

    func onCallLogUpdated(core: Core, cl _: CallLog) {
        if core.callLogs.count > 100 {
            if let last = core.callLogs.last {
                core.removeCallLog(callLog: last)
            }
        }
    }

    func onConferenceStateChanged(_: Core, _: Conference, state: Conference.State) {
        inConferenceCall = state == .Created
    }

    func onAccountRegistrationStateChanged(_: Core, lacc: Account, state: RegistrationState, _: String) {
        if
            let acc = allAccounts.filter({ (_: LinphoneAccount, value: Account) in
                value.params?.identityAddress?.weakEqual(address2: (lacc.params?.identityAddress)!) ?? false
            }).first?.key
        {
            switch state {
            case .Ok:
                acc.status = .registered
            case .Progress, .Refreshing:
                acc.status = .registering
            case .Failed, .Cleared, .None:
                acc.status = .unregistered
            }
        }
    }
}

// MARK: Dial related functions

extension LinphoneEngineCore {
    /// Make a call to the other party
    /// - Parameters:
    ///   - useAccount: use which Account to make the call
    ///   - audioOnly: if it's audio only
    ///   - number: the number to dial
    ///   - displayName: the name to display
    public func dial(useAccount: LinphoneAccount, audioOnly: Bool, number: String, displayName: String? = nil) throws {
        if mCore.inCall() {
            throw GeneralError.runtimeError("Already in a call")
        }
        let params = try mCore.createCallParams(call: nil)
        params.mediaEncryption = .None
        params.account = allAccounts[useAccount]
        params.videoEnabled = !audioOnly
        cameraSource = if User.instance.autoCameraOff, params.videoEnabled {
            "StaticImage: Static picture"
        } else {
            "AV Capture: com.apple.avfoundation.avcapturedevice.built-in_video:1"
        }
        let remoteAddress = try Factory.Instance.createAddress(addr: "sip:\(number)@\(useAccount.domain)")
        try remoteAddress.setDisplayname(newValue: displayName ?? number)
        _ = mCore.inviteAddressWithParams(addr: remoteAddress, params: params)
    }

    /// accept a call with special parameters
    /// - Parameter call: the call to accept
    public func acceptCall(call: Call) throws {
        let params = try mCore.createCallParams(call: call)
        params.videoEnabled = call.remoteParams?.videoEnabled ?? false
        cameraSource = if User.instance.onlyAudioCall || User.instance.autoCameraOff {
            "StaticImage: Static picture"
        } else {
            "AV Capture: com.apple.avfoundation.avcapturedevice.built-in_video:1"
        }
        params.mediaEncryption = .None
        if call.getCobject != nil {
            try call.acceptWithParams(params: params)
        }
    }

    /// pass through a Call end action to the callkit
    /// - Parameter callUUID: the UUID of the call
    public func endCall(_ callUUID: UUID) throws {
        try callKit?.sendCallEndAction(callUUID)
    }

    /// invite another address to the call
    /// - Parameters:
    ///   - callUUID: the call uuid
    ///   - participantDialCode: the other party's dialcode
    ///   - participantName: the other party's name if there is a match
    public func inviteToCall(_ callUUID: UUID, participantDialCode: String, participantName: String? = nil) throws {
        let actualParticipantName = participantName ?? participantDialCode
        let concatName = "\(PersistentCallStatus.instance.callStates[callUUID]?.displayName ?? "Existing Caller")\n\(actualParticipantName)"
        guard let call = try callKit?.updateNameForCall(callUUID, participantName: concatName) else {
            throw GeneralError.runtimeError("No call")
        }
        let params = try mCore.createCallParams(call: call)
        params.mediaEncryption = .None
        guard let domain = call.remoteAddress?.domain else {
            throw GeneralError.runtimeError("no domain")
        }
        let translatedDomain = DeploymentConfig.domainAliases[domain]
        try throwErrorIfAlreadyInCallOrSelf(dialCode: participantDialCode, translatedDomain: translatedDomain, domain: domain)
        let remoteAddress = try Factory.Instance.createAddress(addr: "sip:\(participantDialCode)@\(translatedDomain ?? domain)")
        try remoteAddress.setDisplayname(newValue: actualParticipantName)
        if call.conference == nil {
            let conf = try mCore.createConferenceWithParams(params: mCore.createConferenceParams(conference: nil))
            try conf.addParticipant(call: call)
//            try mCore.addToConference(call: call)
        } else if call.conference?.isIn == false {
            _ = call.conference?.enter()
        }
        try call.conference?.inviteParticipants(addresses: [remoteAddress], params: params)
    }

    /// join all ongoing calls to one conference
    public func joinAllCallToConference(_ mainCall: Call) throws {
        if mainCall.conference == nil {
            // try mCore.addToConference(call: mainCall)
            let conf = try mCore.createConferenceWithParams(params: mCore.createConferenceParams(conference: nil))
            try conf.addParticipant(call: mainCall)
        }
        if mainCall.conference?.isIn == false {
            _ = mainCall.conference?.enter()
        }
        let callsToJoin = mCore.calls.filter { ca in
            ca.getCobject != mainCall.getCobject && ca.conference == nil
        }
        guard !callsToJoin.isEmpty else {
            return
        }
        try mainCall.conference?.addParticipants(calls: callsToJoin)
    }

    /// Destroy the conference call
    public func unjoinAllCalls() throws {
        if let conf = mCore.currentCall?.conference {
            _ = conf.leave()
        }
    }

    /// to transfer a call to another party
    /// - Parameters:
    ///   - callUUID: the call to transfer
    ///   - transfereeDialCode: the dialcode to transfer to
    public func transferCall(_ callUUID: UUID, transfereeDialCode: String) throws {
        guard let call = try callKit?.updateNameForCall(callUUID, participantName: "tranfering to " + transfereeDialCode) else {
            throw GeneralError.runtimeError("No call")
        }
        guard let domain = call.remoteAddress?.domain else {
            throw GeneralError.runtimeError("no domain")
        }
        let translatedDomain = DeploymentConfig.domainAliases[domain]
        try throwErrorIfAlreadyInCallOrSelf(dialCode: transfereeDialCode, translatedDomain: translatedDomain, domain: domain)
        let remoteAddress = try Factory.Instance.createAddress(addr: "sip:\(transfereeDialCode)@\(translatedDomain ?? domain)")
        try call.transferTo(referTo: remoteAddress)
    }

    private func throwErrorIfAlreadyInCallOrSelf(dialCode: String, translatedDomain: String?, domain: String) throws {
        guard
            !(callKit?.isTargetInCall(target: dialCode) ?? false), !allAccounts.contains(where: { (key: LinphoneAccount, _: Account) in
                key.username == dialCode && key.domain.contains(translatedDomain ?? domain)
            })
        else {
            throw GeneralError.runtimeError("Can't do this call")
        }
    }
}

// MARK: PersistenCallStatus related

extension LinphoneEngineCore {
    /// set / get the microphone
    var microphoneMuted: Bool {
        get {
            !mCore.micEnabled
        }
        set {
            mCore.micEnabled = !newValue
            PersistentCallStatus.instance.requiresUpdate()
            callKit?.muteMicrophone(isMuted: newValue)
        }
    }

    /// set / get the ViewSupplier, will only apply if there is new window to replace
    var callViewSupplier: CallViewSupplier {
        get {
            CallViewSupplier(previewWindow: mCore.nativeVideoWindow, remoteWindow: mCore.nativePreviewWindow)
        }
        set {
            if let nativeWindow = newValue.remoteWindow {
                mCore.nativeVideoWindow = nativeWindow
            }
            if let previewWindow = newValue.previewWindow {
                mCore.nativePreviewWindow = previewWindow
            }
        }
    }

    /// get / set the camera source
    var cameraSource: String? {
        get {
            mCore.videoDevice
        }
        set {
            if let newValue {
                Task { // to prevent run in the main thread
                    try? mCore.setVideodevice(newValue: newValue)
                }
            }
        }
    }

    /// The list of cameras avilable
    var cameraSourceList: [String] {
        mCore.videoDevicesList
    }

    /// The list of audio devices avilable
    var audioSourceList: [AudioCommunicationDevice] {
        var result: [AudioCommunicationDevice] = []
        for device in mCore.extendedAudioDevices {
            if let translated = LinphoneEngineCore.translateAudioDeviceInfo(device) {
                result.append(translated)
            }
        }
        return result
    }

    /// set / get the input audio device
    var audioInputSource: AudioCommunicationDevice? {
        get {
            LinphoneEngineCore.translateAudioDeviceInfo(mCore.inputAudioDevice)
        }
        set {
            mCore.inputAudioDevice = findAudioDevice(newValue)
        }
    }

    /// set / get the output audio device
    var audioOutputSouce: AudioCommunicationDevice? {
        get {
            LinphoneEngineCore.translateAudioDeviceInfo(mCore.outputAudioDevice)
        }
        set {
            mCore.outputAudioDevice = findAudioDevice(newValue)
        }
    }

    /// check if there is any call that is video enabled
    /// - Parameter uuid: the uuid of the call
    /// - Returns: true if in video
    func isCallInVideoCall(_ uuid: UUID) throws -> Bool {
        guard let callKit else {
            throw GeneralError.runtimeError("No Call Kit")
        }
        return try callKit.checkCallInVideoCall(uuid)
    }

    /// pass through the DTMF Actions to call kit to handle, to stay at synced
    /// - Parameters:
    ///   - uuid: the UUID of the call
    ///   - digits: the digits to send
    func sendDTMFAction(_ uuid: UUID, digits: String) throws {
        try callKit?.sendDTMFAction(uuid, digits: digits)
    }

    /// Pause the current call into on hold
    /// - Parameters:
    ///   - uuid: the call to pause
    ///   - pause: pause or resume
    func pauseCall(_ uuid: UUID, pause: Bool) throws {
        try callKit?.pauseCall(uuid, pause: pause)
    }

    /// check if call is paused
    /// - Parameter uuid: the call uuid
    /// - Returns: true if call is paused
    func callPaused(_ uuid: UUID) throws -> Bool {
        guard let callKit else {
            throw GeneralError.runtimeError("No callkit init")
        }
        return try callKit.callPaused(uuid)
    }

    private static func translateAudioDeviceInfo(_ device: AudioDevice?) -> AudioCommunicationDevice? {
        var inputOk = false
        var outputOk = false
        if let device {
            switch device.capabilities {
            case .CapabilityAll:
                inputOk = true
                outputOk = true
            case .CapabilityPlay:
                outputOk = true
            case .CapabilityRecord:
                inputOk = true
            default:
                print("device both capabilities are false")
            }
            if inputOk || outputOk {
                return AudioCommunicationDevice(id: device.id, name: device.deviceName, inputCapable: inputOk, outputCapable: outputOk)
            }
        }
        return nil
    }

    private func findAudioDevice(_ device: AudioCommunicationDevice?) -> AudioDevice? {
        if let device {
            return mCore.extendedAudioDevices.first { ad in
                ad.id == device.id
            }
        }
        return nil
    }
}

// MARK: Call history

extension LinphoneEngineCore {
    /// Parse the linphone Call log to CallHistoryLog
    /// - Returns: the list of call history
    func parseCallLogs() -> [CallHistoryLog] {
        var result: [CallHistoryLog] = []
        for callLog in mCore.callLogs {
            let callHisType: CallHistoryType = switch callLog.status {
            case .Success, .AcceptedElsewhere:
                if callLog.dir == .Incoming {
                    .incoming
                } else {
                    .outgoing
                }
            default:
                if callLog.dir == .Incoming {
                    .missedIncoming
                } else {
                    .missedOutgoing
                }
            }
            let numberToDialBack: String? = switch callHisType {
            case .incoming, .missedIncoming:
                callLog.fromAddress?.username
            case .outgoing, .missedOutgoing:
                callLog.toAddress?.username
            }
            let fromDisplay = getDisplayName(address: callLog.fromAddress)
            let toDisplay = getDisplayName(address: callLog.toAddress)
            let time = Date(timeIntervalSince1970: Double(callLog.startDate))
            let isVideo = callLog.videoEnabled
            result.append(CallHistoryLog(displayFrom: fromDisplay, displayTo: toDisplay, time: time, isVideo: isVideo, callType: callHisType, numberToDialBack: numberToDialBack))
        }
        return result
    }

    private func matchPhoneBookNamesFromAddress(address: Address?) -> String {
        guard let address else {
            return "Unknown"
        }
        let registrations = User.instance.allRegistrations.filter { reg in
            address.domain!.contains(reg.url)
        }
        for registration in registrations {
            if let name = try? ContactManager.instance.findContactName(address.username!, reg: registration) {
                return name
            }
        }
        return address.username!
    }

    private func getDisplayName(address: Address?) -> String {
        var name = "Unkown"
        if let tempDisplayName = address?.displayName {
            if tempDisplayName.isEmpty {
                name = matchPhoneBookNamesFromAddress(address: address)
            } else {
                name = tempDisplayName
            }
        }
        return name
    }
}
