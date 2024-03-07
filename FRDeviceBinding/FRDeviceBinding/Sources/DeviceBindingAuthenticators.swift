//
//  DeviceBindingAuthenticators.swift
//  FRDeviceBinding
//
//  Copyright (c) 2022-2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Security
import Foundation
import FRCore
import JOSESwift
import LocalAuthentication
import FRAuth


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
    /// - Throws: `DeviceBindingStatus` if any error occurs while signing
    func sign(keyPair: KeyPair, kid: String, userId: String, challenge: String, expiration: Date) throws -> String
    
    /// Sign the challenge sent from the server and generate signed JWT
    /// - Parameter userKey: user Information
    /// - Parameter challenge: challenge received from server
    /// - Parameter expiration: experation Date of jws
    /// - Parameter customClaims: A dictionary of custom claims to be added to the jws payload
    /// - Returns: compact serialized jws
    /// - Throws: `DeviceBindingStatus` if any error occurs while signing
    func sign(userKey: UserKey, challenge: String, expiration: Date, customClaims: [String: Any]) throws -> String
    
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
    func initialize(userId: String, prompt: Prompt)
    
    /// initialize already created entity with useriD and Promp
    /// - Parameter userId: userId of the authentication
    func initialize(userId: String)
    
    /// Remove Keys
    func deleteKeys()
    
    /// Get the token signed issue time.
    func issueTime() -> Date
    
    /// Get the token not before time.
    func notBeforeTime() -> Date
    
    /// Validate custom claims
    /// - Parameter customClaims: A dictionary of custom claims to be validated
    /// - Returns: Bool value indicating whether the custom claims are valid or not
    func validateCustomClaims(_ customClaims: [String: Any]) -> Bool
}


open class DefaultDeviceAuthenticator: DeviceAuthenticator {
    /// prompt  for authentication if applicable
    var prompt: Prompt?
    
    /// Generate public and private key pair
    open func generateKeys() throws -> FRCore.KeyPair {
         throw DeviceBindingStatus.unsupported(errorMessage: "Cannot use DefaultDeviceAuthenticator. Must be subclassed")
    }
    
    /// Check if authentication is supported
    open func isSupported() -> Bool {
        return false
    }
    
    /// Access Control for the authetication type
    open func accessControl() -> SecAccessControl? {
        return nil
    }
    
    /// Get the Device Binding Authentication Type
    open func type() -> DeviceBindingAuthenticationType {
        return .none
    }
    
    /// Remove Keys
    open func deleteKeys() { }
    
    
    /// Default implemention
    /// Sign the challenge sent from the server and generate signed JWT
    /// - Parameter keyPair: Public and private key pair
    /// - Parameter kid: Generated key id
    /// - Parameter userId: user Id received from server
    /// - Parameter challenge: challenge received from server
    /// - Parameter expiration: experation Date of jws
    /// - Returns: compact serialized jws
    /// - Throws: `DeviceBindingStatus` if any error occurs while signing
    open func sign(keyPair: KeyPair, kid: String, userId: String, challenge: String, expiration: Date) throws -> String {
        
        let jwk = try ECPublicKey(publicKey: keyPair.publicKey, additionalParameters: [JWKParameter.keyUse.rawValue: DBConstants.sig, JWKParameter.algorithm.rawValue: DBConstants.ES256, JWKParameter.keyIdentifier.rawValue: kid])
        let algorithm = SignatureAlgorithm.ES256
        
        //create header
        var header = JWSHeader(algorithm: algorithm)
        header.kid = kid
        header.typ = DBConstants.JWS
        header.jwkTyped = jwk
        
        //create payload
        var params: [String: Any] = [DBConstants.sub: userId, DBConstants.challenge: challenge, DBConstants.exp: (Int(expiration.timeIntervalSince1970)), DBConstants.platform : DBConstants.ios, DBConstants.iat: (Int(issueTime().timeIntervalSince1970)), DBConstants.nbf: (Int(notBeforeTime().timeIntervalSince1970))]
        
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            throw DeviceBindingStatus.unsupported(errorMessage: "Bundle Identifier is missing")
        }
        params[DBConstants.iss] = bundleIdentifier
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
    /// - Parameter customClaims: A dictionary of custom claims to be added to the jws payload
    /// - Returns: compact serialized jws
    /// - Throws: `DeviceBindingStatus` if any error occurs while signing
    open func sign(userKey: UserKey, challenge: String, expiration: Date, customClaims: [String: Any] = [:]) throws -> String {
        
        let cryptoKey = CryptoKey(keyId: userKey.userId, accessGroup: FRAuth.shared?.options?.keychainAccessGroup)
        guard let keyStoreKey = cryptoKey.getSecureKey(reason: prompt?.description) else {
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
        let jws = try JWS(header: header, payload: payload, signer: signer)
        
        return jws.compactSerializedString
    }
    
    
    
    /// Set the Authentication Prompt
    open func setPrompt(_ prompt: Prompt) {
        //Do Nothing
    }
    
    
    /// initialize already created entity with useriD and Promp
    /// - Parameter userId: userId of the authentication
    /// - Parameter prompt: Prompt containing the description for authentication
    open func initialize(userId: String, prompt: Prompt) {
        
        setPrompt(prompt)
        initialize(userId: userId)
    }
    
    
    /// initialize already created entity with useriD and Promp
    /// - Parameter userId: userId of the authentication
    open func initialize(userId: String) {
        
        if let cryptoAware = self as? CryptoAware {
            cryptoAware.setKey(cryptoKey: CryptoKey(keyId: userId, accessGroup: FRAuth.shared?.options?.keychainAccessGroup))
        }
    }
    
    
    /// Get the token signed issue time.
    open func issueTime() -> Date {
        return Date()
    }

    
    /// Get the token not before time.
    open func notBeforeTime() -> Date {
        return Date()
    }
    
    /// Validate custom claims
    /// - Parameter customClaims: A dictionary of custom claims to be validated
    /// - Returns: Bool value indicating whether the custom claims are valid or not
    open func validateCustomClaims(_ customClaims: [String: Any]) -> Bool {
        let registeredKeys = [DBConstants.sub,
                              DBConstants.challenge,
                              DBConstants.exp,
                              DBConstants.iat,
                              DBConstants.nbf,
                              DBConstants.iss]
        return customClaims.keys.filter { registeredKeys.contains($0) }.isEmpty
    }
}


open class BiometricAuthenticator: DefaultDeviceAuthenticator, CryptoAware {
    
