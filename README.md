# Webb VOIP — iOS

A SIP softphone for iOS. Register one or more SIP accounts, then place and
receive audio and video calls. Incoming calls ring through CallKit, so they
behave like regular phone calls and show up in the system call history.

Built with Swift and SwiftUI on top of the
[Linphone SDK](https://linphone.org/).

**Features:** SIP registration · audio/video calls · dialer · call history ·
contacts · VoIP push wake-up for incoming calls · optional per-domain STUN/ICE
for NAT traversal

## Requirements

- Xcode (recent stable release)
- iOS 16.0+
- CocoaPods

## Build & run

```bash
git clone <repository-url>
cd webb-voip-companion-IOS
pod install
open WebbVoip.xcworkspace
```

Open the **`.xcworkspace`**, not the `.xcodeproj` — the project mixes CocoaPods
and Swift Package Manager dependencies. Then select the `WebbVoip` scheme and
Run.

From the command line:

```bash
xcodebuild -workspace WebbVoip.xcworkspace \
           -scheme WebbVoip \
           -destination 'generic/platform=iOS' \
           build
```

## First run

The app starts with no accounts. Open the **Register** screen, add a
registration, and fill in your SIP username, password, and server. Once it
shows *Registered*, use the dialer to call.

## configuration

```bash
cp Config/Deployment.local.xcconfig.example Config/Deployment.local.xcconfig
```

## License

Licensed under the **GNU Affero General Public License v3.0** — see
[LICENSE](LICENSE).

You may use, modify, and distribute this software, including commercially,
provided you meet the AGPLv3 conditions:

- **Disclose source** — source code must be made available when the software is
  distributed.
- **License and copyright notice** — a copy of the license and the original
  copyright notice must be included.
- **Network use is distribution** — users who interact with the software over a
  network must be offered its source code.
- **Same license** — modifications must be released under the same license.
- **State changes** — significant changes made to the code must be documented.

The bundled **Linphone SDK** is licensed by Belledonne Communications under
GPLv3 (or a separate commercial license). GPLv3 section 13 permits combining
GPLv3 code with AGPLv3 works, so the two are compatible here.
