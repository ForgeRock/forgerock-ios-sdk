//
//  FRDeviceIdentifier.swift
//  FRAuth
//
//  Copyright (c) 2019 - 2025 Ping Identity Corporation. All rights reserved.
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
    static let identifierKeychainServiceKey = "com.forgerock.ios.device-identifier.hash-base64-string-identifier"
    
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
        
        if let identifier = self.keychainService.getString(FRDeviceIdentifier.identifierKeychainServiceKey) {
            FRLog.v("Device Identifier is retrieved from Device Identifier Store")
            // If the identifier was found from KeychainService
            return identifier
        }
        else if let keyData = self.keychainService.getData(self.publicKeyDataKeychainServiceKey) {
            // Keys exist but identifier is missing - regenerate identifier from existing key
            FRLog.v("Public key found but identifier missing; regenerating identifier from existing key data")
            let identifier = self.hashAndBase64Data(keyData)
            self.keychainService.set(identifier, key: FRDeviceIdentifier.identifierKeychainServiceKey)
            return identifier
        }
        else if self.generateKeyPair(), let keyData = self.keychainService.getData(self.publicKeyDataKeychainServiceKey) {
            FRLog.v("Device Identifier is created, and hash/base64; storing it into Device Identifier Store")
            // If the identifier was not found from KeychainService, then generates Key Pair and hash Public Key
            let identifier = self.hashAndBase64Data(keyData)
            // Persists the identifier
            self.keychainService.set(identifier, key: FRDeviceIdentifier.identifierKeychainServiceKey)
            return identifier
        }
        else {
            FRLog.w("Failed to generate or retrieve Device Identifier; generating Device Identifier based on UUID")
            // If some reason Identifier was not found, and Key Pair generation and/or store process failed, then use randomly generated UUID
            let uuid = UUID().uuidString
            let uuidData = uuid.data(using: .utf8)!
            // Hash UUID string, and persists it
            let identifier = self.hashAndBase64Data(uuidData)
            self.keychainService.set(identifier, key: FRDeviceIdentifier.identifierKeychainServiceKey)
            return identifier
        }
    }
    
    
    /// Hashes given Data using SHA1
    ///
    /// - Parameter data: Data to be hashed
    /// - Returns: Hashed String of given Data
    func hashAndBase64Data(_ data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
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
        
        // First, check if keys already exist and delete them to avoid conflicts
        self.deleteExistingKeys()
        
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
        
        guard status == noErr else {
            FRLog.e("Failed to generate Key Pair using SecKeyGeneratePair(). Status: \(status), OSStatus description: \(self.keychainErrorDescription(status))")
            return false
        }
        
        guard let generatedPrivateKey = privateKey, let generatedPublicKey = publicKey else {
            FRLog.e("Key Pair generation returned noErr but keys are nil")
            return false
        }
        
        FRLog.v("Key Pair generated successfully, extracting key data")
        
        // Use SecKeyCopyExternalRepresentation instead of SecItemCopyMatching for better reliability
        var publicKeyError: Unmanaged<CFError>?
        var privateKeyError: Unmanaged<CFError>?
        
        guard let publicKeyData = SecKeyCopyExternalRepresentation(generatedPublicKey, &publicKeyError) as Data? else {
            if let error = publicKeyError?.takeRetainedValue() {
                FRLog.e("Failed to extract public key data: \(error)")
            }
            return false
        }
        
        guard let privateKeyData = SecKeyCopyExternalRepresentation(generatedPrivateKey, &privateKeyError) as Data? else {
            if let error = privateKeyError?.takeRetainedValue() {
                FRLog.e("Failed to extract private key data: \(error)")
            }
            return false
        }
        
        FRLog.v("Key data extracted, storing to KeychainService")
        
        // Store the key data
        guard self.keychainService.set(publicKeyData, key: self.publicKeyDataKeychainServiceKey) else {
            FRLog.e("Failed to store Public Key data into Keychain Service")
            return false
        }
        
        guard self.keychainService.set(privateKeyData, key: self.privateKeyDataKeychainServiceKey) else {
            FRLog.e("Failed to store Private Key data into Keychain Service")
            // Clean up the public key we just stored
            _ = self.keychainService.delete(self.publicKeyDataKeychainServiceKey)
            return false
        }
        
        FRLog.v("Key Pair generation and storage completed successfully")
        return true
    }
    
    
    /// Deletes existing keys from keychain to avoid conflicts during key generation
    private func deleteExistingKeys() {
        // Delete public key
        var publicKeyQuery = self.buildQuery(.publicKey)
        publicKeyQuery.removeValue(forKey: kSecReturnData as String)
        SecItemDelete(publicKeyQuery as CFDictionary)
        
        // Delete private key
        var privateKeyQuery = self.buildQuery(.privateKey)
        privateKeyQuery.removeValue(forKey: kSecReturnData as String)
        SecItemDelete(privateKeyQuery as CFDictionary)
    }
    
    
    /// Provides human-readable description for OSStatus error codes
    ///
    /// - Parameter status: OSStatus error code
    /// - Returns: Human-readable error description
    private func keychainErrorDescription(_ status: OSStatus) -> String {
        switch status {
        case errSecSuccess:
            return "Success"
        case errSecUnimplemented:
            return "Function or operation not implemented"
        case errSecParam:
            return "One or more parameters passed to the function were not valid"
        case errSecAllocate:
            return "Failed to allocate memory"
        case errSecNotAvailable:
            return "No trust results are available"
        case errSecAuthFailed:
            return "Authorization/Authentication failed"
        case errSecDuplicateItem:
            return "The item already exists"
        case errSecItemNotFound:
            return "The item cannot be found"
        case errSecInteractionNotAllowed:
            return "Interaction with the Security Server is not allowed"
        case errSecDecode:
            return "Unable to decode the provided data"
        default:
            return "Unknown error (\(status))"
        }
    }
    
    /// Builds Dictionary of Keychain operation attributes for Key Pair generation based on given Key Type
    ///
    /// - Parameter keyType: RSA Key Type whether Public or Private Key
    /// - Returns: A dictionary of Keychain operation attributes
    func buildKeyAttr(_ keyType: FRDeviceIdentifierKeyType) -> [String: Any] {
        var query: [String: Any] = [:]
        
        query[kSecAttrAccessible as String] = KeychainAccessibility.afterFirstUnlockThisDeviceOnly.rawValue
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
