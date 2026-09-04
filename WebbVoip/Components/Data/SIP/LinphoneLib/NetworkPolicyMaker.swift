import Foundation
import linphonesw

/// function to create Network Policy (NAT) on special cases
enum NetworkPolicyMaker {
    /// Create the NAT policy for a domain, using the STUN servers configured in
    /// ``DeploymentConfig``. A domain without a configured STUN server gets no
    /// policy at all.
    /// - Parameters:
    ///   - core: the linphone core
    ///   - domain: the SIP domain
    /// - Returns: the policy to apply, or `nil` when the domain needs none
    static func createPolicy(_ core: Core, domain: String) throws -> NatPolicy? {
        guard let stunServer = DeploymentConfig.natStunServers[domain] else {
            return nil
        }
        let policy = try core.createNatPolicy()
        policy.stunServer = stunServer
        policy.iceEnabled = true
        policy.stunEnabled = true
        return policy
    }
}
