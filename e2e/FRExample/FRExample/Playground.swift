//
//  Playground.swift
//  FRExample
//
//  Copyright (c) 2023 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRDeviceBinding

// MARK: - Validate code compilation

// In this section we will define some classes and methods that will test the access level of SDK classes and methods
// As we are using @testable import in our test classes, we are not able to properly test the open/public access level in our tests
// Instead, by defining some code here, we make sure we have the intended access level and nothing less
// We don't need to call this code anywhere, we want to make sure everything compiles properly

class AccessLevelValidation {
    func validateDeviceBindingCallback() {
        let deviceBindingCallback = try! DeviceBindingCallback(json: [:])
        
        let _ = deviceBindingCallback.getExpiration(timeout: 60)
        let _ = deviceBindingCallback.getDeviceAuthenticator(type: .none)
        
        // custom application pin UI
        deviceBindingCallback.bind(deviceAuthenticator: { type in
            switch type {
            case .applicationPin:
                return ApplicationPinDeviceAuthenticator(pinCollector: CustomPinCollector())
            default:
                return deviceBindingCallback.getDeviceAuthenticator(type: type)
            }
        }, completion: { result in
            switch result {
            case .success:
                print("Success")
            case .failure(let error):
                print(error.localizedDescription)
            }
        })
        
        //error handling
        deviceBindingCallback.bind() { result in
            switch result {
            case .success:
                print("Success")
            case .failure(let error):
                // Custom Error
                if error == DeviceBindingStatus.unAuthorize {
                    deviceBindingCallback.setClientError("CustomUnAuthorize")
                }
            }
        }
    }
    
    func validateDeviceSigningVerifierCallback() {
        let deviceSigningVerifierCallback = try! DeviceSigningVerifierCallback(json: [:])
        
        
        //custom key selection UI
        deviceSigningVerifierCallback.sign(userKeySelector: CustomUserKeySelector()) { result in
            switch result {
            case .success:
                print("Success")
            case .failure(let error):
                print(error.errorMessage)
            }
        }
        
        //custom claims
        deviceSigningVerifierCallback.sign(
            customClaims: [
                "platform": "iOS",
                "isCompanyPhone": true,
                "lastUpdated": Int(Date().timeIntervalSince1970)
            ]
        ) { result in
            switch result
            {
            case .success:
                print("Success")
            case .failure(let error):
                // Handle the error and proceed to the next node
                if error == .invalidCustomClaims {
                    // Fix the invalid custom claims
                    print(error.errorMessage)
                    return
                }
            }
        }
    }
    
    func validateCustomDeviceAuthenticators() {
        let customNone = CustomNone()
        let _ = customNone.notBeforeTime()
        let _ = customNone.issueTime()
        
        let customBiometricOnly = CustomBiometricOnly()
        let _ = try? customBiometricOnly.generateKeys()
        let _ = customBiometricOnly.isSupported()
        
        let customBiometricAndDeviceCredential = CustomBiometricAndDeviceCredential()
        let _ = customBiometricAndDeviceCredential.accessControl()
        
        
        let customApplicationPinDeviceAuthenticator = CustomApplicationPinDeviceAuthenticator()
        let _ = customApplicationPinDeviceAuthenticator.pinCollector
        let _ = customApplicationPinDeviceAuthenticator.validateCustomClaims([:])
        
        let _ = ApplicationPinDeviceAuthenticator(pinCollector: CustomPinCollector())
    }
}


class CustomPinCollector: PinCollector {
    func collectPin(prompt: Prompt, completion: @escaping (String?) -> Void) {
        // Implement your custom app PIN UI...
        completion("1234")
    }
}


class CustomUserKeySelector: UserKeySelector {
    func selectUserKey(userKeys: [UserKey], selectionCallback: @escaping UserKeySelectorCallback) {
        selectionCallback(userKeys.first)
    }
}


class CustomNone: None {
    override func issueTime() -> Date {
        return Date()
    }
    
    override func notBeforeTime() -> Date {
        return Date()
    }
}


class CustomBiometricAndDeviceCredential: BiometricAndDeviceCredential {
    override init() {
        super.init()
    }
    
    override func issueTime() -> Date {
        return Date()
    }
    
    override func notBeforeTime() -> Date {
        return Date()
    }
}


class CustomBiometricOnly: BiometricOnly {
    override func issueTime() -> Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    }
    
    override func notBeforeTime() -> Date {
        return Calendar.current.date(byAdding: .day, value: 2, to: Date())!
    }
}


class CustomApplicationPinDeviceAuthenticator: ApplicationPinDeviceAuthenticator {
    override init(pinCollector: PinCollector = DefaultPinCollector()) {
        super.init(pinCollector: pinCollector)
    }
    
    override func isSupported() -> Bool {
        return true
    }
    
    override func issueTime() -> Date {
        return Date()
    }
    
    override func notBeforeTime() -> Date {
        return Date()
    }
}
