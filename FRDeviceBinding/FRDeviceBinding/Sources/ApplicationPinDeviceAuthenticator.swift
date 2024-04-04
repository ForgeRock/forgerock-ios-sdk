// 
//  ApplicationPinDeviceAuthenticator.swift
//  FRDeviceBinding
//
//  Copyright (c) 2022-2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import UIKit
import LocalAuthentication
import FRCore
import JOSESwift


/// DeviceAuthenticator adoption for Application Pin authentication
open class ApplicationPinDeviceAuthenticator: DefaultDeviceAuthenticator, CryptoAware {
    /// cryptoKey for key pair generation
    var cryptoKey: CryptoKey?
    /// AppPinAuthenticator to take care of key generation
    var appPinAuthenticator: AppPinAuthenticator?
    /// PinCollector for collecting the Pin
    public var pinCollector: PinCollector
    
    public init(pinCollector: PinCollector = DefaultPinCollector()) {
        self.pinCollector = pinCollector
    }
    
    /// Generate public and private key pair
    open override func generateKeys() throws -> KeyPair {
        guard let appPinAuthenticator = appPinAuthenticator, let prompt = prompt else {
            throw DeviceBindingStatus.unsupported(errorMessage: "Cannot generate keys, missing appPinAuthenticator or prompt")
        }
       
        if let pin = collectPin(prompt: prompt) {
            do {
                return try appPinAuthenticator.generateKeys(description: prompt.description, pin: pin)
            } catch {
                throw DeviceBindingStatus.unsupported(errorMessage: nil)
            }
        } else {
            throw DeviceBindingStatus.abort
        }
    }
    
    
    /// Check if authentication is supported
    open override func isSupported() -> Bool {
        return true
    }
    
    
    /// Access Control for the authetication type
    open override func accessControl() -> SecAccessControl? {
        return appPinAuthenticator?.accessControl()
    }
    
    
    open override func type() -> DeviceBindingAuthenticationType {
        return .applicationPin
    }
    
    
    open func setKey(cryptoKey: CryptoKey) {
        self.cryptoKey = cryptoKey
        self.appPinAuthenticator = AppPinAuthenticator(cryptoKey: cryptoKey)
    }
    
    
    open override func setPrompt(_ prompt: Prompt) {
        self.prompt = prompt
    }
    
    
    public override func deleteKeys() {
        cryptoKey?.deleteKeys()
    }
    
    
    // Default implemention
    /// Sign the challenge sent from the server and generate signed JWT
    /// - Parameter userKey: user Information
    /// - Parameter challenge: challenge received from server
    /// - Parameter expiration: experation Date of jws
    /// - Parameter customClaims: A dictionary of custom claims to be added to the jws payload
    /// - Returns: compact serialized jws
    /// - Throws: `DeviceBindingStatus` if any error occurs while signing
    public override func sign(userKey: UserKey, challenge: String, expiration: Date, customClaims: [String: Any] = [:]) throws -> String {
        guard let prompt = prompt else {
            throw DeviceBindingStatus.unsupported(errorMessage: "Cannot retrive keys, missing prompt")
        }
        
        guard let pin = collectPin(prompt: prompt) else {
            throw DeviceBindingStatus.abort
        }
        
        guard let keyStoreKey = cryptoKey?.getSecureKey(pin: pin) else {
            throw DeviceBindingStatus.clientNotRegistered
        }
        let algorithm = SignatureAlgorithm.ES256
        
        //create header
        var header = JWSHeader(algorithm: algorithm)
        header.kid = userKey.kid
        header.typ = DBConstants.JWS
        
        //create payload
        var params: [String: Any] = [DBConstants.sub: userKey.userId, DBConstants.challenge: challenge, DBConstants.exp: (Int(expiration.timeIntervalSince1970)), DBConstants.iat: (Int(issueTime().timeIntervalSince1970)), DBConstants.nbf: (Int(notBeforeTime().timeIntervalSince1970))].merging(customClaims) { (current, _) in current }
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            throw DeviceBindingStatus.unsupported(errorMessage: "Bundle Identifier is missing")
        }
        params[DBConstants.iss] = bundleIdentifier
        let message = try JSONSerialization.data(withJSONObject: params, options: [])
        let payload = Payload(message)
        
        //create signer
        guard let signer = Signer(signingAlgorithm: algorithm, key: keyStoreKey) else {
            throw DeviceBindingStatus.unsupported(errorMessage: "Cannot create a signer for jws")
        }
        
        //create jws
        // Even if the provided pin is wrong, the system still returns the key above in the CryptoKey.getSecureKey call.
        // However it fails during signing. So we catch the invalid credentials error only during signing
        do {
            let jws = try JWS(header: header, payload: payload, signer: signer)
            return jws.compactSerializedString
        } catch {
            throw DeviceBindingStatus.unAuthorize
        }
    }
    
    
    func collectPin(prompt: Prompt) -> String? {
        // Use DispatchGroup to wait for pinCollector to finish collecting the pin before continuing
        let group = DispatchGroup()
        var pin: String?
        
        group.enter()
        pinCollector.collectPin(prompt: prompt, completion: { collectedPin in
            pin = collectedPin
            group.leave()
        })
        
        group.wait()
        return pin
    }
}
