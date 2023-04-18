//
//  FRDeviceIdentifier.swift
//  FRAuth
//
//  Copyright (c) 2019-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import CommonCrypto
import FRCore

/// FRDeviceIdentifier provides a unique identifier for each device defined in same Shared Keychain Access Group,
/// and provides a secure mechanism to uniquely generate, persist, and manage the identifier
public struct FRDeviceIdentifier {
    
    /// RSA Key types enumeration
    ///
    /// - privateKey: Private Key for RSA Key Pair
    /// - publicKey: Public Key for RSA Key Pair
    enum FRDeviceIdentifierKeyType {
        case privateKey
        case publicKey
    }
    /// Constant Public Key tag
    let publicKeyTag = "com.forgerock.ios.device-identifier.public-key".data(using: .utf8)!
    /// Constant Private Key tag
    let privateKeyTag = "com.forgerock.ios.device-identifier.private-key".data(using: .utf8)!
    /// Constant Key Pair type
    let keychainKeyType = kSecAttrKeyTypeRSA
    /// Constant RSA Key Pair size
    let keychainKeySize = 2048
    /// KeychainService instance to persist, and manage generated identifier
    var keychainService: KeychainService
    /// Constant Key for Public Key in KeychainService
    let publicKeyDataKeychainServiceKey = "com.forgerock.ios.device-identifier.pubic-key.data"
    /// Constant Key for Private Key in KeychainService
    let privateKeyDataKeychainServiceKey = "com.forgerock.ios.device-identifier.private-key.data"
    /// Constant Key for Identifier in KeychainService
    let identifierKeychainServiceKey = "com.forgerock.ios.device-identifier.hash-base64-string-identifier"
    
    /// Initializes FRDeviceIdentifier
    ///
    /// - Parameter keychainService: Designated KeychainService to persist, and manage generated Key Pair, and Identifier
    init(keychainService: KeychainService) {
        self.keychainService = keychainService
    }
    
    /// Generates, or retrieves an identifier, returns
    ///
    /// - Returns: Uniquely generated Identifier as per Keychain Sharing Access Group
    @discardableResult public func getIdentifier() -> String {
        
        if let identifier = self.keychainService.getString(self.identifierKeychainServiceKey) {
            FRLog.v("Device Identifier is retrieved from Device Identifier Store")
            // If the identifier was found from KeychainService
            return identifier
        }
        else if self.generateKeyPair(), let keyData = self.keychainService.getData(self.publicKeyDataKeychainServiceKey) {
            FRLog.v("Device Identifier is created, and hash/base64; storing it into Device Identifier Store")
            // If the identifier was not found from KeychainService, then generates Key Pair and hash Public Key
            let identifier = self.hashAndBase64Data(keyData)
            // Persists the identifier
            self.keychainService.set(identifier, key: self.identifierKeychainServiceKey)
            return identifier
        }
        else {
            FRLog.w("Failed to generate or retrieve Device Identifier; generating Device Identifier based on UUID")
            // If some reason Identifier was not found, and Key Pair generation and/or store process failed, then use randomly generated UUID
            let uuid = UUID().uuidString
            let uuidData = uuid.data(using: .utf8)!
            // Hash UUID string, and persists it
            let identifier = self.hashAndBase64Data(uuidData)
            self.keychainService.set(identifier, key: self.identifierKeychainServiceKey)
            return identifier
        }
    }
    
    
    /// Hashes given Data using SHA1
    ///
    /// - Parameter data: Data to be hashed
    /// - Returns: Hashed String of given Data
    func hashAndBase64Data(_ data: Data) -> String {
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        let hexString = Data(bytes: digest, count: digest.count).toHexString()
        return hexString
    }
    
    
    /// Generates Key Pair, and persists generated Keys
    ///
    /// - Returns: A boolean result of whether Key Pair generation, and store process was successful or not
    func generateKeyPair() -> Bool {
        FRLog.v("Generating KeyPair for Device Identifier")
        let publicKeyPairAttr: [String: Any] = self.buildKeyAttr(.publicKey)
        let privateKeyPairAttr: [String: Any] = self.buildKeyAttr(.privateKey)
        
        let keyPairAttr: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecPublicKeyAttrs as String: publicKeyPairAttr,
            kSecPrivateKeyAttrs as String: privateKeyPairAttr
        ]
        
        var publicKey: SecKey?
        var privateKey: SecKey?
        let status = SecKeyGeneratePair(keyPairAttr as CFDictionary, &publicKey, &privateKey)
        
        if status == noErr, let _ = privateKey, let _ = publicKey {
            let publicKeyQuery = self.buildQuery(.publicKey)
            var publicKeyDataRef: CFTypeRef?
            let publicKeyStatus = SecItemCopyMatching(publicKeyQuery as CFDictionary, &publicKeyDataRef)
            let privateKeyQuery = self.buildQuery(.privateKey)
            var privateKeyDataRef: CFTypeRef?
            let privateKeyStatus = SecItemCopyMatching(privateKeyQuery as CFDictionary, &privateKeyDataRef)
            
            if publicKeyStatus == noErr, let publicKeyData = publicKeyDataRef as? Data, privateKeyStatus == noErr, let privateKeyData = privateKeyDataRef as? Data {
                
                if self.keychainService.set(publicKeyData, key: self.publicKeyDataKeychainServiceKey), self.keychainService.set(privateKeyData, key: self.privateKeyDataKeychainServiceKey) {
                    return true
                }
                else {
                    FRLog.e("Failed to store Key Pairs into Keychain Service: \(self)")
                }
            }
            else {
                FRLog.e("Failed to retrieve Key Pairs from Keychain Service: \(self)")
            }
        }
        else {
            FRLog.e("Failed to generate Key Pair using SecKeyGeneratePair(): \(self)")
        }
        
        return false
    }
    
    
    /// Builds Dictionary of Keychain operation attributes for Key Pair generation based on given Key Type
    ///
    /// - Parameter keyType: RSA Key Type whether Public or Private Key
    /// - Returns: A dictionary of Keychain operation attributes
    func buildKeyAttr(_ keyType: FRDeviceIdentifierKeyType) -> [String: Any] {
        var query: [String: Any] = [:]
        
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAlwaysThisDeviceOnly
        query[kSecAttrIsPermanent as String] = true
        
        switch keyType {
        case .privateKey:
            query[kSecAttrLabel as String] = "FRAuth SDK FRDevice identifier private key"
            query[kSecAttrApplicationTag as String] = self.privateKeyTag
            break
        case .publicKey:
            query[kSecAttrLabel as String] = "FRAuth SDK FRDevice identifier public key"
            query[kSecAttrApplicationTag as String] = self.publicKeyTag
            break
        }
        
        return query
    }
    
    
    /// Builds Dictionary of Keychain operation attributes for retrieving Key based on given Key Type
    ///
    /// - Parameter keyType: RSA Key Type whether Public or Private Key
    /// - Returns: A dictionary of Keychain operation attributes
    func buildQuery(_ keyType: FRDeviceIdentifierKeyType) -> [String: Any] {
        var query: [String: Any] = [:]
        query[kSecClass as String] = kSecClassKey
        query[kSecAttrKeyType as String] = self.keychainKeyType
        query[kSecReturnData as String] = true
        
        switch keyType {
        case .privateKey:
            query[kSecAttrApplicationTag as String] = self.privateKeyTag
            break
        case .publicKey:
            query[kSecAttrApplicationTag as String] = self.publicKeyTag
            break
        }
        
        return query
    }
}


extension Data {
    func toHexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
