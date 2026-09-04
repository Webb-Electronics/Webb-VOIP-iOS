import SwiftUI

struct CallHistoryLogListItem: View {
    @ObservedObject var vm: CallHistoryLogListItemVM
    var body: some View {
        HStack {
            if vm.log.isVideo {
                Image(systemName: "video.fill").foregroundStyle(.blue)
            } else {
                Image(systemName: "speaker.2.fill").foregroundStyle(.blue)
            }

            VStack(alignment: .leading) {
                Text("t: " + vm.log.displayTo)
                    .font(.subheadline).lineLimit(1)
                Text("f: " + vm.log.displayFrom)
                    .font(.subheadline).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(vm.log.time, style: .date).font(.footnote).lineLimit(1)
                Text(vm.log.time, style: .time).font(.footnote).lineLimit(1)
            }

            getCallTypeIcon()
        }.onTapGesture {
            vm.showCallSheet = true
        }.alert("Dial Out Failed", isPresented: $vm.errorDial) {}.sheet(isPresented: $vm.showCallSheet, content: {
            if let numberToDialBack = vm.log.numberToDialBack {
                ContactChooseCallingSheet(
                    numbers: [numberToDialBack],
                    registrations: vm.getRegistrations(),
                    errorDialOut: $vm.errorDial,
                    additionalText: "Last used account: \(vm.log.displayLocal)"
                )
                .presentationDetents([.medium, .large])
            } else {
                Text("Error getting the number to dial back").presentationDetents([.medium])
            }

        })
    }

    @ViewBuilder
    func getCallTypeIcon() -> some View {
        switch vm.log.callType {
        case .incoming:
            Image(systemName: "phone.arrow.down.left.fill").foregroundStyle(.green)
        case .missedIncoming:
            Image(systemName: "phone.arrow.down.left.fill").foregroundStyle(.red)
        case .outgoing:
            Image(systemName: "phone.arrow.up.right.fill").foregroundStyle(.green)
        case .missedOutgoing:
            Image(systemName: "phone.arrow.up.right.fill").foregroundStyle(.red)
        }
    }

    @ViewBuilder
    func getCallTypeText() -> some View {
        switch vm.log.callType {
        case .incoming:
            Text("Incoming")
        case .outgoing:
            Text("Outgoing")
        case .missedIncoming:
            Text("Missed Incoming")
        case .missedOutgoing:
            Text("Missed Outgoing")
        }
    }
}

struct CallHistoryPage: View {
    var body: some View {
        @ObservedObject var vm = CallHistoryPageVM()
        NavigationStack {
            VStack {
                if vm.callLogs.isEmpty {
                    Spacer()
                    Text("No Call History Found")
                }

                List(vm.callLogs) {
                    CallHistoryLogListItem(vm: CallHistoryLogListItemVM(log: $0))
                }
            }.onAppear {
                vm.reloadLogs()
            }.refreshable {
                vm.reloadLogs()
            }
            .navigationTitle("Call History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.red, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            //.toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    CallHistoryPage()
}
