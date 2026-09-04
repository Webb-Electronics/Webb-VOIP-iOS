import SwiftUI

struct ManageContactListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: ManageContactListSheetVM = .init()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if vm.phoneBooks.isEmpty {
                        Text("No Phone Books Added")
                    }
                    List {
                        ForEach(vm.phoneBooks, id: \.self) {
                            pb in
                            Text(pb.name.isEmpty ? pb.url : pb.name).lineLimit(1)
                        }.onDelete(perform: { i in
                            vm.removePhoneBook(index: i)
                        })
                    }
                } header: {
                    Text("Existing Phone Books")
                }

                Section {
                    if !vm.error.isEmpty {
                        Text(vm.error).foregroundStyle(.red)
                    }
                    TextField("Phone Book URL", text: $vm.newUrl)
                    Button {
                        Task {
                            await vm.addPhoneBook()
                        }

                    } label: {
                        if vm.loading {
                            ProgressView()
                        } else {
                            Text("Add")
                        }
                    }
                } header: {
                    Text("Add New")
                }
            }
            .toolbar {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle").foregroundStyle(.foreground)
                }
            }
        }
    }
}

#Preview {
    ManageContactListSheet()
}
