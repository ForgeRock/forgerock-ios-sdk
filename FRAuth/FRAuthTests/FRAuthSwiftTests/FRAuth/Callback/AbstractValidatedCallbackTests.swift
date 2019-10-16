//
//  AbstractVAlidatedCallbackTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest

class AbstractValidatedCallbackTests: FRBaseTest {
    
    // - MARK: ValidatedCreateUsernameCallback
    
    func testValidatedCreateUsernameCallbackInit_MissingOutput() {
        
        // Given
        let jsonStr = """
        {
            "type": "ValidatedCreateUsernameCallback",
            "input": [
                {
                    "name": "IDToken1",
                    "value": ""
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        
        // Try
        do {
            let _ = try ValidatedCreateUsernameCallback(json: callbackResponse)
            XCTFail("Succeed while expecting failure for invalid ValidatedCreateUsernameCallback response: \(jsonStr)")
        } catch {
        }
    }

    
    func testValidatedCreateUsernameCallbackInit() {
        
        // Given
        let jsonStr = """
        {
            "type": "ValidatedCreateUsernameCallback",
            "output": [
                {
                    "name": "policies",
                    "value": [
                        "unique",
                        "no-internal-user-conflict",
                        "cannot-contain-characters",
                        "minimum-length",
                        "maximum-length"
                    ]
                },
                {
                    "name": "failedPolicies",
                    "value": []
                },
                {
                    "name": "prompt",
                    "value": "Username"
                }
            ],
            "input": [
                {
                    "name": "IDToken1",
                    "value": ""
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        
        // Try
        do {
            let callback = try ValidatedCreateUsernameCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback.type, "ValidatedCreateUsernameCallback")
            XCTAssertEqual(callback.prompt, "Username")
            XCTAssertEqual(callback.inputName, "IDToken1")
            
            guard let policies = callback.policies else {
                XCTFail("Failed to convert \"policies\" in Callback response")
                return
            }
            
            XCTAssertTrue(policies.count == 5)
            XCTAssertTrue(policies.contains("unique"))
            XCTAssertTrue(policies.contains("no-internal-user-conflict"))
            XCTAssertTrue(policies.contains("cannot-contain-characters"))
            XCTAssertTrue(policies.contains("minimum-length"))
            XCTAssertTrue(policies.contains("maximum-length"))
            
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testValidatedCreateUsernameCallbackInitWithFailedPolicy() {
        
        // Given
        let jsonStr = """
        {
            "type": "ValidatedCreateUsernameCallback",
            "output": [
                {
                    "name": "policies",
                    "value": [
                        "unique",
                        "no-internal-user-conflict",
                        "cannot-contain-characters",
                        "minimum-length",
                        "maximum-length"
                    ]
                },
                {
                    "name": "failedPolicies",
                    "value": []
                },
                {
                    "name": "prompt",
                    "value": "Username"
                }
            ],
            "input": [
                {
                    "name": "IDToken1",
                    "value": ""
                }
            ]
        }
        """
        var callbackResponse = self.parseStringToDictionary(jsonStr)
        
        guard var outputs = callbackResponse["output"] as? [[String: Any]] else {
            XCTFail("Failed to parse given JSON (missing output): \(jsonStr)")
            return
        }
        
        for (index, var output) in outputs.enumerated() {
            if let name = output["name"] as? String, name == "failedPolicies" {
                outputs.remove(at: index)
                output["value"] = ["{ \"params\": { \"minLength\": 8 }, \"policyRequirement\": \"MIN_LENGTH\" }",
                                   "{ \"params\": { \"numCaps\": 1 }, \"policyRequirement\": \"AT_LEAST_X_CAPITAL_LETTERS\" }",
                                   "{ \"params\": { \"numNums\": 1 }, \"policyRequirement\": \"AT_LEAST_X_NUMBERS\" }"]
                outputs.append(output)
            }
        }
        
        callbackResponse["output"] = outputs
        
        // Try
        do {
            let callback = try ValidatedCreateUsernameCallback(json: callbackResponse)
            
            
            guard let failedPolicies = callback.failedPolicies else {
                XCTFail("Failed to convert \"policies\" in Callback response")
                return
            }
            
            XCTAssertTrue(failedPolicies.count == 3)
            
            for failedPolicy in failedPolicies {
                if failedPolicy.policyRequirement == "MIN_LENGTH" {
                    if let params = failedPolicy.params, let minLen = params["minLength"] as? Int {
                        XCTAssertTrue(minLen == 8)
                    }
                    else {
                        XCTFail("Failed to load expected \"params\" from FailedPolicy, or failed to load expected value")
                    }
                }
                else if failedPolicy.policyRequirement == "AT_LEAST_X_CAPITAL_LETTERS" {
                    if let params = failedPolicy.params, let numCaps = params["numCaps"] as? Int {
                        XCTAssertTrue(numCaps == 1)
                    }
                    else {
                        XCTFail("Failed to load expected \"params\" from FailedPolicy, or failed to load expected value")
                    }
                }
                else if failedPolicy.policyRequirement == "AT_LEAST_X_NUMBERS" {
                    if let params = failedPolicy.params, let numNums = params["numNums"] as? Int {
                        XCTAssertTrue(numNums == 1)
                    }
                    else {
                        XCTFail("Failed to load expected \"params\" from FailedPolicy, or failed to load expected value")
                    }
                }
                else {
                    XCTFail("Unexpected params loaded")
                }
            }
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testValidatedCreateUsernameCallbackInitWithInvalidFailedPolicyStructure() {
        // Given
        let jsonStr = """
        {
            "type": "ValidatedCreateUsernameCallback",
            "output": [
                {
                    "name": "policies",
                    "value": [
                        "unique",
                        "no-internal-user-conflict",
                        "cannot-contain-characters",
                        "minimum-length",
                        "maximum-length"
                    ]
                },
                {
                    "name": "failedPolicies",
                    "value": []
                },
                {
                    "name": "prompt",
                    "value": "Username"
                }
            ],
            "input": [
                {
                    "name": "IDToken1",
                    "value": ""
                }
            ]
        }
        """
        var callbackResponse = self.parseStringToDictionary(jsonStr)
        
        guard var outputs = callbackResponse["output"] as? [[String: Any]] else {
            XCTFail("Failed to parse given JSON (missing output): \(jsonStr)")
            return
        }
        
        for (index, var output) in outputs.enumerated() {
            if let name = output["name"] as? String, name == "failedPolicies" {
                outputs.remove(at: index)
                output["value"] = ["Invalid failed policies format"]
                outputs.append(output)
            }
        }
        
        callbackResponse["output"] = outputs
        
        // Try
        do {
            let _ = try ValidatedCreateUsernameCallback(json: callbackResponse)
            XCTFail("Succeed while expecting failure: \(callbackResponse)")
        } catch {
        }
    }
    
    
    func testValidatedCreateUsernameCallbackInitWithFailedPolicyMissingRequiredValue() {
        // Given
        let jsonStr = """
        {
            "type": "ValidatedCreateUsernameCallback",
            "output": [
                {
                    "name": "policies",
                    "value": [
                        "unique",
                        "no-internal-user-conflict",
                        "cannot-contain-characters",
                        "minimum-length",
                        "maximum-length"
                    ]
                },
                {
                    "name": "failedPolicies",
                    "value": []
                },
                {
                    "name": "prompt",
                    "value": "Username"
                }
            ],
            "input": [
                {
                    "name": "IDToken1",
                    "value": ""
                }
            ]
        }
        """
        var callbackResponse = self.parseStringToDictionary(jsonStr)
        
        guard var outputs = callbackResponse["output"] as? [[String: Any]] else {
            XCTFail("Failed to parse given JSON (missing output): \(jsonStr)")
            return
        }
        
        for (index, var output) in outputs.enumerated() {
            if let name = output["name"] as? String, name == "failedPolicies" {
                outputs.remove(at: index)
                output["value"] = ["{ \"params\": { \"minLength\": 8 }}"]
                outputs.append(output)
            }
        }
        
        callbackResponse["output"] = outputs
        
        // Try
        do {
            let _ = try ValidatedCreateUsernameCallback(json: callbackResponse)
            XCTFail("Succeed while expecting failure: \(callbackResponse)")
        } catch {
        }
    }
    
    
    func testValidatedCreateUsernameCallbackBuildResponse() {
        
        // Given
        let jsonStr = """
        {
            "type": "ValidatedCreateUsernameCallback",
            "output": [
                {
                    "name": "policies",
                    "value": [
                        "unique",
                        "no-internal-user-conflict",
                        "cannot-contain-characters",
                        "minimum-length",
                        "maximum-length"
                    ]
                },
                {
                    "name": "failedPolicies",
                    "value": []
                },
                {
                    "name": "prompt",
                    "value": "Username"
                }
            ],
            "input": [
                {
                    "name": "IDToken1",
                    "value": ""
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        
        // Try
        do {
            let callback = try ValidatedCreateUsernameCallback(json: callbackResponse)
            // Sets Username
            callback.value = "username"
            
            // Builds new response
            let builtJson = """
        {
            "type": "ValidatedCreateUsernameCallback",
            "output": [
                {
                    "name": "policies",
                    "value": [
                        "unique",
                        "no-internal-user-conflict",
                        "cannot-contain-characters",
                        "minimum-length",
                        "maximum-length"
                    ]
                },
                {
                    "name": "failedPolicies",
                    "value": []
                },
                {
                    "name": "prompt",
                    "value": "Username"
                }
            ],
            "input": [
                {
                    "name": "IDToken1",
                    "value": "username"
                }
            ]
        }
        """
            let response = self.parseStringToDictionary(builtJson)
            
            // Should equal when built
            XCTAssertTrue(NSDictionary(dictionary: response).isEqual(to: callback.buildResponse()))
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    // - MARK: FailedPolicy
    
    func testFailedPolicyInitWithInvalidFormat() {
        // Given
        let jsonStr = """
        {
            "params": {"numNums": 1}
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let _ = try FailedPolicy("Username", failedPolicyJson)
            XCTFail("Succeed while expecting failure for invalid FailedPolicy response: \(failedPolicyJson)")
        } catch {
        }
    }
    
    
    func testFailedPolicyInit_UNKNOWN_FORMAT() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "UNKNOWN_FORMAT"
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "UNKNOWN_FORMAT")
            XCTAssertEqual(failedPolicy.failedDescription(), "Username: Unknown policy requirement - UNKNOWN_FORMAT")
            
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_REQUIRED() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "REQUIRED"
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "REQUIRED")
            XCTAssertEqual(failedPolicy.failedDescription(), "Username is required")
            
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_UNIQUE() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "UNIQUE"
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "UNIQUE")
            XCTAssertEqual(failedPolicy.failedDescription(), "Username must be unique")
            
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_INVALID_DATE() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "VALID_DATE"
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "VALID_DATE")
            XCTAssertEqual(failedPolicy.failedDescription(), "Invalid date")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_INVALID_EMAIL_FORMAT() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "VALID_EMAIL_ADDRESS_FORMAT"
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "VALID_EMAIL_ADDRESS_FORMAT")
            XCTAssertEqual(failedPolicy.failedDescription(), "Invalid Email format")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_INVALID_NAME_FORMAT() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "VALID_NAME_FORMAT"
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "VALID_NAME_FORMAT")
            XCTAssertEqual(failedPolicy.failedDescription(), "Invalid name format")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_INVALID_PHONE_FORMAT() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "VALID_PHONE_FORMAT"
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "VALID_PHONE_FORMAT")
            XCTAssertEqual(failedPolicy.failedDescription(), "Invalid phone number")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_AtLeastCapital() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "AT_LEAST_X_CAPITAL_LETTERS",
            "params" : {
                "numCaps" : 5
            }
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNotNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "AT_LEAST_X_CAPITAL_LETTERS")
            XCTAssertEqual(failedPolicy.failedDescription(), "Username must contain at least 5 capital letter(s)")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_AtLeastNumber() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "AT_LEAST_X_NUMBERS",
            "params" : {
                "numNums" : 5
            }
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNotNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "AT_LEAST_X_NUMBERS")
            XCTAssertEqual(failedPolicy.failedDescription(), "Username must contain at least 5 numeric value(s)")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_INVALID_NUMBER() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "VALID_NUMBER"
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "VALID_NUMBER")
            XCTAssertEqual(failedPolicy.failedDescription(), "Invalid number")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_MIN_LENGTH() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "MIN_LENGTH",
            "params" : {
                "minLength" : 5
            }
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNotNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "MIN_LENGTH")
            XCTAssertEqual(failedPolicy.failedDescription(), "Username must be at least 5 character(s)")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_MAX_LENGTH() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "MAX_LENGTH",
            "params" : {
                "maxLength" : 5
            }
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNotNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "MAX_LENGTH")
            XCTAssertEqual(failedPolicy.failedDescription(), "Username must be at most 5 character(s)")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
}

