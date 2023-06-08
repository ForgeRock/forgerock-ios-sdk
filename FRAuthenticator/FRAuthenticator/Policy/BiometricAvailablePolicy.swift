// 
//  BiometricAvailablePolicy.swift
//  FRAuthenticator
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import LocalAuthentication

/// The Biometric Available policy checks if the device has enabled Biometric capabilities.
///
/// JSON Policy format:
/// {"biometricAvailable": { }}
public class BiometricAvailablePolicy: FRAPolicy {
    
    public var name: String = "biometricAvailable"
    
    public var data: Any?
    
    public func evaluate() -> Bool {
        return LAContext().biometricAvailable
    }
    
}

extension LAContext {
    var biometricAvailable: Bool {
        var error: NSError?

        guard self.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return biometricResult(result: false)
        }

        switch self.biometryType {
        case .none:
            return biometricResult(result: false)
        case .touchID, .faceID:
            return biometricResult(result: true)
        @unknown default:
            return biometricResult(result: false)
        }
    }
    
    private func biometricResult(result: Bool) -> Bool {
        result ? FRALog.v("Biometric Available Policy passed: device registered with TouchID/FaceID.")
               : FRALog.v("Biometric Available Policy fail: device not registered with TouchID/FaceID.")
        return result
    }
}
