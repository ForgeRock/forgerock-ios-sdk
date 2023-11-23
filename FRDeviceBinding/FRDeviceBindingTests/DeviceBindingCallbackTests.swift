// 
//  DeviceBindingCallbackTests.swift
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

class DeviceBindingCallbackTests: FRAuthBaseTest {
    
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
    
    func getJsonString(userIdKey: String = "userId",
                       userId: String = "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config",
                       usernameKey: String = "username",
                       username: String = "demo",
                       authenticationTypeKey: String = "authenticationType",
                       authenticationType: DeviceBindingAuthenticationType = .none,
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
                       deviceNameKey: String = "IDToken1deviceName",
                       deviceName: String = "",
                       deviceIdKey: String = "IDToken1deviceId",
                       deviceId: String = "",
                       clientErrorKey: String = "IDToken1clientError",
                       clientError: String = "") -> String {
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "\(userIdKey)",
                    "value": "\(userId)"
                },
                {
                    "name": "\(usernameKey)",
                    "value": "\(username)"
                },
                {
                    "name": "\(authenticationTypeKey)",
                    "value": "\(authenticationType.rawValue)"
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
                    "name": "\(deviceNameKey)",
                    "value": "\(deviceName)"
                },
                {
                    "name": "\(deviceIdKey)",
                    "value": "\(deviceId)"
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
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_02_callback_construction_successful() {
        let userId = "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
        let username = "demo"
        let authenticationType = DeviceBindingAuthenticationType(rawValue: "NONE")!
        let challenge = "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
        let title = "Authentication required"
        let subtitle = "Cryptography device binding"
        let description = "Please complete with biometric to proceed"
        let timeout = 60
        let jwsKey = "IDToken1jws"
        let deviceNameKey = "IDToken1deviceName"
        let deviceIdKey = "IDToken1deviceId"
        let clientErrorKey = "IDToken1clientError"
        
        let jsonStr = getJsonString(userId: userId,
                                    username: username,
                                    authenticationType: authenticationType,
                                    challenge: challenge,
                                    title: title,
                                    subtitle: subtitle,
                                    description: description,
                                    timeout: timeout,
                                    jwsKey: jwsKey,
                                    deviceNameKey: deviceNameKey,
                                    deviceIdKey: deviceIdKey,
                                    clientErrorKey: clientErrorKey)
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            
            XCTAssertNotNil(callback)
            XCTAssertEqual(callback.userId, userId)
            XCTAssertEqual(callback.userName, username)
            XCTAssertEqual(callback.deviceBindingAuthenticationType, authenticationType)
            XCTAssertEqual(callback.challenge, challenge)
            XCTAssertEqual(callback.title, title)
            XCTAssertEqual(callback.subtitle, subtitle)
            XCTAssertEqual(callback.promptDescription, description)
            XCTAssertEqual(callback.timeout, timeout)
            
            XCTAssertTrue(callback.inputNames.contains(jwsKey))
            XCTAssertTrue(callback.inputNames.contains(deviceNameKey))
            XCTAssertTrue(callback.inputNames.contains(deviceIdKey))
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
            let _ = try DeviceBindingCallback(json: callbackResponse)
            XCTFail("Initiating DeviceBindingCallback with invalid JSON was successful")
        }
        catch let error as AuthError {
            switch error {
                // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing userId")
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_04_missing_username_value() {
        let jsonStr = getJsonString(usernameKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try DeviceBindingCallback(json: callbackResponse)
            XCTFail("Initiating DeviceBindingCallback with invalid JSON was successful")
        }
        catch let error as AuthError {
            switch error {
                // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing username")
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_05_missing_authenticationType_value() {
        let jsonStr = getJsonString(authenticationTypeKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try DeviceBindingCallback(json: callbackResponse)
            XCTFail("Initiating DeviceBindingCallback with invalid JSON was successful")
        }
        catch let error as AuthError {
            switch error {
                // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing authenticationType")
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_06_missing_challenge_value() {
        let jsonStr = getJsonString(challengeKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try DeviceBindingCallback(json: callbackResponse)
            XCTFail("Initiating DeviceBindingCallback with invalid JSON was successful")
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
    
    
    func test_07_missing_title_value() {
        let jsonStr = getJsonString(titleKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try DeviceBindingCallback(json: callbackResponse)
            XCTFail("Initiating DeviceBindingCallback with invalid JSON was successful")
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
    
    
    func test_08_missing_subtitle_value() {
        let jsonStr = getJsonString(subtitleKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try DeviceBindingCallback(json: callbackResponse)
            XCTFail("Initiating DeviceBindingCallback with invalid JSON was successful")
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
    
    
    func test_09_missing_description_value() {
        let jsonStr = getJsonString(descriptionKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try DeviceBindingCallback(json: callbackResponse)
            XCTFail("Initiating DeviceBindingCallback with invalid JSON was successful")
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
    
    
    func test_10_missing_timeout_value() {
        let jsonStr = getJsonString(timeoutKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
        }
        catch {
            XCTFail("Failed to construct callback with missing timeout: \(callbackResponse)")
        }
    }
    
    
    func test_11_missing_jwsKey_value() {
        let jsonStr = getJsonString(jwsKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try DeviceBindingCallback(json: callbackResponse)
            XCTFail("Initiating DeviceBindingCallback with invalid JSON was successful")
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
    
    
    func test_12_missing_deviceNameKey_value() {
        let jsonStr = getJsonString(deviceNameKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try DeviceBindingCallback(json: callbackResponse)
            XCTFail("Initiating DeviceBindingCallback with invalid JSON was successful")
        }
        catch let error as AuthError {
            switch error {
                // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing deviceNameKey")
            default:
                XCTFail("Failed with unexpected error: \(error)")
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_13_missing_deviceIdKey_value() {
        let jsonStr = getJsonString(deviceIdKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try DeviceBindingCallback(json: callbackResponse)
            XCTFail("Initiating DeviceBindingCallback with invalid JSON was successful")
        }
        catch let error as AuthError {
            switch error {
                // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing deviceIdKey")
            default:
                XCTFail("Failed with unexpected error: \(error)")
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_14_missing_clientErrorKey_value() {
        let jsonStr = getJsonString(clientErrorKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try DeviceBindingCallback(json: callbackResponse)
            XCTFail("Initializing DeviceBindingCallback with invalid JSON was successful")
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
    
    
    func test_15_validate_building_response() {
        let jws = "JWS"
        let deviceId = "DeviceId"
        let deviceName = "DeviceName"
        let clientError = "ClientError"
        
        let jsonStrWithoutInputValues = getJsonString()
        let jsonStrWithInputValues = getJsonString(jws: jws,
                                                   deviceName: deviceName,
                                                   deviceId: deviceId,
                                                   clientError: clientError)
        let callbackResponse1 = self.parseStringToDictionary(jsonStrWithoutInputValues)
        let callbackResponse2 = self.parseStringToDictionary(jsonStrWithInputValues)
        
        do {
            let callback1 = try DeviceBindingCallback(json: callbackResponse1)
            XCTAssertNotNil(callback1)
            
            callback1.setJws(jws)
            callback1.setDeviceId(deviceId)
            callback1.setDeviceName(deviceName)
            callback1.setClientError(clientError)
            
            let response1 = callback1.buildResponse()
            
            XCTAssertTrue(response1["type"] as! String == callbackResponse2["type"] as! String)
            //XCTAssertTrue(response1["output"] as! [[String : Any]] == callbackResponse2["output"] as! [[String : Any]])
            
            let input1 = (response1["input"]  as! [[String : String]]).sorted{$0["name"]! > $1["name"]!}
            let input2 = (callbackResponse2["input"] as! [[String : String]]).sorted{$0["name"]! > $1["name"]!}
            XCTAssertTrue(input1 == input2)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse1)")
        }
    }
    
    func test_16_getExpiration() {
        let jsonStr = getJsonString()
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            let expiration = callback.getExpiration(timeout: callback.timeout)
            XCTAssertGreaterThanOrEqual(Date().addingTimeInterval(Double(callback.timeout ?? 60)), expiration)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_17_getDeviceBindingAuthenticator_None() {
        let jsonStr = getJsonString(authenticationType: .none)
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            let noneAuthenticator = callback.getDeviceAuthenticator(type: .none)
            XCTAssertTrue(noneAuthenticator is None)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_18_getDeviceBindingAuthenticator_BiometricOnly() {
        let jsonStr = getJsonString(authenticationType: .biometricOnly)
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            let biometricOnlyAuthenticator = callback.getDeviceAuthenticator(type: .biometricOnly)
            
            XCTAssertNotNil(callback)
            XCTAssertTrue(biometricOnlyAuthenticator is BiometricOnly)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_19_getDeviceBindingAuthenticator_BiometricAndDeviceCredential() {
        let jsonStr = getJsonString(authenticationType: .biometricAllowFallback)
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            let biometricAllowFallbackAuthenticator = callback.getDeviceAuthenticator(type: .biometricAllowFallback)
            XCTAssertTrue(biometricAllowFallbackAuthenticator is BiometricAndDeviceCredential)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_19_1_getDeviceBindingAuthenticator_ApplicationPin() {
        let jsonStr = getJsonString(authenticationType: .applicationPin)
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            let applicationPinAuthenticator = callback.getDeviceAuthenticator(type: .applicationPin)
            XCTAssertTrue(applicationPinAuthenticator is ApplicationPinDeviceAuthenticator)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_20_execute_success() throws {
        // Skip the test on iOS 15 Simulator due to the bug when private key generation fails with Access Control Flags set
        // https://stackoverflow.com/questions/69279715/ios-15-xcode-13-cannot-generate-private-key-on-simulator-running-ios-15-with-s
        try XCTSkipIf(self.isSimulator && isIOS15, "on iOS 15 Simulator private key generation fails with Access Control Flags set")
        
        
        let jsonStr = getJsonString(authenticationType: .none)
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            callback.execute(deviceId: "DeviceId") { result in
                switch result {
                case .success:
                    XCTAssertTrue(callback.inputValues.count == 2)
                case .failure(let error):
                    XCTFail("Callback Execute failed: \(error.errorMessage)")
                }
            }
            let cryptoKey = CryptoKey(keyId: callback.userId)
            cryptoKey.deleteKeys()
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_21_execute_fail_timeout() throws {
        // Skip the test on iOS 15 Simulator due to the bug when private key generation fails with Access Control Flags set
        // https://stackoverflow.com/questions/69279715/ios-15-xcode-13-cannot-generate-private-key-on-simulator-running-ios-15-with-s
        try XCTSkipIf(self.isSimulator && isIOS15, "on iOS 15 Simulator private key generation fails with Access Control Flags set")
        
        let jsonStr = getJsonString(authenticationType: .none,
                                    timeout: 0)
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            callback.execute(deviceId: "DeviceId") { result in
                switch result {
                case .success:
                    XCTFail("Callback Execute succeeded instead of timeout")
                case .failure(let error):
                    XCTAssertEqual(error.clientError, DeviceBindingStatus.timeout.clientError)
                    XCTAssertTrue(callback.inputValues.count == 1)
                }
            }
            let cryptoKey = CryptoKey(keyId: callback.userId)
            cryptoKey.deleteKeys()
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_22_execute_custom_not_supported() {
        let jsonStr = getJsonString(authenticationType: .biometricAllowFallback)
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            callback.execute(authInterface: CustomAuthenticatorUnsupported(cryptoKey: CryptoKey(keyId: callback.userId)), deviceId: "DeviceId") { result in
                switch result {
                case .success:
                    XCTFail("Callback Execute succeeded instead of unsupported")
                case .failure(let error):
                    XCTAssertEqual(error.clientError, DeviceBindingStatus.unsupported(errorMessage: "").clientError)
                    XCTAssertTrue(callback.inputValues.count == 1)
                }
            }
            let cryptoKey = CryptoKey(keyId: callback.userId)
            cryptoKey.deleteKeys()
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_23_execute_custom_generate_keys_failed() {
        let jsonStr = getJsonString(authenticationType: .biometricAllowFallback)
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            callback.execute(authInterface: CustomAuthenticatorGenerateKeysFailed(cryptoKey: CryptoKey(keyId: callback.userId)), deviceId: "DeviceId") { result in
                switch result {
                case .success:
                    XCTFail("Callback Execute succeeded instead of unsupported")
                case .failure(let error):
                    XCTAssertEqual(error.clientError, DeviceBindingStatus.abort.clientError)
                    XCTAssertTrue(callback.inputValues.count == 1)
                }
            }
            let cryptoKey = CryptoKey(keyId: callback.userId)
            cryptoKey.deleteKeys()
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_24_execute_custom_sign_failed() {
        let jsonStr = getJsonString(authenticationType: .biometricAllowFallback)
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            callback.execute(authInterface: CustomAuthenticatorSignFailed(cryptoKey: CryptoKey(keyId: callback.userId)), deviceId: "DeviceId") { result in
                switch result {
                case .success:
                    XCTFail("Callback Execute succeeded instead of unsupported")
                case .failure(let error):
                    XCTAssertEqual(error.clientError, DeviceBindingStatus.abort.clientError)
                    XCTAssertTrue(callback.inputValues.count == 1)
                }
            }
            let cryptoKey = CryptoKey(keyId: callback.userId)
            cryptoKey.deleteKeys()
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_25_execute_custom_aborted() {
        let jsonStr = getJsonString(authenticationType: .biometricAllowFallback)
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            callback.execute(authInterface: CustomAuthenticatorAborted(cryptoKey: CryptoKey(keyId: callback.userId)), deviceId: "DeviceId") { result in
                switch result {
                case .success:
                    XCTFail("Callback Execute succeeded instead of aborted")
                case .failure(let error):
                    XCTAssertEqual(error.clientError, DeviceBindingStatus.abort.clientError)
                    XCTAssertTrue(callback.inputValues.count == 1)
                }
            }
            let cryptoKey = CryptoKey(keyId: callback.userId)
            cryptoKey.deleteKeys()
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_26_bind_customDeviceBindingIdentifier() throws {
        // Skip the test on iOS 15 Simulator due to the bug when private key generation fails with Access Control Flags set
        // https://stackoverflow.com/questions/69279715/ios-15-xcode-13-cannot-generate-private-key-on-simulator-running-ios-15-with-s
        try XCTSkipIf(self.isSimulator && isIOS15, "on iOS 15 Simulator private key generation fails with Access Control Flags set")
        
        let jsonStr = getJsonString(authenticationType: .biometricAllowFallback)
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            let customDeviceBindingIdentifier: (DeviceBindingAuthenticationType) -> DeviceAuthenticator =  { type in
                return CustomDeviceAuthenticator(cryptoKey: CryptoKey(keyId: callback.userId))
            }
            let expectation = self.expectation(description: "Device Binding")
            callback.bind(deviceAuthenticator: customDeviceBindingIdentifier) { result in
                switch result {
                    
                case .success:
                    XCTAssertTrue((callback.inputValues["IDToken1jws"] as? String) == "CUSTOM_JWS")
                case .failure(let error):
                    XCTFail("Callback Execute failed: \(error.errorMessage)")
                }
                expectation.fulfill()
            }
            let cryptoKey = CryptoKey(keyId: callback.userId)
            cryptoKey.deleteKeys()
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
}


struct CustomAuthenticatorUnsupported: DeviceAuthenticator {
    var cryptoKey: CryptoKey
    
    init(cryptoKey: CryptoKey) {
        self.cryptoKey = cryptoKey
    }
    
    func generateKeys() throws -> KeyPair {
        let keyBuilderQuery = cryptoKey.keyBuilderQuery()
        return try cryptoKey.createKeyPair(builderQuery: keyBuilderQuery)
    }
    func isSupported() -> Bool {
        return false
    }
    
    func accessControl() -> SecAccessControl? {
        return nil
    }
    
    func type() -> DeviceBindingAuthenticationType {
        return .none
    }
    
    func deleteKeys() {
        cryptoKey.deleteKeys()
    }
}


struct CustomAuthenticatorGenerateKeysFailed: DeviceAuthenticator {
    var cryptoKey: CryptoKey
    
    init(cryptoKey: CryptoKey) {
        self.cryptoKey = cryptoKey
    }
    
    func generateKeys() throws -> KeyPair {
        throw NSError(domain: "domain", code: 1)
    }
    func isSupported() -> Bool {
        return true
    }
    
    func accessControl() -> SecAccessControl? {
        return nil
    }
    
    func type() -> DeviceBindingAuthenticationType {
        return .none
    }
    
    func deleteKeys() {
        cryptoKey.deleteKeys()
    }
}


struct CustomAuthenticatorSignFailed: DeviceAuthenticator {
    var cryptoKey: CryptoKey
    
    init(cryptoKey: CryptoKey) {
        self.cryptoKey = cryptoKey
    }
    
    func generateKeys() throws -> KeyPair {
        let keyBuilderQuery = cryptoKey.keyBuilderQuery()
        return try cryptoKey.createKeyPair(builderQuery: keyBuilderQuery)
    }
    func isSupported() -> Bool {
        return true
    }
    
    func accessControl() -> SecAccessControl? {
        return nil
    }
    
    func sign(keyPair: KeyPair, kid: String, userId: String, challenge: String, expiration: Date, customClaims: [String: Any]) throws -> String {
        throw NSError(domain: "domain", code: 1)
    }
    
    func type() -> DeviceBindingAuthenticationType {
        return .none
    }
    
    func deleteKeys() {
        cryptoKey.deleteKeys()
    }
}


struct CustomAuthenticatorAborted: DeviceAuthenticator {
    var cryptoKey: CryptoKey
    
    init(cryptoKey: CryptoKey) {
        self.cryptoKey = cryptoKey
    }
    
    func generateKeys() throws -> KeyPair {
        let keyBuilderQuery = cryptoKey.keyBuilderQuery()
        return try cryptoKey.createKeyPair(builderQuery: keyBuilderQuery)
    }
    func isSupported() -> Bool {
        return true
    }
    
    func accessControl() -> SecAccessControl? {
        return nil
    }
    
    func sign(keyPair: KeyPair, kid: String, userId: String, challenge: String, expiration: Date, customClaims: [String: Any]) throws -> String {
        throw JOSESwiftError.localAuthenticationFailed(errorCode: 1)
    }
    
    func type() -> DeviceBindingAuthenticationType {
        return .none
    }
    
    func deleteKeys() {
        cryptoKey.deleteKeys()
    }
}


struct CustomDeviceAuthenticator: DeviceAuthenticator {
    var cryptoKey: CryptoKey
    
    init(cryptoKey: CryptoKey) {
        self.cryptoKey = cryptoKey
    }
    
    func generateKeys() throws -> KeyPair {
        let keyBuilderQuery = cryptoKey.keyBuilderQuery()
        return try cryptoKey.createKeyPair(builderQuery: keyBuilderQuery)
    }
    func isSupported() -> Bool {
        return true
    }
    
    func accessControl() -> SecAccessControl? {
        return nil
    }
    
    func sign(keyPair: KeyPair, kid: String, userId: String, challenge: String, expiration: Date, customClaims: [String: Any]) throws -> String {
        return "CUSTOM_JWS"
    }
    
    func sign(userKey: UserKey, challenge: String, expiration: Date, customClaims: [String: Any]) throws -> String {
        return "CUSTOM_JWS"
    }
    
    func type() -> DeviceBindingAuthenticationType {
        return .none
    }
    
    func deleteKeys() {
        cryptoKey.deleteKeys()
    }
}
