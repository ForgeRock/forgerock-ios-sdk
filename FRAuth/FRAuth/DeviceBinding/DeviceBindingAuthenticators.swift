//
//  DeviceBindingAuthenticators.swift
//  FRAuth
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
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
    
    /// Check if authentication is supported
    func isSupported() -> Bool
    
    /// Access Control for the authetication type
    func accessControl() -> SecAccessControl?
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
    func sign(keyPair: KeyPair, kid: String, userId: String, challenge: String, expiration: Date) throws -> String {
        let jwk = try ECPublicKey(publicKey: keyPair.publicKey, additionalParameters: ["use": "sig", "alg": "ES256"])
        let jwkWithKeyId = try jwk.withThumbprintAsKeyId()
        let algorithm = SignatureAlgorithm.ES256
        
        //create header
        var header = JWSHeader(algorithm: algorithm)
        header.kid = kid
        header.typ = "JWS"
        header.jwkTyped = jwkWithKeyId
        
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
    
}


/// DeviceAuthenticator adoption for biometric only authentication
internal struct BiometricOnly: DeviceAuthenticator {
    /// prompt description for authentication promp if applicable
    var promptDescription: String
    /// local authentication policy for authentication
    var policy: LAPolicy
    /// keyAware for key pair generation
    var keyAware: KeyAware
    
    
    /// Initializes BiometricOnly with given BiometricHandler and KeyAware
    /// - Parameter biometricInterface: biometric handler for authentication
    /// - Parameter keyAware: keyAware for key pair generation
    init(description: String, keyAware: KeyAware) {
        self.promptDescription = description
        self.keyAware = keyAware
        policy = .deviceOwnerAuthenticationWithBiometrics
    }
    
    
    /// Generate public and private key pair
    func generateKeys() throws -> KeyPair {
        var keyBuilderQuery = keyAware.keyBuilderQuery()
        keyBuilderQuery[String(kSecAttrAccessControl)] = accessControl()
        
#if !targetEnvironment(simulator)
        let context = LAContext()
        context.localizedReason = promptDescription
        keyBuilderQuery[String(kSecUseAuthenticationContext)] = context
#endif
        
        return try keyAware.createKeyPair(builderQuery: keyBuilderQuery)
    }
    
    
    /// Check if authentication is supported
    func isSupported() -> Bool {
        let laContext = LAContext()
        var evalError: NSError?
        return laContext.canEvaluatePolicy(policy, error: &evalError)
    }
    
    
    /// Access Control for the authetication type
    func accessControl() -> SecAccessControl? {
#if !targetEnvironment(simulator)
        return SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, [.biometryCurrentSet, .privateKeyUsage], nil)
#else
        return SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, [.biometryCurrentSet], nil)
#endif
    }
}


/// DeviceAuthenticator adoption for biometric and Device Credential authentication
internal struct BiometricAndDeviceCredential: DeviceAuthenticator {
    /// prompt description for authentication promp if applicable
    var promptDescription: String
    /// local authentication policy for authentication
    var policy: LAPolicy
    /// keyAware for key pair generation
    var keyAware: KeyAware
    
    
    /// Initializes BiometricOnly with given BiometricHandler and KeyAware
    /// - Parameter biometricInterface: biometric handler for authentication
    /// - Parameter keyAware: keyAware for key pair generation
    init(description: String, keyAware: KeyAware) {
        self.promptDescription = description
        self.keyAware = keyAware
        policy = .deviceOwnerAuthentication
    }
    
    
    /// Generate public and private key pair
    func generateKeys() throws -> KeyPair {
        var keyBuilderQuery = keyAware.keyBuilderQuery()
        keyBuilderQuery[String(kSecAttrAccessControl)] = accessControl()
        
#if !targetEnvironment(simulator)
        let context = LAContext()
        context.localizedReason = promptDescription
        keyBuilderQuery[String(kSecUseAuthenticationContext)] = context
#endif
        
        return try keyAware.createKeyPair(builderQuery: keyBuilderQuery)
    }
    
    
    /// Check if authentication is supported
    func isSupported() -> Bool {
        let laContext = LAContext()
        var evalError: NSError?
        return laContext.canEvaluatePolicy(policy, error: &evalError)
    }
    
    
    /// Access Control for the authetication type
    func accessControl() -> SecAccessControl? {
#if !targetEnvironment(simulator)
        return SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, [.userPresence, .privateKeyUsage], nil)
#else
        return SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, [.userPresence], nil)
#endif
    }
}


internal struct None: DeviceAuthenticator {
    
    /// keyAware for key pair generation
    var keyAware: KeyAware
    
    
    /// Initializes BiometricOnly with given BiometricHandler and KeyAware
    /// - Parameter keyAware: keyAware for key pair generation
    init(keyAware: KeyAware) {
        self.keyAware = keyAware
    }
    
    
    /// Generate public and private key pair
    func generateKeys() throws -> KeyPair {
        let keyBuilderQuery = keyAware.keyBuilderQuery()
        return try keyAware.createKeyPair(builderQuery: keyBuilderQuery)
    }
    
    
    /// Check if authentication is supported
    func isSupported() -> Bool {
        return true
    }
    
    
    /// Access Control for the authetication type
    func accessControl() -> SecAccessControl? {
        return nil
    }
}


///Public and private keypair struct
public struct KeyPair {
    /// The Private key
    var privateKey: SecKey
    /// The Private key
    var publicKey: SecKey
    /// Alias for the key
    var keyAlias: String
}


/// AuthenticatorFactory to create the authentication type.
internal struct AuthenticatorFactory {
    
    /// Static method to create and return the correct type of authenticator
    static func getAuthenticator(userId: String,
                                 authentication: DeviceBindingAuthenticationType,
                                 title: String,
                                 subtitle: String,
                                 description: String,
                                 keyAware: KeyAware?) -> DeviceAuthenticator {
        let newKeyAware = keyAware ?? KeyAware(userId: userId)
        switch authentication {
        case .biometricOnly:
            return BiometricOnly(description: description, keyAware: newKeyAware)
        case .biometricAllowFallback:
            return BiometricAndDeviceCredential(description: description, keyAware: newKeyAware)
        case .none:
            return None(keyAware: newKeyAware)
            
        }
    }
}
