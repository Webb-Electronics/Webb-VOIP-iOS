import SwiftUI

struct CallLoadingPage: View {
    let vm: AudioCallPageVM
    var body: some View {
        VStack {
            Text("Connecting...").foregroundStyle(.white)
            Spacer()
            TimerView(vm: vm.callPageVM)
            HStack {
                Text(vm.callPageVM.callingText).font(.system(size: 45))
                    .foregroundStyle(.white)
            }
            Spacer()
            HStack {}
            HStack {
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
}

#Preview {
    CallLoadingPage(vm: AudioCallPageVM(callPageVM: CallPageVM(callingUUID: UUID()), allVM: [], updater: { _ in

    }))
}
