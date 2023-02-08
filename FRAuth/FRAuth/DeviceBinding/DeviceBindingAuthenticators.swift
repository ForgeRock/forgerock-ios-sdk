//
//  DeviceBindingAuthenticators.swift
//  FRAuth
//
//  Copyright (c) 2022-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Security
import Foundation
import FRCore
import JOSESwift
import LocalAuthentication


/// Protocol to override keypair generation, authentication, signing and access control
public protocol DeviceAuthenticator {
    
    /// Generate public and private key pair
    func generateKeys() throws -> KeyPair
    
    /// Sign the challenge sent from the server and generate signed JWT
    /// - Parameter keyPair: Public and private key pair
    /// - Parameter kid: Generated key id
    /// - Parameter userId: user Id received from server
    /// - Parameter challenge: challenge received from server
    /// - Parameter expiration: experation Date of jws
    /// - Returns: compact serialized jws
    func sign(keyPair: KeyPair, kid: String, userId: String, challenge: String, expiration: Date) throws -> String
    
    /// Sign the challenge sent from the server and generate signed JWT
    /// - Parameter userKey: user Information
    /// - Parameter challenge: challenge received from server
    /// - Parameter expiration: experation Date of jws
    /// - Returns: compact serialized jws
    func sign(userKey: UserKey, challenge: String, expiration: Date) throws -> String
    
    /// Check if authentication is supported
    func isSupported() -> Bool
    
    /// Access Control for the authetication type
    func accessControl() -> SecAccessControl?
    
    /// Set the Authentication Prompt
    func setPrompt(_ prompt: Prompt)
    
    /// Get the Device Binding Authentication Type
    func type() -> DeviceBindingAuthenticationType
    
    /// initialize already created entity with useriD and Promp
    /// - Parameter userId: userId of the authentication
    /// - Parameter prompt: Prompt containing the description for authentication
    func initialize(userId: String, prompt: Prompt) -> DeviceAuthenticator 
    
    
    /// initialize already created entity with useriD and Promp
    /// - Parameter userId: userId of the authentication
    func initialize(userId: String) -> DeviceAuthenticator
    
    
    /// Remove Keys
    func deleteKeys()
}


extension DeviceAuthenticator {
    
    /// Default implemention
    /// Sign the challenge sent from the server and generate signed JWT
    /// - Parameter keyPair: Public and private key pair
    /// - Parameter kid: Generated key id
    /// - Parameter userId: user Id received from server
    /// - Parameter challenge: challenge received from server
    /// - Parameter expiration: experation Date of jws
    /// - Returns: compact serialized jws
    public func sign(keyPair: KeyPair, kid: String, userId: String, challenge: String, expiration: Date) throws -> String {
        let jwk = try ECPublicKey(publicKey: keyPair.publicKey, additionalParameters: [JWKParameter.keyUse.rawValue: "sig", JWKParameter.algorithm.rawValue: "ES256", JWKParameter.keyIdentifier.rawValue: kid])
        let algorithm = SignatureAlgorithm.ES256
        
        //create header
        var header = JWSHeader(algorithm: algorithm)
        header.kid = kid
        header.typ = "JWS"
        header.jwkTyped = jwk
        
        //create payload
        let params: [String: Any] = ["sub": userId, "challenge": challenge, "exp": (Int(expiration.timeIntervalSince1970))]
        let message = try JSONSerialization.data(withJSONObject: params, options: [])
        let payload = Payload(message)
        
        //create signer
        guard let signer = Signer(signingAlgorithm: algorithm, key: keyPair.privateKey) else {
            throw DeviceBindingStatus.unsupported(errorMessage: "Cannot create a signer for jws")
        }
        
        //create jws
        let jws = try JWS(header: header, payload: payload, signer: signer)
        
        return jws.compactSerializedString
    }
    
    
    // Default implemention
    /// Sign the challenge sent from the server and generate signed JWT
    /// - Parameter userKey: user Information
    /// - Parameter challenge: challenge received from server
    /// - Parameter expiration: experation Date of jws
    /// - Returns: compact serialized jws
    public func sign(userKey: UserKey, challenge: String, expiration: Date) throws -> String {
        guard let keyStoreKey = CryptoKey.getSecureKey(keyAlias: userKey.keyAlias) else {
            throw DeviceBindingStatus.unRegister
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
    
    
    
    /// Set the Authentication Prompt
    public func setPrompt(_ prompt: Prompt) {
        //Do Nothing
    }
    
    
    /// initialize already created entity with useriD and Promp
    /// - Parameter userId: userId of the authentication
    /// - Parameter prompt: Prompt containing the description for authentication
    public func initialize(userId: String, prompt: Prompt) -> DeviceAuthenticator {
        
        self.setPrompt(prompt)
        return initialize(userId: userId)
    }
    
    
    /// initialize already created entity with useriD and Promp
    /// - Parameter userId: userId of the authentication
    public func initialize(userId: String) -> DeviceAuthenticator {
        
        if let cryptoAware = self as? CryptoAware {
            cryptoAware.setKey(cryptoKey: CryptoKey(keyId: userId))
        }
        
        return self
    }
}


open class BiometricAuthenticator: CryptoAware {
    
    /// prompt  for authentication promp if applicable
    var prompt: Prompt?
    /// cryptoKey for key pair generation
    var cryptoKey: CryptoKey?
    
    
    open func setKey(cryptoKey: CryptoKey) {
        self.cryptoKey = cryptoKey
    }
    
    
    open func setPrompt(_ prompt: Prompt) {
        self.prompt = prompt
    }
    
    /// Remove keys
    open func deleteKeys() {
        cryptoKey?.deleteKeys()
    }
}


/// DeviceAuthenticator adoption for biometric only authentication
open class BiometricOnly: BiometricAuthenticator, DeviceAuthenticator {
    /// local authentication policy for authentication
    var policy: LAPolicy
    
    
    /// Initializes BiometricOnly with the right LAPolicy
    override init() {
        policy = .deviceOwnerAuthenticationWithBiometrics
    }
    
    
    /// Generate public and private key pair
    open func generateKeys() throws -> KeyPair {
        guard let cryptoKey = cryptoKey, let prompt = prompt else {
            throw DeviceBindingStatus.unsupported(errorMessage: "Cannot generate keys, missing cryptoKey or prompt")
        }
        
        var keyBuilderQuery = cryptoKey.keyBuilderQuery()
        keyBuilderQuery[String(kSecAttrAccessControl)] = accessControl()
        
#if !targetEnvironment(simulator)
        let context = LAContext()
        context.localizedReason = prompt.description
        keyBuilderQuery[String(kSecUseAuthenticationContext)] = context
#endif
        do {
            return try cryptoKey.createKeyPair(builderQuery: keyBuilderQuery)
        } catch {
            throw DeviceBindingStatus.unsupported(errorMessage: nil)
        }
    }
    
    
    /// Check if authentication is supported
    open func isSupported() -> Bool {
        let laContext = LAContext()
        var evalError: NSError?
        return laContext.canEvaluatePolicy(policy, error: &evalError)
    }
    
    
    /// Access Control for the authetication type
    open func accessControl() -> SecAccessControl? {
#if !targetEnvironment(simulator)
        return SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, [.biometryCurrentSet, .privateKeyUsage], nil)
#else
        return SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, [.biometryCurrentSet], nil)
#endif
    }
    
    
    open func type() -> DeviceBindingAuthenticationType {
        return .biometricOnly
    }
}


