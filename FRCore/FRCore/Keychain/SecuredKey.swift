// 
//  SecuredKey.swift
//  FRCore
//
//  Copyright (c) 2020 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import LocalAuthentication
#if canImport(CryptoKit)
import CryptoKit
#endif

/// SecuredKey is a representation of Secure Enclave keypair and performing PKI using Secure Enclave
public struct SecuredKey {
    
    /// Private Key of SecuredKey
    fileprivate var privateKey: SecKey
    /// Public Key of SecuredKey
    fileprivate var publicKey: SecKey
    /// Algorithm to be used for encryption/decryption using SecuredKey
    fileprivate let oldAlgorithm: SecKeyAlgorithm = .eciesEncryptionCofactorX963SHA256AESGCM
    
    /// Validates whether SecuredKey using Secure Enclave is available on the device or not
    public static func isAvailable() -> Bool {
        
        #if canImport(CryptoKit)
        if #available(iOS 13.0, *) {
            Log.v("Secure Enclave availability: \(SecureEnclave.isAvailable)")
            return SecureEnclave.isAvailable
        }
        #endif
        
        let laContext = LAContext()
        var error: NSError?
        
        // Validate if LocalAuthentication can be processed or not; this simply validates whether LA can be processed or not, and not necessarily returning the result of Secure Enclave's availability
        var canEvaluatePolicy = laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if canEvaluatePolicy == false, let error = error {
            
            // Check if an error is whether LocalAuthentication is not available (meaning there is no hardware security module)
            canEvaluatePolicy = error.code != LAError.biometryNotAvailable.rawValue
            
            if !canEvaluatePolicy {
                Log.w("Biometry is not available on the device; SDK continues without storage data encryption")
            }
        }
        
