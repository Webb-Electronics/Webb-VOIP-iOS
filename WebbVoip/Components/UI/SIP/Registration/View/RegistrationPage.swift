import SwiftUI

struct RegistrationPageListItem: View {
    let updateFunction: (Registration) -> Void
    @ObservedObject var reg: Registration
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(reg.username).font(.headline).lineLimit(1)
                Text(reg.url).fontWeight(.light).font(.system(size: 12)).lineLimit(1)
            }
            Spacer()
            displayRegistrationStatus().scaledToFill()
            Button {
                updateFunction(reg)
            } label: {
                Image(systemName: "info.circle")
            }
        }
    }

    @ViewBuilder
    func displayRegistrationStatus() -> some View {
        switch reg.registrationStatus {
        case .registered:
            HStack {
                Text("Registered")
                Image(systemName: "checkmark.circle.fill")
            }.foregroundStyle(.green)
        case .unregistered:
            HStack {
                Text("Not Registered")
                Image(systemName: "xmark.circle.fill")
            }.foregroundStyle(.red)
        case .registering:
            HStack(spacing: 5) {
                Text("Registering")
                ProgressView().padding(.init(top: 0, leading: 0, bottom: 0, trailing: 1))
            }.foregroundStyle(.yellow)
        }
    }
}

struct RegistrationPageToolBar: View {
    @Binding var showSettings: Bool
    var body: some View {
        HStack {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
            }.navigationDestination(isPresented: $showSettings) {
                GeneralSettings()
            }
        }
    }
}

struct RegistrationPage: View {
    @ObservedObject var vm: RegistrationPageVM = .init()
    var body: some View {
        NavigationStack {
            Form {
                if vm.user.allRegistrations.isEmpty {
                    Text("No Registration")
                }
                List(vm.user.allRegistrations) {
                    RegistrationPageListItem(updateFunction: vm.setShowingDetail, reg: $0)
                }

                Button {
                    vm.showAddNew = true
                } label: {
                    Text("Add New")
                }.sheet(isPresented: $vm.showAddNew) {
                    AddNewRegistrationSheet().presentationDetents([.medium])
                }
            }.refreshable {
                vm.reloadRegistrations()
            }.sheet(isPresented: $vm.showDetail) {
                RegistrationDetailSheet(existingReg: vm.showingRegistration!)
            }
            .navigationTitle("Registered SIP Accounts")
            //.toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.red, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    RegistrationPageToolBar(showSettings: $vm.showSettings)
                }
            }
        }
    }
}

#Preview {
    RegistrationPage()
}
