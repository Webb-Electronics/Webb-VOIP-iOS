# Deployment configuration

Everything specific to one deployment — the Apple team ID, the push-registration
service, which SIP domains get push notifications, and the NAT/STUN settings —
lives outside the tracked source so the repository can be published.

## Setting it up

```sh
cp Config/Deployment.local.xcconfig.example Config/Deployment.local.xcconfig
```

Then edit `Config/Deployment.local.xcconfig` and fill in your own values.
The file is git-ignored; `Config/Deployment.xcconfig` holds the (empty)
defaults and includes it optionally, so a checkout without it still builds.

## Building without it

Every setting is optional. With no local configuration the app builds and runs
normally: push registration is skipped, no NAT policy is applied, no domain
aliasing happens, and users register against whichever SIP server they type
into the Register screen.

## Available settings

| Setting | Purpose |
| --- | --- |
| `WEBB_DEVELOPMENT_TEAM` | Apple Developer Team ID used to sign the app. |
| `WEBB_PUSH_REGISTRATION_ENDPOINT` | Host + path of the push-registration service, **without** a scheme. |
| `WEBB_PUSH_ALLOWED_DOMAINS` | Comma-separated SIP domains allowed to register for push. |
| `WEBB_DOMAIN_ALIASES` | Comma-separated `address=canonicalDomain` pairs. |
| `WEBB_NAT_STUN_POLICIES` | Comma-separated `domain=stunServer` pairs; listed domains get ICE + STUN. |

`//` starts a comment in xcconfig files, so no setting may contain a URL
scheme. `WEBB_PUSH_REGISTRATION_ENDPOINT` is therefore given as host + path;
the app always talks HTTPS.

The values are injected into `Info.plist` at build time and read at runtime by
`WebbVoip/Components/Data/Config/DeploymentConfig.swift`.

## Signing material

Certificates, private keys and provisioning profiles are git-ignored by
extension (`*.p12`, `*.pem`, `*.cer`, `*.mobileprovision`, …) and must be
distributed out of band — never committed.
