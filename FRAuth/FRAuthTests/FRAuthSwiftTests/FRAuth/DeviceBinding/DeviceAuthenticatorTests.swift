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
@testable import FRCore

class DeviceAuthenticatorTests: XCTestCase {
    
    func test_01_getDeviceAuthenticator() {
        let noneAuthenticator = DeviceBindingAuthenticationType.none.getAuthType()
        XCTAssertTrue(noneAuthenticator is None)
        
        let biometricOnlyAuthenticator = DeviceBindingAuthenticationType.biometricOnly.getAuthType()
        XCTAssertTrue(biometricOnlyAuthenticator is BiometricOnly)
        
        let biometricAllowFallbackAuthenticator = DeviceBindingAuthenticationType.biometricAllowFallback.getAuthType()
        XCTAssertTrue(biometricAllowFallbackAuthenticator is BiometricAndDeviceCredential)
        
        let applicationPinAuthenticator = DeviceBindingAuthenticationType.applicationPin.getAuthType()
        XCTAssertTrue(applicationPinAuthenticator is ApplicationPinDeviceAuthenticator)
    }
    
    
    func test_02_None_sign() {
        let userId = "Test User Id 2"
        let challenge = "challenge"
        let expiration = Date().addingTimeInterval(60.0)
        let kid = UUID().uuidString
        
        let authenticator = None()
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: ""))
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
    
    
    func test_03_None_generateKeys() {
        let userId = "Test User Id 3"
        let key = CryptoKey.getKeyAlias(keyName: userId)
        
        let authenticator = None()
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: ""))
        XCTAssertTrue(authenticator.isSupported())
        XCTAssertNil(authenticator.accessControl())
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
    
    
    func test_04_BiometricOnly_sign() {
        // Skip the test on iOS 15 Simulator due to the bug when private key generation fails with Access Control Flags set
        // https://stackoverflow.com/questions/69279715/ios-15-xcode-13-cannot-generate-private-key-on-simulator-running-ios-15-with-s
#if targetEnvironment(simulator)
        if #available(iOS 15.0, *) {
            guard #available(iOS 16.0, *) else {
                return
            }
        }
#endif
        let userId = "Test User Id 4"
        let challenge = "challenge"
        let expiration = Date().addingTimeInterval(60.0)
        let kid = UUID().uuidString
        
        let authenticator = BiometricOnly()
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: "Description"))
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
    
    
    func test_05_BiometricOnly_generateKeys() {
        // Skip the test on iOS 15 Simulator due to the bug when private key generation fails with Access Control Flags set
        // https://stackoverflow.com/questions/69279715/ios-15-xcode-13-cannot-generate-private-key-on-simulator-running-ios-15-with-s
#if targetEnvironment(simulator)
        if #available(iOS 15.0, *) {
            guard #available(iOS 16.0, *) else {
                return
            }
        }
#endif
        let userId = "Test User Id 5"
        let key = CryptoKey.getKeyAlias(keyName: userId)
        
        let authenticator = BiometricOnly()
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: "Description"))
#if !targetEnvironment(simulator)
        XCTAssertTrue(authenticator.isSupported())
#else
        XCTAssertFalse(authenticator.isSupported())
#endif
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
    
    
    func test_06_BiometricAndDeviceCredential_sign() {
        // Skip the test on iOS 15 Simulator due to the bug when private key generation fails with Access Control Flags set
        // https://stackoverflow.com/questions/69279715/ios-15-xcode-13-cannot-generate-private-key-on-simulator-running-ios-15-with-s
#if targetEnvironment(simulator)
        if #available(iOS 15.0, *) {
            guard #available(iOS 16.0, *) else {
                return
            }
        }
#endif
        let userId = "Test User Id 6"
        let challenge = "challenge"
        let expiration = Date().addingTimeInterval(60.0)
        let kid = UUID().uuidString
        
        let authenticator = BiometricAndDeviceCredential()
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: "Description"))
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
    
    
    func test_07_BiometricAndDeviceCredential_generateKeys() {
        // Skip the test on iOS 15 Simulator due to the bug when private key generation fails with Access Control Flags set
        // https://stackoverflow.com/questions/69279715/ios-15-xcode-13-cannot-generate-private-key-on-simulator-running-ios-15-with-s
#if targetEnvironment(simulator)
        if #available(iOS 15.0, *) {
            guard #available(iOS 16.0, *) else {
                return
            }
        }
#endif
        let userId = "Test User Id 7"
        let key = CryptoKey.getKeyAlias(keyName: userId)
        
        let authenticator = BiometricAndDeviceCredential()
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: "Description"))
        
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
    
    
    func test_08_None_sign_with_userKey() {
        let userId = "Test User Id 8"
        let challenge = "challenge"
        let expiration = Date().addingTimeInterval(60.0)
        let kid = UUID().uuidString
        
        let authenticator = None()
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: ""))
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
    
    
    func test_09_BiometricOnly_sign_with_userKey() {
        // Skip the test on iOS 15 Simulator due to the bug when private key generation fails with Access Control Flags set
        // https://stackoverflow.com/questions/69279715/ios-15-xcode-13-cannot-generate-private-key-on-simulator-running-ios-15-with-s
#if targetEnvironment(simulator)
        if #available(iOS 15.0, *) {
            guard #available(iOS 16.0, *) else {
                return
            }
        }
#endif
        let userId = "Test User Id 9"
        let challenge = "challenge"
        let expiration = Date().addingTimeInterval(60.0)
        let kid = UUID().uuidString
        
        let authenticator = BiometricOnly()
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: "Description"))
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
    
    
    func test_10_BiometricAndDeviceCredential_sign_with_userKey() {
        // Skip the test on iOS 15 Simulator due to the bug when private key generation fails with Access Control Flags set
        // https://stackoverflow.com/questions/69279715/ios-15-xcode-13-cannot-generate-private-key-on-simulator-running-ios-15-with-s
#if targetEnvironment(simulator)
        if #available(iOS 15.0, *) {
            guard #available(iOS 16.0, *) else {
                return
            }
        }
#endif
        let userId = "Test User Id 10"
        let challenge = "challenge"
        let expiration = Date().addingTimeInterval(60.0)
        let kid = UUID().uuidString
        
        let authenticator = BiometricAndDeviceCredential()
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: "Description"))
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
    
    
    func test_11_None_generateKeys_without_initialize() {
        //make sure initialize is not called
        let authenticator = None()
        XCTAssertEqual(authenticator.type(), .none)
        
        do {
            _ = try authenticator.generateKeys()
            XCTFail("Generate Keys should have failed withut calling initialize()")
            
        } catch {
            //all good, do nothing
        }
    }
    
    
    func test_12_BiometricOnly_generateKeys_without_initialize() {
        //make sure initialize is not called
        let authenticator = BiometricOnly()
        XCTAssertEqual(authenticator.type(), .biometricOnly)
        
        do {
            _ = try authenticator.generateKeys()
            XCTFail("Generate Keys should have failed withut calling initialize()")
            
        } catch {
            //all good, do nothing
        }
    }
    
    
    func test_13_BiometricAndDeviceCredential_generateKeys_without_initialize() {
        //make sure initialize is not called
        let authenticator = BiometricAndDeviceCredential()
        XCTAssertEqual(authenticator.type(), .biometricAllowFallback)
        
        do {
            _ = try authenticator.generateKeys()
            XCTFail("Generate Keys should have failed withut calling initialize()")
            
        } catch {
            //all good, do nothing
        }
    }
}
