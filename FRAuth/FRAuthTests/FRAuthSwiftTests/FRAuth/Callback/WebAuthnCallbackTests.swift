// 
//  WebAuthnCallbackTests.swift
//  FRAuthTests
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

class WebAuthnCallbackTests: FRAuthBaseTest {

    override func setUp() {
        self.configFileName = "Config"
        self.shouldLoadMockResponses = true
        super.setUp()
    }
    
    
    //  MARK: - getWebAuthnType tests
    
    func test_01_invalid_type() {
        let jsonStr = """
        {
        "type": "NameCallback",
        "output": [{
                "name": "prompt","value": "User Name"
            }],
        "input": [{
            "name": "IDToken2", "value": ""
        }],
        "_id": 1
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        XCTAssertEqual(WebAuthnCallback.getWebAuthnType(callbackResponse), .invalid)
    }
    
    
    func test_02_AM71_registration_validation() {
        let jsonStr = """
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
                        "_authenticatorSelection": {
                            "userVerification": "discouraged"
                        },
                        "_pubKeyCredParams": [
                            {
                                "type": "public-key",
                                "alg": -257
                            }
                        ],
                        "timeout": "60000",
                        "_excludeCredentials": [{ "type": "public-key", "id": [-37, 41, 3, -121, 85, 100, 67, -108, -79, -115, 37, -45, 48, 94, 71, 74]}],
                        "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                        "_relyingPartyId": "com.forgerock.ios",
                        "_type": "WebAuthn"
                    }
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        XCTAssertEqual(WebAuthnCallback.getWebAuthnType(callbackResponse), .registration)
    }
    
    
    func test_03_AM71_authentication_validation() {
        let jsonStr = """
        {
            "type": "MetadataCallback",
            "output": [
                {
                    "name": "data",
                    "value": {
                        "_action": "webauthn_authentication",
                        "challenge": "G5MMUCfoB2TGpdqmXNmPqkf3YxKL5uGURyOVvW8jjFQ=",
                        "_allowCredentials": [
                            {
                                "type": "public-key",
                                "id": [-87, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]
                            }
                        ],
                        "timeout": "60000",
                        "userVerification": "preferred",
                        "_relyingPartyId": "com.forgerock.ios",
                        "_type": "WebAuthn"
                    }
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        XCTAssertEqual(WebAuthnCallback.getWebAuthnType(callbackResponse), .authentication)
    }
    
    
    func test_03_AM70_registration_validation() {
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
        
        XCTAssertEqual(WebAuthnCallback.getWebAuthnType(callbackResponse), .registration)
    }
    
    
    func test_04_AM70_authentication_validation() {
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
        
        XCTAssertEqual(WebAuthnCallback.getWebAuthnType(callbackResponse), .authentication)
    }
    
    
    func test_05_AM71_invalid_action_validation() {
        let jsonStr = """
        {
            "type": "MetadataCallback",
            "output": [
                {
                    "name": "data",
                    "value": {
                        "_action": "WebAuthn",
                        "challenge": "G5MMUCfoB2TGpdqmXNmPqkf3YxKL5uGURyOVvW8jjFQ=",
                        "_allowCredentials": [
                            {
                                "type": "public-key",
                                "id": [-87, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]
                            }
                        ],
                        "timeout": "60000",
                        "userVerification": "preferred",
                        "_relyingPartyId": "com.forgerock.ios",
                        "_type": "WebAuthn"
                    }
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        XCTAssertEqual(WebAuthnCallback.getWebAuthnType(callbackResponse), .invalid)
    }
    
    
    func test_06_missing_output_type_validation() {
        let jsonStr = """
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
                        "_authenticatorSelection": {
                            "userVerification": "discouraged"
                        },
                        "_pubKeyCredParams": [
                            {
                                "type": "public-key",
                                "alg": -257
                            }
                        ],
                        "timeout": "60000",
                        "_excludeCredentials": [{ "type": "public-key", "id": [-37, 41, 3, -121, 85, 100, 67, -108, -79, -115, 37, -45, 48, 94, 71, 74]}],
                        "displayName": "527490d2-0d91-483e-bf0b-853ff3bb2447",
                        "_relyingPartyId": "com.forgerock.ios"
                    }
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        XCTAssertEqual(WebAuthnCallback.getWebAuthnType(callbackResponse), .invalid)
    }
    
    
    func test_07_missing_output_validation() {
        let jsonStr = """
        {
            "type": "MetadataCallback"
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        XCTAssertEqual(WebAuthnCallback.getWebAuthnType(callbackResponse), .invalid)
    }
    
    
    //  MARK: - convertInt8Arr tests
    
    func test_08_parsing_multiple_int_arr() {
        let str = "{ \"type\": \"public-key\", \"id\": new Int8Array([-8, -75, 121, 26, -95, 63, 65, 104, -114, -93, -5, 111, -14, 24, -113, -84]).buffer },{ \"type\": \"public-key\", \"id\": new Int8Array([-37, 41, 3, -121, 85, 100, 67, -108, -79, -115, 37, -45, 48, 94, 71, 74]).buffer }"
        XCTAssertEqual(WebAuthnCallback.convertInt8Arr(query: str).count, 2)
    }
    
    func test_09_parsing_single_int_arr() {
        let str = "{ \"type\": \"public-key\", \"id\": new Int8Array([-8, -75, 121, 26, -95, 63, 65, 104, -114, -93, -5, 111, -14, 24, -113, -84]).buffer }"
        XCTAssertEqual(WebAuthnCallback.convertInt8Arr(query: str).count, 1)
    }
    
    
    //  MARK: - setWebAuthnOutcome tests
    
    func test_10_set_value_success() {
        
        //  Init SDK
        self.startSDK()
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_WebAuthnRegistrationNodeAM71"])
        
        var currentNode: Node?
        
        //  To handle async operation for test; this allows async operation to be sync
        let ex = self.expectation(description: "First Node submit for Login")
        FRUser.login { (user: FRUser?, node, error) in
            //  Validate result
            XCTAssertNil(error)
            XCTAssertNil(user)
            XCTAssertNotNil(node)
            currentNode = node
            //  Exit the async operation
            ex.fulfill()
        }
        //  Wait for async operation to be finished
        waitForExpectations(timeout: 60, handler: nil)
        
        //  To make sure that we captured Node object, and unwrap optional value of currentNode
        guard let node = currentNode else {
            XCTFail("Failed to get Node from the first request from Registration tree")
            return
        }
        
        XCTAssertTrue(node.callbacks.first is WebAuthnCallback)
        XCTAssertTrue(node.callbacks.last is HiddenValueCallback)
        
        guard let webAuthCallback = node.callbacks.first as? WebAuthnRegistrationCallback, let hiddenValueCallback = node.callbacks.last as? HiddenValueCallback else {
            XCTFail("Unexpected Callbacks received")
            return
        }
        
        webAuthCallback.setWebAuthnOutcome(node: node, outcome: "test_outcome")
        XCTAssertEqual(hiddenValueCallback.isWebAuthnOutcome, true)
        XCTAssertEqual(hiddenValueCallback.getValue() as? String, "test_outcome")
    }
    
    
    func test_11_set_value_with_invalid_hidden_value_callback() {
        
        //  Init SDK
        self.startSDK()
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_WebAuthnRegistrationNodeAM71InvalidHiddenValueCallback"])
        
        var currentNode: Node?
        
        //  To handle async operation for test; this allows async operation to be sync
        let ex = self.expectation(description: "First Node submit for Login")
        FRUser.login { (user: FRUser?, node, error) in
            //  Validate result
            XCTAssertNil(error)
            XCTAssertNil(user)
            XCTAssertNotNil(node)
            currentNode = node
            //  Exit the async operation
            ex.fulfill()
        }
        //  Wait for async operation to be finished
        waitForExpectations(timeout: 60, handler: nil)
        
        //  To make sure that we captured Node object, and unwrap optional value of currentNode
        guard let node = currentNode else {
            XCTFail("Failed to get Node from the first request from Registration tree")
            return
        }
        
        XCTAssertTrue(node.callbacks.first is WebAuthnCallback)
        XCTAssertTrue(node.callbacks.last is HiddenValueCallback)
        
        guard let webAuthCallback = node.callbacks.first as? WebAuthnRegistrationCallback, let hiddenValueCallback = node.callbacks.last as? HiddenValueCallback else {
            XCTFail("Unexpected Callbacks received")
            return
        }
        
        webAuthCallback.setWebAuthnOutcome(node: node, outcome: "test_outcome")
        XCTAssertEqual(hiddenValueCallback.isWebAuthnOutcome, false)
        XCTAssertEqual(hiddenValueCallback.getValue() as? String, "")
    }
}
