import Foundation
import SwiftUI

struct ContactChooseCallingSheet: View {
    private let numbers: [DialTarget]
    let additionalText: String?
    let registrations: ([Registration], [Registration])
    @Binding var errorDialOut: Bool
    @State fileprivate var numberToDial: String

    var body: some View {
        VStack {
            if numbers.isEmpty {
                Text("No Number to Dial")
            } else if registrations.0.isEmpty, registrations.1.isEmpty {
                Text("No Account Avilable")
            } else {
                Form {
                    if let additionalText {
                        Text(additionalText).backgroundStyle(.clear)
                    }
                    if !numbers.isEmpty {
                        Section {
                            List(numbers) { num in
                                HStack {
                                    if numberToDial == num.target {
                                        Image(systemName: "arrowshape.forward.fill").foregroundStyle(.blue)
                                        Text(num.target).foregroundStyle(.blue)
                                    } else {
                                        Text(num.target)
                                    }

                                    Button {
                                        print("button set")
                                        numberToDial = num.target
                                    } label: {}
                                }
                            }
                        } header: {
                            Text("Number to Dial")
                        }
                    }
                    if !registrations.0.isEmpty {
                        RegistrationList(regs: registrations.0, text: "Related Accounts", dialTarget: $numberToDial, errorDialOut: $errorDialOut)
                    }
                    if !registrations.1.isEmpty {
                        RegistrationList(regs: registrations.1, text: "All Accounts", dialTarget: $numberToDial, errorDialOut: $errorDialOut)
                    }
                }
            }
        }
    }

    init(numbers: [String], registrations: ([Registration], [Registration]), errorDialOut: Binding<Bool>, additionalText: String? = nil) {
        self.numbers = DialTarget.fromListOfStrings(strings: numbers)
        self.registrations = registrations
        self._errorDialOut = errorDialOut
        self.numberToDial = numbers.first ?? ""
        self.additionalText = additionalText
    }
}

private struct DialTarget: Identifiable, Hashable {
    let id = UUID()
    let target: String

    static func fromListOfStrings(strings: [String]) -> [DialTarget] {
        var result: [DialTarget] = []
        for string in strings {
            result.append(DialTarget(target: string))
        }
        return result
    }
}

private struct RegistrationList: View {
    let regs: [Registration]
    let text: String
    @Binding var dialTarget: String
    @Binding var errorDialOut: Bool
    var body: some View {
        Section {
            List(regs) { reg in
                HStack {
                    VStack(alignment: .leading) {
                        Text(reg.username).lineLimit(1)
                        if let realName = reg.realName {
                            Text(realName).font(.footnote).lineLimit(1)
                        }
                        Text(reg.url).lineLimit(1)
                    }
                    Spacer()
                    Button {
                        Task {
                            do {
                                try reg.dial(number: dialTarget)
                            } catch {
                                errorDialOut = true
                            }
                        }
                    } label: {
                        Image(systemName: "phone.fill")
                    }
                }
            }
        } header: {
            Text(text)
        }
    }
}
