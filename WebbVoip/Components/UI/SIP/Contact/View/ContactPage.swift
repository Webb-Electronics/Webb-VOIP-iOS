import SwiftUI

private struct ContactRow: View {
    let contact: Contact
    let updateFunc: (Contact, Bool) -> Void
    var body: some View {
        HStack {
            Text(contact.name).lineLimit(1)
            Spacer()
            Text(contact.dialTarget.joined(separator: " ")).lineLimit(1)
            Button {
                updateFunc(contact, true)
            } label: {
                Image(systemName: "teletype").scaledToFit()
            }
        }
    }
}

private struct ContactPageToolBar: View {
    @Binding var showEdit: Bool
    var body: some View {
        HStack {
            Button {
                showEdit = true
            } label: {
                Image(systemName: "externaldrive.badge.plus")
            }
        }
    }
}

struct ContactPage: View {
    @ObservedObject var vm: ContactPageVM = .init()

    var body: some View {
        NavigationStack {
            Form {
                if vm.contacts.isEmpty {
                    Text("No Contact Avilable")
                }
                List(vm.getCurrentList()) {
                    ContactRow(contact: $0, updateFunc: vm.updateDetailContact)
                }
            }.refreshable {
                vm.reloadContacts()
            }.sheet(isPresented: $vm.showDetailed) {
                ContactChooseCallingSheet(
                    numbers: vm.detailedContact?.dialTarget ?? [],
                    registrations: vm.getRegistrations() ?? ([], []),
                    errorDialOut: $vm.errorDialOut
                ).presentationDetents([.medium, .large])
            }.sheet(isPresented: $vm.showEdit) {
                ManageContactListSheet().presentationDetents([.medium, .large])
            }
            .alert("Error Loading Contacts", isPresented: $vm.errorLoading) {}
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.inline)
            //.toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.red, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    ContactPageToolBar(showEdit: $vm.showEdit)
                }
            }
        }
    }
}

#Preview {
    ContactPage()
}
