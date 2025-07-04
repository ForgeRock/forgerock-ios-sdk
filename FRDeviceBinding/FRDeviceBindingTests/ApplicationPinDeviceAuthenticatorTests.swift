// 
//  ApplicationPinDeviceAuthenticatorTests.swift
//  FRDeviceBindingTests
//
//  Copyright (c) 2022 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
import JOSESwift
@testable import FRAuth
@testable import FRCore
@testable import FRDeviceBinding

class ApplicationPinDeviceAuthenticatorTests: FRBaseTestCase {
    
    func test_01_sign() throws {
        try XCTSkipIf(!Self.biometricTestsSupported, "This test requires PIN setup on the device")
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
    
    
    func test_02_sign_with_userKey() throws {
        try XCTSkipIf(self.isSimulator, "LAContext().setCredential(...) call is not supported on iOS Simulator.")
        try XCTSkipIf(!Self.biometricTestsSupported, "This test requires PIN setup on the device")
        let userId = "Test User Id 2"
        let challenge = "challenge"
        let expiration = Date().addingTimeInterval(60.0)
        let kid = UUID().uuidString
        
        let authenticator = ApplicationPinDeviceAuthenticator(pinCollector: PinCollectorMock())
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: "description"))
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
    
    
    func test_03_generateKeys() throws {
        try XCTSkipIf(!Self.biometricTestsSupported, "This test requires PIN setup on the device")
        let userId = "Test User Id 3"
        let cryptoKey = CryptoKey(keyId: userId)
        let key = cryptoKey.keyAlias
        
        let authenticator = ApplicationPinDeviceAuthenticator(pinCollector: PinCollectorMock())
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: "description"))
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
    
    
    func test_05_sign_with_userKey_customClaims() throws {
        try XCTSkipIf(self.isSimulator, "LAContext().setCredential(...) call is not supported on iOS Simulator.")
        try XCTSkipIf(!Self.biometricTestsSupported, "This test requires PIN setup on the device")
        let userId = "Test User Id 2"
        let challenge = "challenge"
        let expiration = Date().addingTimeInterval(60.0)
        let kid = UUID().uuidString
        let lastUpdatedDate = Date()
        let customClaims: [String : Any] = ["deviceId": "DEVICE_ID", "isCompanyPhone": true, "lastUpdated": Int(lastUpdatedDate.timeIntervalSince1970)]
        
        let authenticator = ApplicationPinDeviceAuthenticator(pinCollector: PinCollectorMock())
        authenticator.initialize(userId: userId, prompt: Prompt(title: "", subtitle: "", description: "description"))
        do {
            let keyPair = try authenticator.generateKeys()
            let userKey = UserKey(id: CryptoKey.getKeyAlias(keyName: userId), userId: userId, userName: "username", kid: kid, authType: .applicationPin, createdAt: Date().timeIntervalSince1970)
            let jwsString = try authenticator.sign(userKey: userKey, challenge: challenge, expiration: expiration, customClaims: customClaims)
            
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
            XCTAssertEqual(messageDictionary["deviceId"] as? String, "DEVICE_ID")
            XCTAssertEqual(messageDictionary["isCompanyPhone"] as? Bool, true)
            XCTAssertEqual(messageDictionary["lastUpdated"] as? Int, Int(lastUpdatedDate.timeIntervalSince1970))
            
        } catch {
            XCTFail("Failed to verify JWS signature")
        }
        let cryptoKey = CryptoKey(keyId: userId)
        cryptoKey.deleteKeys()
    }
    
    
    
    class PinCollectorMock: PinCollector {
        func collectPin(prompt: Prompt, completion: @escaping (String?) -> Void) {
            completion("1234")
        }
    }
}
