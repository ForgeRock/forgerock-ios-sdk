// 
//  BiometricBindingHandler.swift
//  FRAuth
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import LocalAuthentication

/// Protocol to display biometric and verify the device supported for biometric
protocol BiometricHandler {
    
    /// Check support for the authentication type
    /// - Parameter policy: Local authentication policy to be evaluated
    /// - Returns: Boolean status for policy support
    func isSupported(policy: LAPolicy) -> Bool
    
    /// Display biometric prompt for Biometric and device credential if needed
    /// - Parameter timeout: Timeout for the biometric prompt
    /// - Parameter completion: Completion block for Device binding result callback
    func authenticate(timeout: Int, completion: @escaping DeviceBindingResultCallback)
}


/// Helper struct for managing Biometric configuration.
internal struct BiometricBindingHandler: BiometricHandler {
    
    /// title for authentication promp if applicable
    var title: String
    /// subtitile for authentication promp if applicable
    var subtitle: String
    /// prompt description for authentication promp if applicable
    var promptDescription: String
    /// local authentication policy for authentication
    var policy: LAPolicy
    
    
    /// Check support for the authentication type
    /// - Parameter policy: Local authentication policy to be evaluated
    /// - Returns: Boolean status for policy support
    func isSupported(policy: LAPolicy) -> Bool {
        let laContext = LAContext()
        var evalError: NSError?
        return laContext.canEvaluatePolicy(policy, error: &evalError)
    }
    
    
    /// Display biometric prompt for Biometric and device credential if needed
    /// - Parameter timeout: Timeout for the biometric prompt
    /// - Parameter completion: Completion block for Device binding result callback
    func authenticate(timeout: Int, completion: @escaping DeviceBindingResultCallback) {
        let localAuthenticationContext = LAContext()
        var authError: NSError?
        let startTime = Date()
        if localAuthenticationContext.canEvaluatePolicy(policy, error: &authError) {
            localAuthenticationContext.evaluatePolicy(policy, localizedReason: promptDescription) { success, evaluateError in
                if success {
                    let delta = Date().timeIntervalSince(startTime)
                    if(delta > Double(timeout)) {
                        completion(.failure(.timeout))
                    } else {
                        completion(.success)
                    }
                } else {
                    completion(.failure(.abort))
                }
            }
        } else {
            guard let error = authError else {
                completion(.failure(.unsupported(errorMessage: nil)))
                return
            }
            completion(.failure(.unsupported(errorMessage: error.localizedDescription)))
        }
    }
    
    
    /// Initializes BiometricBindingHandler with given title, subtitle, promptDescription
    /// - Parameter title: title for authentication promp if applicable
    /// - Parameter subtitle: subtitile for authentication promp if applicable
    /// - Parameter promptDescription: prompt description for authentication promp if applicable
    /// - Parameter policy: local authentication policy for authentication
    init(title: String, subtitle: String, description: String, policy: LAPolicy) {
        self.title = title
        self.subtitle = subtitle
        self.promptDescription = description
        self.policy = policy
    }
}
