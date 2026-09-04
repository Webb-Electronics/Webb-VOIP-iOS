import Foundation

/// A Static API Class to call the registeration or unregistration process of the Notfication service
class NetworkNotificationServerAPI {
    /// Register current APN with DialCode to the specified domain
    /// - Parameters:
    ///   - dialCode: the dialcode of account registered
    ///   - serverDomain: the URL of the domain
    static func register(dialCode: String, serverDomain: String) async throws {
        guard DeploymentConfig.pushAllowedDomains.contains(serverDomain) else {
            return
        }
        guard !UserDefaultsConfigurator.instance.registeredTokens.contains("\(dialCode)@\(serverDomain)") else {
            return
        }
        try await NetworkNotificationRequest("register", dialCode: dialCode, serverDomain: serverDomain).send()
        UserDefaultsConfigurator.instance.registeredTokens.append("\(dialCode)@\(serverDomain)")
    }

    /// Unregister current APN with DialCode to the specified domain
    /// - Parameters:
    ///   - dialCode: the dialcode of account unregistered
    ///   - serverDomain: the URL of the domain
    static func unregister(dialCode: String, serverDomain: String) async throws {
        guard DeploymentConfig.pushAllowedDomains.contains(serverDomain) else {
            return
        }
        guard UserDefaultsConfigurator.instance.registeredTokens.contains("\(dialCode)@\(serverDomain)") else {
            return
        }
        try await NetworkNotificationRequest("unregister", dialCode: dialCode, serverDomain: serverDomain).send()
        UserDefaultsConfigurator.instance.registeredTokens.removeAll { str in
            str == "\(dialCode)@\(serverDomain)"
        }
    }

    private init() {}
}

private class NetworkNotificationRequest: NetworkRequest {
    let sendingHeaders: [String: String] = ["Content-Type": "application/json"]

    var url: URL

    let body: String?

    init(_ action: String, dialCode: String, serverDomain: String) throws {
        guard ["register", "unregister"].contains(action) else {
            throw GeneralError.runtimeError("subPath incorrect - \(action)")
        }
        guard let urlData = DeploymentConfig.pushRegistrationURL else {
            throw GeneralError.runtimeError("push registration endpoint is not configured")
        }
        let dic: [String: Any] = [
            "action": action,
            "payload": [
                "dialCode": dialCode,
                "token": UserDefaultsConfigurator.instance.userApnToken,
                "serverDomain": serverDomain,
            ],
        ]
        self.body = try String(data: JSONSerialization.data(withJSONObject: dic), encoding: .utf8)

        self.url = urlData
    }

    func send() async throws {
        _ = try await sendRequest(body: body, httpRequestMethod: "POST")
    }
}
