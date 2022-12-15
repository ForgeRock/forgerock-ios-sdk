// 
//  AppPinAuthenticatorTests.swift
//  FRCoreTests
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRCore

class AppPinAuthenticatorTests: XCTestCase {
    
    func test_01_generateKeys() {
        let userId = "Test User Id 1"
        let cryptoKey = CryptoKey(keyId: userId)
        let appPinAuthenticator = AppPinAuthenticator(cryptoKey: cryptoKey)
        
        do {
            let keyPair = try appPinAuthenticator.generateKeys(description: "Description")
            XCTAssertEqual(cryptoKey.keyAlias, keyPair.keyAlias)
            
            let privateKey = CryptoKey.getSecureKey(keyAlias: cryptoKey.keyAlias)
            XCTAssertNotNil(privateKey)
        } catch {
            XCTFail("Failed to generate keys")
        }
        CryptoKey.deleteKey(keyAlias: cryptoKey.keyAlias)
    }
    
    
    func test_02_getKeyAlias() {
        let userId = "Test User Id 2"
        let cryptoKey = CryptoKey(keyId: userId)
        let appPinAuthenticator = AppPinAuthenticator(cryptoKey: cryptoKey)
        
        XCTAssertEqual(cryptoKey.keyAlias, appPinAuthenticator.getKeyAlias())
        
        CryptoKey.deleteKey(keyAlias: cryptoKey.keyAlias)
    }
    
    
    func test_03_getPrivateKey() {
        let userId = "Test User Id 3"
        let cryptoKey = CryptoKey(keyId: userId)
        let appPinAuthenticator = AppPinAuthenticator(cryptoKey: cryptoKey)
        
        do {
            let keyPair = try appPinAuthenticator.generateKeys(description: "Description")
            XCTAssertEqual(cryptoKey.keyAlias, keyPair.keyAlias)
            
            let cryptoPrivateKey = CryptoKey.getSecureKey(keyAlias: cryptoKey.keyAlias)
            XCTAssertNotNil(cryptoPrivateKey)
            
            let privateKey = appPinAuthenticator.getPrivateKey()
            XCTAssertNotNil(privateKey)
            
            XCTAssertEqual(cryptoPrivateKey, privateKey)
        } catch {
            XCTFail("Failed to generate keys")
        }
        CryptoKey.deleteKey(keyAlias: cryptoKey.keyAlias)
    }
}
