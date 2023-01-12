// 
//  ApplicationPinDeviceAuthenticator.swift
//  FRAuth
//
//  Copyright (c) 2022-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import UIKit
import LocalAuthentication
import FRCore
import JOSESwift


/// DeviceAuthenticator adoption for Application Pin authentication
open class ApplicationPinDeviceAuthenticator: DeviceAuthenticator, CryptoAware {
    /// prompt  for authentication promp if applicable
    var prompt: Prompt?
    /// cryptoKey for key pair generation
    var cryptoKey: CryptoKey?
    /// AppPinAuthenticator to take care of key generation
    var appPinAuthenticator: AppPinAuthenticator?
    /// ApplicationPinDeviceAuthenticatorDelegate for collection the Pin
    public var delegate: ApplicationPinDeviceAuthenticatorDelegate?
    
    init() {
        delegate = ApplicationPinDeviceAuthenticatorDefaultDelegate()
    }
    
    /// Generate public and private key pair
    open func generateKeys() throws -> KeyPair {
        
        guard let appPinAuthenticator = appPinAuthenticator, let prompt = prompt else {
            throw DeviceBindingStatus.unsupported(errorMessage: "Cannot generate keys, missing appPinAuthenticator or prompt")
        }
        
        // Use DispatchSemaphore to wait for the delegate to finish collecting the pin from the user before continuing
        let semaphore = DispatchSemaphore(value: 0)
        var pin: String? = nil
        delegate?.collectPin(prompt: prompt, completion: { collectedPin in
            pin = collectedPin
            semaphore.signal()
        })
        semaphore.wait()
        
        if let pin = pin {
            return try appPinAuthenticator.generateKeys(description: prompt.description, pin: pin)
        } else {
            throw DeviceBindingStatus.abort
        }
    }
    
    
    /// Check if authentication is supported
    open func isSupported() -> Bool {
        return true
    }
    
    
    /// Access Control for the authetication type
    open func accessControl() -> SecAccessControl? {
        return appPinAuthenticator?.accessControl()
    }
    
    
    open func type() -> DeviceBindingAuthenticationType {
        return .applicationPin
    }
    
    
    open func setKey(cryptoKey: CryptoKey) {
        self.cryptoKey = cryptoKey
        self.appPinAuthenticator = AppPinAuthenticator(cryptoKey: cryptoKey)
    }
    
    
    open func setPrompt(_ prompt: Prompt) {
        self.prompt = prompt
    }
    
    
    // Default implemention
    /// Sign the challenge sent from the server and generate signed JWT
    /// - Parameter userKey: user Information
    /// - Parameter challenge: challenge received from server
    /// - Parameter expiration: experation Date of jws
    /// - Returns: compact serialized jws
    public func sign(userKey: UserKey, challenge: String, expiration: Date) throws -> String {
        guard let prompt = prompt else {
            throw DeviceBindingStatus.unsupported(errorMessage: "Cannot retrive keys, missing prompt")
        }
        // Use DispatchSemaphore to wait for the delegate to finish collecting the pin from the user before continuing
        let semaphore = DispatchSemaphore(value: 0)
        var pin: String? = nil
        delegate?.collectPin(prompt: prompt, completion: { collectedPin in
            pin = collectedPin
            semaphore.signal()
        })
        semaphore.wait()
        
        guard let pin = pin else {
            throw DeviceBindingStatus.abort
        }
        
        guard let keyStoreKey = CryptoKey.getSecureKey(keyAlias: userKey.keyAlias, pin: pin) else {
            throw DeviceBindingStatus.unsupported(errorMessage: "Cannot read the private key")
        }
        let algorithm = SignatureAlgorithm.ES256
        
        //create header
        var header = JWSHeader(algorithm: algorithm)
        header.kid = userKey.kid
        header.typ = "JWS"
        
        //create payload
        let params: [String: Any] = ["sub": userKey.userId, "challenge": challenge, "exp": (Int(expiration.timeIntervalSince1970))]
        let message = try JSONSerialization.data(withJSONObject: params, options: [])
        let payload = Payload(message)
        
        //create signer
        guard let signer = Signer(signingAlgorithm: algorithm, key: keyStoreKey) else {
            throw DeviceBindingStatus.unsupported(errorMessage: "Cannot create a signer for jws")
        }
        
        //create jws
        let jws = try JWS(header: header, payload: payload, signer: signer)
        
        return jws.compactSerializedString
    }
}
