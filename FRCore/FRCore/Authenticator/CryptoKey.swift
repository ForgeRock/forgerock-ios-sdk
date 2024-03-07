//
//  CryptoKey.swift
//  FRCore
//
//  Copyright (c) 2022-2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import CommonCrypto
import CryptoKit
import LocalAuthentication


///Helper struct to generate and sign the keys
public struct CryptoKey {
    private var keyId: String
    var timeout = 60
    private var keySize = 256
    private var keyType = kSecAttrKeyTypeECSECPrimeRandom
    var keyAlias: String
    private var accessGroup: String?
    
    
    /// Initializes CryptoKey with given keyId String
    /// - Parameter keyId: user id for which key pair is to be generated
    /// - Parameter accessGroup: Optional Access Group string
    public init(keyId: String, accessGroup: String? = nil) {
        self.keyId = keyId
        self.keyAlias = CryptoKey.getKeyAlias(keyName: keyId)
        if let accessGroup = accessGroup {
            var validatedAccessGroup = accessGroup
            if let appleTeamId = KeychainService.getAppleTeamId(), !accessGroup.hasPrefix(appleTeamId) {
                // If Apple TeamId prefix is found, and accessGroup provided doesn't contain, append it
                validatedAccessGroup = appleTeamId + "." + accessGroup
            }
            self.accessGroup = validatedAccessGroup
        }
    }
    
    
    /// Query attributes dictionary for generating key pair
    public func keyBuilderQuery() -> [String: Any] {
        var query = [String: Any]()
        
        query[String(kSecAttrKeyType)] = String(keyType)
        query[String(kSecAttrKeySizeInBits)] = keySize
        
        
        if let accessGroup = accessGroup {
            query[String(kSecAttrAccessGroup)] = accessGroup
        }
        
        var keyAttr = [String: Any]()
        keyAttr[String(kSecAttrIsPermanent)] = true
        keyAttr[String(kSecAttrApplicationTag)] = keyAlias
        query[String(kSecPrivateKeyAttrs)] = keyAttr
        
#if !targetEnvironment(simulator)
        query[String(kSecAttrTokenID)] = String(kSecAttrTokenIDSecureEnclave)
#endif
        
        return query
    }
    
    
    /// Creates Keypair for the given builder query attributes
    /// - Parameter builderQuery: query attributes dictionary for generating key pair
    /// - Throws: error during private/public key generation
    public func createKeyPair(builderQuery: [String: Any]) throws -> KeyPair {
        
        deleteKeys()
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(builderQuery as CFDictionary, &error) else {
            throw error?.takeRetainedValue() as? Error ?? NSError()
        }
        
        guard let publicKey: SecKey = SecKeyCopyPublicKey(privateKey) else {
            throw NSError()
        }
        
        return KeyPair(privateKey: privateKey, publicKey: publicKey, keyAlias: keyAlias)
    }
    
    
    /// Get the private key from the Keychain for given key alias
    /// - Parameter pin: password for the private key credential if applies
    /// - Parameter reason: localized reason for the authentication screen
    /// - Returns: private key for the given key alias
    public func getSecureKey(pin: String? = nil, reason: String? = nil) -> SecKey? {
        
        var query = [String: Any]()
        query[String(kSecClass)] = kSecClassKey
        query[String(kSecAttrKeyType)] = String(kSecAttrKeyTypeECSECPrimeRandom)
        query[String(kSecReturnRef)] = true
        query[String(kSecAttrApplicationTag)] = keyAlias
        
        let context = LAContext()
        if let pin = pin {
            let credentialIsSet = context.setCredential(pin.data(using: .utf8), type: .applicationPassword)
            guard credentialIsSet == true else { return nil }
            context.interactionNotAllowed = false
        }
        if let reason = reason {
            context.localizedReason = reason
        }
        //Add LAContext to the query only if any of it's parameters is set
        if pin != nil || reason != nil {
            query[kSecUseAuthenticationContext as String] = context
        }
        
        if let accessGroup = accessGroup {
            query[String(kSecAttrAccessGroup)] = accessGroup
        }
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            return nil
        }
        return (item as! SecKey)
    }
    
    
    /// Delete Keys from the Keychain
    public func deleteKeys() {
        var query = [String: Any]()
        query[String(kSecClass)] = String(kSecClassKey)
        query[String(kSecAttrApplicationTag)] = keyAlias
        if let accessGroup = accessGroup {
            query[String(kSecAttrAccessGroup)] = accessGroup
        }
        SecItemDelete(query as CFDictionary)
    }
    
    
    /// Get hash for the given key name (user id)
    /// - Parameter keyName: key names to be hashed
    /// - Returns: the hash for the given key name
    public static func getKeyAlias(keyName: String) -> String {
        let data = Data(keyName.utf8)
        if #available(iOS 13, *) {
            return Data(SHA256.hash(data: data)).base64EncodedString()
        } else {
            return data.sha256.base64EncodedString(options: NSData.Base64EncodingOptions([]))
        }
    }
}


/// Public and private keypair struct
public struct KeyPair {
    /// The Private key
    public var privateKey: SecKey
    /// The Private key
    public var publicKey: SecKey
    /// Alias for the key
    public var keyAlias: String
}
