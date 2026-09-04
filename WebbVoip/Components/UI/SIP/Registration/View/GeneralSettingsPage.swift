import SwiftUI

struct GeneralSettings: View {
    @ObservedObject var vm = GeneralSettingsVM()
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Call")) {
                    Toggle("Start Audio Only Session", isOn: $vm.onlyAudioCall)
                    if !vm.onlyAudioCall {
                        Toggle("Automatic Camera Off", isOn: $vm.autoCameraOff)
                    }
                }
                if !vm.registrations.isEmpty {
                    Section(header: Text("Sip Accounts")) {
                        Picker("Default Outgoing Call Account", selection: $vm.registrationDefault) {
                            ForEach(vm.registrations) {
                                i in
                                VStack(alignment: .leading) {
                                    Text(i.username)
                                    Text(i.url).font(.footnote)
                                }.tag(i)
                            }
                        }.pickerStyle(.inline)
                    }
                }
            }
            .navigationTitle("General Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.red, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            //.toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    GeneralSettings()
}
