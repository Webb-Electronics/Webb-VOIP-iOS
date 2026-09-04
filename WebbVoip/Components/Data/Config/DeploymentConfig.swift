import Foundation

/// Site-specific deployment settings.
///
/// The values come from `Config/Deployment.xcconfig` and the git-ignored
/// `Config/Deployment.local.xcconfig`, which the build injects into the
/// `WebbDeploymentConfig` dictionary of `Info.plist`.
///
/// Every setting is optional. When one is absent the matching behaviour is
/// simply switched off, so a checkout without a local configuration still
/// builds and runs -- users register against whichever SIP server they enter
/// on the Register screen.
enum DeploymentConfig {
    /// URL of the push-registration service, or `nil` when not configured.
    ///
    /// The endpoint is configured as host plus path, without a scheme, because
    /// `//` starts a comment in xcconfig files. HTTPS is always used.
    static let pushRegistrationURL: URL? = {
        let endpoint = string(for: "PushRegistrationEndpoint")
        guard !endpoint.isEmpty else {
            return nil
        }
        return URL(string: "https://" + endpoint)
    }()

    /// SIP domains the app may register for push notifications against.
    static let pushAllowedDomains: [String] = list(for: "PushAllowedDomains")

    /// Aliases that rewrite a SIP server address into its canonical domain, so
    /// that the same account reached over the LAN and over the internet is
    /// treated as one identity.
    static let domainAliases: [String: String] = pairs(for: "DomainAliases")

    /// STUN server to use per SIP domain. A domain absent from this map gets no
    /// NAT policy at all.
    static let natStunServers: [String: String] = pairs(for: "NatStunPolicies")

    private static let settings: [String: Any] =
        Bundle.main.object(forInfoDictionaryKey: "WebbDeploymentConfig") as? [String: Any] ?? [:]

    /// Read a raw setting.
    /// - Parameter key: the key inside the `WebbDeploymentConfig` dictionary
    /// - Returns: the trimmed value, or an empty string when unset
    private static func string(for key: String) -> String {
        (settings[key] as? String ?? "").trimmingCharacters(in: .whitespaces)
    }

    /// Read a setting holding a comma-separated list.
    /// - Parameter key: the key inside the `WebbDeploymentConfig` dictionary
    /// - Returns: the non-empty entries
    private static func list(for key: String) -> [String] {
        string(for: key)
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Read a setting holding comma-separated `key=value` pairs.
    ///
    /// Entries without both halves are skipped, so a partially filled
    /// configuration cannot break start-up.
    /// - Parameter key: the key inside the `WebbDeploymentConfig` dictionary
    /// - Returns: the parsed pairs
    private static func pairs(for key: String) -> [String: String] {
        var result: [String: String] = [:]
        for entry in list(for: key) {
            let halves = entry.split(separator: "=", maxSplits: 1).map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            guard halves.count == 2, !halves[0].isEmpty, !halves[1].isEmpty else {
                continue
            }
            result[halves[0]] = halves[1]
        }
        return result
    }
}
