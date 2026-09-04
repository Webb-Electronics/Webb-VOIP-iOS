import SwiftUI

struct WebbInputField: View {
    var textHint: String
    var password: Bool
    var textPrompt: String
    @Binding var textEntered: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(textHint).padding(.top)
            if password {
                SecureField(textPrompt, text: $textEntered)
                    .textFieldStyle(.roundedBorder)
            } else {
                TextField(text: $textEntered, prompt: Text(textPrompt)) {}
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled(true)
                    .autocapitalization(.none)
            }
        }
    }
}

struct AddNewRegistrationSheet: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var vm: AddNewRegistrationDetailSheetVM = .init()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                WebbInputField(
                    textHint: "Server URL:",
                    password: false,
                    textPrompt: "Required",
                    textEntered: $vm.newData.url
                )
                WebbInputField(
                    textHint: "User Name:",
                    password: false,
                    textPrompt: "Required",
                    textEntered: $vm.newData.username
                )
                WebbInputField(
                    textHint: "Password:",
                    password: true,
                    textPrompt: "",
                    textEntered: $vm.newData.password
                )
                Text("Transport:").padding(.top)
                Picker("Transport", selection: $vm.newData.transport) {
                    Text(SIPTransportProtocol.udp.rawValue).tag(SIPTransportProtocol.udp)
                    Text(SIPTransportProtocol.tls.rawValue).tag(SIPTransportProtocol.tls)
                }.pickerStyle(.segmented)
                Button {
                    do {
                        vm.loading = true
                        try vm.saveData()
                        try vm.register()
                        dismiss()
                    } catch {
                        vm.loading = false
                    }

                } label: {
                    if vm.loading {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Register").frame(maxWidth: .infinity)
                    }

                }.frame(maxWidth: .infinity)
                    .padding()
                    .background(.green).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(radius: 5, x: 3, y: 3)
                    .padding(.vertical)
                    .alert("Invalid Registration", isPresented: $vm.showInvalidEntry) {}.alert("Registration Already Exists", isPresented: $vm.showAlreadyExist) {}
            }.disabled(vm.loading).padding()
                .toolbar {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle").foregroundStyle(.foreground)
                    }
                }
            Text("").padding(.bottom, 20)
        }
    }
}

#Preview {
    AddNewRegistrationSheet()
}
