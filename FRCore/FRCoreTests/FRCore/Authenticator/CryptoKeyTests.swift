// 
//  CryptoKeyTests.swift
//  FRCoreTests
//
//  Copyright (c) 2022-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRCore


class CryptoKeyTests: XCTestCase {
    
    func test_01_basic_init() {
        let userId = "Test User Id 1"
        let cryptoKey = CryptoKey(keyId: userId)
        XCTAssertEqual(cryptoKey.timeout, 60)
    }
    
    
    func test_02_keyBuilderQuery() {
        let userId = "Test User Id 2"
        let key = CryptoKey.getKeyAlias(keyName: userId)
        let cryptoKey = CryptoKey(keyId: userId)
        let query = cryptoKey.keyBuilderQuery()
        
        XCTAssertEqual(query[String(kSecAttrKeyType)] as! String, String(kSecAttrKeyTypeECSECPrimeRandom))
        XCTAssertEqual(query[String(kSecAttrKeySizeInBits)] as! Int, 256)
        
        
        let keyAttr = query[String(kSecPrivateKeyAttrs)] as! [String: Any]
        XCTAssertEqual(keyAttr[String(kSecAttrIsPermanent)] as! Bool, true)
        XCTAssertEqual(keyAttr[String(kSecAttrApplicationTag)] as! String, key)
        
#if !targetEnvironment(simulator)
        XCTAssertEqual(query[String(kSecAttrTokenID)] as! String, String(kSecAttrTokenIDSecureEnclave))
#endif
    }
    
