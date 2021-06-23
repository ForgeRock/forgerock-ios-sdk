// 
//  WebAuthnRegistrationCallbackTests.swift
//  FRAuthTests
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

class WebAuthnRegistrationCallbackTests: FRAuthBaseTest {

    //  MARK: - AM 7.0.0 Response: Valid Callback with configurations
    
    func test_01_default_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "attestationPreference": "none",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "_type": "WebAuthn",
                    "relyingPartyId": "id: \"com.forgerock.ios\",",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "authenticatorSelection": "{\"userVerification\":\"preferred\"}",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "timeout": "60000",
                    "excludeCredentials": "",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]",
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\"}"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let callback = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            
            //  Not nil
            XCTAssertNotNil(callback._type)
            XCTAssertNotNil(callback.relyingPartyName)
            XCTAssertNotNil(callback.attestationPreference)
            XCTAssertNotNil(callback.displayName)
            XCTAssertNotNil(callback.relyingPartyId)
            XCTAssertNotNil(callback.userName)
            XCTAssertNotNil(callback.userId)
            XCTAssertNotNil(callback.timeout)
            XCTAssertNotNil(callback.excludeCredentials)
            XCTAssertNotNil(callback.pubKeyCredParams)
            XCTAssertNotNil(callback.challenge)
            XCTAssertNotNil(callback.userVerification)
            XCTAssertNotNil(callback.requireResidentKey)
            XCTAssertNotNil(callback.authenticatorAttachment)
            
            //  Equal
            XCTAssertEqual(callback._type, "WebAuthn")
            XCTAssertEqual(callback.relyingPartyName, "ForgeRock")
            XCTAssertEqual(callback.attestationPreference, .none)
            XCTAssertEqual(callback.displayName, "527490d2-0d91-483e-bf0b-853ff3bb2447")
            XCTAssertEqual(callback.relyingPartyId, "com.forgerock.ios")
            XCTAssertEqual(callback.userName, "527490d2-0d91-483e-bf0b-853ff3bb2447")
            XCTAssertEqual(callback.userId, "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3")
            XCTAssertEqual(callback.timeout, 60000)
            XCTAssertEqual(callback.excludeCredentials.count, 0)
            XCTAssertEqual(callback.pubKeyCredParams.count, 2)
            XCTAssertEqual(callback.pubCredAlg.count, 2)
            XCTAssertEqual(callback.challenge, "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg=")
            XCTAssertEqual(callback.userVerification, .preferred)
            XCTAssertEqual(callback.requireResidentKey, false)
            XCTAssertEqual(callback.authenticatorAttachment, .unspecified)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_02_platform_authenticator_require_resident_key_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "attestationPreference": "none",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "_type": "WebAuthn",
                    "relyingPartyId": "id: \"com.forgerock.ios\",",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "authenticatorSelection": "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\",\"requireResidentKey\":true}",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "timeout": "60000",
                    "excludeCredentials": "",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]",
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\",\"requireResidentKey\":true}"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let callback = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            
            //  Not nil
            XCTAssertNotNil(callback._type)
            XCTAssertNotNil(callback.relyingPartyName)
            XCTAssertNotNil(callback.attestationPreference)
            XCTAssertNotNil(callback.displayName)
            XCTAssertNotNil(callback.relyingPartyId)
            XCTAssertNotNil(callback.userName)
            XCTAssertNotNil(callback.userId)
            XCTAssertNotNil(callback.timeout)
            XCTAssertNotNil(callback.excludeCredentials)
            XCTAssertNotNil(callback.pubKeyCredParams)
            XCTAssertNotNil(callback.challenge)
            XCTAssertNotNil(callback.userVerification)
            XCTAssertNotNil(callback.requireResidentKey)
            XCTAssertNotNil(callback.authenticatorAttachment)
            
            //  Equal
            XCTAssertEqual(callback._type, "WebAuthn")
            XCTAssertEqual(callback.relyingPartyName, "ForgeRock")
            XCTAssertEqual(callback.attestationPreference, .none)
            XCTAssertEqual(callback.displayName, "527490d2-0d91-483e-bf0b-853ff3bb2447")
            XCTAssertEqual(callback.relyingPartyId, "com.forgerock.ios")
            XCTAssertEqual(callback.userName, "527490d2-0d91-483e-bf0b-853ff3bb2447")
            XCTAssertEqual(callback.userId, "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3")
            XCTAssertEqual(callback.timeout, 60000)
            XCTAssertEqual(callback.excludeCredentials.count, 0)
            XCTAssertEqual(callback.pubKeyCredParams.count, 2)
            XCTAssertEqual(callback.pubCredAlg.count, 2)
            XCTAssertEqual(callback.challenge, "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg=")
            XCTAssertEqual(callback.userVerification, .preferred)
            XCTAssertEqual(callback.requireResidentKey, true)
            XCTAssertEqual(callback.authenticatorAttachment, .platform)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_03_required_uv_direct_attestation_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "attestationPreference": "direct",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "_type": "WebAuthn",
                    "relyingPartyId": "id: \"com.forgerock.ios\",",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "authenticatorSelection": "{\"userVerification\":\"required\"}",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "timeout": "60000",
                    "excludeCredentials": "",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]",
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "direct"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"required\"}"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let callback = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            
            //  Not nil
            XCTAssertNotNil(callback._type)
            XCTAssertNotNil(callback.relyingPartyName)
            XCTAssertNotNil(callback.attestationPreference)
            XCTAssertNotNil(callback.displayName)
            XCTAssertNotNil(callback.relyingPartyId)
            XCTAssertNotNil(callback.userName)
            XCTAssertNotNil(callback.userId)
            XCTAssertNotNil(callback.timeout)
            XCTAssertNotNil(callback.excludeCredentials)
            XCTAssertNotNil(callback.pubKeyCredParams)
            XCTAssertNotNil(callback.challenge)
            XCTAssertNotNil(callback.userVerification)
            XCTAssertNotNil(callback.requireResidentKey)
            XCTAssertNotNil(callback.authenticatorAttachment)
            
            //  Equal
            XCTAssertEqual(callback._type, "WebAuthn")
            XCTAssertEqual(callback.relyingPartyName, "ForgeRock")
            XCTAssertEqual(callback.attestationPreference, .direct)
            XCTAssertEqual(callback.displayName, "527490d2-0d91-483e-bf0b-853ff3bb2447")
            XCTAssertEqual(callback.relyingPartyId, "com.forgerock.ios")
            XCTAssertEqual(callback.userName, "527490d2-0d91-483e-bf0b-853ff3bb2447")
            XCTAssertEqual(callback.userId, "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3")
            XCTAssertEqual(callback.timeout, 60000)
            XCTAssertEqual(callback.excludeCredentials.count, 0)
            XCTAssertEqual(callback.pubKeyCredParams.count, 2)
            XCTAssertEqual(callback.pubCredAlg.count, 2)
            XCTAssertEqual(callback.challenge, "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg=")
            XCTAssertEqual(callback.userVerification, .required)
            XCTAssertEqual(callback.requireResidentKey, false)
            XCTAssertEqual(callback.authenticatorAttachment, .unspecified)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_04_discouraged_uv_indirect_attestation_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "attestationPreference": "indirect",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "_type": "WebAuthn",
                    "relyingPartyId": "id: \"com.forgerock.ios\",",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "authenticatorSelection": "{\"userVerification\":\"discouraged\"}",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "timeout": "60000",
                    "excludeCredentials": "",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]",
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["relyingPartyName"] = "ForgeRockTest"
        outputValue["attestationPreference"] = "indirect"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios.test\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"discouraged\"}"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let callback = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            
            //  Not nil
            XCTAssertNotNil(callback._type)
            XCTAssertNotNil(callback.relyingPartyName)
            XCTAssertNotNil(callback.attestationPreference)
            XCTAssertNotNil(callback.displayName)
            XCTAssertNotNil(callback.relyingPartyId)
            XCTAssertNotNil(callback.userName)
            XCTAssertNotNil(callback.userId)
            XCTAssertNotNil(callback.timeout)
            XCTAssertNotNil(callback.excludeCredentials)
            XCTAssertNotNil(callback.pubKeyCredParams)
            XCTAssertNotNil(callback.challenge)
            XCTAssertNotNil(callback.userVerification)
            XCTAssertNotNil(callback.requireResidentKey)
            XCTAssertNotNil(callback.authenticatorAttachment)
            
            //  Equal
            XCTAssertEqual(callback._type, "WebAuthn")
            XCTAssertEqual(callback.relyingPartyName, "ForgeRockTest")
            XCTAssertEqual(callback.attestationPreference, .indirect)
            XCTAssertEqual(callback.displayName, "527490d2-0d91-483e-bf0b-853ff3bb2447")
            XCTAssertEqual(callback.relyingPartyId, "com.forgerock.ios.test")
            XCTAssertEqual(callback.userName, "527490d2-0d91-483e-bf0b-853ff3bb2447")
            XCTAssertEqual(callback.userId, "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3")
            XCTAssertEqual(callback.timeout, 60000)
            XCTAssertEqual(callback.excludeCredentials.count, 0)
            XCTAssertEqual(callback.pubKeyCredParams.count, 2)
            XCTAssertEqual(callback.pubCredAlg.count, 2)
            XCTAssertEqual(callback.challenge, "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg=")
            XCTAssertEqual(callback.userVerification, .discouraged)
            XCTAssertEqual(callback.requireResidentKey, false)
            XCTAssertEqual(callback.authenticatorAttachment, .unspecified)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_05_cross_platform_authenticator_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "attestationPreference": "none",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "_type": "WebAuthn",
                    "relyingPartyId": "id: \"com.forgerock.ios\",",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "authenticatorSelection": "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"cross-platform\"}",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "timeout": "60000",
                    "excludeCredentials": "",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]",
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"cross-platform\"}"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Unsupported Authenticator Attachment type"))
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
    
    
    func test_06_single_pub_key_cred_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "attestationPreference": "direct",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "_type": "WebAuthn",
                    "relyingPartyId": "id: \"com.forgerock.ios\",",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "authenticatorSelection": "{\"userVerification\":\"required\"}",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "timeout": "60000",
                    "excludeCredentials": "",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -257 } ]",
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "direct"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"required\"}"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let callback = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            
            //  Not nil
            XCTAssertNotNil(callback._type)
            XCTAssertNotNil(callback.relyingPartyName)
            XCTAssertNotNil(callback.attestationPreference)
            XCTAssertNotNil(callback.displayName)
            XCTAssertNotNil(callback.relyingPartyId)
            XCTAssertNotNil(callback.userName)
            XCTAssertNotNil(callback.userId)
            XCTAssertNotNil(callback.timeout)
            XCTAssertNotNil(callback.excludeCredentials)
            XCTAssertNotNil(callback.pubKeyCredParams)
            XCTAssertNotNil(callback.challenge)
            XCTAssertNotNil(callback.userVerification)
            XCTAssertNotNil(callback.requireResidentKey)
            XCTAssertNotNil(callback.authenticatorAttachment)
            
            //  Equal
            XCTAssertEqual(callback._type, "WebAuthn")
            XCTAssertEqual(callback.relyingPartyName, "ForgeRock")
            XCTAssertEqual(callback.attestationPreference, .direct)
            XCTAssertEqual(callback.displayName, "527490d2-0d91-483e-bf0b-853ff3bb2447")
            XCTAssertEqual(callback.relyingPartyId, "com.forgerock.ios")
            XCTAssertEqual(callback.userName, "527490d2-0d91-483e-bf0b-853ff3bb2447")
            XCTAssertEqual(callback.userId, "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3")
            XCTAssertEqual(callback.timeout, 60000)
            XCTAssertEqual(callback.excludeCredentials.count, 0)
            XCTAssertEqual(callback.pubKeyCredParams.count, 1)
            XCTAssertEqual(callback.pubCredAlg.count, 1)
            XCTAssertEqual(callback.pubCredAlg.first, .rs256)
            XCTAssertEqual(callback.challenge, "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg=")
            XCTAssertEqual(callback.userVerification, .required)
            XCTAssertEqual(callback.requireResidentKey, false)
            XCTAssertEqual(callback.authenticatorAttachment, .unspecified)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_07_excluded_credentials_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "attestationPreference": "direct",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "_type": "WebAuthn",
                    "relyingPartyId": "id: \"com.forgerock.ios\",",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "authenticatorSelection": "{\"userVerification\":\"required\"}",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "timeout": "60000",
                    "excludeCredentials": "{ \"type\": \"public-key\", \"id\": new Int8Array([-37, 41, 3, -121, 85, 100, 67, -108, -79, -115, 37, -45, 48, 94, 71, 74]).buffer }",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]",
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "direct"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"required\"}"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = "{ \"type\": \"public-key\", \"id\": new Int8Array([-37, 41, 3, -121, 85, 100, 67, -108, -79, -115, 37, -45, 48, 94, 71, 74]).buffer }"
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        let excludeCredentials: [UInt8] = [UInt8(bitPattern: Int8(-37)), UInt8(bitPattern: Int8(41)), UInt8(bitPattern: Int8(3)), UInt8(bitPattern: Int8(-121)), UInt8(bitPattern: Int8(85)), UInt8(bitPattern: Int8(100)), UInt8(bitPattern: Int8(67)), UInt8(bitPattern: Int8(-108)), UInt8(bitPattern: Int8(-79)), UInt8(bitPattern: Int8(-115)), UInt8(bitPattern: Int8(37)), UInt8(bitPattern: Int8(-45)), UInt8(bitPattern: Int8(48)), UInt8(bitPattern: Int8(94)), UInt8(bitPattern: Int8(71)), UInt8(bitPattern: Int8(74))]
        
        // When
        do {
            let callback = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            
            //  Not nil
            XCTAssertNotNil(callback._type)
            XCTAssertNotNil(callback.relyingPartyName)
            XCTAssertNotNil(callback.attestationPreference)
            XCTAssertNotNil(callback.displayName)
            XCTAssertNotNil(callback.relyingPartyId)
            XCTAssertNotNil(callback.userName)
            XCTAssertNotNil(callback.userId)
            XCTAssertNotNil(callback.timeout)
            XCTAssertNotNil(callback.excludeCredentials)
            XCTAssertNotNil(callback.pubKeyCredParams)
            XCTAssertNotNil(callback.challenge)
            XCTAssertNotNil(callback.userVerification)
            XCTAssertNotNil(callback.requireResidentKey)
            XCTAssertNotNil(callback.authenticatorAttachment)
            
            //  Equal
            XCTAssertEqual(callback._type, "WebAuthn")
            XCTAssertEqual(callback.relyingPartyName, "ForgeRock")
            XCTAssertEqual(callback.attestationPreference, .direct)
            XCTAssertEqual(callback.displayName, "527490d2-0d91-483e-bf0b-853ff3bb2447")
            XCTAssertEqual(callback.relyingPartyId, "com.forgerock.ios")
            XCTAssertEqual(callback.userName, "527490d2-0d91-483e-bf0b-853ff3bb2447")
            XCTAssertEqual(callback.userId, "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3")
            XCTAssertEqual(callback.timeout, 60000)
            XCTAssertEqual(callback.excludeCredentials.count, 1)
            XCTAssertEqual(callback.excludeCredentials.first, excludeCredentials)
            XCTAssertEqual(callback.pubKeyCredParams.count, 2)
            XCTAssertEqual(callback.pubCredAlg.count, 2)
            XCTAssertEqual(callback.challenge, "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg=")
            XCTAssertEqual(callback.userVerification, .required)
            XCTAssertEqual(callback.requireResidentKey, false)
            XCTAssertEqual(callback.authenticatorAttachment, .unspecified)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_08_multiple_excluded_credentials_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "attestationPreference": "direct",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "_type": "WebAuthn",
                    "relyingPartyId": "id: \"com.forgerock.ios\",",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "authenticatorSelection": "{\"userVerification\":\"required\"}",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "timeout": "60000",
                    "excludeCredentials": "{ \"type\": \"public-key\", \"id\": new Int8Array([-8, -75, 121, 26, -95, 63, 65, 104, -114, -93, -5, 111, -14, 24, -113, -84]).buffer },{ \"type\": \"public-key\", \"id\": new Int8Array([-37, 41, 3, -121, 85, 100, 67, -108, -79, -115, 37, -45, 48, 94, 71, 74]).buffer }",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]",
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "direct"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"required\"}"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = "{ \"type\": \"public-key\", \"id\": new Int8Array([-8, -75, 121, 26, -95, 63, 65, 104, -114, -93, -5, 111, -14, 24, -113, -84]).buffer },{ \"type\": \"public-key\", \"id\": new Int8Array([-37, 41, 3, -121, 85, 100, 67, -108, -79, -115, 37, -45, 48, 94, 71, 74]).buffer }"
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let callback = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            
            //  Not nil
            XCTAssertNotNil(callback._type)
            XCTAssertNotNil(callback.relyingPartyName)
            XCTAssertNotNil(callback.attestationPreference)
            XCTAssertNotNil(callback.displayName)
            XCTAssertNotNil(callback.relyingPartyId)
            XCTAssertNotNil(callback.userName)
            XCTAssertNotNil(callback.userId)
            XCTAssertNotNil(callback.timeout)
            XCTAssertNotNil(callback.excludeCredentials)
            XCTAssertNotNil(callback.pubKeyCredParams)
            XCTAssertNotNil(callback.challenge)
            XCTAssertNotNil(callback.userVerification)
            XCTAssertNotNil(callback.requireResidentKey)
            XCTAssertNotNil(callback.authenticatorAttachment)
            
            //  Equal
            XCTAssertEqual(callback._type, "WebAuthn")
            XCTAssertEqual(callback.relyingPartyName, "ForgeRock")
            XCTAssertEqual(callback.attestationPreference, .direct)
            XCTAssertEqual(callback.displayName, "527490d2-0d91-483e-bf0b-853ff3bb2447")
            XCTAssertEqual(callback.relyingPartyId, "com.forgerock.ios")
            XCTAssertEqual(callback.userName, "527490d2-0d91-483e-bf0b-853ff3bb2447")
            XCTAssertEqual(callback.userId, "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3")
            XCTAssertEqual(callback.timeout, 60000)
            XCTAssertEqual(callback.excludeCredentials.count, 2)
            XCTAssertEqual(callback.pubKeyCredParams.count, 2)
            XCTAssertEqual(callback.pubCredAlg.count, 2)
            XCTAssertEqual(callback.challenge, "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg=")
            XCTAssertEqual(callback.userVerification, .required)
            XCTAssertEqual(callback.requireResidentKey, false)
            XCTAssertEqual(callback.authenticatorAttachment, .unspecified)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    //  MARK: - Both AM 7.0.0 / 7.1.0 Invalid Callback validation
    
    func test_09_missing_attestation_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "_type": "WebAuthn",
                    "relyingPartyId": "id: \"com.forgerock.ios\",",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "authenticatorSelection": "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "timeout": "60000",
                    "excludeCredentials": "",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]",
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Missing attestationPreference"))
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
    
    
    func test_10_missing_relying_party_name_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "attestationPreference": "none",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "_type": "WebAuthn",
                    "relyingPartyId": "id: \"com.forgerock.ios\",",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "authenticatorSelection": "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "timeout": "60000",
                    "excludeCredentials": "",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]",
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Missing relyingPartyName"))
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
    
    
    func test_11_missing_display_name_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "attestationPreference": "none",
                    "_type": "WebAuthn",
                    "relyingPartyId": "id: \"com.forgerock.ios\",",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "authenticatorSelection": "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "timeout": "60000",
                    "excludeCredentials": "",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]",
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Missing displayName"))
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
    
    
    func test_12_missing_user_name_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "attestationPreference": "none",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "_type": "WebAuthn",
                    "relyingPartyId": "id: \"com.forgerock.ios\",",
                    "authenticatorSelection": "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "timeout": "60000",
                    "excludeCredentials": "",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]",
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Missing userName"))
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
    
    
    func test_13_missing_user_id_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "attestationPreference": "none",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "_type": "WebAuthn",
                    "relyingPartyId": "id: \"com.forgerock.ios\",",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "authenticatorSelection": "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}",
                    "timeout": "60000",
                    "excludeCredentials": "",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]",
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Missing userId"))
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
    
    
    func test_14_type_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "attestationPreference": "none",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "relyingPartyId": "id: \"com.forgerock.ios\",",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "authenticatorSelection": "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "timeout": "60000",
                    "excludeCredentials": "",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]",
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Missing or invalid _type"))
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
    
    
    func test_15_missing_timeout_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "attestationPreference": "none",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "_type": "WebAuthn",
                    "relyingPartyId": "id: \"com.forgerock.ios\",",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "authenticatorSelection": "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "excludeCredentials": "",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]",
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["excludeCredentials"] = ""
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnRegistrationCallback(json: callbackResponse)
            
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
    
    
    func test_16_missing_challenge_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "attestationPreference": "none",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "_type": "WebAuthn",
                    "relyingPartyId": "id: \"com.forgerock.ios\",",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "authenticatorSelection": "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "timeout": "60000",
                    "excludeCredentials": "",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnRegistrationCallback(json: callbackResponse)
            
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
    
    
    //  MARK: - AM 7.0.0 Specific Response: Invalid Callback
    
    func test_17_AM70_invalid_relying_party_id_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "attestationPreference": "none",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "_type": "WebAuthn",
                    "relyingPartyId": "com.forgerock.ios",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "authenticatorSelection": "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "timeout": "60000",
                    "excludeCredentials": "",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]",
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "com.forgerock.ios"
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"cross-platform\"}"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnRegistrationCallback(json: callbackResponse)
            
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
    
    func test_18_AM70_missing_relying_party_id_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "attestationPreference": "none",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "_type": "WebAuthn",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "authenticatorSelection": "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "timeout": "60000",
                    "excludeCredentials": "",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]",
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"cross-platform\"}"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnRegistrationCallback(json: callbackResponse)
            
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
    
    
    func test_19_AM70_missing_authenticator_selection_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "attestationPreference": "none",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "_type": "WebAuthn",
                    "relyingPartyId": "id: \"com.forgerock.ios\",",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "timeout": "60000",
                    "excludeCredentials": "",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]",
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Missing authenticatorSelection"))
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
    
    
    func test_20_AM70_missing_pub_key_cred_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "attestationPreference": "none",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "_type": "WebAuthn",
                    "relyingPartyId": "id: \"com.forgerock.ios\",",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "authenticatorSelection": "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}"
                    "timeout": "60000",
                    "excludeCredentials": "",
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Missing pubKeyCredParams"))
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
    
    
    func test_21_AM70_invalid_pub_key_cred_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "attestationPreference": "none",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "_type": "WebAuthn",
                    "relyingPartyId": "id: \"com.forgerock.ios\",",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "authenticatorSelection": "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}"
                    "timeout": "60000",
                    "excludeCredentials": "",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": 77 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": 77 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Invalid pubKeyCredParams format"))
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
    
    
    func test_22_AM70_invalid_excluded_cred_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [{
                "name": "data",
                "value": {
                    "relyingPartyName": "ForgeRock",
                    "attestationPreference": "none",
                    "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "_type": "WebAuthn",
                    "relyingPartyId": "id: \"com.forgerock.ios\",",
                    "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                    "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                    "authenticatorSelection": "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}"
                    "timeout": "60000",
                    "excludeCredentials": "{ \"type\": \"public-key\", \"id\": new Int8Array([999, -75, 121, 26, -95, 63, 65, 104, -114, -93, -5, 111, -14, 24, -113, -84]).buffer }",
                    "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
                    "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = "{ \"type\": \"public-key\", \"id\": new Int8Array([999, -75, 121, 26, -95, 63, 65, 104, -114, -93, -5, 111, -14, 24, -113, -84]).buffer }"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\"}"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Invalid excludeCredentials byte"))
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
    
    
    //  MARK: - AM 7.1.0 Specific Response: Invalid Callback validation
    
    
    func test_23_AM71_missing_authenticator_selection_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [
                {
                    "name": "data",
                    "value": {
                        "_action": "webauthn_registration",
                        "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg=",
                        "attestationPreference": "none",
                        "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                        "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                        "relyingPartyName": "ForgeRock",
                        "authenticatorSelection": "{\"userVerification\":\"preferred\"}",
                        "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -257 }, { \"type\": \"public-key\", \"alg\": -7 } ]",
                        "_pubKeyCredParams": [
                            {
                                "type": "public-key",
                                "alg": -257
                            },
                            {
                                "type": "public-key",
                                "alg": -7
                            }
                        ],
                        "timeout": "60000",
                        "excludeCredentials": "",
                        "_excludeCredentials": [],
                        "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                        "relyingPartyId": "id: \"com.forgerock.ios\",",
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\"}"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        
        //  AM 7.1.0 specific response
        outputValue["_relyingPartyId"] = "com.forgerock.ios"
        outputValue["_excludeCredentials"] = []
        outputValue["_pubKeyCredParams"] = [["type": "public-key", "alg": -257], ["type": "public-key", "alg": -7]]
        outputValue["_action"] = "webauthn_registration"
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Missing authenticatorSelection"))
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
    
    
    func test_24_AM71_cross_platform_authenticator_selection_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [
                {
                    "name": "data",
                    "value": {
                        "_action": "webauthn_registration",
                        "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg=",
                        "attestationPreference": "none",
                        "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                        "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                        "relyingPartyName": "ForgeRock",
                        "authenticatorSelection": "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"cross-platform\"}",
                        "_authenticatorSelection": {
                            "userVerification": "preferred",
                            "authenticatorAttachment": "cross-platform"
                        },
                        "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -257 }, { \"type\": \"public-key\", \"alg\": -7 } ]",
                        "_pubKeyCredParams": [
                            {
                                "type": "public-key",
                                "alg": -257
                            },
                            {
                                "type": "public-key",
                                "alg": -7
                            }
                        ],
                        "timeout": "60000",
                        "excludeCredentials": "",
                        "_excludeCredentials": [],
                        "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                        "relyingPartyId": "id: \"com.forgerock.ios\",",
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"cross-platform\"}"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        
        //  AM 7.1.0 specific response
        outputValue["_relyingPartyId"] = "com.forgerock.ios"
        outputValue["_excludeCredentials"] = []
        outputValue["_pubKeyCredParams"] = [["type": "public-key", "alg": -257], ["type": "public-key", "alg": -7]]
        outputValue["_authenticatorSelection"] = ["userVerification": "preferred", "authenticatorAttachment": "cross-platform"]
        outputValue["_action"] = "webauthn_registration"
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Unsupported Authenticator Attachment type"))
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
    
    
    func test_25_AM71_missing_relying_party_id_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [
                {
                    "name": "data",
                    "value": {
                        "_action": "webauthn_registration",
                        "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg=",
                        "attestationPreference": "none",
                        "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                        "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                        "relyingPartyName": "ForgeRock",
                        "authenticatorSelection": "{\"userVerification\":\"preferred\"}",
                        "_authenticatorSelection": {
                            "userVerification": "preferred"
                        },
                        "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -257 }, { \"type\": \"public-key\", \"alg\": -7 } ]",
                        "_pubKeyCredParams": [
                            {
                                "type": "public-key",
                                "alg": -257
                            },
                            {
                                "type": "public-key",
                                "alg": -7
                            }
                        ],
                        "timeout": "60000",
                        "excludeCredentials": "",
                        "_excludeCredentials": [],
                        "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                        "relyingPartyId": "id: \"com.forgerock.ios\",",
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\"}"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        
        //  AM 7.1.0 specific response
        outputValue["_excludeCredentials"] = []
        outputValue["_pubKeyCredParams"] = [["type": "public-key", "alg": -257], ["type": "public-key", "alg": -7]]
        outputValue["_authenticatorSelection"] = ["userVerification": "preferred"]
        outputValue["_action"] = "webauthn_registration"
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnRegistrationCallback(json: callbackResponse)
            
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
    
    
    func test_26_AM71_invalid_pub_key_cred_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [
                {
                    "name": "data",
                    "value": {
                        "_action": "webauthn_registration",
                        "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg=",
                        "attestationPreference": "none",
                        "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                        "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                        "relyingPartyName": "ForgeRock",
                        "authenticatorSelection": "{\"userVerification\":\"preferred\"}",
                        "_authenticatorSelection": {
                            "userVerification": "preferred"
                        },
                        "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -257 }, { \"type\": \"public-key\", \"alg\": -7 } ]",
                        "_pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -257 }, { \"type\": \"public-key\", \"alg\": -7 } ]",
                        "timeout": "60000",
                        "excludeCredentials": "",
                        "_excludeCredentials": [],
                        "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                        "relyingPartyId": "id: \"com.forgerock.ios\",",
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\"}"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        
        //  AM 7.1.0 specific response
        outputValue["_relyingPartyId"] = "com.forgerock.ios"
        outputValue["_excludeCredentials"] = []
        outputValue["_pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -257 }, { \"type\": \"public-key\", \"alg\": -7 } ]"
        outputValue["_authenticatorSelection"] = ["userVerification": "preferred"]
        outputValue["_action"] = "webauthn_registration"
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Invalid pubKeyCredParams format"))
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
    
    
    func test_27_AM71_invalid_pub_key_cred_format_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [
                {
                    "name": "data",
                    "value": {
                        "_action": "webauthn_registration",
                        "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg=",
                        "attestationPreference": "none",
                        "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                        "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                        "relyingPartyName": "ForgeRock",
                        "authenticatorSelection": "{\"userVerification\":\"preferred\"}",
                        "_authenticatorSelection": {
                            "userVerification": "preferred"
                        },
                        "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -257 }, { \"type\": \"public-key\", \"alg\": -7 } ]",
                        "_pubKeyCredParams": [
                            {
                                "type": "public-key",
                                "alg": 257
                            },
                            {
                                "type": "public-key",
                                "alg": -7
                            }
                        ],
                        "timeout": "60000",
                        "excludeCredentials": "",
                        "_excludeCredentials": [],
                        "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                        "relyingPartyId": "id: \"com.forgerock.ios\",",
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\"}"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        
        //  AM 7.1.0 specific response
        outputValue["_relyingPartyId"] = "com.forgerock.ios"
        outputValue["_excludeCredentials"] = []
        outputValue["_pubKeyCredParams"] = [["type": "public-key", "alg": 257], ["type": "public-key", "alg": -7]]
        outputValue["_authenticatorSelection"] = ["userVerification": "preferred"]
        outputValue["_action"] = "webauthn_registration"
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let _ = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTFail("Invalid WebAuthnAuthenticationCallback unexpectedly succeeded")
        }
        catch let error as AuthError {
            //  Should fail with AuthError.invalidCallbackResponse
            switch error {
            case .invalidCallbackResponse:
                XCTAssertTrue(error.localizedDescription.contains("Invalid pubKeyCredParams format"))
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
    
    
    //  MARK: - AM 7.1.0 Specific Response: Valid Callback with configuration
    
    func test_28_AM71_platform_authenticator_require_resident_key_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [
                {
                    "name": "data",
                    "value": {
                        "_action": "webauthn_registration",
                        "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg=",
                        "attestationPreference": "none",
                        "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                        "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                        "relyingPartyName": "ForgeRock",
                        "authenticatorSelection": "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\",\"requireResidentKey\":true}",
                        "_authenticatorSelection": {
                            "userVerification": "preferred",
                            "authenticatorAttachment": "platform",
                            "requireResidentKey": true
                        },
                        "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -257 }, { \"type\": \"public-key\", \"alg\": -7 } ]",
                        "_pubKeyCredParams": [
                            {
                                "type": "public-key",
                                "alg": -257
                            },
                            {
                                "type": "public-key",
                                "alg": -7
                            }
                        ],
                        "timeout": "60000",
                        "excludeCredentials": "",
                        "_excludeCredentials": [],
                        "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                        "relyingPartyId": "id: \"com.forgerock.ios\",",
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\",\"requireResidentKey\":true}"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        
        //  AM 7.1.0 specific response
        outputValue["_relyingPartyId"] = "com.forgerock.ios"
        outputValue["_excludeCredentials"] = []
        outputValue["_pubKeyCredParams"] = [["type": "public-key", "alg": -257], ["type": "public-key", "alg": -7]]
        outputValue["_authenticatorSelection"] = ["userVerification": "preferred", "authenticatorAttachment": "platform", "requireResidentKey": true]
        outputValue["_action"] = "webauthn_registration"
        
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let callback = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            
            //  Not nil
            XCTAssertNotNil(callback._type)
            XCTAssertNotNil(callback.relyingPartyName)
            XCTAssertNotNil(callback.attestationPreference)
            XCTAssertNotNil(callback.displayName)
            XCTAssertNotNil(callback.relyingPartyId)
            XCTAssertNotNil(callback.userName)
            XCTAssertNotNil(callback.userId)
            XCTAssertNotNil(callback.timeout)
            XCTAssertNotNil(callback.excludeCredentials)
            XCTAssertNotNil(callback.pubKeyCredParams)
            XCTAssertNotNil(callback.challenge)
            XCTAssertNotNil(callback.userVerification)
            XCTAssertNotNil(callback.requireResidentKey)
            XCTAssertNotNil(callback.authenticatorAttachment)
            
            //  Equal
            XCTAssertEqual(callback._type, "WebAuthn")
            XCTAssertEqual(callback.relyingPartyName, "ForgeRock")
            XCTAssertEqual(callback.attestationPreference, .none)
            XCTAssertEqual(callback.displayName, "527490d2-0d91-483e-bf0b-853ff3bb2447")
            XCTAssertEqual(callback.relyingPartyId, "com.forgerock.ios")
            XCTAssertEqual(callback.userName, "527490d2-0d91-483e-bf0b-853ff3bb2447")
            XCTAssertEqual(callback.userId, "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3")
            XCTAssertEqual(callback.timeout, 60000)
            XCTAssertEqual(callback.excludeCredentials.count, 0)
            XCTAssertEqual(callback.pubKeyCredParams.count, 2)
            XCTAssertEqual(callback.pubCredAlg.count, 2)
            XCTAssertEqual(callback.challenge, "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg=")
            XCTAssertEqual(callback.userVerification, .preferred)
            XCTAssertEqual(callback.requireResidentKey, true)
            XCTAssertEqual(callback.authenticatorAttachment, .platform)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_29_AM71_user_verification_discouraged_unspecified_platform_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [
                {
                    "name": "data",
                    "value": {
                        "_action": "webauthn_registration",
                        "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg=",
                        "attestationPreference": "none",
                        "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                        "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                        "relyingPartyName": "ForgeRock",
                        "authenticatorSelection": "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\",\"requireResidentKey\":true}",
                        "_authenticatorSelection": {
                            "userVerification": "discouraged"
                        },
                        "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -257 }, { \"type\": \"public-key\", \"alg\": -7 } ]",
                        "_pubKeyCredParams": [
                            {
                                "type": "public-key",
                                "alg": -257
                            },
                            {
                                "type": "public-key",
                                "alg": -7
                            }
                        ],
                        "timeout": "60000",
                        "excludeCredentials": "",
                        "_excludeCredentials": [],
                        "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                        "relyingPartyId": "id: \"com.forgerock.ios\",",
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\",\"requireResidentKey\":true}"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = ""
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        
        //  AM 7.1.0 specific response
        outputValue["_relyingPartyId"] = "com.forgerock.ios"
        outputValue["_excludeCredentials"] = []
        outputValue["_pubKeyCredParams"] = [["type": "public-key", "alg": -257], ["type": "public-key", "alg": -7]]
        outputValue["_authenticatorSelection"] = ["userVerification": "discouraged"]
        outputValue["_action"] = "webauthn_registration"
        
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        // When
        do {
            let callback = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            
            //  Not nil
            XCTAssertNotNil(callback._type)
            XCTAssertNotNil(callback.relyingPartyName)
            XCTAssertNotNil(callback.attestationPreference)
            XCTAssertNotNil(callback.displayName)
            XCTAssertNotNil(callback.relyingPartyId)
            XCTAssertNotNil(callback.userName)
            XCTAssertNotNil(callback.userId)
            XCTAssertNotNil(callback.timeout)
            XCTAssertNotNil(callback.excludeCredentials)
            XCTAssertNotNil(callback.pubKeyCredParams)
            XCTAssertNotNil(callback.challenge)
            XCTAssertNotNil(callback.userVerification)
            XCTAssertNotNil(callback.requireResidentKey)
            XCTAssertNotNil(callback.authenticatorAttachment)
            
            //  Equal
            XCTAssertEqual(callback._type, "WebAuthn")
            XCTAssertEqual(callback.relyingPartyName, "ForgeRock")
            XCTAssertEqual(callback.attestationPreference, .none)
            XCTAssertEqual(callback.displayName, "527490d2-0d91-483e-bf0b-853ff3bb2447")
            XCTAssertEqual(callback.relyingPartyId, "com.forgerock.ios")
            XCTAssertEqual(callback.userName, "527490d2-0d91-483e-bf0b-853ff3bb2447")
            XCTAssertEqual(callback.userId, "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3")
            XCTAssertEqual(callback.timeout, 60000)
            XCTAssertEqual(callback.excludeCredentials.count, 0)
            XCTAssertEqual(callback.pubKeyCredParams.count, 2)
            XCTAssertEqual(callback.pubCredAlg.count, 2)
            XCTAssertEqual(callback.challenge, "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg=")
            XCTAssertEqual(callback.userVerification, .discouraged)
            XCTAssertEqual(callback.requireResidentKey, false)
            XCTAssertEqual(callback.authenticatorAttachment, .unspecified)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_30_AM71_excluded_credentials_single_pub_key_cred_registration_callback() {
        //  JSON response
        let _ = """
        {
            "type": "MetadataCallback",
            "output": [
                {
                    "name": "data",
                    "value": {
                        "_action": "webauthn_registration",
                        "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg=",
                        "attestationPreference": "none",
                        "userName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                        "userId": "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3",
                        "relyingPartyName": "ForgeRock",
                        "authenticatorSelection": "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\",\"requireResidentKey\":true}",
                        "_authenticatorSelection": {
                            "userVerification": "discouraged"
                        },
                        "pubKeyCredParams": "[ { \"type\": \"public-key\", \"alg\": -257 }, { \"type\": \"public-key\", \"alg\": -7 } ]",
                        "_pubKeyCredParams": [
                            {
                                "type": "public-key",
                                "alg": -257
                            }
                        ],
                        "timeout": "60000",
                        "excludeCredentials": "{ \"type\": \"public-key\", \"id\": new Int8Array([-37, 41, 3, -121, 85, 100, 67, -108, -79, -115, 37, -45, 48, 94, 71, 74]).buffer }",
                        "_excludeCredentials": [{ "type": "public-key", "id": [-37, 41, 3, -121, 85, 100, 67, -108, -79, -115, 37, -45, 48, 94, 71, 74]}],
                        "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                        "relyingPartyId": "id: \"com.forgerock.ios\",",
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
        outputValue["relyingPartyName"] = "ForgeRock"
        outputValue["attestationPreference"] = "none"
        outputValue["displayName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["_type"] = "WebAuthn"
        outputValue["relyingPartyId"] = "id: \"com.forgerock.ios\","
        outputValue["userName"] = "527490d2-0d91-483e-bf0b-853ff3bb2447"
        outputValue["authenticatorSelection"] = "{\"userVerification\":\"preferred\",\"authenticatorAttachment\":\"platform\",\"requireResidentKey\":true}"
        outputValue["userId"] = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3"
        outputValue["timeout"] = "60000"
        outputValue["excludeCredentials"] = "{ \"type\": \"public-key\", \"id\": new Int8Array([-37, 41, 3, -121, 85, 100, 67, -108, -79, -115, 37, -45, 48, 94, 71, 74]).buffer }"
        outputValue["pubKeyCredParams"] = "[ { \"type\": \"public-key\", \"alg\": -7 }, { \"type\": \"public-key\", \"alg\": -257 } ]"
        outputValue["challenge"] = "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg="
        
        //  AM 7.1.0 specific response
        outputValue["_relyingPartyId"] = "com.forgerock.ios"
        outputValue["_excludeCredentials"] = [["type": "public-key", "id": [-37, 41, 3, -121, 85, 100, 67, -108, -79, -115, 37, -45, 48, 94, 71, 74]]]
        outputValue["_pubKeyCredParams"] = [["type": "public-key", "alg": -257]]
        outputValue["_authenticatorSelection"] = ["userVerification": "discouraged"]
        outputValue["_action"] = "webauthn_registration"
        
        output["value"] = outputValue
        callbackResponse["output"] = [output]
        
        let excludeCredentials: [UInt8] = [UInt8(bitPattern: Int8(-37)), UInt8(bitPattern: Int8(41)), UInt8(bitPattern: Int8(3)), UInt8(bitPattern: Int8(-121)), UInt8(bitPattern: Int8(85)), UInt8(bitPattern: Int8(100)), UInt8(bitPattern: Int8(67)), UInt8(bitPattern: Int8(-108)), UInt8(bitPattern: Int8(-79)), UInt8(bitPattern: Int8(-115)), UInt8(bitPattern: Int8(37)), UInt8(bitPattern: Int8(-45)), UInt8(bitPattern: Int8(48)), UInt8(bitPattern: Int8(94)), UInt8(bitPattern: Int8(71)), UInt8(bitPattern: Int8(74))]
        
        // When
        do {
            let callback = try WebAuthnRegistrationCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            
            //  Not nil
            XCTAssertNotNil(callback._type)
            XCTAssertNotNil(callback.relyingPartyName)
            XCTAssertNotNil(callback.attestationPreference)
            XCTAssertNotNil(callback.displayName)
            XCTAssertNotNil(callback.relyingPartyId)
            XCTAssertNotNil(callback.userName)
            XCTAssertNotNil(callback.userId)
            XCTAssertNotNil(callback.timeout)
            XCTAssertNotNil(callback.excludeCredentials)
            XCTAssertNotNil(callback.pubKeyCredParams)
            XCTAssertNotNil(callback.challenge)
            XCTAssertNotNil(callback.userVerification)
            XCTAssertNotNil(callback.requireResidentKey)
            XCTAssertNotNil(callback.authenticatorAttachment)
            
            //  Equal
            XCTAssertEqual(callback._type, "WebAuthn")
            XCTAssertEqual(callback.relyingPartyName, "ForgeRock")
            XCTAssertEqual(callback.attestationPreference, .none)
            XCTAssertEqual(callback.displayName, "527490d2-0d91-483e-bf0b-853ff3bb2447")
            XCTAssertEqual(callback.relyingPartyId, "com.forgerock.ios")
            XCTAssertEqual(callback.userName, "527490d2-0d91-483e-bf0b-853ff3bb2447")
            XCTAssertEqual(callback.userId, "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3")
            XCTAssertEqual(callback.timeout, 60000)
            XCTAssertEqual(callback.excludeCredentials.count, 1)
            XCTAssertEqual(callback.excludeCredentials.first, excludeCredentials)
            XCTAssertEqual(callback.pubKeyCredParams.count, 1)
            XCTAssertEqual(callback.pubCredAlg.count, 1)
            XCTAssertEqual(callback.challenge, "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg=")
            XCTAssertEqual(callback.userVerification, .discouraged)
            XCTAssertEqual(callback.requireResidentKey, false)
            XCTAssertEqual(callback.authenticatorAttachment, .unspecified)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
}
