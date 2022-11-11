// 
//  DeviceAuthenticatorTests.swift
//  FRAuthTests
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
import JOSESwift
@testable import FRAuth

class DeviceAuthenticatorTests: XCTestCase {
    
    func test_01_AuthenticatorFactory_getAuthenticator() {
        let userId = "Test User Id 1"
        let keyAware = KeyAware(userId: userId)
        
        let noneAuthenticator = AuthenticatorFactory.getAuthenticator(userId: userId, authentication: .none, title: "Title", subtitle: "Subtitle", description: "description", keyAware: keyAware)
        XCTAssertTrue(noneAuthenticator is None)
        
        let biometricOnlyAuthenticator = AuthenticatorFactory.getAuthenticator(userId: userId, authentication: .biometricOnly, title: "Title", subtitle: "Subtitle", description: "description", keyAware: keyAware)
        XCTAssertTrue(biometricOnlyAuthenticator is BiometricOnly)
        
        let biometricAllowFallbackAuthenticator = AuthenticatorFactory.getAuthenticator(userId: userId, authentication: .biometricAllowFallback, title: "Title", subtitle: "Subtitle", description: "description", keyAware: keyAware)
        XCTAssertTrue(biometricAllowFallbackAuthenticator is BiometricAndDeviceCredential)
    }
    
    
    func test_02_test_None_sign() {
        let userId = "Test User Id 2"
        let challenge = "challenge"
        let expiration = Date().addingTimeInterval(60.0)
        let keyAware = KeyAware(userId: userId)
        let kid = UUID().uuidString
        
        let authenticator = None(keyAware: keyAware)
        do {
            let keyPair = try authenticator.generateKeys()
            let jwsString = try authenticator.sign(keyPair: keyPair, kid: kid, userId: userId, challenge: challenge, expiration: expiration)
            
            //verify signature
            let jws = try JWS(compactSerialization: jwsString)
            guard let verifier = Verifier(verifyingAlgorithm: .ES256, key: keyPair.publicKey) else {
                XCTFail("Failed to create Verifier")
                return
            }
            
            let _ = try jws.validate(using: verifier)
            let payload = jws.payload
            let message = String(data: payload.data(), encoding: .utf8)!
            XCTAssertEqual(kid, jws.header.kid)
            XCTAssertEqual("JWS", jws.header.typ)
            
            let messageDictionary = FRTestUtils.parseStringToDictionary(message)
            
            XCTAssertEqual(messageDictionary["challenge"] as? String, challenge)
            XCTAssertEqual(messageDictionary["sub"] as? String, userId)
            XCTAssertEqual(messageDictionary["exp"] as? Int, Int(expiration.timeIntervalSince1970))
        } catch {
            XCTFail("Failed to verify JWS signature")
        }
    }
    
    
    func test_03_None_generateKeys() {
        let userId = "Test User Id 3"
        let keyAware = KeyAware(userId: userId)
        let key = KeyAware.getKeyAlias(keyName: userId)
        
        let authenticator = None(keyAware: keyAware)
        XCTAssertTrue(authenticator.isSupported())
        XCTAssertNil(authenticator.accessControl())
        do {
            let keyPair = try authenticator.generateKeys()
            XCTAssertEqual(key, keyPair.keyAlias)
            
            let privateKey = KeyAware.getSecureKey(keyAlias: key)
            XCTAssertNotNil(privateKey)
            KeyAware.deleteKey(keyAlias: key)
        } catch {
            XCTFail("Failed to generate keys")
        }
    }
    
    
    func test_04_test_BiometricOnly_sign() {
        let userId = "Test User Id 4"
        let challenge = "challenge"
        let expiration = Date().addingTimeInterval(60.0)
        let keyAware = KeyAware(userId: userId)
        let kid = UUID().uuidString
        
        let authenticator = BiometricOnly(description: "Description", keyAware: keyAware)
        do {
            let keyPair = try authenticator.generateKeys()
            let jwsString = try authenticator.sign(keyPair: keyPair, kid: kid, userId: userId, challenge: challenge, expiration: expiration)
            
            //verify signature
            let jws = try JWS(compactSerialization: jwsString)
            guard let verifier = Verifier(verifyingAlgorithm: .ES256, key: keyPair.publicKey) else {
                XCTFail("Failed to create Verifier")
                return
            }
            
            let _ = try jws.validate(using: verifier)
            let payload = jws.payload
            let message = String(data: payload.data(), encoding: .utf8)!
            XCTAssertEqual(kid, jws.header.kid)
            XCTAssertEqual("JWS", jws.header.typ)
            
            let messageDictionary = FRTestUtils.parseStringToDictionary(message)
            
            XCTAssertEqual(messageDictionary["challenge"] as? String, challenge)
            XCTAssertEqual(messageDictionary["sub"] as? String, userId)
            XCTAssertEqual(messageDictionary["exp"] as? Int, Int(expiration.timeIntervalSince1970))
        } catch {
            XCTFail("Failed to verify JWS signature")
        }
    }
    
    
    func test_05_BiometricOnly_generateKeys() {
        let userId = "Test User Id 5"
        let keyAware = KeyAware(userId: userId)
        let key = KeyAware.getKeyAlias(keyName: userId)
        
        let authenticator = BiometricOnly(description: "Description", keyAware: keyAware)
#if !targetEnvironment(simulator)
        XCTAssertTrue(authenticator.isSupported())
#else
        XCTAssertFalse(authenticator.isSupported())
#endif
        XCTAssertNotNil(authenticator.accessControl())
        do {
            let keyPair = try authenticator.generateKeys()
            XCTAssertEqual(key, keyPair.keyAlias)
            
            let privateKey = KeyAware.getSecureKey(keyAlias: key)
            XCTAssertNotNil(privateKey)
            KeyAware.deleteKey(keyAlias: key)
        } catch {
            XCTFail("Failed to generate keys")
        }
    }
    
    
    func test_06_test_BiometricAndDeviceCredential_sign() {
        let userId = "Test User Id 6"
        let challenge = "challenge"
        let expiration = Date().addingTimeInterval(60.0)
        let keyAware = KeyAware(userId: userId)
        let kid = UUID().uuidString
        
        let authenticator = BiometricAndDeviceCredential(description: "Description", keyAware: keyAware)
        do {
            let keyPair = try authenticator.generateKeys()
            let jwsString = try authenticator.sign(keyPair: keyPair, kid: kid, userId: userId, challenge: challenge, expiration: expiration)
            
            //verify signature
            let jws = try JWS(compactSerialization: jwsString)
            guard let verifier = Verifier(verifyingAlgorithm: .ES256, key: keyPair.publicKey) else {
                XCTFail("Failed to create Verifier")
                return
            }
            
            let _ = try jws.validate(using: verifier)
            let payload = jws.payload
            let message = String(data: payload.data(), encoding: .utf8)!
            XCTAssertEqual(kid, jws.header.kid)
            XCTAssertEqual("JWS", jws.header.typ)
            
            let messageDictionary = FRTestUtils.parseStringToDictionary(message)
            
            XCTAssertEqual(messageDictionary["challenge"] as? String, challenge)
            XCTAssertEqual(messageDictionary["sub"] as? String, userId)
            XCTAssertEqual(messageDictionary["exp"] as? Int, Int(expiration.timeIntervalSince1970))
        } catch {
            XCTFail("Failed to verify JWS signature")
        }
    }
    
    
    func test_07_BiometricAndDeviceCredential_generateKeys() {
        let userId = "Test User Id 7"
        let keyAware = KeyAware(userId: userId)
        let key = KeyAware.getKeyAlias(keyName: userId)
        
        let authenticator = BiometricAndDeviceCredential(description: "Description", keyAware: keyAware)
        
        XCTAssertTrue(authenticator.isSupported())
        XCTAssertNotNil(authenticator.accessControl())
        do {
            let keyPair = try authenticator.generateKeys()
            XCTAssertEqual(key, keyPair.keyAlias)
            
            let privateKey = KeyAware.getSecureKey(keyAlias: key)
            XCTAssertNotNil(privateKey)
            KeyAware.deleteKey(keyAlias: key)
        } catch {
            XCTFail("Failed to generate keys")
        }
    }
}