    /// cryptoKey for key pair generation
    var cryptoKey: CryptoKey?
    
    
    open func setKey(cryptoKey: CryptoKey) {
        self.cryptoKey = cryptoKey
    }
    
    
    open override func setPrompt(_ prompt: Prompt) {
        self.prompt = prompt
    }
    
    /// Remove keys
    open override func deleteKeys() {
        cryptoKey?.deleteKeys()
    }
    
}


/// DeviceAuthenticator adoption for biometric only authentication
open class BiometricOnly: BiometricAuthenticator {
    /// local authentication policy for authentication
    var policy: LAPolicy
    
    
    /// Initializes BiometricOnly with the right LAPolicy
    public override init() {
        policy = .deviceOwnerAuthenticationWithBiometrics
    }
    
    
    /// Generate public and private key pair
    open override func generateKeys() throws -> KeyPair {
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
    open override func isSupported() -> Bool {
        let laContext = LAContext()
        var evalError: NSError?
        return laContext.canEvaluatePolicy(policy, error: &evalError)
    }
    
    
    /// Access Control for the authetication type
    open override func accessControl() -> SecAccessControl? {
#if !targetEnvironment(simulator)
        return SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, [.biometryCurrentSet, .privateKeyUsage], nil)
#else
        return SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, [.biometryCurrentSet], nil)
#endif
    }
    
    
    open override func type() -> DeviceBindingAuthenticationType {
        return .biometricOnly
    }
}


/// DeviceAuthenticator adoption for biometric and Device Credential authentication
open class BiometricAndDeviceCredential: BiometricAuthenticator {
    /// local authentication policy for authentication
    var policy: LAPolicy
    
    
    /// Initializes BiometricOnly with the rightLAPolicy
    public override init() {
        policy = .deviceOwnerAuthentication
    }
    
    
    /// Generate public and private key pair
    open override func generateKeys() throws -> KeyPair {
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
    open override func isSupported() -> Bool {
        let laContext = LAContext()
        var evalError: NSError?
        return laContext.canEvaluatePolicy(policy, error: &evalError)
    }
    
    
    /// Access Control for the authetication type
    open override func accessControl() -> SecAccessControl? {
#if !targetEnvironment(simulator)
        return SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, [.userPresence, .privateKeyUsage], nil)
#else
        return SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, [.userPresence], nil)
#endif
    }
    
    
    open override func type() -> DeviceBindingAuthenticationType {
        return .biometricAllowFallback
    }
}


open class None: DefaultDeviceAuthenticator, CryptoAware {
    
    /// cryptoKey for key pair generation
    var cryptoKey: CryptoKey?
    
    public override init() { }
    
    /// Generate public and private key pair
    open override func generateKeys() throws -> KeyPair {
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
    open override func isSupported() -> Bool {
        return true
    }
    
    
    /// Access Control for the authetication type
    open override func accessControl() -> SecAccessControl? {
        return nil
    }
    
    
    open override func type() -> DeviceBindingAuthenticationType {
        return .none
    }
    
    
    open func setKey(cryptoKey: CryptoKey) {
        self.cryptoKey = cryptoKey
    }
    
    
    open override func deleteKeys() {
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
    
    /// Memberwise initializer
    /// - Parameters:
    ///   - title: title for the prompt
    ///   - subtitle: subtitle for the promp
    ///   - description: description for the prompt
    public init(title: String, subtitle: String, description: String) {
        self.title = title
        self.subtitle = subtitle
        self.description = description
    }
}

//  MARK: - Device Binding Constants
struct DBConstants {
    static let sig: String = "sig"
    static let alg: String = "alg"
    static let ES256: String = "ES256"
    static let JWS: String = "JWS"
    static let sub: String = "sub"
    static let challenge: String = "challenge"
    static let exp: String = "exp"
    static let platform: String = "platform"
    static let ios: String = "ios"
    static let iss: String = "iss"
    static let iat: String = "iat"
    static let nbf: String = "nbf"
}
