// 
//  DeviceBindingCallbackTests.swift
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

class DeviceBindingCallbackTests: FRAuthBaseTest {
    
    func test_01_basic_init() {
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "NONE"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
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
        
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "\(userId)"
                },
                {
                    "name": "username",
                    "value": "\(username)"
                },
                {
                    "name": "authenticationType",
                    "value": "\(authenticationType.rawValue)"
                },
                {
                    "name": "challenge",
                    "value": "\(challenge)"
                },
                {
                    "name": "title",
                    "value": "\(title)"
                },
                {
                    "name": "subtitle",
                    "value": "\(subtitle)"
                },
                {
                    "name": "description",
                    "value": "\(description)"
                },
                {
                    "name": "timeout",
                    "value": \(timeout)
                }
            ],
            "input": [
                {
                    "name": "\(jwsKey)",
                    "value": ""
                },
                {
                    "name": "\(deviceNameKey)",
                    "value": ""
                },
                {
                    "name": "\(deviceIdKey)",
                    "value": ""
                },
                {
                    "name": "\(clientErrorKey)",
                    "value": ""
                }
            ]
        }
        """
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
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "NONE"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
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
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "authenticationType",
                    "value": "NONE"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
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
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
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
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "NONE"
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
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
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "NONE"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
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
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "NONE"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
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
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "NONE"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
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
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "NONE"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                }
                        
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
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
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "NONE"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
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
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "NONE"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
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
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "NONE"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
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
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "NONE"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                }
            ]
        }
        """
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
        
        let jsonStrWithoutInputValues = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "NONE"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
        let jsonStrWithInputValues = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "NONE"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": "\(jws)"
                },
                {
                    "name": "IDToken1deviceName",
                    "value": "\(deviceName)"
                },
                {
                    "name": "IDToken1deviceId",
                    "value": "\(deviceId)"
                },
                {
                    "name": "IDToken1clientError",
                    "value": "\(clientError)"
                }
            ]
        }
        """
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
            XCTAssertTrue(response1["output"] as! [[String : Any]] == callbackResponse2["output"] as! [[String : Any]])
            
            let input1 = (response1["input"]  as! [[String : String]]).sorted{$0["name"]! > $1["name"]!}
            let input2 = (callbackResponse2["input"] as! [[String : String]]).sorted{$0["name"]! > $1["name"]!}
            XCTAssertTrue(input1 == input2)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse1)")
        }
    }
    
    func test_16_getExpiration() {
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "NONE"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            let expiration = callback.getExpiration()
            XCTAssertGreaterThanOrEqual(Date().addingTimeInterval(Double(callback.timeout ?? 60)), expiration)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_17_getDeviceBindingAuthenticator_None() {
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "NONE"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            let noneAuthenticator = callback.getDeviceBindingAuthenticator()
            XCTAssertTrue(noneAuthenticator is None)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_18_getDeviceBindingAuthenticator_BiometricOnly() {
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "BIOMETRIC_ONLY"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            let noneAuthenticator = callback.getDeviceBindingAuthenticator()
            
            XCTAssertNotNil(callback)
            XCTAssertTrue(noneAuthenticator is BiometricOnly)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_19_getDeviceBindingAuthenticator_BiometricAndDeviceCredential() {
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "BIOMETRIC_ALLOW_FALLBACK"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            let noneAuthenticator = callback.getDeviceBindingAuthenticator()
            XCTAssertTrue(noneAuthenticator is BiometricAndDeviceCredential)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_20_execute_success() {
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "BIOMETRIC_ALLOW_FALLBACK"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            callback.execute(authInterface: nil, deviceId: "DeviceId") { result in
                switch result {
                case .success:
                    XCTAssertTrue(callback.inputValues.count == 2)
                case .failure(let error):
                    XCTFail("Callback Execute failed: \(error.errorMessage)")
                }
            }
            KeyAware.deleteKey(keyAlias: KeyAware.getKeyAlias(keyName: callback.userId))
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_21_execute_fail_timeout() {
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "BIOMETRIC_ALLOW_FALLBACK"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 0
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            callback.execute(authInterface: nil, deviceId: "DeviceId") { result in
                switch result {
                case .success:
                    XCTFail("Callback Execute succeeded instead of timeout")
                case .failure(let error):
                    XCTAssertEqual(error.clientError, DeviceBindingStatus.timeout.clientError)
                    XCTAssertTrue(callback.inputValues.count == 1)
                }
            }
            KeyAware.deleteKey(keyAlias: KeyAware.getKeyAlias(keyName: callback.userId))
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_22_execute_custom_not_supported() {
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "BIOMETRIC_ALLOW_FALLBACK"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            callback.execute(authInterface: CustomAuthenticatorUnsupported(keyAware: KeyAware(userId: callback.userId)), deviceId: "DeviceId") { result in
                switch result {
                case .success:
                    XCTFail("Callback Execute succeeded instead of unsupported")
                case .failure(let error):
                    XCTAssertEqual(error.clientError, DeviceBindingStatus.unsupported(errorMessage: "").clientError)
                    XCTAssertTrue(callback.inputValues.count == 1)
                }
            }
            KeyAware.deleteKey(keyAlias: KeyAware.getKeyAlias(keyName: callback.userId))
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_23_execute_custom_generate_keys_failed() {
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "BIOMETRIC_ALLOW_FALLBACK"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            callback.execute(authInterface: CustomAuthenticatorGenerateKeysFailed(keyAware: KeyAware(userId: callback.userId)), deviceId: "DeviceId") { result in
                switch result {
                case .success:
                    XCTFail("Callback Execute succeeded instead of unsupported")
                case .failure(let error):
                    XCTAssertEqual(error.clientError, DeviceBindingStatus.unsupported(errorMessage: "").clientError)
                    XCTAssertTrue(callback.inputValues.count == 1)
                }
            }
            KeyAware.deleteKey(keyAlias: KeyAware.getKeyAlias(keyName: callback.userId))
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_24_execute_custom_sign_failed() {
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "BIOMETRIC_ALLOW_FALLBACK"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            callback.execute(authInterface: CustomAuthenticatorSignFailed(keyAware: KeyAware(userId: callback.userId)), deviceId: "DeviceId") { result in
                switch result {
                case .success:
                    XCTFail("Callback Execute succeeded instead of unsupported")
                case .failure(let error):
                    XCTAssertEqual(error.clientError, DeviceBindingStatus.unsupported(errorMessage: "").clientError)
                    XCTAssertTrue(callback.inputValues.count == 1)
                }
            }
            KeyAware.deleteKey(keyAlias: KeyAware.getKeyAlias(keyName: callback.userId))
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_25_execute_custom_aborted() {
        let jsonStr = """
        {
            "type": "DeviceBindingCallback",
            "output": [
                {
                    "name": "userId",
                    "value": "id=b8f68f20-312c-4e52-b835-f0518cddc648,ou=user,o=alpha,ou=services,ou=am-config"
                },
                {
                    "name": "username",
                    "value": "vahan"
                },
                {
                    "name": "authenticationType",
                    "value": "BIOMETRIC_ALLOW_FALLBACK"
                },
                {
                    "name": "challenge",
                    "value": "uPbJ4E58qPAQJn4zyN7PI5NwKEibZzd6NnPHOhYLOJo="
                },
                {
                    "name": "title",
                    "value": "Authentication required"
                },
                {
                    "name": "subtitle",
                    "value": "Cryptography device binding"
                },
                {
                    "name": "description",
                    "value": "Please complete with biometric to proceed"
                },
                {
                    "name": "timeout",
                    "value": 60
                }
            ],
            "input": [
                {
                    "name": "IDToken1jws",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceName",
                    "value": ""
                },
                {
                    "name": "IDToken1deviceId",
                    "value": ""
                },
                {
                    "name": "IDToken1clientError",
                    "value": ""
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try DeviceBindingCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            callback.execute(authInterface: CustomAuthenticatorAborted(keyAware: KeyAware(userId: callback.userId)), deviceId: "DeviceId") { result in
                switch result {
                case .success:
                    XCTFail("Callback Execute succeeded instead of aborted")
                case .failure(let error):
                    XCTAssertEqual(error.clientError, DeviceBindingStatus.abort.clientError)
                    XCTAssertTrue(callback.inputValues.count == 1)
                }
            }
            KeyAware.deleteKey(keyAlias: KeyAware.getKeyAlias(keyName: callback.userId))
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
}


struct CustomAuthenticatorUnsupported: DeviceAuthenticator {
    var keyAware: KeyAware
    
    init(keyAware: KeyAware) {
        self.keyAware = keyAware
    }
    
    func generateKeys() throws -> KeyPair {
        let keyBuilderQuery = keyAware.keyBuilderQuery()
        return try keyAware.createKeyPair(builderQuery: keyBuilderQuery)
    }
    func isSupported() -> Bool {
        return false
    }
    
    func accessControl() -> SecAccessControl? {
        return nil
    }
}


struct CustomAuthenticatorGenerateKeysFailed: DeviceAuthenticator {
    var keyAware: KeyAware
    
    init(keyAware: KeyAware) {
        self.keyAware = keyAware
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
}


struct CustomAuthenticatorSignFailed: DeviceAuthenticator {
    var keyAware: KeyAware
    
    init(keyAware: KeyAware) {
        self.keyAware = keyAware
    }
    
    func generateKeys() throws -> KeyPair {
        let keyBuilderQuery = keyAware.keyBuilderQuery()
        return try keyAware.createKeyPair(builderQuery: keyBuilderQuery)
    }
    func isSupported() -> Bool {
        return true
    }
    
    func accessControl() -> SecAccessControl? {
        return nil
    }
    
    func sign(keyPair: KeyPair, kid: String, userId: String, challenge: String, expiration: Date) throws -> String {
        throw NSError(domain: "domain", code: 1)
    }
}


struct CustomAuthenticatorAborted: DeviceAuthenticator {
    var keyAware: KeyAware
    
    init(keyAware: KeyAware) {
        self.keyAware = keyAware
    }
    
    func generateKeys() throws -> KeyPair {
        let keyBuilderQuery = keyAware.keyBuilderQuery()
        return try keyAware.createKeyPair(builderQuery: keyBuilderQuery)
    }
    func isSupported() -> Bool {
        return true
    }
    
    func accessControl() -> SecAccessControl? {
        return nil
    }
    
    func sign(keyPair: KeyPair, kid: String, userId: String, challenge: String, expiration: Date) throws -> String {
        throw JOSESwiftError.localAuthenticationFailed(errorCode: 1)
    }
}
