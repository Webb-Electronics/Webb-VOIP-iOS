import SwiftUI

struct TimerView: View {
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var elapsedTime: String
    var size: CGFloat
    let vm: CallPageVM
    var body: some View {
        Text(elapsedTime)
            .onReceive(timer) { _ in
                elapsedTime = Date().passedTime(from: vm.startTime)
            }.font(.system(size: size))
            .foregroundStyle(.white)
    }

    init(vm: CallPageVM, size: CGFloat = 26.0) {
        self.elapsedTime = Date().passedTime(from: vm.startTime)
        self.vm = vm
        self.size = size
    }
}

struct AudioOnlyPage: View {
    @ObservedObject var vm: AudioCallPageVM

    var body: some View {
        VStack {
            Text("Audio Only").foregroundStyle(.white)
            HStack {
                Button {
                    vm.minimizeVideo = true
                } label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .padding().font(.system(size: 20)).foregroundStyle(.white)
                }
                Spacer()
                Menu {
                    ForEach(vm.allUUID, id: \.self) { uuid in
                        Button {
                            vm.currentUUID = uuid
                        } label: {
                            if vm.currentUUID == uuid {
                                Image(systemName: "person.wave.2.fill")
                            }
                            Text(AudioCallPageVM.getCallerName(uuid))
                            if vm.queryCallPaused(uuid) {
                                Image(systemName: "pause.fill")
                            }
                        }
                    }
                } label: {
                    Image(systemName: "phone.connection.fill").padding().font(.system(size: 20)).foregroundStyle(.white)
                }
                Button {
                    vm.showConferenceInviteSheet = true
                } label: {
                    Image(systemName: "person.fill.badge.plus")
                        .padding().font(.system(size: 20)).foregroundStyle(.white)
                }
                Button {
                    vm.showCallTransferSheet = true
                } label: {
                    Image(systemName: "person.fill.and.arrow.left.and.arrow.right")
                        .padding().font(.system(size: 20)).foregroundStyle(.white)
                }
                Button {
                    vm.paused.toggle()
                } label: {
                    Image(systemName: vm.paused ? "play.fill" : "pause.fill")
                        .padding().font(.system(size: 20)).foregroundStyle(.white)
                }

            }.sheet(isPresented: $vm.showConferenceInviteSheet, content: {
                InvitationSelectorSheet(allContacts: vm.allContacts, callBackFunc: vm.inviteToConference)
            }).sheet(isPresented: $vm.showCallTransferSheet, content: {
                InvitationSelectorSheet(allContacts: vm.allContacts, callBackFunc: vm.transferCall)
            }).alert("Cannot Dial This Number", isPresented: $vm.errorDialCode) {}
            Spacer()
            TimerView(vm: vm.callPageVM)

            HStack {
                Text(vm.callPageVM.callingText).font(.system(size: 45))
                    .foregroundStyle(.white)
            }
            if vm.showDialPad {
                Text(vm.dtmfToSend).font(.footnote).foregroundStyle(.white).lineLimit(1)
                DialPadSheet(numberToDial: $vm.dtmfToSend, forceDarkMode: true).foregroundStyle(.white)
            }
            Spacer()
            HStack {
                Button {
                    withAnimation {
                        vm.showDialPad.toggle()
                        vm.dtmfToSend = ""
                    }
                } label: {
                    Image(systemName: vm.showDialPad ? "circle.grid.3x3" : "circle.grid.3x3.fill")
                }.foregroundStyle(.white).padding().font(.system(size: 25))
                Spacer()
                Menu {
                    ForEach(vm.availableSpeakers, id: \.self) { acd in
                        Button {
                            vm.currentSpeaker = acd
                        } label: {
                            HStack {
                                Image(systemName: AudioCallPageVM.imageAudioDeviceName(acd.name))
                                Text((vm.currentSpeaker?.id == acd.id ? "✔️" : "") + AudioCallPageVM.translateAudioDeviceName(acd.name))
                            }
                        }
                    }
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                }.foregroundStyle(.white).padding().font(.system(size: 25))
                Spacer()
                Button {
                    vm.micMuted = !vm.micMuted

                } label: {
                    Image(systemName: vm.micMuted ? "mic.slash.fill" : "mic.fill")
                }.foregroundStyle(.white).padding().font(.system(size: 25))
                Spacer()
                Button {
                    vm.callPageVM.endCall()
                } label: {
                    Image(systemName: "phone.down.fill")
                }.foregroundStyle(.red).padding().font(.system(size: 25))
            }
        }.frame(maxWidth: .infinity)
            .background(Color(UIColor.darkGray))
    }

    init(vm: AudioCallPageVM) {
        self.vm = vm
    }
}

#Preview {
    AudioOnlyPage(vm: AudioCallPageVM(callPageVM: CallPageVM(callingUUID: UUID()), allVM: [], updater: { _ in

    }))
}
