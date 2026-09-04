import SwiftUI

struct DialPageNumberBar: View {
    @Binding var numberToDial: String
    let pasteAction: (Bool) -> Void

    var body: some View {
        HStack {
            Text(numberToDial.isEmpty ? " " : numberToDial)
                .font(.largeTitle)
                .frame(maxWidth: .infinity, minHeight: 65)
                .lineLimit(2)
                .truncationMode(.head)

            Button {
                numberToDial.removeLast()
            } label: {
                Image(systemName: "delete.backward.fill")
                    .font(.title)
                    .foregroundColor(.gray)
            }
            .padding(.trailing)
            .opacity(numberToDial.isEmpty ? 0 : 1)
            .disabled(numberToDial.isEmpty)
        }
        .padding(.horizontal)
        .contentShape(Rectangle()) // Make the entire HStack tappable for the context menu
        .contextMenu {
            Button {
                pasteAction(false)
            } label: {
                Label("Paste Number", systemImage: "doc.on.clipboard")
            }

            Button {
                pasteAction(true)
            } label: {
                Label("Paste External", systemImage: "doc.on.clipboard.fill")
            }
        }
    }
}

struct DialPageUserSelect: View {
    let onlineRegistration: [Registration]
    @Binding var currentAccount: Registration

    var body: some View {
        Picker("Account", selection: $currentAccount) {
            ForEach(onlineRegistration, id: \.self) {
                Text($0.username + " (" + $0.url + ")").tag($0)
            }
        }.pickerStyle(.menu)
    }
}

struct DialPage: View {
    @ObservedObject var vm: DialPageVM = .init()
    var body: some View {
        LazyVStack {
            if vm.onlineRegistration.count > 1 {
                DialPageUserSelect(onlineRegistration: vm.onlineRegistration, currentAccount: $vm.currentAccount)
            }
            DialPageNumberBar(numberToDial: $vm.numberToDial) {
                external in
                vm.pasteNumnberFromClipboard(external)
            }
            Divider()
            DialPadSheet(numberToDial: $vm.numberToDial)
            DialPageOutgoingDialButton(
                numberToDial: $vm.numberToDial,
                currentAccount: $vm.currentAccount,
                enabled: !vm.onlineRegistration.isEmpty,
                audioOnly: vm.audioOnly
            )
        }.onAppear {
            vm.reloadRegistrations()
        }
    }
}

#Preview {
    DialPage()
}
