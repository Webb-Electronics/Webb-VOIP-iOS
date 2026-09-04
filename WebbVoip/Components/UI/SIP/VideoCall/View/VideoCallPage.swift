import SwiftUI

struct VideoScreenStream: UIViewRepresentable {
    let viewUpdater: (UIView) -> Void
    public func makeUIView(context _: Context) -> UIView {
        let view = UIView()
        viewUpdater(view)
        return view
    }

    public func updateUIView(_: UIView, context _: Context) {}
}

struct VideoCallPage: View {
    @ObservedObject var vm: VideoCallPageVM

    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Text(vm.callPageVM.callingText)
                        .padding(.top, 40)
                        .padding(.leading, 25)
                        .font(.system(size: 17))
                        .foregroundStyle(.white)
                    Spacer()
                    TimerView(vm: vm.callPageVM, size: 17)
                        .padding(.top, 40)
                        .padding(.trailing, 25)
                }
                HStack {
                    (
                        VideoScreenStream {
                            view in
                            vm.updateCallViewSupplier(view, remote: true)
                        }

                        .overlay(alignment: .topLeading) {
                            HStack {
                                Button {
                                    vm.minimizeVideo = true
                                } label: {
                                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                                        .padding().font(.system(size: 20)).foregroundStyle(.white)
                                }
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
                                Spacer()

                            }.sheet(isPresented: $vm.showCallTransferSheet, content: {
                                InvitationSelectorSheet(allContacts: vm.allContacts, callBackFunc: vm.transferCall)
                            }).alert("Cannot Dial This Number", isPresented: $vm.errorDialCode) {}
                        }
                        .overlay(alignment: .topTrailing) {
                            VideoScreenStream {
                                view in
                                vm.updateCallViewSupplier(view, remote: false)
                            }
                            .cornerRadius(10.0)
                            .padding(EdgeInsets(top: 15, leading: 0, bottom: 0, trailing: 15))
                            .frame(width: geometry.size.width / 3.5, height: geometry.size.height / 5)
                        }
                    )
                } // HS 2 ends

                HStack {
                    Menu {
                        ForEach(vm.availableCameras, id: \.self) { cam in
                            Button {
                                vm.currentCamera = cam
                            } label: {
                                HStack {
                                    Image(systemName: VideoCallPageVM.imageCameraDeviceName(cam))
                                    Text((vm.currentCamera == cam ? "✔️" : "") +
                                        VideoCallPageVM.translateCameraDeviceName(cam)
                                    )
                                }
                            }
                        }
                    } label: {
                        Image(systemName: vm.currentCamera == "StaticImage: Static picture" ? "video.slash.fill" : "video.fill")
                    }.foregroundStyle(.white).padding().font(.system(size: 25))
                    Spacer()
                    Menu {
                        ForEach(vm.availableSpeakers, id: \.self) { acd in
                            Button {
                                acd.setAduio()
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
            }
            .background(Color(UIColor.darkGray))
            .edgesIgnoringSafeArea(.top)
        }
    }
}

#Preview {
    VideoCallPage(vm: VideoCallPageVM(callPageVM: CallPageVM(callingUUID: UUID()), allVM: [], updater: { _ in

    }))
}