/// DeviceAuthenticator adoption for biometric and Device Credential authentication
open class BiometricAndDeviceCredential: BiometricAuthenticator, DeviceAuthenticator {
    /// local authentication policy for authentication
    var policy: LAPolicy
    
    
    /// Initializes BiometricOnly with the rightLAPolicy
    override init() {
        policy = .deviceOwnerAuthentication
    }
    
    
    /// Generate public and private key pair
    open func generateKeys() throws -> KeyPair {
        guard let cryptoKey = cryptoKey, let prompt = prompt else {
            throw DeviceBindingStatus.unsupported(errorMessage: "Cannot generate keys, missing cryptoKey or prompt")
        }
        
        var keyBuilderQuery = cryptoKey.keyBuilderQuery()
        keyBuilderQuery[String(kSecAttrAccessControl)] = accessControl()
        
#if !targetEnvironment(simulator)
        let context = LAContext()
        context.localizedReason = prompt.description
        keyBuilderQuery[String(kSecUseAuthenticationContext)] = context
#endif
        
        do {
            return try cryptoKey.createKeyPair(builderQuery: keyBuilderQuery)
        } catch {
            throw DeviceBindingStatus.unsupported(errorMessage: nil)
        }
    }
    
    
    /// Check if authentication is supported
    open func isSupported() -> Bool {
        let laContext = LAContext()
        var evalError: NSError?
        return laContext.canEvaluatePolicy(policy, error: &evalError)
    }
    
    
    /// Access Control for the authetication type
    open func accessControl() -> SecAccessControl? {
#if !targetEnvironment(simulator)
        return SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, [.userPresence, .privateKeyUsage], nil)
#else
        return SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, [.userPresence], nil)
#endif
    }
    
    
    open func type() -> DeviceBindingAuthenticationType {
        return .biometricAllowFallback
    }
}


open class None: DeviceAuthenticator, CryptoAware {
    
    /// cryptoKey for key pair generation
    var cryptoKey: CryptoKey?
    
    /// Generate public and private key pair
    open func generateKeys() throws -> KeyPair {
        guard let cryptoKey = cryptoKey else {
            throw DeviceBindingStatus.unsupported(errorMessage: "Cannot generate keys, missing cryptoKey")
        }
        
        let keyBuilderQuery = cryptoKey.keyBuilderQuery()
        do {
            return try cryptoKey.createKeyPair(builderQuery: keyBuilderQuery)
        } catch {
            throw DeviceBindingStatus.unsupported(errorMessage: nil)
        }
    }
    
    
    /// Check if authentication is supported
    open func isSupported() -> Bool {
        return true
    }
    
    
    /// Access Control for the authetication type
    open func accessControl() -> SecAccessControl? {
        return nil
    }
    
    
    open func type() -> DeviceBindingAuthenticationType {
        return .none
    }
    
    
    open func setKey(cryptoKey: CryptoKey) {
        self.cryptoKey = cryptoKey
    }
    
    
    open func deleteKeys() {
        cryptoKey?.deleteKeys()
    }
}


/// Convert authentication type string received from server to authentication type enum
public enum DeviceBindingAuthenticationType: String, Codable {
    case biometricOnly = "BIOMETRIC_ONLY"
    case biometricAllowFallback = "BIOMETRIC_ALLOW_FALLBACK"
    case applicationPin = "APPLICATION_PIN"
    case none = "NONE"
    
    /// get the right type of DeviceAuthenticator
    func getAuthType() -> DeviceAuthenticator {
        switch self {
        case .biometricOnly:
            return BiometricOnly()
        case .biometricAllowFallback:
            return BiometricAndDeviceCredential()
        case .applicationPin:
            return ApplicationPinDeviceAuthenticator()
        case .none:
            return None()
        }
    }
}


public struct Prompt {
    var title: String
    var subtitle: String
    var description: String
}
