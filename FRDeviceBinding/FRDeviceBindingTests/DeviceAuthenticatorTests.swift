// 
//  DeviceAuthenticatorTests.swift
//  FRDeviceBindingTests
//
//  Copyright (c) 2022 - 2026 Ping Identity Corporation. All rights reserved.
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
            guard let verifier = Verifier(signatureAlgorithm: .ES256, key: keyPair.publicKey) else {
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
            guard let verifier = Verifier(signatureAlgorithm: .ES256, key: keyPair.publicKey) else {
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
            guard let verifier = Verifier(signatureAlgorithm: .ES256, key: keyPair.publicKey) else {
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
            guard let verifier = Verifier(signatureAlgorithm: .ES256, key: keyPair.publicKey) else {
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
            guard let verifier = Verifier(signatureAlgorithm: .ES256, key: keyPair.publicKey) else {
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
            guard let verifier = Verifier(signatureAlgorithm: .ES256, key: keyPair.publicKey) else {
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
    
    
    // MARK: - biometricDomainState tests
    
    func test_16_biometricDomainState_defaultReturnsNil() {
        // DefaultDeviceAuthenticator base implementation should return nil
        let noneAuthenticator = None()
        XCTAssertNil(noneAuthenticator.biometricDomainState())
        
        let biometricOnly = BiometricOnly()
        XCTAssertNil(biometricOnly.biometricDomainState())
        
        let appPin = ApplicationPinDeviceAuthenticator()
        XCTAssertNil(appPin.biometricDomainState())
    }
    
    
    func test_17_biometricDomainState_biometricAndDeviceCredential() {
        // On simulator without biometrics, evaluatedPolicyDomainState returns nil
        let authenticator = BiometricAndDeviceCredential()
        let state = authenticator.biometricDomainState()
        // On simulator biometrics are not enrolled, so domain state is nil
        XCTAssertNil(state)
    }
    
    
    func test_18_biometricDomainState_storedInUserKey() {
        // Verify biometricDomainState can be stored and retrieved from UserKey
        let testData = "test-biometric-state".data(using: .utf8)
        let userKey = UserKey(id: "id", userId: "user", userName: "name", kid: "kid", authType: .biometricAllowFallback, createdAt: Date().timeIntervalSince1970, biometricDomainState: testData)
        XCTAssertEqual(userKey.biometricDomainState, testData)
        
        // Verify it encodes/decodes correctly
        let encoded = try! JSONEncoder().encode(userKey)
        let decoded = try! JSONDecoder().decode(UserKey.self, from: encoded)
        XCTAssertEqual(decoded.biometricDomainState, testData)
    }
    
    
    func test_19_biometricDomainState_nilInUserKey_backwardCompatibility() {
        // Verify UserKey without biometricDomainState decodes correctly (backward compatibility)
        let userKey = UserKey(id: "id", userId: "user", userName: "name", kid: "kid", authType: .none, createdAt: Date().timeIntervalSince1970)
        XCTAssertNil(userKey.biometricDomainState)
        
        // Simulate a UserKey encoded without the biometricDomainState field
        let json = """
        {"id":"id","userId":"user","userName":"name","kid":"kid","authType":"NONE","createdAt":1000000}
        """
        let decoded = try! JSONDecoder().decode(UserKey.self, from: json.data(using: .utf8)!)
        XCTAssertNil(decoded.biometricDomainState)
    }
    
    
    func test_20_biometricDomainState_signRejectsMismatch() {
        // BiometricAndDeviceCredential.sign(userKey:...) should throw .clientNotRegistered
        // when stored biometricDomainState doesn't match current state
        let userId = "Test User Id 20"
        let challenge = "challenge"
        let expiration = Date().addingTimeInterval(60.0)
        
        let authenticator = BiometricAndDeviceCredential()
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: ""))
        
        // Create a UserKey with a fake stored biometric state that won't match current
        let fakeState = "fake-biometric-state".data(using: .utf8)
        let userKey = UserKey(id: "id", userId: userId, userName: "name", kid: UUID().uuidString, authType: .biometricAllowFallback, createdAt: Date().timeIntervalSince1970, biometricDomainState: fakeState)
        
        do {
            _ = try authenticator.sign(userKey: userKey, challenge: challenge, expiration: expiration, customClaims: [:])
            XCTFail("Sign should have thrown .clientNotRegistered due to biometric state mismatch")
        } catch let error as DeviceBindingStatus {
            XCTAssertEqual(error, .clientNotRegistered)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        let cryptoKey = CryptoKey(keyId: userId)
        cryptoKey.deleteKeys()
    }
    
    
    func test_21_biometricDomainState_signSkipsCheckWhenNil() {
        // When biometricDomainState is nil in UserKey, the domain state check should be skipped.
        // We verify this by confirming the authenticator does NOT delete keys before failing.
        // If the domain state check were triggered, deleteKeys() would be called first.
        let userId = "Test User Id 21"
        let challenge = "challenge"
        let expiration = Date().addingTimeInterval(60.0)
        
        let authenticator = SpyBiometricAndDeviceCredential()
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: ""))
        
        // UserKey without biometricDomainState (nil) - domain state check should be skipped
        let userKey = UserKey(id: "id", userId: userId, userName: "name", kid: UUID().uuidString, authType: .biometricAllowFallback, createdAt: Date().timeIntervalSince1970, biometricDomainState: nil)
        
        do {
            _ = try authenticator.sign(userKey: userKey, challenge: challenge, expiration: expiration, customClaims: [:])
        } catch {
            // Expected to fail (key doesn't exist), but deleteKeys should NOT have been called
            // because the domain state check was skipped
            XCTAssertFalse(authenticator.deleteKeysCalled, "deleteKeys should not be called when biometricDomainState is nil")
        }
        
        let cryptoKey = CryptoKey(keyId: userId)
        cryptoKey.deleteKeys()
    }
    
    
    func test_22_biometricDomainState_protocolExtensionDefault() {
        // Verify that a type conforming directly to DeviceAuthenticator
        // gets the default nil implementation from the protocol extension
        let customAuthenticator = CustomProtocolOnlyAuthenticator()
        XCTAssertNil(customAuthenticator.biometricDomainState())
    }
    
}


/// Test authenticator conforming directly to DeviceAuthenticator protocol (not subclassing DefaultDeviceAuthenticator)
/// Used to verify the protocol extension provides a default biometricDomainState() implementation
private class CustomProtocolOnlyAuthenticator: DeviceAuthenticator {
    func generateKeys() throws -> KeyPair { fatalError() }
    func sign(keyPair: KeyPair, kid: String, userId: String, challenge: String, expiration: Date) throws -> String { fatalError() }
    func sign(userKey: UserKey, challenge: String, expiration: Date, customClaims: [String: Any]) throws -> String { fatalError() }
    func isSupported() -> Bool { return false }
    func accessControl() -> SecAccessControl? { return nil }
    func setPrompt(_ prompt: Prompt) { }
    func type() -> DeviceBindingAuthenticationType { return .none }
    func initialize(userId: String, prompt: Prompt) { }
    func initialize(userId: String) { }
    func deleteKeys() { }
    func issueTime() -> Date { return Date() }
    func notBeforeTime() -> Date { return Date() }
    func validateCustomClaims(_ customClaims: [String: Any]) -> Bool { return true }
}


/// Spy subclass of BiometricAndDeviceCredential to track whether deleteKeys() is called
/// during the biometric domain state check in sign(userKey:...)
private class SpyBiometricAndDeviceCredential: BiometricAndDeviceCredential {
    var deleteKeysCalled = false
    
    override func deleteKeys() {
        deleteKeysCalled = true
        super.deleteKeys()
    }
}