    func test_03_createKeyPair() {
        let userId = "Test User Id 3"
        let key = CryptoKey.getKeyAlias(keyName: userId)
        let cryptoKey = CryptoKey(keyId: userId)
        let query = cryptoKey.keyBuilderQuery()
        var privateKey: SecKey?
        
        do {
            privateKey = cryptoKey.getSecureKey()
            XCTAssertNil(privateKey)
            
            let keyPair = try cryptoKey.createKeyPair(builderQuery: query)
            XCTAssertEqual(keyPair.keyAlias, key)
            
            privateKey = cryptoKey.getSecureKey()
            XCTAssertNotNil(privateKey)
        } catch {
            XCTFail("Failed to create KeyPair")
        }
        cryptoKey.deleteKeys()
    }
    
    
    func test_04_getSecureKey() {
        let userId = "Test User Id 4"
        let cryptoKey = CryptoKey(keyId: userId)
        let query = cryptoKey.keyBuilderQuery()
        var privateKey: SecKey?
        
        privateKey = cryptoKey.getSecureKey()
        XCTAssertNil(privateKey)
        
        SecKeyCreateRandomKey(query as CFDictionary, nil)
        
        privateKey = cryptoKey.getSecureKey()
        XCTAssertNotNil(privateKey)
        
        cryptoKey.deleteKeys()
    }
    
    
    func test_05_deleteKey() {
        let userId = "Test User Id 5"
        let cryptoKey = CryptoKey(keyId: userId)
        let query = cryptoKey.keyBuilderQuery()
        var privateKey: SecKey?
        
        SecKeyCreateRandomKey(query as CFDictionary, nil)
        
        privateKey = cryptoKey.getSecureKey()
        XCTAssertNotNil(privateKey)
        
        cryptoKey.deleteKeys()
        privateKey = cryptoKey.getSecureKey()
        XCTAssertNil(privateKey)
    }
    
    
    func test_06_getKeyAlias() {
        let userId1 = "Test User Id 6-1"
        let userId2 = "Test User Id 6-2"
        
        XCTAssertEqual(CryptoKey.getKeyAlias(keyName: userId1), CryptoKey.getKeyAlias(keyName: userId1))
        XCTAssertNotEqual(CryptoKey.getKeyAlias(keyName: userId1), CryptoKey.getKeyAlias(keyName: userId2))
    }
    
    
    func test_07_deleteKeys() {
        let userId = "Test User Id 7"
        let cryptoKey = CryptoKey(keyId: userId)
        let query = cryptoKey.keyBuilderQuery()
        var privateKey: SecKey?
        
        SecKeyCreateRandomKey(query as CFDictionary, nil)
        
        privateKey = cryptoKey.getSecureKey()
        XCTAssertNotNil(privateKey)
        
        cryptoKey.deleteKeys()
        privateKey = cryptoKey.getSecureKey()
        XCTAssertNil(privateKey)
    }
    
    
    func test_08_same_accessGroup() {
        let userId = "Test User Id 8"
        let accessGroup = "com.forgerock.ios.shared" //com.forgerock.ios.FRTestHost
        let cryptoKey = CryptoKey(keyId: userId, accessGroup: accessGroup)
        
        let query = cryptoKey.keyBuilderQuery()
        var privateKey: SecKey?
        
        do {
            privateKey = cryptoKey.getSecureKey()
            XCTAssertNil(privateKey)
            
            let keyPair = try cryptoKey.createKeyPair(builderQuery: query)
            XCTAssertNotNil(keyPair.privateKey)
            
            privateKey = cryptoKey.getSecureKey()
            XCTAssertNotNil(privateKey)
            
            XCTAssertEqual(keyPair.privateKey, privateKey)
            
            let cryptoKey2 = CryptoKey(keyId: userId, accessGroup: accessGroup)
            XCTAssertEqual(keyPair.privateKey, cryptoKey2.getSecureKey())
        } catch {
            XCTFail("Failed to create KeyPair")
        }
        
        cryptoKey.deleteKeys()
        privateKey = cryptoKey.getSecureKey()
        XCTAssertNil(privateKey)
    }
    
    
    func test_09_different_accessGroup() {
        let userId = "Test User Id 9"
        let accessGroup1 = "com.forgerock.ios.shared"
        let accessGroup2 = "com.forgerock.ios.FRTestHost"
        let cryptoKey1 = CryptoKey(keyId: userId, accessGroup: accessGroup1)
        let cryptoKey2 = CryptoKey(keyId: userId, accessGroup: accessGroup2)
        let query1 = cryptoKey1.keyBuilderQuery()
        let query2 = cryptoKey2.keyBuilderQuery()
        var privateKey1: SecKey?
        var privateKey2: SecKey?
        
        do {
            // Access Group 1
            privateKey1 = cryptoKey1.getSecureKey()
            XCTAssertNil(privateKey1)
            
            let keyPair1 = try cryptoKey1.createKeyPair(builderQuery: query1)
            XCTAssertNotNil(keyPair1.privateKey)
            
            privateKey1 = cryptoKey1.getSecureKey()
            XCTAssertNotNil(privateKey1)
            
            XCTAssertEqual(keyPair1.privateKey, privateKey1)
            
            // Access Group 2
            privateKey2 = cryptoKey2.getSecureKey()
            XCTAssertNil(privateKey2)
            
            let keyPair2 = try cryptoKey2.createKeyPair(builderQuery: query2)
            XCTAssertNotNil(keyPair2.privateKey)
            
            privateKey2 = cryptoKey2.getSecureKey()
            XCTAssertNotNil(privateKey2)
            
            XCTAssertEqual(keyPair2.privateKey, privateKey2)
            
            // Compare keys from Access Group 1 and 2
            XCTAssertNotEqual(privateKey1, privateKey2)
            
        } catch {
            XCTFail("Failed to create KeyPair")
        }
        
        cryptoKey1.deleteKeys()
        privateKey1 = cryptoKey1.getSecureKey()
        XCTAssertNil(privateKey1)
        
        cryptoKey2.deleteKeys()
        privateKey2 = cryptoKey2.getSecureKey()
        XCTAssertNil(privateKey2)
    }
    
    
    func test_10_with_and_without_accessGroup() {
        let userId = "Test User Id 10"
        let accessGroup1 = "com.forgerock.ios.shared"
        let cryptoKey1 = CryptoKey(keyId: userId, accessGroup: accessGroup1)
        let cryptoKey2 = CryptoKey(keyId: userId)
        let query1 = cryptoKey1.keyBuilderQuery()
        let query2 = cryptoKey2.keyBuilderQuery()
        var privateKey1: SecKey?
        var privateKey2: SecKey?
        
        do {
            // With Access Group
            let keyPair1 = try cryptoKey1.createKeyPair(builderQuery: query1)
            XCTAssertNotNil(keyPair1.privateKey)
            
            privateKey1 = cryptoKey1.getSecureKey()
            XCTAssertNotNil(privateKey1)
            
            XCTAssertEqual(keyPair1.privateKey, privateKey1)
            
            // Without Access Group
            let keyPair2 = try cryptoKey2.createKeyPair(builderQuery: query2)
            XCTAssertNotNil(keyPair2.privateKey)
            
            privateKey2 = cryptoKey2.getSecureKey()
            XCTAssertNotNil(privateKey2)
            
            XCTAssertEqual(keyPair2.privateKey, privateKey2)
            
            // Compare keys
            XCTAssertNotEqual(privateKey1, privateKey2)
            
        } catch {
            XCTFail("Failed to create KeyPair")
        }
        
        cryptoKey1.deleteKeys()
        privateKey1 = cryptoKey1.getSecureKey()
        XCTAssertNil(privateKey1)
        
        cryptoKey2.deleteKeys()
        privateKey2 = cryptoKey2.getSecureKey()
        XCTAssertNil(privateKey2)
    }
}
