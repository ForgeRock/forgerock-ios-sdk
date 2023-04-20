// 
//  DeviceSigningVerifierCallback.swift
//  FRDeviceBinding
//
//  Copyright (c) 2022-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import UIKit
import JOSESwift
import FRAuth

/**
 * Callback to collect the device binding information
 */
extension DeviceSigningVerifierCallback:  Binding {
    
    /// Sign the challenge with binded device key
    /// - Parameter userKeySelector: ``UserKeySelector`` implementation - default value is `DefaultUserKeySelector()`
    /// - Parameter deviceAuthenticator: method for providing a ``DeviceAuthenticator`` from ``DeviceBindingAuthenticationType`` -default value is `deviceAuthenticatorIdentifier`
    /// - Parameter completion: Completion block for Device binding result callback
    public func sign(userKeySelector: UserKeySelector = DefaultUserKeySelector(),
                   deviceAuthenticator: ((DeviceBindingAuthenticationType) -> DeviceAuthenticator)? = nil,
                   completion: @escaping DeviceSigningResultCallback) {
        
        let deviceAuthenticator = deviceAuthenticator ?? deviceAuthenticatorIdentifier
        dispatchQueue.async {
            self.execute(userKeySelector: userKeySelector, deviceAuthenticator: deviceAuthenticator, completion)
        }
    }
    
    
    /// Helper method to execute signing, show biometric prompt.
    /// - Parameter userKeyService: service to sort and fetch the keys stored in the device - default value is `UserDeviceKeyService()`
    /// - Parameter userKeySelector: ``UserKeySelector`` implementation - default value is  `DefaultUserKeySelector()`
    /// - Parameter deviceAuthenticator: method for providing a ``DeviceAuthenticator`` from ``DeviceBindingAuthenticationType`` - default value is `deviceAuthenticatorIdentifier`
    /// - Parameter completion: Completion block for Device signing result callback
    internal func execute(userKeyService: UserKeyService = UserDeviceKeyService(),
                          userKeySelector: UserKeySelector = DefaultUserKeySelector(),
                          deviceAuthenticator: ((DeviceBindingAuthenticationType) -> DeviceAuthenticator)? = nil,
                          _ completion: @escaping DeviceSigningResultCallback) {
        
        let deviceAuthenticator = deviceAuthenticator ?? deviceAuthenticatorIdentifier
        let status = userKeyService.getKeyStatus(userId: userId)
        
        switch status {
        case .singleKeyFound(key: let key):
            authenticate(userKey: key, authInterface: deviceAuthenticator(key.authType), completion)
        case .multipleKeysFound(keys: _):
            userKeySelector.selectUserKey(userKeys: userKeyService.getAll()) { key in
                if let key = key {
                    self.dispatchQueue.async {
                        self.authenticate(userKey: key, authInterface: deviceAuthenticator(key.authType), completion)
                    }
                } else {
                    self.handleException(status: .abort, completion: completion)
                }
            }
            break
        case .noKeysFound:
            handleException(status: .clientNotRegistered, completion: completion)
        }
    }
    
    
    /// Helper method to execute signing, show biometric prompt.
    /// - Parameter userKey: User Information
    /// - Parameter authInterface: Interface to find the Authentication Type
    /// - Parameter completion: Completion block for Device binding result callback
    internal func authenticate(userKey: UserKey,
                               authInterface: DeviceAuthenticator,
                               _ completion: @escaping DeviceSigningResultCallback) {
        
        authInterface.initialize(userId: userKey.userId, prompt: Prompt(title: title, subtitle: subtitle, description: promptDescription))
        guard authInterface.isSupported() else {
            handleException(status: .unsupported(errorMessage: nil), completion: completion)
            return
        }
        
        let startTime = Date()
        let timeout = timeout ?? 60
        
        do {
            // Authentication will be triggered during signing if necessary
            let jws = try authInterface.sign(userKey: userKey, challenge: challenge, expiration: getExpiration(timeout: timeout))
            
            // Check for timeout
            let delta = Date().timeIntervalSince(startTime)
            if(delta > Double(timeout)) {
                handleException(status: .timeout, completion: completion)
                return
            }
            
            // If no errors, set the input values and complete with success
            self.setJws(jws)
            
            completion(.success)
        } catch JOSESwiftError.localAuthenticationFailed {
            handleException(status: .abort, completion: completion)
        } catch let error as DeviceBindingStatus {
            handleException(status: error, completion: completion)
        } catch {
            handleException(status: .abort, completion: completion)
        }
    }
    
    
    /// Handle all the errors for the device binding.
    /// - Parameter status: Device binding status
    /// - Parameter completion: Completion block Device binding result callback
    public func handleException(status: DeviceBindingStatus, completion: @escaping DeviceSigningResultCallback) {
        setClientError(status.clientError)
        FRLog.e(status.errorMessage)
        completion(.failure(status))
    }
}
