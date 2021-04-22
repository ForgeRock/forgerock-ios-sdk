// 
//  ECPrimeRandomKey.swift
//  FRCore
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import LocalAuthentication
#if canImport(CryptoKit)
import CryptoKit
#endif

/**
 ECPrimeRandomKey is a representation of Elliptic Curve Key on iOS' Secure Enclave to generate hardware-backed security key and to perform encryption, decryption, and signing operations using the key.
 */
public struct ECPrimeRandomKey {

    //  MARK: - Properties
    
    /// Private key representation of EC Prime Key
    fileprivate var privateKey: SecKey

    /// Public key representation of EC Prime Key
    fileprivate var publicKey: SecKey
    
    
    //  MARK: - Init
    
    /// Initializes ECPrimeRandomeKey object with public and private keys (SecKey)
    /// - Parameters:
    ///   - publicKey: Public key representation of SecKey
    ///   - privateKey: Private key representation of SecKey
    init(publicKey: SecKey, privateKey: SecKey) {
        self.publicKey = publicKey
        self.privateKey = privateKey
    }
    
    
    //  MARK: - Internal instance methods
    
    /// Extracts Public Key into bytes array
    /// - Throws: `SecurityError`
    /// - Returns: Bytes array of public key
    func getPublicKeyData() throws -> Data {
        var error : Unmanaged<CFError>?
        guard let rawData = SecKeyCopyExternalRepresentation(self.publicKey, &error) else {
            throw SecurityError.failToExtractPublicKey
        }
        return rawData as Data
    }
    
    
    //  MARK: - Public instance methods
    
    /// Extracts public key data and converts it into DER format
    /// - Throws: `SecurityError`
    /// - Returns: Bytes array of public key representation in DER format
    public func getPublicKeyDERData() throws -> Data {
        // Original source code from: https://github.com/agens-no/EllipticCurveKeyPair/blob/master/Sources/EllipticCurveKeyPair.swift#L532
        let rawData = try self.getPublicKeyData()
        let x9_62HeaderECHeader = [UInt8]([
            /* sequence          */ 0x30, 0x59,
            /* |-> sequence      */ 0x30, 0x13,
            /* |---> ecPublicKey */ 0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01, // http://oid-info.com/get/1.2.840.10045.2.1 (ANSI X9.62 public key type)
            /* |---> prime256v1  */ 0x06, 0x08, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, // http://oid-info.com/get/1.2.840.10045.3.1.7 (ANSI X9.62 named elliptic curve)
            /* |-> bit headers   */ 0x07, 0x03, 0x42, 0x00
            ])
        var result = Data()
        result.append(Data(x9_62HeaderECHeader))
        result.append(rawData)
        return result
    }

    
    /// Signs given bytes array using EC Prime Random Key using SHA256
    /// - Parameter data: Data object to be signed
    /// - Returns: Signed data
    public func sign(data: Data) -> Data? {
        var error : Unmanaged<CFError>?
        let result = SecKeyCreateSignature(self.privateKey, .ecdsaSignatureMessageX962SHA256, data as CFData, &error)
        
        if let signature = result {
            return signature as Data
        }
        else {
            Log.e("Failed to sign data")
            return nil
        }
    }
    
    
    //  MARK: - Static query generation methods
    
    /// Generates EC Prime Random Key with given information
    /// - Parameters:
    ///   - publicKeyLabel: Public key label information
    ///   - privateKeyLabel: Private key label information
    ///   - accessGroup: Optional Access Group string to be shared using Shared Keychain Service
    ///   - context: Optional LAContext to be used to generate the key
    /// - Returns: Dictionary containing public / private key generated
    static func generateKeyQuery(publicKeyLabel: String, privateKeyLabel: String, accessGroup: String? = "", context: LAContext? = nil) -> [String: Any] {
        
        //  Public Key Query
        var publicQuery: [String: Any] = [:]
        publicQuery[String(kSecAttrLabel)] = publicKeyLabel
        publicQuery[String(kSecAttrAccessControl)] = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleAlwaysThisDeviceOnly, [], nil)!
        
