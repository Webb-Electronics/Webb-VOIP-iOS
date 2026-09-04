import SwiftUI

struct WebbDialButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    var forceDarkMode: Bool
    func makeBody(configuration: Configuration) -> some View {
        if colorScheme == .light, !forceDarkMode {
            configuration.label.padding().padding().background(Color(red: 0.9, green: 0.9, blue: 0.9))
                .clipShape(Circle()).font(.largeTitle)
        } else {
            configuration.label.padding().padding().background(Color(red: 0.2, green: 0.2, blue: 0.2))
                .clipShape(Circle()).font(.largeTitle)
        }
    }
}

struct DialPageOutgoingDialButton: View {
    @Binding var numberToDial: String
    @State var showAlert: Bool = false
    @State var showError: Bool = false
    @Binding var currentAccount: Registration
    let enabled: Bool
    let audioOnly: Bool
    var body: some View {
        HStack {
            Spacer()
            Button {
                if !enabled {
                    showAlert = true
                    return
                }
                do {
                    try currentAccount.dial(number: numberToDial)
                    numberToDial = ""
                } catch {
                    showError = true
                }

            } label: {
                Image(systemName: audioOnly ? "phone.fill" : "video.fill")
            }.padding().padding()
                .background(enabled ? Color.green : Color.red)
                .clipShape(Circle()).font(.title)
                .foregroundColor(.white)
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("No Account"), message: Text("You need at least 1 account that is registered"))
                }.alert("Call Failed, might already be in a call", isPresented: $showError) {}

            Spacer()
        }
    }
}
