// 
//  BiometricAuthentication.swift
//  FRAuthenticator
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import LocalAuthentication

struct BiometricAuthentication {
    
    /// Authenticate with biometric. Use this method to handle
    /// notification of type PushType.biometric
    /// - Parameters:
    ///   - title: the title to be displayed on the prompt.
    ///   - allowDeviceCredentials:  if true, accepts device PIN, pattern, or password to process notification.
    ///   - onSuccess: successful completion callback
    ///   - onError: failure error callback
    static func authenticate(title: String, allowDeviceCredentials: Bool, onSuccess: @escaping SuccessCallback, onError: @escaping ErrorCallback) {
        
        if allowDeviceCredentials {
            deviceOwnerAuthentication(title: title, policy: .deviceOwnerAuthentication, onSuccess: onSuccess, onError: onError)
        } else {
            deviceOwnerAuthentication(title: title, policy: .deviceOwnerAuthenticationWithBiometrics, onSuccess: onSuccess, onError: onError)
        }
    }
    
    
    /// Authenticate with biometric ONLY. Doesn't allow fallback to passcode
    /// - Parameters:
    ///   - title: the title to be displayed on the prompt.
    ///   - policy: The policy to evaluate. For possible values, see LAPolicy.
    ///   - onSuccess: successful completion callback
    ///   - onError: failure error callback
    private static func deviceOwnerAuthentication(title: String, policy: LAPolicy, onSuccess: @escaping SuccessCallback, onError: @escaping ErrorCallback) {
        
        let localAuthenticationContext = LAContext()
        var authError: NSError?
        
        if localAuthenticationContext.canEvaluatePolicy(policy, error: &authError) {
            localAuthenticationContext.evaluatePolicy(policy, localizedReason: title) { success, evaluateError in
                
                if success {
                    onSuccess()
                } else {
                    guard let error = evaluateError else {
                        FRALog.e("Biometric Authentication failed")
                        onError(MechanismError.invalidInformation("Biometric Authentication failed"))
                        return
                    }
                    FRALog.e(evaluateAuthenticationPolicyMessageForLA(errorCode: error._code))
                    onError(error)
                }
            }
        } else {
            
            guard let error = authError else {
                FRALog.e("Biometric Authentication failed")
                onError(MechanismError.invalidInformation("Biometric Authentication failed: can't evaluate policy"))
                return
            }
            FRALog.e(evaluateAuthenticationPolicyMessageForLA(errorCode: error.code))
            onError(error)
        }
    }

    
    private static func evaluatePolicyFailErrorMessageForLA(errorCode: Int) -> String {
        var message = ""
        
        if #available(iOS 11.0, macOS 10.13, *) {
            switch errorCode {
            case LAError.biometryNotAvailable.rawValue:
                message = "Authentication could not start because the device does not support biometric authentication."
            case LAError.biometryLockout.rawValue:
                message = "Authentication could not continue because the user has been locked out of biometric authentication, due to failing authentication too many times."
            case LAError.biometryNotEnrolled.rawValue:
                message = "Authentication could not start because the user has not enrolled in biometric authentication."
            default:
                message = "Did not find error code on LAError object"
            }
        } else {
            switch errorCode {
            case LAError.touchIDLockout.rawValue:
                message = "Too many failed attempts."
            case LAError.touchIDNotAvailable.rawValue:
                message = "TouchID is not available on the device"
            case LAError.touchIDNotEnrolled.rawValue:
                message = "TouchID is not enrolled on the device"
            default:
                message = "Did not find error code on LAError object"
            }
        }
        
        return message;
    }
    
    private static func evaluateAuthenticationPolicyMessageForLA(errorCode: Int) -> String {
        var message = ""
        
        switch errorCode {
        case LAError.authenticationFailed.rawValue:
            message = "The user failed to provide valid credentials"
        case LAError.appCancel.rawValue:
            message = "Authentication was cancelled by application"
        case LAError.invalidContext.rawValue:
            message = "The context is invalid"
        case LAError.notInteractive.rawValue:
            message = "Not interactive"
        case LAError.passcodeNotSet.rawValue:
            message = "Passcode is not set on the device"
        case LAError.systemCancel.rawValue:
            message = "Authentication was cancelled by the system"
        case LAError.userCancel.rawValue:
            message = "The user did cancel"
        case LAError.userFallback.rawValue:
            message = "The user chose to use the fallback"
        default:
            message = evaluatePolicyFailErrorMessageForLA(errorCode: errorCode)
        }
        
        return message
    }
}
