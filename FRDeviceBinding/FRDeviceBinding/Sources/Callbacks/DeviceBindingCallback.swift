// 
//  DeviceBindingCallback.swift
//  FRDeviceBinding
//
//  Copyright (c) 2022-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import JOSESwift
import FRCore
import FRAuth

/**
 * Callback to collect the device binding information
 */
extension DeviceBindingCallback: Binding {
    
    /// Bind the device.
    /// - Parameter deviceAuthenticator: method for providing a ``DeviceAuthenticator`` from ``DeviceBindingAuthenticationType`` - defaults value is `deviceAuthenticatorIdentifier`
    /// - Parameter completion: Completion block for Device binding result callback
    public func bind(deviceAuthenticator: ((DeviceBindingAuthenticationType) -> DeviceAuthenticator)? = nil,
                   completion: @escaping DeviceBindingResultCallback) {
        
        let authInterface = deviceAuthenticator?(deviceBindingAuthenticationType) ?? deviceAuthenticatorIdentifier(deviceBindingAuthenticationType)
        let dispatchQueue = DispatchQueue(label: "com.forgerock.concurrentQueue", qos: .userInitiated)
        dispatchQueue.async {
            self.execute(authInterface: authInterface, completion)
        }
    }
    
    
    /// Helper method to execute binding , signing, show biometric prompt.
    /// - Parameter authInterface: Interface to find the Authentication Type - default value is ``getDeviceAuthenticator(type: deviceBindingAuthenticationType)``
    /// - Parameter deviceId: Interface to find the Authentication Type - default value is `FRDevice.currentDevice?.identifier.getIdentifier()`
    /// - Parameter deviceRepository: Storage for user keys - default value is ``LocalDeviceBindingRepository()``
    /// - Parameter completion: Completion block for Device binding result callback
    internal func execute(authInterface: DeviceAuthenticator? = nil,
                          deviceId: String? = nil,
                          deviceRepository: DeviceBindingRepository = LocalDeviceBindingRepository(),
                          _ completion: @escaping DeviceBindingResultCallback) {

        let authInterface = authInterface ?? getDeviceAuthenticator(type: deviceBindingAuthenticationType)
        authInterface.initialize(userId: userId, prompt: Prompt(title: title, subtitle: subtitle, description: promptDescription))
        let deviceId = deviceId ?? FRDevice.currentDevice?.identifier.getIdentifier()
        
        guard authInterface.isSupported() else {
            handleException(status: .unsupported(errorMessage: nil), completion: completion)
            return
        }
        
        let startTime = Date()
        let timeout = timeout ?? 60
        
        do {
            let keyPair = try authInterface.generateKeys()
            let userKey = UserKey(id: keyPair.keyAlias, userId: userId, userName: userName, kid: UUID().uuidString, authType: deviceBindingAuthenticationType, createdAt: Date().timeIntervalSince1970)
            try deviceRepository.persist(userKey: userKey)
            // Authentication will be triggered during signing if necessary
            let jws = try authInterface.sign(keyPair: keyPair, kid: userKey.kid, userId: userId, challenge: challenge, expiration: getExpiration(timeout: timeout))
            
            // Check for timeout
            let delta = Date().timeIntervalSince(startTime)
            if(delta > Double(timeout)) {
                authInterface.deleteKeys()
                handleException(status: .timeout, completion: completion)
                return
            }
            
            // If no errors, set the input values and complete with success
            setJws(jws)
            if let deviceId = deviceId {
                setDeviceId(deviceId)
            }
            completion(.success)
        } catch JOSESwiftError.localAuthenticationFailed {
            authInterface.deleteKeys()
            handleException(status: .abort, completion: completion)
        } catch let error as DeviceBindingStatus {
            authInterface.deleteKeys()
            handleException(status: error, completion: completion)
        } catch {
            authInterface.deleteKeys()
            handleException(status: .abort, completion: completion)
        }
    }
    
    
    /// Handle all the errors for the device binding.
    /// - Parameter status: Device binding status
    /// - Parameter completion: Completion block Device binding result callback
    public func handleException(status: DeviceBindingStatus, completion: @escaping DeviceBindingResultCallback) {
        setClientError(status.clientError)
        FRLog.e(status.errorMessage)
        completion(.failure(status))
    }
}
