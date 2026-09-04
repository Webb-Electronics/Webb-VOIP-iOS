import SwiftUI

struct WebbTabButton<Content: View>: View {
    let labelName: String
    let systemImage: String
    @ViewBuilder let content: Content
    var body: some View {
        content.tabItem {
            Label(labelName, systemImage: systemImage)
        }
    }
}

struct SIPContainerPage: View {
    @ObservedObject var pcm: PersistentCallStatus = .instance

    let vm: SipContainerVM = .init()
    var body: some View {
        let currentStatus = vm.getCurrentPageState()
        switch currentStatus {
        case .notInCall:
            SIPTabView()

        case .minimizedInCall:
            if let pageVm = vm.callPageVM {
                MinimizedCallContainer(vm: VideoCallPageVM(callPageVM: pageVm, allVM: vm.allVMs, updater: vm.updateCallingPageVM), video: vm.isVideoCall) {
                    SIPTabView()
                }
            }
        case .connectingCall:
            if let pageVm = vm.callPageVM {
                CallLoadingPage(vm: AudioCallPageVM(callPageVM: pageVm, allVM: vm.allVMs, updater: vm.updateCallingPageVM))
            }
        case .inCall:
            if let pageVm = vm.callPageVM {
                if vm.isVideoCall {
                    VideoCallPage(vm: VideoCallPageVM(callPageVM: pageVm, allVM: vm.allVMs, updater: vm.updateCallingPageVM))
                } else {
                    AudioOnlyPage(vm: AudioCallPageVM(callPageVM: pageVm, allVM: vm.allVMs, updater: vm.updateCallingPageVM))
                }
            }
        }
    }
}

struct SIPTabView: View {
    var body: some View {
        TabView {
            WebbTabButton(labelName: "Registration", systemImage: "externaldrive.badge.wifi") {
                RegistrationPage()
            }
            WebbTabButton(labelName: "Dial", systemImage: "phone.fill") {
                DialPage()
            }
            WebbTabButton(labelName: "Contacts", systemImage: "person.crop.circle") {
                ContactPage()
            }
            WebbTabButton(labelName: "Call History", systemImage: "phone.bubble.left.fill") {
                CallHistoryPage()
            }
        }
    }
}

#Preview {
    SIPContainerPage()
}
