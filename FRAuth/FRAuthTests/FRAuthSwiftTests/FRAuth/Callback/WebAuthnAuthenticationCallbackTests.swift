// 
//  WebAuthnAuthenticationCallbackTests.swift
//  FRAuthTests
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

class WebAuthnAuthenticationCallbackTests: FRAuthBaseTest {

    //  MARK: - AM 7.0.0 Response: Valid Callback with configurations
    
    func test_01_default_authentication_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "userVerification": "preferred",
                    "_type": "WebAuthn",
                    "challenge": "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc=",
                    "relyingPartyId": "rpId: \"com.forgerock.ios\",",
                    "allowCredentials": "allowCredentials: [{ \"type\": \"public-key\", \"id\": new Int8Array([-87, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]).buffer }]",
                    "timeout": "60000"
                }
            }]
        }
        """
        //  Due to parsing issue from script string into proper JSON, manually construct JSON
        var callbackResponse: [String: Any] = [:]
        callbackResponse["type"] = "MetadataCallback"
        var output: [String: Any] = [:]
        output["name"] = "data"
        var outputValue: [String: Any] = [:]
        outputValue["userVerification"] = "preferred"
        outputValue["_type"] = "WebAuthn"
        outputValue["challenge"] = "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc="
        outputValue["relyingPartyId"] = "rpId: \"com.forgerock.ios\","
        outputValue["allowCredentials"] = "allowCredentials: [{ \"type\": \"public-key\", \"id\": new Int8Array([-87, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]).buffer }]"
        outputValue["timeout"] = "60000"
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        let allowedCredential: [UInt8] = [UInt8(bitPattern: Int8(-87)), UInt8(bitPattern: Int8(55)), UInt8(bitPattern: Int8(-118)), UInt8(bitPattern: Int8(-125)), UInt8(bitPattern: Int8(-94)), UInt8(bitPattern: Int8(76)), UInt8(bitPattern: Int8(75)), UInt8(bitPattern: Int8(-30)), UInt8(bitPattern: Int8(-68)), UInt8(bitPattern: Int8(20)), UInt8(bitPattern: Int8(-108)), UInt8(bitPattern: Int8(53)), UInt8(bitPattern: Int8(-80)), UInt8(bitPattern: Int8(-17)), UInt8(bitPattern: Int8(89)), UInt8(bitPattern: Int8(33))]
        
        // When
        do {
            let callback = try WebAuthnAuthenticationCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            
            //  Not nil
            XCTAssertNotNil(callback._type)
            XCTAssertNotNil(callback.userVerification)
            XCTAssertNotNil(callback.challenge)
            XCTAssertNotNil(callback.relyingPartyId)
            XCTAssertNotNil(callback.allowCredentials)
            XCTAssertNotNil(callback.timeout)
            
            //  Equal
            XCTAssertEqual(callback._type, "WebAuthn")
            XCTAssertEqual(callback.userVerification, .preferred)
            XCTAssertEqual(callback.challenge, "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc=")
            XCTAssertEqual(callback.relyingPartyId, "com.forgerock.ios")
            XCTAssertEqual(callback.allowCredentials.count, 1)
            XCTAssertEqual(callback.allowCredentials.first, allowedCredential)
            XCTAssertEqual(callback.timeout, 60000)
            XCTAssertEqual(callback.isNewJSONFormat, false)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_02_multiple_credentials_authentication_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "userVerification": "required",
                    "_type": "WebAuthn",
                    "challenge": "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc=",
                    "relyingPartyId": "rpId: \"com.forgerock.ios\",",
                    "allowCredentials": "allowCredentials: [{ \"type\": \"public-key\", \"id\": new Int8Array([89, -32, 62, -85, 125, -10, 76, 60, -86, 112, -56, 123, 92, -38, 63, -118]).buffer },{ \"type\": \"public-key\", \"id\": new Int8Array([-87, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]).buffer }]",
                    "timeout": "60000"
                }
            }]
        }
        """
        //  Due to parsing issue from script string into proper JSON, manually construct JSON
        var callbackResponse: [String: Any] = [:]
        callbackResponse["type"] = "MetadataCallback"
        var output: [String: Any] = [:]
        output["name"] = "data"
        var outputValue: [String: Any] = [:]
        outputValue["userVerification"] = "required"
        outputValue["_type"] = "WebAuthn"
        outputValue["challenge"] = "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc="
        outputValue["relyingPartyId"] = "rpId: \"com.forgerock.ios\","
        outputValue["allowCredentials"] = "allowCredentials: [{ \"type\": \"public-key\", \"id\": new Int8Array([89, -32, 62, -85, 125, -10, 76, 60, -86, 112, -56, 123, 92, -38, 63, -118]).buffer },{ \"type\": \"public-key\", \"id\": new Int8Array([-87, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]).buffer }]"
        outputValue["timeout"] = "60000"
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let callback = try WebAuthnAuthenticationCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            
            //  Not nil
            XCTAssertNotNil(callback._type)
            XCTAssertNotNil(callback.userVerification)
            XCTAssertNotNil(callback.challenge)
            XCTAssertNotNil(callback.relyingPartyId)
            XCTAssertNotNil(callback.allowCredentials)
            XCTAssertNotNil(callback.timeout)
            
            //  Equal
            XCTAssertEqual(callback._type, "WebAuthn")
            XCTAssertEqual(callback.userVerification, .required)
            XCTAssertEqual(callback.challenge, "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc=")
            XCTAssertEqual(callback.relyingPartyId, "com.forgerock.ios")
            XCTAssertEqual(callback.allowCredentials.count, 2)
            XCTAssertEqual(callback.timeout, 60000)
            XCTAssertEqual(callback.isNewJSONFormat, false)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_03_empty_credentials_authentication_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "userVerification": "discouraged",
                    "_type": "WebAuthn",
                    "challenge": "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc=",
                    "relyingPartyId": "rpId: \"com.forgerock.ios\",",
                    "allowCredentials": "",
                    "timeout": "6000"
                }
            }]
        }
        """
        //  Due to parsing issue from script string into proper JSON, manually construct JSON
        var callbackResponse: [String: Any] = [:]
        callbackResponse["type"] = "MetadataCallback"
        var output: [String: Any] = [:]
        output["name"] = "data"
        var outputValue: [String: Any] = [:]
        outputValue["userVerification"] = "discouraged"
        outputValue["_type"] = "WebAuthn"
        outputValue["challenge"] = "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc="
        outputValue["relyingPartyId"] = "rpId: \"com.forgerock.ios\","
        outputValue["allowCredentials"] = ""
        outputValue["timeout"] = "6000"
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let callback = try WebAuthnAuthenticationCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            
            //  Not nil
            XCTAssertNotNil(callback._type)
            XCTAssertNotNil(callback.userVerification)
            XCTAssertNotNil(callback.challenge)
            XCTAssertNotNil(callback.relyingPartyId)
            XCTAssertNotNil(callback.allowCredentials)
            XCTAssertNotNil(callback.timeout)
            
            //  Equal
            XCTAssertEqual(callback._type, "WebAuthn")
            XCTAssertEqual(callback.userVerification, .discouraged)
            XCTAssertEqual(callback.challenge, "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc=")
            XCTAssertEqual(callback.relyingPartyId, "com.forgerock.ios")
            XCTAssertEqual(callback.allowCredentials.count, 0)
            XCTAssertEqual(callback.timeout, 6000)
            XCTAssertEqual(callback.isNewJSONFormat, false)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    //  MARK: - AM 7.0.0: Invalid Callback
    
    func test_04_invalid_user_verification_authentication_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "userVerification": "invalid",
                    "_type": "WebAuthn",
                    "challenge": "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc=",
                    "relyingPartyId": "rpId: \"com.forgerock.ios\",",
                    "allowCredentials": "",
                    "timeout": "6000"
                }
            }]
        }
        """
        //  Due to parsing issue from script string into proper JSON, manually construct JSON
        var callbackResponse: [String: Any] = [:]
        callbackResponse["type"] = "MetadataCallback"
        var output: [String: Any] = [:]
        output["name"] = "data"
        var outputValue: [String: Any] = [:]
        outputValue["userVerification"] = "invalid"
        outputValue["_type"] = "WebAuthn"
        outputValue["challenge"] = "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc="
        outputValue["relyingPartyId"] = "rpId: \"com.forgerock.ios\","
        outputValue["allowCredentials"] = ""
        outputValue["timeout"] = "6000"
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnAuthenticationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Missing userVerification"))
                break
            default:
                XCTFail("Invalid WebAuthnAuthenticationCallback failed with unexpected error: \(error.localizedDescription)")
                break
            }
        }
        catch {
            XCTFail("Invalid WebAuthnAuthenticationCallback failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    func test_05_invalid_timeout_verification_authentication_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "userVerification": "discouraged",
                    "_type": "WebAuthn",
                    "challenge": "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc=",
                    "relyingPartyId": "rpId: \"com.forgerock.ios\",",
                    "allowCredentials": ""
                }
            }]
        }
        """
        //  Due to parsing issue from script string into proper JSON, manually construct JSON
        var callbackResponse: [String: Any] = [:]
        callbackResponse["type"] = "MetadataCallback"
        var output: [String: Any] = [:]
        output["name"] = "data"
        var outputValue: [String: Any] = [:]
        outputValue["userVerification"] = "discouraged"
        outputValue["_type"] = "WebAuthn"
        outputValue["challenge"] = "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc="
        outputValue["relyingPartyId"] = "rpId: \"com.forgerock.ios\","
        outputValue["allowCredentials"] = ""
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnAuthenticationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Missing timeout"))
                break
            default:
                XCTFail("Invalid WebAuthnAuthenticationCallback failed with unexpected error: \(error.localizedDescription)")
                break
            }
        }
        catch {
            XCTFail("Invalid WebAuthnAuthenticationCallback failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_06_invalid_relying_party_id_authentication_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "userVerification": "discouraged",
                    "_type": "WebAuthn",
                    "challenge": "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc=",
                    "relyingPartyId": "com.forgerock.ios",
                    "allowCredentials": "",
                    "timeout": "6000"
                }
            }]
        }
        """
        //  Due to parsing issue from script string into proper JSON, manually construct JSON
        var callbackResponse: [String: Any] = [:]
        callbackResponse["type"] = "MetadataCallback"
        var output: [String: Any] = [:]
        output["name"] = "data"
        var outputValue: [String: Any] = [:]
        outputValue["userVerification"] = "discouraged"
        outputValue["_type"] = "WebAuthn"
        outputValue["challenge"] = "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc="
        outputValue["relyingPartyId"] = "com.forgerock.ios"
        outputValue["allowCredentials"] = ""
        outputValue["timeout"] = "6000"
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnAuthenticationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Invalid relying party identifier"))
                break
            default:
                XCTFail("Invalid WebAuthnAuthenticationCallback failed with unexpected error: \(error.localizedDescription)")
                break
            }
        }
        catch {
            XCTFail("Invalid WebAuthnAuthenticationCallback failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_07_missing_relying_party_id_authentication_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "userVerification": "discouraged",
                    "_type": "WebAuthn",
                    "challenge": "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc=",
                    "allowCredentials": "",
                    "timeout": "6000"
                }
            }]
        }
        """
        //  Due to parsing issue from script string into proper JSON, manually construct JSON
        var callbackResponse: [String: Any] = [:]
        callbackResponse["type"] = "MetadataCallback"
        var output: [String: Any] = [:]
        output["name"] = "data"
        var outputValue: [String: Any] = [:]
        outputValue["userVerification"] = "discouraged"
        outputValue["_type"] = "WebAuthn"
        outputValue["challenge"] = "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc="
        outputValue["allowCredentials"] = ""
        outputValue["timeout"] = "6000"
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnAuthenticationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Missing relyingPartyId"))
                break
            default:
                XCTFail("Invalid WebAuthnAuthenticationCallback failed with unexpected error: \(error.localizedDescription)")
                break
            }
        }
        catch {
            XCTFail("Invalid WebAuthnAuthenticationCallback failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_08_invalid_allowed_credentials_id_authentication_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "userVerification": "discouraged",
                    "_type": "WebAuthn",
                    "challenge": "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc=",
                    "relyingPartyId": "rpId: \"com.forgerock.ios\",",
                    "allowCredentials": "allowCredentials: [{ \"type\": \"public-key\", \"id\": new Int8Array([999, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]).buffer }]",
                    "timeout": "6000"
                }
            }]
        }
        """
        //  Due to parsing issue from script string into proper JSON, manually construct JSON
        var callbackResponse: [String: Any] = [:]
        callbackResponse["type"] = "MetadataCallback"
        var output: [String: Any] = [:]
        output["name"] = "data"
        var outputValue: [String: Any] = [:]
        outputValue["userVerification"] = "discouraged"
        outputValue["_type"] = "WebAuthn"
        outputValue["challenge"] = "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc="
        outputValue["relyingPartyId"] = "rpId: \"com.forgerock.ios\","
        outputValue["allowCredentials"] = "allowCredentials: [{ \"type\": \"public-key\", \"id\": new Int8Array([999, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]).buffer }]"
        outputValue["timeout"] = "6000"
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnAuthenticationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Invalid allowCredentials byte"))
                break
            default:
                XCTFail("Invalid WebAuthnAuthenticationCallback failed with unexpected error: \(error.localizedDescription)")
                break
            }
        }
        catch {
            XCTFail("Invalid WebAuthnAuthenticationCallback failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_09_missing_allowed_credentials_id_authentication_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "userVerification": "discouraged",
                    "_type": "WebAuthn",
                    "challenge": "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc=",
                    "relyingPartyId": "rpId: \"com.forgerock.ios\",",
                    "timeout": "6000"
                }
            }]
        }
        """
        //  Due to parsing issue from script string into proper JSON, manually construct JSON
        var callbackResponse: [String: Any] = [:]
        callbackResponse["type"] = "MetadataCallback"
        var output: [String: Any] = [:]
        output["name"] = "data"
        var outputValue: [String: Any] = [:]
        outputValue["userVerification"] = "discouraged"
        outputValue["_type"] = "WebAuthn"
        outputValue["challenge"] = "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc="
        outputValue["relyingPartyId"] = "rpId: \"com.forgerock.ios\","
        outputValue["timeout"] = "6000"
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnAuthenticationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Missing allowCredentials"))
                break
            default:
                XCTFail("Invalid WebAuthnAuthenticationCallback failed with unexpected error: \(error.localizedDescription)")
                break
            }
        }
        catch {
            XCTFail("Invalid WebAuthnAuthenticationCallback failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_10_missing_challenge_authentication_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "userVerification": "discouraged",
                    "_type": "WebAuthn",
                    "relyingPartyId": "rpId: \"com.forgerock.ios\",",
                    "allowCredentials": "allowCredentials: [{ \"type\": \"public-key\", \"id\": new Int8Array([999, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]).buffer }]",
                    "timeout": "6000"
                }
            }]
        }
        """
        //  Due to parsing issue from script string into proper JSON, manually construct JSON
        var callbackResponse: [String: Any] = [:]
        callbackResponse["type"] = "MetadataCallback"
        var output: [String: Any] = [:]
        output["name"] = "data"
        var outputValue: [String: Any] = [:]
        outputValue["userVerification"] = "discouraged"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "rpId: \"com.forgerock.ios\","
        outputValue["allowCredentials"] = "allowCredentials: [{ \"type\": \"public-key\", \"id\": new Int8Array([999, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]).buffer }]"
        outputValue["timeout"] = "6000"
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnAuthenticationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Missing challenge"))
                break
            default:
                XCTFail("Invalid WebAuthnAuthenticationCallback failed with unexpected error: \(error.localizedDescription)")
                break
            }
        }
        catch {
            XCTFail("Invalid WebAuthnAuthenticationCallback failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_11_missing_type_authentication_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "userVerification": "discouraged",
                    "challenge": "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc=",
                    "relyingPartyId": "rpId: \"com.forgerock.ios\",",
                    "allowCredentials": "allowCredentials: [{ \"type\": \"public-key\", \"id\": new Int8Array([999, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]).buffer }]",
                    "timeout": "6000"
                }
            }]
        }
        """
        //  Due to parsing issue from script string into proper JSON, manually construct JSON
        var callbackResponse: [String: Any] = [:]
        callbackResponse["type"] = "MetadataCallback"
        var output: [String: Any] = [:]
        output["name"] = "data"
        var outputValue: [String: Any] = [:]
        outputValue["userVerification"] = "discouraged"
        outputValue["challenge"] = "OemzNzq+ggvrQWAmQQ5/JDxjanFapY+ZM/q2nnJCINc="
        outputValue["relyingPartyId"] = "rpId: \"com.forgerock.ios\","
        outputValue["allowCredentials"] = "allowCredentials: [{ \"type\": \"public-key\", \"id\": new Int8Array([999, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]).buffer }]"
        outputValue["timeout"] = "6000"
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnAuthenticationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Missing _type"))
                break
            default:
                XCTFail("Invalid WebAuthnAuthenticationCallback failed with unexpected error: \(error.localizedDescription)")
                break
            }
        }
        catch {
            XCTFail("Invalid WebAuthnAuthenticationCallback failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    //  MARK: - AM 7.1.0 Response: Valid Callback with configuration
    
    func test_12_AM71_default_authentication_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [
                {
                    "name": "data",
                    "value": {
                        "_action": "webauthn_authentication",
                        "challenge": "G5MMUCfoB2TGpdqmXNmPqkf3YxKL5uGURyOVvW8jjFQ=",
                    "allowCredentials": "allowCredentials: [{ \"type\": \"public-key\", \"id\": new Int8Array([-87, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]).buffer }]",
                        "_allowCredentials": [
                            {
                                "type": "public-key",
                                "id": [-87, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]
                            }
                        ],
                        "timeout": "60000",
                        "userVerification": "preferred",
                        "relyingPartyId": "rpId: \"com.forgerock.ios\",",
                        "_relyingPartyId": "com.forgerock.ios",
                        "_type": "WebAuthn"
                    }
                }
            ]
        }
        """
        //  Due to parsing issue from script string into proper JSON, manually construct JSON
        var callbackResponse: [String: Any] = [:]
        callbackResponse["type"] = "MetadataCallback"
        var output: [String: Any] = [:]
        output["name"] = "data"
        var outputValue: [String: Any] = [:]
        outputValue["userVerification"] = "preferred"
        outputValue["_type"] = "WebAuthn"
        outputValue["challenge"] = "G5MMUCfoB2TGpdqmXNmPqkf3YxKL5uGURyOVvW8jjFQ="
        outputValue["relyingPartyId"] = "rpId: \"com.forgerock.ios\","
        outputValue["allowCredentials"] = "allowCredentials: [{ \"type\": \"public-key\", \"id\": new Int8Array([-87, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]).buffer }]"
        outputValue["timeout"] = "60000"
        
        //  AM 7.1.0 response
        outputValue["_action"] = "webauthn_authentication"
        outputValue["_relyingPartyId"] = "com.forgerock.ios"
        var allowedCredentials: [String: Any] = [:]
        allowedCredentials["type"] = "public-key"
        allowedCredentials["id"] = [-87, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]
        outputValue["_allowCredentials"] = [allowedCredentials]
        
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        let allowedCredential: [UInt8] = [UInt8(bitPattern: Int8(-87)), UInt8(bitPattern: Int8(55)), UInt8(bitPattern: Int8(-118)), UInt8(bitPattern: Int8(-125)), UInt8(bitPattern: Int8(-94)), UInt8(bitPattern: Int8(76)), UInt8(bitPattern: Int8(75)), UInt8(bitPattern: Int8(-30)), UInt8(bitPattern: Int8(-68)), UInt8(bitPattern: Int8(20)), UInt8(bitPattern: Int8(-108)), UInt8(bitPattern: Int8(53)), UInt8(bitPattern: Int8(-80)), UInt8(bitPattern: Int8(-17)), UInt8(bitPattern: Int8(89)), UInt8(bitPattern: Int8(33))]
        
        // When
        do {
            let callback = try WebAuthnAuthenticationCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            
            //  Not nil
            XCTAssertNotNil(callback._type)
            XCTAssertNotNil(callback.userVerification)
            XCTAssertNotNil(callback.challenge)
            XCTAssertNotNil(callback.relyingPartyId)
            XCTAssertNotNil(callback.allowCredentials)
            XCTAssertNotNil(callback.timeout)
            
            //  Equal
            XCTAssertEqual(callback._type, "WebAuthn")
            XCTAssertEqual(callback.userVerification, .preferred)
            XCTAssertEqual(callback.challenge, "G5MMUCfoB2TGpdqmXNmPqkf3YxKL5uGURyOVvW8jjFQ=")
            XCTAssertEqual(callback.relyingPartyId, "com.forgerock.ios")
            XCTAssertEqual(callback.allowCredentials.count, 1)
            XCTAssertEqual(callback.allowCredentials.first, allowedCredential)
            XCTAssertEqual(callback.timeout, 60000)
            XCTAssertEqual(callback.isNewJSONFormat, true)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_13_AM71_multiple_credentials_authentication_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [
                {
                    "name": "data",
                    "value": {
                        "_action": "webauthn_authentication",
                        "challenge": "G5MMUCfoB2TGpdqmXNmPqkf3YxKL5uGURyOVvW8jjFQ=",
                        "allowCredentials": "allowCredentials: [{ \"type\": \"public-key\", \"id\": new Int8Array([89, -32, 62, -85, 125, -10, 76, 60, -86, 112, -56, 123, 92, -38, 63, -118]).buffer },{ \"type\": \"public-key\", \"id\": new Int8Array([-87, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]).buffer }]",
                        "_allowCredentials": [
                            {
                                "type": "public-key",
                                "id": [-87, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]
                            }
                        ],
                        "timeout": "60000",
                        "userVerification": "preferred",
                        "relyingPartyId": "rpId: \"com.forgerock.ios\",",
                        "_relyingPartyId": "com.forgerock.ios",
                        "_type": "WebAuthn"
                    }
                }
            ]
        }
        """
        //  Due to parsing issue from script string into proper JSON, manually construct JSON
        var callbackResponse: [String: Any] = [:]
        callbackResponse["type"] = "MetadataCallback"
        var output: [String: Any] = [:]
        output["name"] = "data"
        var outputValue: [String: Any] = [:]
        outputValue["userVerification"] = "preferred"
        outputValue["_type"] = "WebAuthn"
        outputValue["challenge"] = "G5MMUCfoB2TGpdqmXNmPqkf3YxKL5uGURyOVvW8jjFQ="
        outputValue["relyingPartyId"] = "rpId: \"com.forgerock.ios\","
        outputValue["allowCredentials"] = "allowCredentials: [{ \"type\": \"public-key\", \"id\": new Int8Array([89, -32, 62, -85, 125, -10, 76, 60, -86, 112, -56, 123, 92, -38, 63, -118]).buffer },{ \"type\": \"public-key\", \"id\": new Int8Array([-87, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]).buffer }]"
        outputValue["timeout"] = "60000"
        
        //  AM 7.1.0 response
        outputValue["_action"] = "webauthn_authentication"
        outputValue["_relyingPartyId"] = "com.forgerock.ios"
        var allowedCredentials: [String: Any] = [:]
        allowedCredentials["type"] = "public-key"
        allowedCredentials["id"] = [89, -32, 62, -85, 125, -10, 76, 60, -86, 112, -56, 123, 92, -38, 63, -118]
        var allowedCredentials2: [String: Any] = [:]
        allowedCredentials2["type"] = "public-key"
        allowedCredentials2["id"] = [-87, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]
        outputValue["_allowCredentials"] = [allowedCredentials, allowedCredentials2]
        
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let callback = try WebAuthnAuthenticationCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            
            //  Not nil
            XCTAssertNotNil(callback._type)
            XCTAssertNotNil(callback.userVerification)
            XCTAssertNotNil(callback.challenge)
            XCTAssertNotNil(callback.relyingPartyId)
            XCTAssertNotNil(callback.allowCredentials)
            XCTAssertNotNil(callback.timeout)
            
            //  Equal
            XCTAssertEqual(callback._type, "WebAuthn")
            XCTAssertEqual(callback.userVerification, .preferred)
            XCTAssertEqual(callback.challenge, "G5MMUCfoB2TGpdqmXNmPqkf3YxKL5uGURyOVvW8jjFQ=")
            XCTAssertEqual(callback.relyingPartyId, "com.forgerock.ios")
            XCTAssertEqual(callback.allowCredentials.count, 2)
            XCTAssertEqual(callback.timeout, 60000)
            XCTAssertEqual(callback.isNewJSONFormat, true)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_14_AM71_empty_credentials_authentication_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [
                {
                    "name": "data",
                    "value": {
                        "_action": "webauthn_authentication",
                        "challenge": "G5MMUCfoB2TGpdqmXNmPqkf3YxKL5uGURyOVvW8jjFQ=",
                        "allowCredentials": "",
                        "_allowCredentials": [],
                        "timeout": "60000",
                        "userVerification": "preferred",
                        "relyingPartyId": "rpId: \"com.forgerock.ios\",",
                        "_relyingPartyId": "com.forgerock.ios",
                        "_type": "WebAuthn"
                    }
                }
            ]
        }
        """
        //  Due to parsing issue from script string into proper JSON, manually construct JSON
        var callbackResponse: [String: Any] = [:]
        callbackResponse["type"] = "MetadataCallback"
        var output: [String: Any] = [:]
        output["name"] = "data"
        var outputValue: [String: Any] = [:]
        outputValue["userVerification"] = "preferred"
        outputValue["_type"] = "WebAuthn"
        outputValue["challenge"] = "G5MMUCfoB2TGpdqmXNmPqkf3YxKL5uGURyOVvW8jjFQ="
        outputValue["relyingPartyId"] = "rpId: \"com.forgerock.ios\","
        outputValue["allowCredentials"] = ""
        outputValue["timeout"] = "60000"
        
        //  AM 7.1.0 response
        outputValue["_action"] = "webauthn_authentication"
        outputValue["_relyingPartyId"] = "com.forgerock.ios"
        outputValue["_allowCredentials"] = []
        
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let callback = try WebAuthnAuthenticationCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            
            //  Not nil
            XCTAssertNotNil(callback._type)
            XCTAssertNotNil(callback.userVerification)
            XCTAssertNotNil(callback.challenge)
            XCTAssertNotNil(callback.relyingPartyId)
            XCTAssertNotNil(callback.allowCredentials)
            XCTAssertNotNil(callback.timeout)
            
            //  Equal
            XCTAssertEqual(callback._type, "WebAuthn")
            XCTAssertEqual(callback.userVerification, .preferred)
            XCTAssertEqual(callback.challenge, "G5MMUCfoB2TGpdqmXNmPqkf3YxKL5uGURyOVvW8jjFQ=")
            XCTAssertEqual(callback.relyingPartyId, "com.forgerock.ios")
            XCTAssertEqual(callback.allowCredentials.count, 0)
            XCTAssertEqual(callback.timeout, 60000)
            XCTAssertEqual(callback.isNewJSONFormat, true)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    //  MARK: - AM 7.1.0 Specific Response: Invalid Callback validation
    
    func test_15_AM71_missing_credentials_authentication_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [
                {
                    "name": "data",
                    "value": {
                        "_action": "webauthn_authentication",
                        "challenge": "G5MMUCfoB2TGpdqmXNmPqkf3YxKL5uGURyOVvW8jjFQ=",
                        "timeout": "60000",
                        "userVerification": "preferred",
                        "relyingPartyId": "rpId: \"com.forgerock.ios\",",
                        "_relyingPartyId": "com.forgerock.ios",
                        "_type": "WebAuthn"
                    }
                }
            ]
        }
        """
        //  Due to parsing issue from script string into proper JSON, manually construct JSON
        var callbackResponse: [String: Any] = [:]
        callbackResponse["type"] = "MetadataCallback"
        var output: [String: Any] = [:]
        output["name"] = "data"
        var outputValue: [String: Any] = [:]
        outputValue["userVerification"] = "preferred"
        outputValue["_type"] = "WebAuthn"
        outputValue["challenge"] = "G5MMUCfoB2TGpdqmXNmPqkf3YxKL5uGURyOVvW8jjFQ="
        outputValue["relyingPartyId"] = "rpId: \"com.forgerock.ios\","
        outputValue["timeout"] = "60000"
        
        //  AM 7.1.0 response
        outputValue["_action"] = "webauthn_authentication"
        outputValue["_relyingPartyId"] = "com.forgerock.ios"
        
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnAuthenticationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Missing allowCredentials"))
                break
            default:
                XCTFail("Invalid WebAuthnAuthenticationCallback failed with unexpected error: \(error.localizedDescription)")
                break
            }
        }
        catch {
            XCTFail("Invalid WebAuthnAuthenticationCallback failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_16_AM71_missing_relying_party_id_authentication_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [
                {
                    "name": "data",
                    "value": {
                        "_action": "webauthn_authentication",
                        "challenge": "G5MMUCfoB2TGpdqmXNmPqkf3YxKL5uGURyOVvW8jjFQ=",
                        "allowCredentials": "",
                        "_allowCredentials": [],
                        "timeout": "60000",
                        "userVerification": "preferred",
                        "_type": "WebAuthn"
                    }
                }
            ]
        }
        """
        //  Due to parsing issue from script string into proper JSON, manually construct JSON
        var callbackResponse: [String: Any] = [:]
        callbackResponse["type"] = "MetadataCallback"
        var output: [String: Any] = [:]
        output["name"] = "data"
        var outputValue: [String: Any] = [:]
        outputValue["userVerification"] = "preferred"
        outputValue["_type"] = "WebAuthn"
        outputValue["challenge"] = "G5MMUCfoB2TGpdqmXNmPqkf3YxKL5uGURyOVvW8jjFQ="
        outputValue["allowCredentials"] = ""
        outputValue["timeout"] = "60000"
        
        //  AM 7.1.0 response
        outputValue["_action"] = "webauthn_authentication"
        outputValue["_allowCredentials"] = []
        
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnAuthenticationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Missing relyingPartyId"))
                break
            default:
                XCTFail("Invalid WebAuthnAuthenticationCallback failed with unexpected error: \(error.localizedDescription)")
                break
            }
        }
        catch {
            XCTFail("Invalid WebAuthnAuthenticationCallback failed with unexpected error: \(error.localizedDescription)")
        }
    }
}
