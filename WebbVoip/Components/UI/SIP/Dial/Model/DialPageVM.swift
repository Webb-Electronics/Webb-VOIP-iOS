import Foundation
import UIKit

class DialPageVM: ObservableObject {
    @Published var onlineRegistration: [Registration]!
    @Published var numberToDial = ""
    @Published var currentAccount: Registration!
    @Published var audioOnly = false
    @Published var showOptionToPaste = false

    init() {
        self.numberToDial = ""
        reloadRegistrations()
    }

    func reloadRegistrations() {
        let onlineRegs = User.instance.allRegistrations.filter {
            $0.registrationStatus == .registered
        }
        onlineRegistration = onlineRegs

        let defReg = User.instance.defaultRegistration ?? (onlineRegs.isEmpty ? Registration() : onlineRegs[0])
        currentAccount = defReg
        audioOnly = User.instance.onlyAudioCall
    }

    func pasteNumnberFromClipboard(_ external: Bool) {
        // remove all non-digit characters from the string and set it to numberToDial
        guard let pasteString = UIPasteboard.general.string else {
            return
        }
        let digits = pasteString.filter { $0.isNumber }
        guard digits.isEmpty == false else {
            return
        }
        numberToDial = external ? "9\(digits)" : digits
    }
}