        return canEvaluatePolicy
    }
    
    
    /// Initializes SecuredKey object with designated service; SecuredKey may return nil if it failed to generate keypair
    /// - Parameter applicationTag: Unique identifier for SecuredKey in Keychain Service
    public init?(applicationTag: String, accessGroup: String? = nil, accessibility: KeychainAccessibility = .afterFirstUnlock) {

        Log.v("SecuredKey init - applicationTag: '\(applicationTag)', accessGroup: \(accessGroup ?? "nil"), accessibility: \(accessibility.description)")

        guard SecuredKey.isAvailable() else {
            Log.w("SecuredKey init - SecuredKey is not available on this device; SDK will continue without storage encryption")
            return nil
        }

        // If SecuredKey already exists, return from the storage
        if let privateKey = SecuredKey.readKey(applicationTag: applicationTag, accessGroup: accessGroup) {
            Log.v("SecuredKey init - existing private key found and loaded for tag '\(applicationTag)'")
            self.privateKey = privateKey
        }
        else {
            // Otherwise, generate new keypair
            // NOTE: If a key was expected to exist (e.g. previously stored data is present) but is no
            // longer readable here, generating a new key means previously-encrypted data can no longer
            // be decrypted. This is a key indicator to watch for when diagnosing identifier instability.
            Log.w("SecuredKey init - no existing private key found for tag '\(applicationTag)'; generating a NEW keypair. Any data previously encrypted with an older key will no longer be decryptable.")
            do {
                self.privateKey = try SecuredKey.generateKey(applicationTag: applicationTag, accessGroup: accessGroup, accessibility: accessibility)
                Log.v("SecuredKey init - successfully generated new private key for tag '\(applicationTag)'")
            }
            catch {
                Log.e("SecuredKey init - failed to generate new private key for tag '\(applicationTag)': \(error.localizedDescription)")
                return nil
            }
        }

        // Copy the public key from the private key
        if let publicKey = SecKeyCopyPublicKey(self.privateKey) {
            self.publicKey = publicKey
        }
        else {
            Log.e("SecuredKey init - failed to copy public key from private key for tag '\(applicationTag)'")
            return nil
        }
    }
    
    
    /// Retrieves private key with given 'ApplicationTag'
    /// - Parameter applicationTag: Application Tag string value for private key
    static func readKey(applicationTag: String, accessGroup: String? = nil) -> SecKey? {
        var query = [String: Any]()
        query[String(kSecClass)] = kSecClassKey
        query[String(kSecAttrKeyType)] = String(kSecAttrKeyTypeEC)
        query[String(kSecReturnRef)] = true
        query[String(kSecAttrApplicationTag)] = applicationTag
        
        if let accessGroup = accessGroup {
            query[String(kSecAttrAccessGroup)] = accessGroup
        }
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                Log.v("SecuredKey readKey - no key found for tag '\(applicationTag)' (errSecItemNotFound)")
            } else {
                Log.w("SecuredKey readKey - lookup for tag '\(applicationTag)' returned status: \(status)")
            }
            return nil
        }
        return (item as! SecKey)
    }
    
    
    /// Generates private key with given 'ApplicationTag'
    /// - Parameter applicationTag: Application Tag string value for private key
    static func generateKey(applicationTag: String, accessGroup: String? = nil, accessibility: KeychainAccessibility) throws -> SecKey {
        var query = [String: Any]()
        
        query[String(kSecAttrKeyType)] = String(kSecAttrKeyTypeEC)
        query[String(kSecAttrKeySizeInBits)] = 256
        
        if let accessGroup = accessGroup {
            query[String(kSecAttrAccessGroup)] = accessGroup
        }
        
        var keyAttr = [String: Any]()
        keyAttr[String(kSecAttrIsPermanent)] = true
        keyAttr[String(kSecAttrApplicationTag)] = applicationTag
        
        #if !targetEnvironment(simulator)
        // If the device supports Secure Enclave, create a keypair using Secure Enclave TokenID
        if SecuredKey.isAvailable() {
            query[String(kSecAttrTokenID)] = String(kSecAttrTokenIDSecureEnclave)
            let accessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault, accessibility.rawValue as CFString, .privateKeyUsage, nil)!
            keyAttr[String(kSecAttrAccessControl)] = accessControl
        }
        #endif
        
        query[String(kSecPrivateKeyAttrs)] = keyAttr

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(query as CFDictionary, &error) else {
            Log.e("Error while generating Secure Key: \(error.debugDescription)")
            throw error!.takeRetainedValue() as Error
        }

        return privateKey
    }
    
    
    /// Deletes private key with given 'Application Tag'
    /// - Parameter applicationTag: Application Tag string value for private key
    static func deleteKey(applicationTag: String) {
        var query = [String: Any]()
        query[String(kSecClass)] = String(kSecClassKey)
        query[String(kSecAttrApplicationTag)] = applicationTag
        SecItemDelete(query as CFDictionary)
    }
    
    
    /// Encrypts Data object using SecuredKey object
    /// - Parameter data: Encrypted Data object
    public func encrypt(data: Data, secAlgorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM) -> Data? {
        
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, secAlgorithm) else {
            Log.e("\(secAlgorithm) is not supported on the device.")
            return nil
        }
        
        var error: Unmanaged<CFError>?
        let encryptedData = SecKeyCreateEncryptedData(publicKey, secAlgorithm, data as CFData, &error) as Data?
        if let error = error {
            Log.e("Failed to encrypt data: \(error)")
        }
        
        return encryptedData
    }
    
    
    /// Decrypts Data object using SecuredKey object
    /// - Parameter data: Decrypted Data object
    public func decrypt(data: Data, secAlgorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM) -> Data? {

        guard SecKeyIsAlgorithmSupported(privateKey, .decrypt, secAlgorithm) else {
            Log.e("\(secAlgorithm) is not supported on the device.")
            return nil
        }

        var error: Unmanaged<CFError>?
        let decryptedData = SecKeyCreateDecryptedData(privateKey, secAlgorithm, data as CFData, &error) as Data?
        if let error = error {
            Log.e("Failed to decrypt data (\(data.count) bytes) with primary algorithm - attempting Legacy Algorithm: \(error)")
            var decryptError: Unmanaged<CFError>?
            let decryptedData = SecKeyCreateDecryptedData(privateKey, oldAlgorithm, data as CFData, &decryptError) as Data?
            if let decryptError = decryptError {
                Log.e("Failed to decrypt data with legacy algorithm as well: \(decryptError). The current SecuredKey cannot decrypt this data (likely a different/regenerated key).")
            } else {
                Log.v("Successfully decrypted data using legacy algorithm")
                return decryptedData
            }

        }
        return decryptedData
    }
}
