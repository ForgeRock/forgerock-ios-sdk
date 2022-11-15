// 
//  KeyAwareTests.swift
//  FRAuthTests
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth


class KeyAwareTests: XCTestCase {
    
    func test_01_basic_init() {
        let userId = "Test User Id 1"
        let keyAware = KeyAware(userId: userId)
        XCTAssertEqual(keyAware.timeout, 60)
    }
    
    
    func test_02_keyBuilderQuery() {
        let userId = "Test User Id 2"
        let key = KeyAware.getKeyAlias(keyName: userId)
        let keyAware = KeyAware(userId: userId)
        let query = keyAware.keyBuilderQuery()
        
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
        let key = KeyAware.getKeyAlias(keyName: userId)
        let keyAware = KeyAware(userId: userId)
        let query = keyAware.keyBuilderQuery()
        var privateKey: SecKey?
        
        do {
            privateKey = KeyAware.getSecureKey(keyAlias: key)
            XCTAssertNil(privateKey)
            
            let keyPair = try keyAware.createKeyPair(builderQuery: query)
            XCTAssertEqual(keyPair.keyAlias, key)
            
            privateKey = KeyAware.getSecureKey(keyAlias: key)
            XCTAssertNotNil(privateKey)
        } catch {
            XCTFail("Failed to create KeyPair")
        }
        KeyAware.deleteKey(keyAlias: key)
    }
    
    
    func test_04_getSecureKey() {
        let userId = "Test User Id 4"
        let key = KeyAware.getKeyAlias(keyName: userId)
        let keyAware = KeyAware(userId: userId)
        let query = keyAware.keyBuilderQuery()
        var privateKey: SecKey?
        
        privateKey = KeyAware.getSecureKey(keyAlias: key)
        XCTAssertNil(privateKey)
        
        SecKeyCreateRandomKey(query as CFDictionary, nil)
        
        privateKey = KeyAware.getSecureKey(keyAlias: key)
        XCTAssertNotNil(privateKey)
        
        KeyAware.deleteKey(keyAlias: key)
    }
    
    
    func test_05_deleteKey() {
        let userId = "Test User Id 5"
        let key = KeyAware.getKeyAlias(keyName: userId)
        let keyAware = KeyAware(userId: userId)
        let query = keyAware.keyBuilderQuery()
        var privateKey: SecKey?
        
        SecKeyCreateRandomKey(query as CFDictionary, nil)
        
        privateKey = KeyAware.getSecureKey(keyAlias: key)
        XCTAssertNotNil(privateKey)
        
        KeyAware.deleteKey(keyAlias: key)
        privateKey = KeyAware.getSecureKey(keyAlias: key)
        XCTAssertNil(privateKey)
    }
    
    
    func test_06_getKeyAlias() {
        let userId1 = "Test User Id 6-1"
        let userId2 = "Test User Id 6-2"
        
        XCTAssertEqual(KeyAware.getKeyAlias(keyName: userId1), KeyAware.getKeyAlias(keyName: userId1))
        XCTAssertNotEqual(KeyAware.getKeyAlias(keyName: userId1), KeyAware.getKeyAlias(keyName: userId2))
    }
}
