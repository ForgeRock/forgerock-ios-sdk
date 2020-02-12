// 
//  SecuredKey.swift
//  FRAuth
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import LocalAuthentication

/// SecuredKey is a representation of Secure Enclave keypair and performing PKI using Secure Enclave
struct SecuredKey {
    
    /// Private Key of SecuredKey
    fileprivate var privateKey: SecKey
    /// Public Key of SecuredKey
    fileprivate var publicKey: SecKey
    /// Algorithm to be used for encryption/decryption using SecuredKey
    fileprivate let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorX963SHA256AESGCM
    
    /// Validates whether SecuredKey using Secure Enclave is available on the device or not
    static func isAvailable() -> Bool {
        
        let laContext = LAContext()
        var error: NSError?
        
        // Validate if LocalAuthentication can be processed or not; this simply validates whether LA can be processed or not, and not necessarily returning the result of Secure Enclave's availability
        var canEvaluatePolicy = laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if canEvaluatePolicy == false, let error = error {
            
            // Check if an error is whether LocalAuthentication is not available (meaning there is no hardware security module)
            if #available(iOS 11.0, *) {
                canEvaluatePolicy = error.code != LAError.biometryNotAvailable.rawValue
            }
            else {
                canEvaluatePolicy = error.code != LAError.touchIDNotAvailable.rawValue
            }
            
            if !canEvaluatePolicy {
                FRLog.w("Biometry is not available on the device; SDK continues without storage data encryption")
            }
        }
        
        return canEvaluatePolicy
    }
    
    
    /// Initializes SecuredKey object with designated service; SecuredKey may return nil if it failed to generate keypair
    /// - Parameter applicationTag: Unique identifier for SecuredKey in Keychain Service
    init?(applicationTag: String) {
        
        guard SecuredKey.isAvailable() else {
            return nil
        }
        
        // If SecuredKey already exists, return from the storage
        if let privateKey = SecuredKey.readKey(applicationTag: applicationTag) {
            self.privateKey = privateKey
        }
        else {
            // Otherwise, generate new keypair
            do {
                self.privateKey = try SecuredKey.generateKey(applicationTag: applicationTag)
            }
            catch {
                return nil
            }
        }
        
        // Copy the public key from the private key
        if let publicKey = SecKeyCopyPublicKey(self.privateKey){
            self.publicKey = publicKey
        }
        else {
            return nil
        }
    }
    
    
    /// Retrieves private key with given 'ApplicationTag'
    /// - Parameter applicationTag: Application Tag string value for private key
    static func readKey(applicationTag: String) -> SecKey? {
        var query = [String: Any]()
        query[String(kSecClass)] = kSecClassKey
        query[String(kSecAttrKeyType)] = String(kSecAttrKeyTypeEC)
        query[String(kSecReturnRef)] = true
        query[String(kSecAttrApplicationTag)] = applicationTag
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            return nil
        }
        return (item as! SecKey)
    }
    
    
    /// Generates private key with given 'ApplicationTag'
    /// - Parameter applicationTag: Application Tag string value for private key
    static func generateKey(applicationTag: String) throws -> SecKey {
        var query = [String: Any]()
        
        query[String(kSecAttrKeyType)] = String(kSecAttrKeyTypeEC)
        query[String(kSecAttrKeySizeInBits)] = 256
        
        var keyAttr = [String: Any]()
        keyAttr[String(kSecAttrIsPermanent)] = true
        keyAttr[String(kSecAttrApplicationTag)] = applicationTag
        
        #if !targetEnvironment(simulator)
        // If the device supports Secure Enclave, create a keypair using Secure Enclave TokenID
        if SecuredKey.isAvailable() {
            query[String(kSecAttrTokenID)] = String(kSecAttrTokenIDSecureEnclave)
            let accessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault,kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .privateKeyUsage, nil)!
            keyAttr[String(kSecAttrAccessControl)] = accessControl
        }
        #endif
        
        query[String(kSecPrivateKeyAttrs)] = keyAttr

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(query as CFDictionary, &error) else {
            FRLog.e("Error while generating Secure Key: \(error.debugDescription)")
            throw error!.takeRetainedValue() as Error
        }

        return privateKey
    }
    
    
    /// Deletes private key with given 'Application Tag'
    /// - Parameter applicationTag: Application Tag string value for private key
    static func deleteKey(applicationTag: String) {
        var query = [String: Any]()
        query[String(kSecClass)] = String(kSecAttrKeyTypeEC)
        query[String(kSecAttrApplicationTag)] = applicationTag
        SecItemDelete(query as CFDictionary)
    }
    
    
    /// Encrypts Data object using SecuredKey object
    /// - Parameter data: Encrypted Data object
    func encrypt(data: Data) -> Data? {
        
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else {
            FRLog.e("\(algorithm) is not supported on the device.")
            return nil
        }
        
        var error: Unmanaged<CFError>?
        let encryptedData = SecKeyCreateEncryptedData(publicKey, algorithm, data as CFData, &error) as Data?
        if let error = error {
            FRLog.e("Failed to encrypt data: \(error)")
        }
        
        return encryptedData
    }
    
    
    /// Decrypts Data object using SecuredKey object
    /// - Parameter data: Decrypted Data object
    func decrypt(data: Data) -> Data? {
        
        guard SecKeyIsAlgorithmSupported(privateKey, .decrypt, algorithm) else {
            FRLog.e("\(algorithm) is not supported on the device.")
            return nil
        }
        
        var error: Unmanaged<CFError>?
        let decryptedData = SecKeyCreateDecryptedData(privateKey, algorithm, data as CFData, &error) as Data?
        if let error = error {
            FRLog.e("Failed to decrypt data: \(error)")
        }
        return decryptedData
    }
}
