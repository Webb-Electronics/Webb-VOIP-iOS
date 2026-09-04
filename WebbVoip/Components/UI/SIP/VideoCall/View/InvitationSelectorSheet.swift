import Foundation
import SwiftUI

struct InvitationSelectorSheet: View {
    let allContacts: [Contact]
    let callBackFunc: (String) -> Void
    @State var fullAddr = false
    @State var inputDialCode: String = ""
    var body: some View {
        Form {
            Section {
                TextField("Dial Code", text: $inputDialCode).autocorrectionDisabled(true).keyboardType(.numberPad)
                Button {
                    callBackFunc(inputDialCode)
                } label: {
                    Text("Invite").foregroundStyle(.primary)
                }
            } header: {
                Text("manual add")
            }

            Section {
                if !allContacts.isEmpty {
                    List(allContacts) { cont in
                        InvitationItem(name: cont.name, targets: SelectableTarget.build(cont.dialTarget), callBackFunc: callBackFunc)
                    }
                } else {
                    Text("No Related Contact Found")
                }
            } header: {
                Text("from contacts")
            }
        }
    }
}

private struct SelectableTarget: Identifiable, Hashable {
    let id = UUID()
    let target: String

    static func build(_ strs: [String]) -> [SelectableTarget] {
        strs.map { str in
            SelectableTarget(target: str)
        }
    }
}

private struct InvitationItem: View {
    let name: String
    let targets: [SelectableTarget]
    let callBackFunc: (String) -> Void
    var body: some View {
        Section {
            ForEach(targets) { target in
                TargetSelection(target: target.target, callBackFunc: callBackFunc)
            }
        } header: {
            Text(name)
        }
    }
}

private struct TargetSelection: View {
    let target: String
    let callBackFunc: (String) -> Void
    var body: some View {
        HStack {
            Text(target).font(.footnote).padding(.horizontal)
            Spacer()
            Image(systemName: "plus.circle")
        }.onTapGesture {
            callBackFunc(target)
        }.foregroundStyle(.blue)
    }
}

#Preview {
    InvitationSelectorSheet(
        allContacts:
        [
            Contact(name: "test", dialTarget: ["test", "test2", "test3"]),
            Contact(name: "123", dialTarget: ["1", "2", "3"]),
        ]
    ) {
        print($0)
    }
}
