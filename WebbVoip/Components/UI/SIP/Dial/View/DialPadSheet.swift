import AVFoundation
import SwiftUI

private let DIAL_PLAN_DATA = [
    ["1", "2", "3"],
    ["4", "5", "6"],
    ["7", "8", "9"],
    ["*", "0", "#"],
]
private let DIAL_BUTTON_SOUND = [
    "*": 1210,
    "#": 1211,
    "0": 1200,
    "1": 1201,
    "2": 1202,
    "3": 1203,
    "4": 1204,
    "5": 1205,
    "6": 1206,
    "7": 1207,
    "8": 1208,
    "9": 1209,
]

struct DialPadSheet: View {
    @Binding var numberToDial: String
    var forceDarkMode = false
    var body: some View {
        VStack {
            ForEach(DIAL_PLAN_DATA, id: \.self) {
                buildRow(which: $0)
            }
        }
    }

    @ViewBuilder
    func buildRow(which: [String]) -> some View {
        HStack {
            Spacer()
            ForEach(which, id: \.self) {
                num in Button(num) {
                    AudioServicesPlaySystemSound(UInt32(DIAL_BUTTON_SOUND[num] ?? 1200))
                    withAnimation {
                        numberToDial += num
                    }
                }.buttonStyle(WebbDialButtonStyle(forceDarkMode: forceDarkMode))
                Spacer()
            }
        }
    }
}
