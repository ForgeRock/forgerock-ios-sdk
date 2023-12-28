// 
//  DeviceAuthenticatorTests.swift
//  FRDeviceBindingTests
//
//  Copyright (c) 2022-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
import JOSESwift
@testable import FRAuth
@testable import FRCore
@testable import FRDeviceBinding

class DeviceAuthenticatorTests: FRBaseTestCase {
    
    var isIOS15 = false
    
    override func setUp() {
        super.setUp()
        
        if #available(iOS 15.0, *) {
            if #available(iOS 16.0, *) {
                isIOS15 = false
            } else {
                isIOS15 = true
            }
        }
    }
    
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
            XCTAssertEqual(DBConstants.JWS, jws.header.typ)
            
            let messageDictionary = FRTestUtils.parseStringToDictionary(message)
            
            XCTAssertEqual(messageDictionary[DBConstants.challenge] as? String, challenge)
            XCTAssertEqual(messageDictionary[DBConstants.sub] as? String, userId)
            XCTAssertEqual(messageDictionary[DBConstants.exp] as? Int, Int(expiration.timeIntervalSince1970))
            XCTAssertEqual(messageDictionary[DBConstants.platform] as? String, DBConstants.ios)
            XCTAssertEqual(messageDictionary[DBConstants.iat] as! Int, Int(Date().timeIntervalSince1970), accuracy: 10)
            XCTAssertEqual(messageDictionary[DBConstants.nbf] as! Int, Int(Date().timeIntervalSince1970), accuracy: 10)
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                XCTAssertEqual(messageDictionary[DBConstants.iss] as? String, bundleIdentifier)
            }
        } catch {
            XCTFail("Failed to verify JWS signature")
        }
        let cryptoKey = CryptoKey(keyId: userId)
        cryptoKey.deleteKeys()
    }
    
    
    func test_03_None_generateKeys() {
        let userId = "Test User Id 3"
        let cryptoKey = CryptoKey(keyId: userId)
        let key = cryptoKey.keyAlias
        
        let authenticator = None()
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: ""))
        XCTAssertTrue(authenticator.isSupported())
        XCTAssertNil(authenticator.accessControl())
        do {
            let keyPair = try authenticator.generateKeys()
            XCTAssertEqual(key, keyPair.keyAlias)
            
            
            let privateKey = cryptoKey.getSecureKey()
            XCTAssertNotNil(privateKey)
        } catch {
            XCTFail("Failed to generate keys")
        }
        cryptoKey.deleteKeys()
    }
    
    
    func test_04_BiometricOnly_sign() throws {
        // Skip the test on iOS 15 Simulator due to the bug when private key generation fails with Access Control Flags set
        // https://stackoverflow.com/questions/69279715/ios-15-xcode-13-cannot-generate-private-key-on-simulator-running-ios-15-with-s
        try XCTSkipIf(self.isSimulator && isIOS15, "on iOS 15 Simulator private key generation fails with Access Control Flags set")
        try XCTSkipIf(!Self.biometricTestsSupported, "Biometric tests are not supported")
        
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
            XCTAssertEqual(DBConstants.JWS, jws.header.typ)
            
            let messageDictionary = FRTestUtils.parseStringToDictionary(message)
            
            XCTAssertEqual(messageDictionary[DBConstants.challenge] as? String, challenge)
            XCTAssertEqual(messageDictionary[DBConstants.sub] as? String, userId)
            XCTAssertEqual(messageDictionary[DBConstants.exp] as? Int, Int(expiration.timeIntervalSince1970))
            XCTAssertEqual(messageDictionary[DBConstants.platform] as? String, DBConstants.ios)
            XCTAssertEqual(messageDictionary[DBConstants.iat] as! Int, Int(Date().timeIntervalSince1970), accuracy: 10)
            XCTAssertEqual(messageDictionary[DBConstants.nbf] as! Int, Int(Date().timeIntervalSince1970), accuracy: 10)
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                XCTAssertEqual(messageDictionary[DBConstants.iss] as? String, bundleIdentifier)
            }
        } catch {
            XCTFail("Failed to verify JWS signature")
        }
        let cryptoKey = CryptoKey(keyId: userId)
        cryptoKey.deleteKeys()
    }
    
    
    func test_05_BiometricOnly_generateKeys() throws {
        // Skip the test on iOS 15 Simulator due to the bug when private key generation fails with Access Control Flags set
        // https://stackoverflow.com/questions/69279715/ios-15-xcode-13-cannot-generate-private-key-on-simulator-running-ios-15-with-s
        try XCTSkipIf(self.isSimulator && isIOS15, "on iOS 15 Simulator private key generation fails with Access Control Flags set")
        try XCTSkipIf(!Self.biometricTestsSupported, "This test requires PIN setup on the device")
        
        let userId = "Test User Id 5"
        let cryptoKey = CryptoKey(keyId: userId)
        let key = cryptoKey.keyAlias
        
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
            
            let privateKey = cryptoKey.getSecureKey()
            XCTAssertNotNil(privateKey)
        } catch {
            XCTFail("Failed to generate keys")
        }
        cryptoKey.deleteKeys()
    }
    
    
    func test_06_BiometricAndDeviceCredential_sign() throws {
        // Skip the test on iOS 15 Simulator due to the bug when private key generation fails with Access Control Flags set
        // https://stackoverflow.com/questions/69279715/ios-15-xcode-13-cannot-generate-private-key-on-simulator-running-ios-15-with-s
        try XCTSkipIf(self.isSimulator && isIOS15, "on iOS 15 Simulator private key generation fails with Access Control Flags set")
        try XCTSkipIf(!Self.biometricTestsSupported, "Biometric tests are not supported")
        
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
            XCTAssertEqual(DBConstants.JWS, jws.header.typ)
            
            let messageDictionary = FRTestUtils.parseStringToDictionary(message)
            
            XCTAssertEqual(messageDictionary[DBConstants.challenge] as? String, challenge)
            XCTAssertEqual(messageDictionary[DBConstants.sub] as? String, userId)
            XCTAssertEqual(messageDictionary[DBConstants.exp] as? Int, Int(expiration.timeIntervalSince1970))
            XCTAssertEqual(messageDictionary[DBConstants.platform] as? String, DBConstants.ios)
            XCTAssertEqual(messageDictionary[DBConstants.iat] as! Int, Int(Date().timeIntervalSince1970), accuracy: 10)
            XCTAssertEqual(messageDictionary[DBConstants.nbf] as! Int, Int(Date().timeIntervalSince1970), accuracy: 10)
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                XCTAssertEqual(messageDictionary[DBConstants.iss] as? String, bundleIdentifier)
            }
        } catch {
            XCTFail("Failed to verify JWS signature")
        }
        let cryptoKey = CryptoKey(keyId: userId)
        cryptoKey.deleteKeys()
    }
    
    
    func test_07_BiometricAndDeviceCredential_generateKeys() throws {
        // Skip the test on iOS 15 Simulator due to the bug when private key generation fails with Access Control Flags set
        // https://stackoverflow.com/questions/69279715/ios-15-xcode-13-cannot-generate-private-key-on-simulator-running-ios-15-with-s
        try XCTSkipIf(self.isSimulator && isIOS15, "on iOS 15 Simulator private key generation fails with Access Control Flags set")
        try XCTSkipIf(!Self.biometricTestsSupported, "This test requires PIN setup on the device")
        
        let userId = "Test User Id 7"
        let cryptoKey = CryptoKey(keyId: userId)
        let key = cryptoKey.keyAlias
        
        let authenticator = BiometricAndDeviceCredential()
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: "Description"))
        
        XCTAssertTrue(authenticator.isSupported())
        XCTAssertNotNil(authenticator.accessControl())
        do {
            let keyPair = try authenticator.generateKeys()
            XCTAssertEqual(key, keyPair.keyAlias)
            
            let privateKey = cryptoKey.getSecureKey()
            XCTAssertNotNil(privateKey)
        } catch {
            XCTFail("Failed to generate keys")
        }
        cryptoKey.deleteKeys()
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
            let userKey = UserKey(id: CryptoKey.getKeyAlias(keyName: userId), userId: userId, userName: "username", kid: kid, authType: .none, createdAt: Date().timeIntervalSince1970)
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
            XCTAssertEqual(DBConstants.JWS, jws.header.typ)
            
            let messageDictionary = FRTestUtils.parseStringToDictionary(message)
            
            XCTAssertEqual(messageDictionary[DBConstants.challenge] as? String, challenge)
            XCTAssertEqual(messageDictionary[DBConstants.sub] as? String, userId)
            XCTAssertEqual(messageDictionary[DBConstants.exp] as? Int, Int(expiration.timeIntervalSince1970))
            XCTAssertEqual(messageDictionary[DBConstants.iat] as! Int, Int(Date().timeIntervalSince1970), accuracy: 10)
            XCTAssertEqual(messageDictionary[DBConstants.nbf] as! Int, Int(Date().timeIntervalSince1970), accuracy: 10)
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                XCTAssertEqual(messageDictionary[DBConstants.iss] as? String, bundleIdentifier)
            }
        } catch {
            XCTFail("Failed to verify JWS signature")
        }
        let cryptoKey = CryptoKey(keyId: userId)
        cryptoKey.deleteKeys()
    }
    
    
    func test_09_BiometricOnly_sign_with_userKey() throws {
        // Skip the test on iOS 15 Simulator due to the bug when private key generation fails with Access Control Flags set
        // https://stackoverflow.com/questions/69279715/ios-15-xcode-13-cannot-generate-private-key-on-simulator-running-ios-15-with-s
        try XCTSkipIf(self.isSimulator && isIOS15, "on iOS 15 Simulator private key generation fails with Access Control Flags set")
        try XCTSkipIf(!Self.biometricTestsSupported, "Biometric tests are not supported")
        
        let userId = "Test User Id 9"
        let challenge = "challenge"
        let expiration = Date().addingTimeInterval(60.0)
        let kid = UUID().uuidString
        
        let authenticator = BiometricOnly()
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: "Description"))
        do {
            let keyPair = try authenticator.generateKeys()
            let userKey = UserKey(id: CryptoKey.getKeyAlias(keyName: userId), userId: userId, userName: "username", kid: kid, authType: .none, createdAt: Date().timeIntervalSince1970)
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
            XCTAssertEqual(DBConstants.JWS, jws.header.typ)
            
            let messageDictionary = FRTestUtils.parseStringToDictionary(message)
            
            XCTAssertEqual(messageDictionary[DBConstants.challenge] as? String, challenge)
            XCTAssertEqual(messageDictionary[DBConstants.sub] as? String, userId)
            XCTAssertEqual(messageDictionary[DBConstants.exp] as? Int, Int(expiration.timeIntervalSince1970))
            XCTAssertEqual(messageDictionary[DBConstants.iat] as! Int, Int(Date().timeIntervalSince1970), accuracy: 10)
            XCTAssertEqual(messageDictionary[DBConstants.nbf] as! Int, Int(Date().timeIntervalSince1970), accuracy: 10)
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                XCTAssertEqual(messageDictionary[DBConstants.iss] as? String, bundleIdentifier)
            }
        } catch {
            XCTFail("Failed to verify JWS signature")
        }
        let cryptoKey = CryptoKey(keyId: userId)
        cryptoKey.deleteKeys()
    }
    
    
    func test_10_BiometricAndDeviceCredential_sign_with_userKey() throws {
        // Skip the test on iOS 15 Simulator due to the bug when private key generation fails with Access Control Flags set
        // https://stackoverflow.com/questions/69279715/ios-15-xcode-13-cannot-generate-private-key-on-simulator-running-ios-15-with-s
        try XCTSkipIf(self.isSimulator && isIOS15, "on iOS 15 Simulator private key generation fails with Access Control Flags set")
        try XCTSkipIf(!Self.biometricTestsSupported, "Biometric tests are not supported")
        
        let userId = "Test User Id 10"
        let challenge = "challenge"
        let expiration = Date().addingTimeInterval(60.0)
        let kid = UUID().uuidString
        
        let authenticator = BiometricAndDeviceCredential()
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: "Description"))
        do {
            let keyPair = try authenticator.generateKeys()
            let userKey = UserKey(id: CryptoKey.getKeyAlias(keyName: userId), userId: userId, userName: "username", kid: kid, authType: .none, createdAt: Date().timeIntervalSince1970)
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
            XCTAssertEqual(DBConstants.JWS, jws.header.typ)
            
            let messageDictionary = FRTestUtils.parseStringToDictionary(message)
            
            XCTAssertEqual(messageDictionary[DBConstants.challenge] as? String, challenge)
            XCTAssertEqual(messageDictionary[DBConstants.sub] as? String, userId)
            XCTAssertEqual(messageDictionary[DBConstants.exp] as? Int, Int(expiration.timeIntervalSince1970))
            XCTAssertEqual(messageDictionary[DBConstants.iat] as! Int, Int(Date().timeIntervalSince1970), accuracy: 10)
            XCTAssertEqual(messageDictionary[DBConstants.nbf] as! Int, Int(Date().timeIntervalSince1970), accuracy: 10)
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                XCTAssertEqual(messageDictionary[DBConstants.iss] as? String, bundleIdentifier)
            }
        } catch {
            XCTFail("Failed to verify JWS signature")
        }
        let cryptoKey = CryptoKey(keyId: userId)
        cryptoKey.deleteKeys()
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
    
    
    func test_14_ValidateCustomClaims_valid() {
        
        let authenticator = None()
        let valid = authenticator.validateCustomClaims(["name": "demo", "email_verified": true])
        
        XCTAssertTrue(valid)
    }
    
    
    func test_15_ValidateCustomClaims_invalid() {
        
        let authenticator = None()
        
        XCTAssertFalse(authenticator.validateCustomClaims([DBConstants.sub: "demo"]))
        
        XCTAssertFalse(authenticator.validateCustomClaims([DBConstants.challenge: "demo"]))
        
        XCTAssertFalse(authenticator.validateCustomClaims([DBConstants.exp: "demo"]))
        
        XCTAssertFalse(authenticator.validateCustomClaims([DBConstants.iat: "demo"]))
        
        XCTAssertFalse(authenticator.validateCustomClaims([DBConstants.nbf: "demo"]))
        
        XCTAssertFalse(authenticator.validateCustomClaims([DBConstants.iss: "demo"]))
        
        XCTAssertFalse(authenticator.validateCustomClaims([DBConstants.iss: "demo", DBConstants.exp: Date()]))
        
    }
    
    
    func test_14_ValidateCustomClaims_empty() {
        
        let authenticator = None()
        let valid = authenticator.validateCustomClaims([:])
        
        XCTAssertTrue(valid)
    }
    
}
