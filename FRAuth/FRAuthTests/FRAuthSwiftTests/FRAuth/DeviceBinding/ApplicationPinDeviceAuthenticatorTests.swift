// 
//  ApplicationPinDeviceAuthenticatorTests.swift
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
@testable import FRCore

class ApplicationPinDeviceAuthenticatorTests: XCTestCase {
    
    func test_01_sign() {
        let userId = "Test User Id 1"
        let challenge = "challenge"
        let expiration = Date().addingTimeInterval(60.0)
        let kid = UUID().uuidString
        
        let authenticator = ApplicationPinDeviceAuthenticator(pinCollector: PinCollectorMock())
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: "description"))
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
        CryptoKey.deleteKey(keyAlias: CryptoKey.getKeyAlias(keyName: userId))
    }
    
    
    func test_02_sign_with_userKey() {
        let userId = "Test User Id 2"
        let challenge = "challenge"
        let expiration = Date().addingTimeInterval(60.0)
        let kid = UUID().uuidString
        
        let authenticator = ApplicationPinDeviceAuthenticator(pinCollector: PinCollectorMock())
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: "description"))
        do {
            let keyPair = try authenticator.generateKeys()
            let userKey = UserKey(userId: userId, userName: "username", kid: kid, authType: .none, keyAlias: CryptoKey.getKeyAlias(keyName: userId))
            let jwsString = try authenticator.sign(userKey: userKey, challenge: challenge, expiration: expiration)
            
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
        CryptoKey.deleteKey(keyAlias: CryptoKey.getKeyAlias(keyName: userId))
    }
    
    
    func test_03_generateKeys() {
        let userId = "Test User Id 3"
        let key = CryptoKey.getKeyAlias(keyName: userId)
        
        let authenticator = ApplicationPinDeviceAuthenticator(pinCollector: PinCollectorMock())
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: "description"))
        XCTAssertTrue(authenticator.isSupported())
        XCTAssertNotNil(authenticator.accessControl())
        do {
            let keyPair = try authenticator.generateKeys()
            XCTAssertEqual(key, keyPair.keyAlias)
            
            let privateKey = CryptoKey.getSecureKey(keyAlias: key)
            XCTAssertNotNil(privateKey)
        } catch {
            XCTFail("Failed to generate keys")
        }
        CryptoKey.deleteKey(keyAlias: key)
    }
    
    
    func test_04_generateKeys_without_initialize() {
        //make sure initialize is not called
        let authenticator = ApplicationPinDeviceAuthenticator()
        XCTAssertEqual(authenticator.type(), .applicationPin)
        
        do {
            _ = try authenticator.generateKeys()
            XCTFail("Generate Keys should have failed withut calling initialize()")
            
        } catch {
            //all good, do nothing
        }
    }
    
    class PinCollectorMock: PinCollector {
        func collectPin(prompt: Prompt, completion: @escaping (String?) -> Void) {
            completion("1234")
        }
    }
}
