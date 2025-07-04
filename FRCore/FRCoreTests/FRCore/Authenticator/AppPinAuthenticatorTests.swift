// 
//  AppPinAuthenticatorTests.swift
//  FRCoreTests
//
//  Copyright (c) 2022 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRCore

class AppPinAuthenticatorTests: FRBaseTestCase {
    
    func test_01_generateKeys() throws {
        try XCTSkipIf(self.isSimulator, "LAContext().setCredential(...) call is not supported on iOS Simulator.")
        let userId = "Test User Id 1"
        let cryptoKey = CryptoKey(keyId: userId)
        let appPinAuthenticator = AppPinAuthenticator(cryptoKey: cryptoKey)
        let pin = "1234"
        
        do {
            let keyPair = try appPinAuthenticator.generateKeys(description: "Description", pin: pin)
            XCTAssertEqual(cryptoKey.keyAlias, keyPair.keyAlias)
            
            let privateKey = cryptoKey.getSecureKey(pin: pin)
            XCTAssertNotNil(privateKey)
        } catch {
            XCTFail("Failed to generate keys")
        }
        cryptoKey.deleteKeys()
    }
    
    
    func test_02_getKeyAlias() {
        let userId = "Test User Id 2"
        let cryptoKey = CryptoKey(keyId: userId)
        let appPinAuthenticator = AppPinAuthenticator(cryptoKey: cryptoKey)
        
        XCTAssertEqual(cryptoKey.keyAlias, appPinAuthenticator.getKeyAlias())
        
        cryptoKey.deleteKeys()
    }
    
    
    func test_03_getPrivateKey() throws {
        try XCTSkipIf(self.isSimulator, "LAContext().setCredential(...) call is not supported on iOS Simulator.")
        let userId = "Test User Id 3"
        let cryptoKey = CryptoKey(keyId: userId)
        let appPinAuthenticator = AppPinAuthenticator(cryptoKey: cryptoKey)
        let pin = "1234"
        
        do {
            let keyPair = try appPinAuthenticator.generateKeys(description: "Description", pin: pin)
            XCTAssertEqual(cryptoKey.keyAlias, keyPair.keyAlias)
            
            let cryptoPrivateKey = cryptoKey.getSecureKey(pin: pin)
            XCTAssertNotNil(cryptoPrivateKey)
            
            let privateKey = appPinAuthenticator.getPrivateKey(pin: pin)
            XCTAssertNotNil(privateKey)
            
            XCTAssertEqual(cryptoPrivateKey, privateKey)
        } catch {
            XCTFail("Failed to generate keys")
        }
        cryptoKey.deleteKeys()
    }
}