        //  Private Key Query
        var privateQuery: [String: Any] = [:]
        privateQuery[String(kSecAttrLabel)] = privateKeyLabel
        privateQuery[String(kSecAttrIsPermanent)] = true
        privateQuery[String(kSecUseAuthenticationUI)] = kSecUseAuthenticationUIAllow
        #if !targetEnvironment(simulator)
        privateQuery[String(kSecAttrAccessControl)] = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, [.privateKeyUsage], nil)!
        #endif
        
        if let context = context {
            privateQuery[String(kSecUseAuthenticationContext)] = context
        }
        
        if let accessGroup = accessGroup {
            publicQuery[String(kSecAttrAccessGroup)] = accessGroup
            privateQuery[String(kSecAttrAccessGroup)] = accessGroup
        }
        
        var query: [String: Any] = [:]
        query[String(kSecAttrKeyType)] = kSecAttrKeyTypeECSECPrimeRandom
        query[String(kSecPrivateKeyAttrs)] = privateQuery
        query[String(kSecPublicKeyAttrs)] = publicQuery
        query[String(kSecAttrKeySizeInBits)] = 256
        #if !targetEnvironment(simulator)
        query[String(kSecAttrTokenID)] = kSecAttrTokenIDSecureEnclave
        #endif
        return query
    }
    
    
    /// Retrieves EC Prime Randome Key from Keychain Service with given information
    /// - Parameters:
    ///   - label: String value of label to retrieve the key
    ///   - keyType: Type of key to be retrieved
    ///   - accessGroup: Optional Access Group string to be shared using Shared Keychain Service
    ///   - context: Optional LAContext to be used to retrieve the key
    /// - Returns: Dictionary containing public or private key generated
    static func getKeyQuery(label: String, keyType: String, accessGroup: String? = "", context: LAContext? = nil) -> [String: Any] {
        var query: [String: Any] = [:]
        query[String(kSecClass)] = kSecClassKey
        query[String(kSecAttrKeyClass)] = keyType as CFString
        query[String(kSecAttrLabel)] = label
        query[String(kSecReturnRef)] = true
        
        if let accessGroup = accessGroup {
            query[String(kSecAttrAccessGroup)] = accessGroup
        }
        
        if let context = context, keyType == (kSecAttrKeyClassPrivate as String) {
            query[String(kSecUseAuthenticationContext)] = context
        }
        
        return query
    }
    
    
    //  MARK: - Static Keypair generation / store method
    
    /// Stores Public Key representation into Keychain Service
    /// - Parameters:
    ///   - publicKey: Public Key representation in SecKey
    ///   - label: Label to store the public key
    ///   - accessGroup: Optional Access Group string to be shared using Shared Keychain Service
    /// - Returns: Boolean value indicating the result of the operation
    static func storePublicKey(publicKey: SecKey, label: String, accessGroup: String? = "") -> Bool {
        
        var query: [String: Any] = [:]
        query[String(kSecAttrLabel)] = label
        query[String(kSecClass)] = kSecClassKey
        query[String(kSecValueRef)] = publicKey
        
        if let accessGroup = accessGroup {
            query[String(kSecAttrAccessGroup)] = accessGroup
        }
        
        var keyResult: CFTypeRef?
        var result = SecItemAdd(query as CFDictionary, &keyResult)
        
        if result == errSecSuccess {
            return true
        }
        else if result == errSecDuplicateItem {
            _ = SecItemDelete(query as CFDictionary)
            result = SecItemAdd(query as CFDictionary, &keyResult)
            
            if result == errSecSuccess {
                return true
            }
        }
        
        return false
    }
    
    
    /// Generates or retrieves EC Prime Random key with given information
    /// - Parameters:
    ///   - label: Label string value to generate or retrieve ECPrimeRandomKey object
    ///   - accessGroup: Optional Access Group string to be shared using Shared Keychain Service
    ///   - context: Optional LAContext to be used to retrieve the key
    /// - Returns: ECPrimeRandomKey object
    public static func getKeypair(label: String, accessGroup: String? = nil, context: LAContext? = nil) -> ECPrimeRandomKey? {
        
        let publicKeyQuery = ECPrimeRandomKey.getKeyQuery(label: "\(label)/public", keyType: String(kSecAttrKeyClassPublic), accessGroup: accessGroup, context: context)
        let privateKeyQuery = ECPrimeRandomKey.getKeyQuery(label: "\(label)/private", keyType: String(kSecAttrKeyClassPrivate), accessGroup: accessGroup, context: context)
        
        var publicKeyRaw: CFTypeRef?
        let publicKeyStatus = SecItemCopyMatching(publicKeyQuery as CFDictionary, &publicKeyRaw)
        var privateKeyRaw: CFTypeRef?
        let privateKeyStatus = SecItemCopyMatching(privateKeyQuery as CFDictionary, &privateKeyRaw)
        
        if publicKeyStatus == errSecSuccess, privateKeyStatus == errSecSuccess, let publicKey = publicKeyRaw, let privateKey = privateKeyRaw {
            return ECPrimeRandomKey(publicKey: publicKey as! SecKey, privateKey: privateKey as! SecKey)
        }
        else {
            let generateQuery = ECPrimeRandomKey.generateKeyQuery(publicKeyLabel: "\(label)/public", privateKeyLabel: "\(label)/private", accessGroup: accessGroup, context: context)
            var publicKeyGeneratedRaw: SecKey?
            var privateKeyGeneratedRaw: SecKey?
            let status = SecKeyGeneratePair(generateQuery as CFDictionary, &publicKeyGeneratedRaw, &privateKeyGeneratedRaw)
            if status == errSecSuccess, let publicKey = publicKeyGeneratedRaw, let privateKey = privateKeyGeneratedRaw {
                
                if ECPrimeRandomKey.storePublicKey(publicKey: publicKey, label: "\(label)/public", accessGroup: accessGroup) {
                    return ECPrimeRandomKey(publicKey: publicKey, privateKey: privateKey)
                }
                else {
                    Log.e("Failed to store public key while generation of keypair was successful")
                }
            }
            else {
                Log.e("Failed to generate EC2 Prime Random Key Pair: \(status)")
            }
        }
        
        return nil
    }
}
