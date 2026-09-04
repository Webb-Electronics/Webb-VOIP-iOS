import SwiftUI

struct RegistrationDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState var focusedField: ExistingRegistrationDetailSheetField?
    @ObservedObject var existingReg: Registration
    @ObservedObject var vm: ExistingRegistrationDetailSheetVM

    init(existingReg: Registration) {
        self.existingReg = existingReg
        self.vm = ExistingRegistrationDetailSheetVM(reg: existingReg)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    displayRegistrationStatus().font(.title)
                    if existingReg.registrationStatus == .unregistered {
                        Button {
                            do {
                                try existingReg.register()
                            } catch {
                                vm.registerFailed = true
                                print("\(error)")
                            }

                        } label: {
                            Text("Register")
                        }.disabled(!vm.newData.equivalent(reg: existingReg))
                    } else if existingReg.registrationStatus == .registered {
                        Button {
                            do {
                                try existingReg.unregister()
                            } catch {
                                vm.operationFailed = true
                            }

                        } label: {
                            Text("Unregister")
                        }
                    }
                } header: {
                    Text("current status:")
                }
                Section {
                    LabeledContent {
                        Spacer()
                        TextField("URL", text: $vm.newData.url).focused($focusedField, equals: .url)
                    } label: {
                        Text("URL")
                    }
                    LabeledContent {
                        Spacer()
                        TextField("User Name", text: $vm.newData.username).focused($focusedField, equals: .username)
                    } label: {
                        Text("User Name")
                    }
                    LabeledContent {
                        Spacer()
                        SecureField("Password", text: $vm.newData.password).focused($focusedField, equals: .password)
                    } label: {
                        Text("Password")
                    }

                    Picker("Transport", selection: $vm.newData.transport) {
                        Text(SIPTransportProtocol.udp.rawValue).tag(SIPTransportProtocol.udp)
                        Text(SIPTransportProtocol.tls.rawValue).tag(SIPTransportProtocol.tls)
                    }.pickerStyle(.segmented)
                } header: {
                    Text("User Info")
                }.disabled(existingReg.registrationStatus != RegistrationStatus.unregistered)
                Section {
                    let contacts = vm.getContact(existingReg)
                    if contacts.count > 0 {
                        List(contacts) {
                            Text($0.name)
                        }
                    } else {
                        Text("No Contact Associated")
                    }
                } header: {
                    Text("Potential Associated Contacts")
                }
                if existingReg.registrationStatus == RegistrationStatus.unregistered {
                    Section {
                        Button {
                            do {
                                if vm.newDataAlreadyExist(currentData: existingReg) {
                                    vm.saveDataFailed = true
                                    return
                                }
                                try existingReg.updateWithNewData(reg: vm.newData)
                                focusedField = nil
                                vm.render()

                            } catch {
                                vm.saveDataFailed = true
                            }
                        } label: {
                            Text("Save")
                        }.disabled(vm.newData.equivalent(reg: existingReg))
                        Button {
                            Task {
                                do {
                                    try vm.currentUser.removeRegistration(registration: existingReg)
                                    dismiss()
                                } catch {
                                    print(error.localizedDescription)
                                    vm.operationFailed = true
                                }
                            }
                        } label: {
                            Text("Delete").foregroundStyle(.red)
                        }
                    } header: {
                        Text("Action")
                    }
                }
            }.alert("Saving failed, invalid user info", isPresented: $vm.saveDataFailed) {}
                .alert("Register Failed", isPresented: $vm.registerFailed) {}
                .alert("Operation Failed", isPresented: $vm.operationFailed) {}
                .toolbar {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle").foregroundStyle(.foreground)
                    }
                }
        }
    }

    @ViewBuilder
    func displayRegistrationStatus() -> some View {
        switch existingReg.registrationStatus {
        case .registered:
            HStack {
                Text("Registered")
                Spacer()
                Image(systemName: "checkmark.circle.fill")
            }.foregroundStyle(.green)
        case .unregistered:
            HStack {
                Text("Not Registered")
                Spacer()
                Image(systemName: "xmark.circle.fill")
            }.foregroundStyle(.red)
        case .registering:
            HStack {
                Text(" Registering")
                Spacer()
                ProgressView()
            }.foregroundStyle(.yellow)
        }
    }
}

#Preview {
    let reg = Registration()
    return RegistrationDetailSheet(existingReg: reg)
}
