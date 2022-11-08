// 
//  KeyAware.swift
//  FRAuth
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import CommonCrypto
import FRCore
import CryptoKit

///Helper struct to generate and sign the keys
struct KeyAware {
    private var userId: String
    var timeout = 60
    private var keySize = 256
    private var keyType = kSecAttrKeyTypeECSECPrimeRandom
    private var key: String
    
    
    /// Initializes KeyAware with given userId String
    /// - Parameter userId: user id for which key pair is to be generated
    init(userId: String) {
        self.userId = userId
        self.key = KeyAware.getKeyAlias(keyName: userId)
    }
    
    
    /// Query attributes dictionary for generating key pair
    func keyBuilderQuery() -> [String: Any] {
        var query = [String: Any]()
        
        query[String(kSecAttrKeyType)] = String(keyType)
        query[String(kSecAttrKeySizeInBits)] = keySize
        
        var keyAttr = [String: Any]()
        keyAttr[String(kSecAttrIsPermanent)] = true
        keyAttr[String(kSecAttrApplicationTag)] = key
        query[String(kSecPrivateKeyAttrs)] = keyAttr
        
#if !targetEnvironment(simulator)
        if SecuredKey.isAvailable() {
            query[String(kSecAttrTokenID)] = String(kSecAttrTokenIDSecureEnclave)
        }
#endif
        
        return query
    }
    
    
    /// Creates Keypair for the given builder query attributes
    /// - Parameter builderQuery: query attributes dictionary for generating key pair
    /// - Throws: error during private/public key generation
    func createKeyPair(builderQuery: [String: Any]) throws -> KeyPair {
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(builderQuery as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        
        guard let publicKey: SecKey = SecKeyCopyPublicKey(privateKey) else {
            throw NSError()
        }
        
        return KeyPair(privateKey: privateKey, publicKey: publicKey, keyAlias: key)
    }
    
    
    /// Get the private key from the Keychain for given key alias
    /// - Parameter keyAlias: key alias for which to retrive the private key
    /// - Returns: private key for the given key alias
    static func getSecureKey(keyAlias: String) -> SecKey? {
        
        var query = [String: Any]()
        query[String(kSecClass)] = kSecClassKey
        query[String(kSecAttrKeyType)] = String(kSecAttrKeyTypeEC)
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
    static func deleteKey(keyAlias: String) {
        var query = [String: Any]()
        query[String(kSecClass)] = String(kSecClassKey)
        query[String(kSecAttrApplicationTag)] = keyAlias
        SecItemDelete(query as CFDictionary)
    }
    
    /// Get hash for the given key name (user id)
    /// - Parameter keyName: key names to be hashed
    /// - Returns: the hash for the given key name
    static func getKeyAlias(keyName: String) -> String {
        let data = keyName.data(using: .utf8)!
        if #available(iOS 13, *) {
            return Data(SHA256.hash(data: data)).base64EncodedString()
        } else {
            return data.sha256.base64EncodedString(options: NSData.Base64EncodingOptions([]))
        }
    }
}
