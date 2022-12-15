//
//  CryptoKey.swift
//  FRAuth
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import CommonCrypto
import CryptoKit


///Helper struct to generate and sign the keys
public struct CryptoKey {
    private var keyId: String
    var timeout = 60
    private var keySize = 256
    private var keyType = kSecAttrKeyTypeECSECPrimeRandom
    var keyAlias: String
    
    
    /// Initializes CryptoKey with given keyId String
    /// - Parameter keyId: user id for which key pair is to be generated
    public init(keyId: String) {
        self.keyId = keyId
        self.keyAlias = CryptoKey.getKeyAlias(keyName: keyId)
    }
    
    
    /// Query attributes dictionary for generating key pair
    public func keyBuilderQuery() -> [String: Any] {
        var query = [String: Any]()
        
        query[String(kSecAttrKeyType)] = String(keyType)
        query[String(kSecAttrKeySizeInBits)] = keySize
        
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
    /// - Parameter keyAlias: key alias for which to retrive the private key
    /// - Returns: private key for the given key alias
    public static func getSecureKey(keyAlias: String) -> SecKey? {
        
        var query = [String: Any]()
        query[String(kSecClass)] = kSecClassKey
        query[String(kSecAttrKeyType)] = String(kSecAttrKeyTypeECSECPrimeRandom)
        query[String(kSecReturnRef)] = true
        query[String(kSecAttrApplicationTag)] = keyAlias
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            return nil
        }
        return (item as! SecKey)
    }
    
    
    /// Remove the private key from the Keychain for given key alias
    /// - Parameter keyAlias: key alias for which to retrive the private key
    public static func deleteKey(keyAlias: String) {
        var query = [String: Any]()
        query[String(kSecClass)] = String(kSecClassKey)
        query[String(kSecAttrApplicationTag)] = keyAlias
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


///Public and private keypair struct
public struct KeyPair {
    /// The Private key
    public var privateKey: SecKey
    /// The Private key
    public var publicKey: SecKey
    /// Alias for the key
    public var keyAlias: String
}
