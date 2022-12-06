// 
//  DeviceSigningVerifierCallbackTests.swift
//  FRAuthTests
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

class DeviceSigningVerifierCallbackTests: FRAuthBaseTest {
    
    func getJsonString(userIdKey: String = "userId",
                       userId: String = "",
                       challengeKey: String = "challenge",
                       challenge: String = "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo=",
                       titleKey: String = "title",
                       title: String = "Authentication required",
                       subtitleKey: String = "subtitle",
                       subtitle: String = "Cryptography device binding",
                       descriptionKey: String = "description",
                       description: String = "Please complete with biometric to proceed",
                       timeoutKey: String = "timeout",
                       timeout: Int = 60,
                       jwsKey: String = "IDToken1jws",
                       jws: String = "",
                       clientErrorKey: String = "IDToken1clientError",
                       clientError: String = "") -> String {
        let jsonStr = """
        {
            "type": "DeviceSigningVerifierCallback",
            "output": [
                {
                    "name": "\(userIdKey)",
                    "value": "\(userId)"
                },
                {
                    "name": "\(challengeKey)",
                    "value": "\(challenge)"
                },
                {
                    "name": "\(titleKey)",
                    "value": "\(title)"
                },
                {
                    "name": "\(subtitleKey)",
                    "value": "\(subtitle)"
                },
                {
                    "name": "\(descriptionKey)",
                    "value": "\(description)"
                },
                {
                    "name": "\(timeoutKey)",
                    "value": \(timeout)
                }
            ],
            "input": [
                {
                    "name": "\(jwsKey)",
                    "value": "\(jws)"
                },
                {
                    "name": "\(clientErrorKey)",
                    "value": "\(clientError)"
                }
            ]
        }
        """
        return jsonStr
    }
    
    
    func test_01_basic_init() {
        let jsonStr = getJsonString()
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceSigningVerifierCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_02_callback_construction_successful() {
        let userId = "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
        let challenge = "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
        let title = "Authentication required"
        let subtitle = "Cryptography device binding"
        let description = "Please complete with biometric to proceed"
        let timeout = 60
        let jwsKey = "IDToken1jws"
        let clientErrorKey = "IDToken1clientError"
        
        let jsonStr = getJsonString(userId: userId,
                                    challenge: challenge,
                                    title: title,
                                    subtitle: subtitle,
                                    description: description,
                                    timeout: timeout,
                                    jwsKey: jwsKey,
                                    clientErrorKey: clientErrorKey)
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceSigningVerifierCallback(json: callbackResponse)
            
            XCTAssertNotNil(callback)
            XCTAssertEqual(callback.userId, userId)
            XCTAssertEqual(callback.challenge, challenge)
            XCTAssertEqual(callback.title, title)
            XCTAssertEqual(callback.subtitle, subtitle)
            XCTAssertEqual(callback.promptDescription, description)
            XCTAssertEqual(callback.timeout, timeout)
            
            XCTAssertTrue(callback.inputNames.contains(jwsKey))
            XCTAssertTrue(callback.inputNames.contains(clientErrorKey))
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_03_missing_userId_value() {
        let jsonStr = getJsonString(userIdKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceSigningVerifierCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
        }
        catch {
            XCTFail("Failed to construct callback with missing userId: \(callbackResponse)")
        }
    }
    
    
    func test_04_missing_challenge_value() {
        let jsonStr = getJsonString(challengeKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try DeviceSigningVerifierCallback(json: callbackResponse)
            XCTFail("Initiating DeviceSigningVerifierCallback with invalid JSON was successful")
        }
        catch let error as AuthError {
            switch error {
                // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing challenge")
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_05_missing_title_value() {
        let jsonStr = getJsonString(titleKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try DeviceSigningVerifierCallback(json: callbackResponse)
            XCTFail("Initiating DeviceSigningVerifierCallback with invalid JSON was successful")
        }
        catch let error as AuthError {
            switch error {
                // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing title")
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_06_missing_subtitle_value() {
        let jsonStr = getJsonString(subtitleKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try DeviceSigningVerifierCallback(json: callbackResponse)
            XCTFail("Initiating DeviceSigningVerifierCallback with invalid JSON was successful")
        }
        catch let error as AuthError {
            switch error {
                // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing subtitle")
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_07_missing_description_value() {
        let jsonStr = getJsonString(descriptionKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try DeviceSigningVerifierCallback(json: callbackResponse)
            XCTFail("Initiating DeviceSigningVerifierCallback with invalid JSON was successful")
        }
        catch let error as AuthError {
            switch error {
                // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing description")
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_08_missing_timeout_value() {
        let jsonStr = getJsonString(timeoutKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceSigningVerifierCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
        }
        catch {
            XCTFail("Failed to construct callback with missing timeout: \(callbackResponse)")
        }
    }
    
    
    func test_09_missing_jwsKey_value() {
        let jsonStr = getJsonString(jwsKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try DeviceSigningVerifierCallback(json: callbackResponse)
            XCTFail("Initiating DeviceSigningVerifierCallback with invalid JSON was successful")
        }
        catch let error as AuthError {
            switch error {
                // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing jwsKey")
            default:
                XCTFail("Failed with unexpected error: \(error)")
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_10_missing_clientErrorKey_value() {
        let jsonStr = getJsonString(clientErrorKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try DeviceSigningVerifierCallback(json: callbackResponse)
            XCTFail("Initializing DeviceSigningVerifierCallback with invalid JSON was successful")
        }
        catch let error as AuthError {
            switch error {
                // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing clientErrorKey")
            default:
                XCTFail("Failed with unexpected error: \(error)")
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_11_validate_building_response() {
        let jws = "JWS"
        let clientError = "ClientError"
        
        let jsonStrWithoutInputValues = getJsonString()
        let jsonStrWithInputValues = getJsonString(jws: jws,
                                                   clientError: clientError)
        let callbackResponse1 = self.parseStringToDictionary(jsonStrWithoutInputValues)
        let callbackResponse2 = self.parseStringToDictionary(jsonStrWithInputValues)
        
        do {
            let callback1 = try DeviceSigningVerifierCallback(json: callbackResponse1)
            XCTAssertNotNil(callback1)
            
            callback1.setJws(jws)
            callback1.setClientError(clientError)
            
            let response1 = callback1.buildResponse()
            
            XCTAssertTrue(response1["type"] as! String == callbackResponse2["type"] as! String)
            XCTAssertTrue(response1["output"] as! [[String : Any]] == callbackResponse2["output"] as! [[String : Any]])
            
            let input1 = (response1["input"]  as! [[String : String]]).sorted{$0["name"]! > $1["name"]!}
            let input2 = (callbackResponse2["input"] as! [[String : String]]).sorted{$0["name"]! > $1["name"]!}
            XCTAssertTrue(input1 == input2)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse1)")
        }
    }
    
    
    func test_12_getExpiration() {
        let jsonStr = getJsonString()
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceSigningVerifierCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            let expiration = callback.getExpiration()
            XCTAssertGreaterThanOrEqual(Date().addingTimeInterval(Double(callback.timeout ?? 60)), expiration)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_13_getDeviceBindingAuthenticator_None() {
        let jsonStr = getJsonString()
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceSigningVerifierCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            let userKey = UserKey(userId: "", userName: "", kid: "", authType: .none, keyAlias: "")
            let noneAuthenticator = callback.getDeviceBindingAuthenticator(userKey: userKey)
            XCTAssertTrue(noneAuthenticator is None)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_14_getDeviceBindingAuthenticator_BiometricOnly() {
        let jsonStr = getJsonString()
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceSigningVerifierCallback(json: callbackResponse)
            
            let userKey = UserKey(userId: "", userName: "", kid: "", authType: .biometricOnly, keyAlias: "")
            let noneAuthenticator = callback.getDeviceBindingAuthenticator(userKey: userKey)
            
            XCTAssertNotNil(callback)
            XCTAssertTrue(noneAuthenticator is BiometricOnly)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_15_getDeviceBindingAuthenticator_BiometricAndDeviceCredential() {
        let jsonStr = getJsonString()
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceSigningVerifierCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            let userKey = UserKey(userId: "", userName: "", kid: "", authType: .biometricAllowFallback, keyAlias: "")
            let noneAuthenticator = callback.getDeviceBindingAuthenticator(userKey: userKey)
            XCTAssertTrue(noneAuthenticator is BiometricAndDeviceCredential)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_16_getUserKey() {
        let jsonStr = getJsonString()
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceSigningVerifierCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            let delegate = CustomDeviceSigningVerifierDelegate()
            callback.delegate = delegate
            
            let encryptedPreference = KeychainDeviceRepository(uuid: nil, keychainService: nil)
            let _ = encryptedPreference.deleteAllKeys()
            let _ = try? encryptedPreference.persist(userId: "User Id 1", userName: "User Name 1", key: "User Key 1", authenticationType: .none)
            let _ = try? encryptedPreference.persist(userId: "User Id 2", userName: "User Name 2", key: "User Key 2", authenticationType: .none)
            let userKeyService = UserDeviceKeyService(encryptedPreference: encryptedPreference)
            
            callback.getUserKey(userKeyService: userKeyService) { userkey in
                XCTAssertNotNil(userkey)
            }
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_17_execute_singleKeyFound() {
        // Skip the test on iOS 15 Simulator due to the bug when private key generation fails with Access Control Flags set
        // https://stackoverflow.com/questions/69279715/ios-15-xcode-13-cannot-generate-private-key-on-simulator-running-ios-15-with-s
#if targetEnvironment(simulator)
        if #available(iOS 15.0, *) {
            guard #available(iOS 16.0, *) else {
                return
            }
        }
#endif
        let jsonStr = getJsonString()
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceSigningVerifierCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            let delegate = CustomDeviceSigningVerifierDelegate()
            callback.delegate = delegate
            
            let keyAware = KeyAware(userId: "User Id 1")
            let keyPair = try keyAware.createKeyPair(builderQuery: keyAware.keyBuilderQuery())
            
            let encryptedPreference = KeychainDeviceRepository(uuid: nil, keychainService: nil)
            let _ = encryptedPreference.deleteAllKeys()
            
            let _ = try? encryptedPreference.persist(userId: "User Id 1", userName: "User Name 1", key: keyPair.keyAlias, authenticationType: .none)
            let userKeyService = UserDeviceKeyService(encryptedPreference: encryptedPreference)
            
            callback.execute(userKeyService: userKeyService) { result in
                switch result {
                case .success:
                    XCTAssertTrue(callback.inputValues.count == 1)
                case .failure(let error):
                    XCTFail("Callback Execute failed: \(error.errorMessage)")
                }
            }
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_18_execute_noKeysFound() {
        // Skip the test on iOS 15 Simulator due to the bug when private key generation fails with Access Control Flags set
        // https://stackoverflow.com/questions/69279715/ios-15-xcode-13-cannot-generate-private-key-on-simulator-running-ios-15-with-s
#if targetEnvironment(simulator)
        if #available(iOS 15.0, *) {
            guard #available(iOS 16.0, *) else {
                return
            }
        }
#endif
        let jsonStr = getJsonString()
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceSigningVerifierCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            let delegate = CustomDeviceSigningVerifierDelegate()
            callback.delegate = delegate
            
            let encryptedPreference = KeychainDeviceRepository(uuid: nil, keychainService: nil)
            let _ = encryptedPreference.deleteAllKeys()
            
            let userKeyService = UserDeviceKeyService(encryptedPreference: encryptedPreference)
            
            callback.execute(userKeyService: userKeyService) { result in
                switch result {
                case .success:
                    XCTFail("Should not succeed")
                case .failure(let error):
                    XCTAssertEqual(error.clientError, DeviceBindingStatus.unRegister.clientError)
                    XCTAssertTrue(callback.inputValues.count == 1)
                }
            }
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_19_execute_multipleKeysFound() {
        // Skip the test on iOS 15 Simulator due to the bug when private key generation fails with Access Control Flags set
        // https://stackoverflow.com/questions/69279715/ios-15-xcode-13-cannot-generate-private-key-on-simulator-running-ios-15-with-s
#if targetEnvironment(simulator)
        if #available(iOS 15.0, *) {
            guard #available(iOS 16.0, *) else {
                return
            }
        }
#endif
        let jsonStr = getJsonString()
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceSigningVerifierCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            let delegate = CustomDeviceSigningVerifierDelegate()
            callback.delegate = delegate
            
            let keyAware1 = KeyAware(userId: "User Id 1")
            let keyPair1 = try keyAware1.createKeyPair(builderQuery: keyAware1.keyBuilderQuery())
            
            let keyAware2 = KeyAware(userId: "User Id 2")
            let keyPair2 = try keyAware2.createKeyPair(builderQuery: keyAware2.keyBuilderQuery())
            
            let encryptedPreference = KeychainDeviceRepository(uuid: nil, keychainService: nil)
            let _ = encryptedPreference.deleteAllKeys()
            
            let _ = try? encryptedPreference.persist(userId: "User Id 1", userName: "User Name 1", key: keyPair1.keyAlias, authenticationType: .none)
            let _ = try? encryptedPreference.persist(userId: "User Id 2", userName: "User Name 2", key: keyPair2.keyAlias, authenticationType: .none)
            let userKeyService = UserDeviceKeyService(encryptedPreference: encryptedPreference)
            
            callback.execute(userKeyService: userKeyService) { result in
                switch result {
                case .success:
                    XCTAssertTrue(callback.inputValues.count == 1)
                case .failure(let error):
                    XCTFail("Callback Execute failed: \(error.errorMessage)")
                }
            }
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_20_execute_fail_timeout() {
        // Skip the test on iOS 15 Simulator due to the bug when private key generation fails with Access Control Flags set
        // https://stackoverflow.com/questions/69279715/ios-15-xcode-13-cannot-generate-private-key-on-simulator-running-ios-15-with-s
#if targetEnvironment(simulator)
        if #available(iOS 15.0, *) {
            guard #available(iOS 16.0, *) else {
                return
            }
        }
#endif
        let jsonStr = getJsonString(timeout: 0)
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceSigningVerifierCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            let delegate = CustomDeviceSigningVerifierDelegate()
            callback.delegate = delegate
            
            let keyAware = KeyAware(userId: "User Id 1")
            let keyPair = try keyAware.createKeyPair(builderQuery: keyAware.keyBuilderQuery())
            
            let encryptedPreference = KeychainDeviceRepository(uuid: nil, keychainService: nil)
            let _ = encryptedPreference.deleteAllKeys()
            
            let _ = try? encryptedPreference.persist(userId: "User Id 1", userName: "User Name 1", key: keyPair.keyAlias, authenticationType: .none)
            let userKeyService = UserDeviceKeyService(encryptedPreference: encryptedPreference)
            
            callback.execute(userKeyService: userKeyService) { result in
                switch result {
                case .success:
                    XCTFail("Callback Execute succeeded instead of timeout")
                case .failure(let error):
                    XCTAssertEqual(error.clientError, DeviceBindingStatus.timeout.clientError)
                    XCTAssertTrue(callback.inputValues.count == 1)
                }
            }
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    class CustomDeviceSigningVerifierDelegate: DeviceSigningVerifierDelegate {
        func selectUserKey(userKeys: [UserKey], selectionCallback: @escaping DeviceSigningVerifierKeySelectionCallback) {
            selectionCallback(userKeys.first)
        }
    }
}
