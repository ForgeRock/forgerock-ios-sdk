// 
//  FRAPolicyEvaluator.swift
//  FRAuthenticator
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// The Policy Evaluator is used by the SDK to enforce Policy rules, such as Device Tampering Policy.
/// It consist of one or more `FRAPolicy` objects. Each Policy contain instructions that
/// determine whether it comply to a particular condition at a particular time.
public class FRAPolicyEvaluator {
    
    /// Default set of policies available.
    public static let defaultPolicies : [FRAPolicy] = [BiometricAvailablePolicy(), DeviceTamperingPolicy()]
    
    private var targetedPolicies : [FRAPolicy] = []
    
    
    //  MARK: - Properties
    
    /// The list of polices to be evaluated.
    public internal(set) var policies : [FRAPolicy]?
    
    
    //  MARK: - Init
    
    /// Initializes FRAPolicyEvaluator object
    public init() {
        self.policies = FRAPolicyEvaluator.defaultPolicies
    }
    
    //  MARK: - Result
    
    /// Result of the Policy Evaluator execution.
    public struct Result {
        
        /// Return if all policies were evaluated successfully.
        /// - Returns: true, if all Policies are complying, false if any policy fail.
        public internal(set) var comply: Bool
        
        /// Return the Policy that fail to comply.
        /// - Returns: The Policy object.
        public internal(set) var nonCompliancePolicy: FRAPolicy?
        
    }
    
    //  MARK: - Policy Evaluator
    
    /// Registers a new array of policies; the new array can override the existing policies, or append on top of existing array.
    /// This method does not check if a policy has been added to the list previously.
    /// - Parameters:
    ///   - policies: An array of FRAPolicy to be registered
    ///   - shouldOverride: Boolean indicator whether or not to override existing array
    /// - Throws: FRAError
    public func registerPolicies(policies: [FRAPolicy], shouldOverride: Bool = true) throws {
        for policy in policies {
            guard !policy.name.isEmpty else {
                throw FRAError.invalidPolicyRegisteredWithPolicyEvaluator(String(describing: policy.self))
            }
        }
        
        if shouldOverride || self.policies == nil {
            self.policies = policies
        } else {
            for policy in policies {
                self.policies?.append(policy)
            }
        }
    }
    
    /// Evaluate all registered Policies against an URI.
    /// - Parameter uri: URL of QR Code
    public func evaluate(uri: URL) -> Result {
        let policiesJson = getPoliciesFromURI(uri: uri)
        return processPolicies(policiesJson: policiesJson)
    }
 
    /// Evaluate all registered Policies against an URI.
    /// - Parameter account: Account object
    public func evaluate(account: Account) -> Result {
        return processPolicies(policiesJson: account.policies)
    }
    
    /// Return if a policy was attached to the `Account`.
    /// - Parameters:
    ///   - account: Account object
    ///   - policyName: The name of the policy
    /// - Returns: true, if the policy was attached to the Account, false otherwise.
    public func isPolicyAttached(account: Account, policyName: String) -> Bool {
        if let policies = account.policies, let policiesDictionary = FRJSONEncoder.jsonStringToDictionary(jsonString: policies) {
            return policiesDictionary.keys.contains(policyName)
        } else {
            return false;
        }
    }
    
    
    //  MARK: - Private
    
    private func processPolicies(policiesJson: String?) -> Result {
        if let policies = policiesJson {
            self.targetedPolicies = getPoliciesToVerify(policiesJson: policies)
            
            for policy in self.targetedPolicies {
                if(!policy.evaluate()) {
                    return Result(comply: false, nonCompliancePolicy: policy)
                }
            }
        }

        return Result(comply: true, nonCompliancePolicy: nil)
    }
    
    private func getPoliciesToVerify(policiesJson: String) -> [FRAPolicy] {
        var targetedPolicies = [FRAPolicy]()

        if let policiesDictionary = FRJSONEncoder.jsonStringToDictionary(jsonString: policiesJson), let policies = self.policies {
            for policy in policies {
                if let data = policiesDictionary[policy.name] {
                    policy.data = data
                    targetedPolicies.append(policy)
                }
            }
        } else {
            FRALog.v("No policies to be verified")
        }
        
        return targetedPolicies
    }
    
    private func getPoliciesFromURI(uri: URL) -> String? {
        if let components = URLComponents(url: uri, resolvingAgainstBaseURL: false), let queryItems = components.queryItems {
            var params: [String: String] = [:]
            for item in queryItems {
                if let strVal = item.value {
                    params[item.name] = strVal
                }
            }
            
            if let policies = params["policies"], let pUrlData = policies.decodeURL(), let pUrlStr = String(data: pUrlData, encoding: .utf8) {
                return pUrlStr
            } else {
                return nil
            }
            
        } else {
            return nil
        }
    }
    
}


