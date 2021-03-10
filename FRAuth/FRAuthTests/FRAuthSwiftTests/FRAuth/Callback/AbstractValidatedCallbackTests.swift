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
@testable import FRAuth

class AbstractValidatedCallbackTests: FRAuthBaseTest {
    
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
                    "value": {
                        "policyRequirements": [
                            "REQUIRED",
                            "MIN_LENGTH",
                            "VALID_TYPE",
                            "UNIQUE",
                            "CANNOT_CONTAIN_CHARACTERS"
                        ],
                        "fallbackPolicies": null,
                        "name": "userName",
                        "policies": [
                            {
                                "policyRequirements": [
                                    "REQUIRED"
                                ],
                                "policyId": "required"
                            },
                            {
                                "policyRequirements": [
                                    "REQUIRED"
                                ],
                                "policyId": "not-empty"
                            },
                            {
                                "policyRequirements": [
                                    "MIN_LENGTH"
                                ],
                                "policyId": "minimum-length",
                                "params": {
                                    "minLength": 1
                                }
                            },
                            {
                                "policyRequirements": [
                                    "VALID_TYPE"
                                ],
                                "policyId": "valid-type",
                                "params": {
                                    "types": [
                                        "string"
                                    ]
                                }
                            },
                            {
                                "policyId": "unique",
                                "policyRequirements": [
                                    "UNIQUE"
                                ]
                            },
                            {
                                "policyId": "no-internal-user-conflict",
                                "policyRequirements": [
                                    "UNIQUE"
                                ]
                            },
                            {
                                "policyId": "cannot-contain-characters",
                                "params": {
                                    "forbiddenChars": [
                                        "/"
                                    ]
                                },
                                "policyRequirements": [
                                    "CANNOT_CONTAIN_CHARACTERS"
                                ]
                            }
                        ],
                        "conditionalPolicies": null
                    }
                },
                {
                    "name": "failedPolicies",
                    "value": []
                },
                {
                    "name": "validateOnly",
                    "value": false
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
                },
                {
                    "name": "IDToken1validateOnly",
                    "value": false
                }
            ],
            "_id": 0
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
            guard let policyRequirements = policies["policyRequirements"] as? [String] else {
                XCTFail("Failed to convert \"policyRequirements\" in Callback response")
                return
            }
            XCTAssertNotNil(policyRequirements)
            XCTAssertEqual(policyRequirements.count, 5)
            XCTAssertTrue(policyRequirements.contains("REQUIRED"))
            XCTAssertTrue(policyRequirements.contains("MIN_LENGTH"))
            XCTAssertTrue(policyRequirements.contains("VALID_TYPE"))
            XCTAssertTrue(policyRequirements.contains("UNIQUE"))
            XCTAssertTrue(policyRequirements.contains("CANNOT_CONTAIN_CHARACTERS"))
            XCTAssertNotNil(policies["name"])
            XCTAssertEqual(policies["name"] as? String ?? "", "userName")
            
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
                    "value": {
                        "policyRequirements": [
                            "REQUIRED",
                            "MIN_LENGTH",
                            "VALID_TYPE",
                            "UNIQUE",
                            "CANNOT_CONTAIN_CHARACTERS"
                        ],
                        "fallbackPolicies": null,
                        "name": "userName",
                        "policies": [
                            {
                                "policyRequirements": [
                                    "REQUIRED"
                                ],
                                "policyId": "required"
                            },
                            {
                                "policyRequirements": [
                                    "REQUIRED"
                                ],
                                "policyId": "not-empty"
                            },
                            {
                                "policyRequirements": [
                                    "MIN_LENGTH"
                                ],
                                "policyId": "minimum-length",
                                "params": {
                                    "minLength": 1
                                }
                            },
                            {
                                "policyRequirements": [
                                    "VALID_TYPE"
                                ],
                                "policyId": "valid-type",
                                "params": {
                                    "types": [
                                        "string"
                                    ]
                                }
                            },
                            {
                                "policyId": "unique",
                                "policyRequirements": [
                                    "UNIQUE"
                                ]
                            },
                            {
                                "policyId": "no-internal-user-conflict",
                                "policyRequirements": [
                                    "UNIQUE"
                                ]
                            },
                            {
                                "policyId": "cannot-contain-characters",
                                "params": {
                                    "forbiddenChars": [
                                        "/"
                                    ]
                                },
                                "policyRequirements": [
                                    "CANNOT_CONTAIN_CHARACTERS"
                                ]
                            }
                        ],
                        "conditionalPolicies": null
                    }
                },
                {
                    "name": "failedPolicies",
                    "value": []
                },
                {
                    "name": "validateOnly",
                    "value": false
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
                },
                {
                    "name": "IDToken1validateOnly",
                    "value": false
                }
            ],
            "_id": 2
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
                    "value": {
                        "policyRequirements": [
                            "REQUIRED",
                            "MIN_LENGTH",
                            "VALID_TYPE",
                            "UNIQUE",
                            "CANNOT_CONTAIN_CHARACTERS"
                        ],
                        "fallbackPolicies": null,
                        "name": "userName",
                        "policies": [
                            {
                                "policyRequirements": [
                                    "REQUIRED"
                                ],
                                "policyId": "required"
                            },
                            {
                                "policyRequirements": [
                                    "REQUIRED"
                                ],
                                "policyId": "not-empty"
                            },
                            {
                                "policyRequirements": [
                                    "MIN_LENGTH"
                                ],
                                "policyId": "minimum-length",
                                "params": {
                                    "minLength": 1
                                }
                            },
                            {
                                "policyRequirements": [
                                    "VALID_TYPE"
                                ],
                                "policyId": "valid-type",
                                "params": {
                                    "types": [
                                        "string"
                                    ]
                                }
                            },
                            {
                                "policyId": "unique",
                                "policyRequirements": [
                                    "UNIQUE"
                                ]
                            },
                            {
                                "policyId": "no-internal-user-conflict",
                                "policyRequirements": [
                                    "UNIQUE"
                                ]
                            },
                            {
                                "policyId": "cannot-contain-characters",
                                "params": {
                                    "forbiddenChars": [
                                        "/"
                                    ]
                                },
                                "policyRequirements": [
                                    "CANNOT_CONTAIN_CHARACTERS"
                                ]
                            }
                        ],
                        "conditionalPolicies": null
                    }
                },
                {
                    "name": "failedPolicies",
                    "value": []
                },
                {
                    "name": "validateOnly",
                    "value": false
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
                },
                {
                    "name": "IDToken1validateOnly",
                    "value": false
                }
            ],
            "_id": 2
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
                    "value": {
                        "policyRequirements": [
                            "REQUIRED",
                            "MIN_LENGTH",
                            "VALID_TYPE",
                            "UNIQUE",
                            "CANNOT_CONTAIN_CHARACTERS"
                        ],
                        "fallbackPolicies": null,
                        "name": "userName",
                        "policies": [
                            {
                                "policyRequirements": [
                                    "REQUIRED"
                                ],
                                "policyId": "required"
                            },
                            {
                                "policyRequirements": [
                                    "REQUIRED"
                                ],
                                "policyId": "not-empty"
                            },
                            {
                                "policyRequirements": [
                                    "MIN_LENGTH"
                                ],
                                "policyId": "minimum-length",
                                "params": {
                                    "minLength": 1
                                }
                            },
                            {
                                "policyRequirements": [
                                    "VALID_TYPE"
                                ],
                                "policyId": "valid-type",
                                "params": {
                                    "types": [
                                        "string"
                                    ]
                                }
                            },
                            {
                                "policyId": "unique",
                                "policyRequirements": [
                                    "UNIQUE"
                                ]
                            },
                            {
                                "policyId": "no-internal-user-conflict",
                                "policyRequirements": [
                                    "UNIQUE"
                                ]
                            },
                            {
                                "policyId": "cannot-contain-characters",
                                "params": {
                                    "forbiddenChars": [
                                        "/"
                                    ]
                                },
                                "policyRequirements": [
                                    "CANNOT_CONTAIN_CHARACTERS"
                                ]
                            }
                        ],
                        "conditionalPolicies": null
                    }
                },
                {
                    "name": "failedPolicies",
                    "value": []
                },
                {
                    "name": "validateOnly",
                    "value": false
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
                },
                {
                    "name": "IDToken1validateOnly",
                    "value": false
                }
            ],
            "_id": 2
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
                    "value": {
                        "policyRequirements": [
                            "REQUIRED",
                            "MIN_LENGTH",
                            "VALID_TYPE",
                            "UNIQUE",
                            "CANNOT_CONTAIN_CHARACTERS"
                        ],
                        "fallbackPolicies": null,
                        "name": "userName",
                        "policies": [
                            {
                                "policyRequirements": [
                                    "REQUIRED"
                                ],
                                "policyId": "required"
                            },
                            {
                                "policyRequirements": [
                                    "REQUIRED"
                                ],
                                "policyId": "not-empty"
                            },
                            {
                                "policyRequirements": [
                                    "MIN_LENGTH"
                                ],
                                "policyId": "minimum-length",
                                "params": {
                                    "minLength": 1
                                }
                            },
                            {
                                "policyRequirements": [
                                    "VALID_TYPE"
                                ],
                                "policyId": "valid-type",
                                "params": {
                                    "types": [
                                        "string"
                                    ]
                                }
                            },
                            {
                                "policyId": "unique",
                                "policyRequirements": [
                                    "UNIQUE"
                                ]
                            },
                            {
                                "policyId": "no-internal-user-conflict",
                                "policyRequirements": [
                                    "UNIQUE"
                                ]
                            },
                            {
                                "policyId": "cannot-contain-characters",
                                "params": {
                                    "forbiddenChars": [
                                        "/"
                                    ]
                                },
                                "policyRequirements": [
                                    "CANNOT_CONTAIN_CHARACTERS"
                                ]
                            }
                        ],
                        "conditionalPolicies": null
                    }
                },
                {
                    "name": "failedPolicies",
                    "value": []
                },
                {
                    "name": "validateOnly",
                    "value": false
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
                },
                {
                    "name": "IDToken1validateOnly",
                    "value": false
                }
            ],
            "_id": 2
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        
        // Try
        do {
            let callback = try ValidatedCreateUsernameCallback(json: callbackResponse)
            // Sets Username
            callback.setValue("username")
            callback.validateOnly = true
            
            // Builds new response
            let builtJson = """
            {
                "type": "ValidatedCreateUsernameCallback",
                "output": [
                    {
                        "name": "policies",
                        "value": {
                            "policyRequirements": [
                                "REQUIRED",
                                "MIN_LENGTH",
                                "VALID_TYPE",
                                "UNIQUE",
                                "CANNOT_CONTAIN_CHARACTERS"
                            ],
                            "fallbackPolicies": null,
                            "name": "userName",
                            "policies": [
                                {
                                    "policyRequirements": [
                                        "REQUIRED"
                                    ],
                                    "policyId": "required"
                                },
                                {
                                    "policyRequirements": [
                                        "REQUIRED"
                                    ],
                                    "policyId": "not-empty"
                                },
                                {
                                    "policyRequirements": [
                                        "MIN_LENGTH"
                                    ],
                                    "policyId": "minimum-length",
                                    "params": {
                                        "minLength": 1
                                    }
                                },
                                {
                                    "policyRequirements": [
                                        "VALID_TYPE"
                                    ],
                                    "policyId": "valid-type",
                                    "params": {
                                        "types": [
                                            "string"
                                        ]
                                    }
                                },
                                {
                                    "policyId": "unique",
                                    "policyRequirements": [
                                        "UNIQUE"
                                    ]
                                },
                                {
                                    "policyId": "no-internal-user-conflict",
                                    "policyRequirements": [
                                        "UNIQUE"
                                    ]
                                },
                                {
                                    "policyId": "cannot-contain-characters",
                                    "params": {
                                        "forbiddenChars": [
                                            "/"
                                        ]
                                    },
                                    "policyRequirements": [
                                        "CANNOT_CONTAIN_CHARACTERS"
                                    ]
                                }
                            ],
                            "conditionalPolicies": null
                        }
                    },
                    {
                        "name": "failedPolicies",
                        "value": []
                    },
                    {
                        "name": "validateOnly",
                        "value": false
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
                    },
                    {
                        "name": "IDToken1validateOnly",
                        "value": true
                    }
                ],
                "_id": 2
            }
            """
            let response = self.parseStringToDictionary(builtJson)
            
            // Should equal when built
            XCTAssertTrue(NSDictionary(dictionary: response).isEqual(to: callback.buildResponse()))
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testValidateCreatePasswordCallback_EchoOff() {
        
        // Given
        let jsonStr = """
        {
            "type": "ValidatedCreatePasswordCallback",
            "output": [
                {
                    "name": "echoOn",
                    "value": false
                },
                {
                    "name": "policies",
                    "value": {
                        "policyRequirements": [
                            "REQUIRED",
                            "MIN_LENGTH",
                            "VALID_TYPE",
                            "AT_LEAST_X_CAPITAL_LETTERS",
                            "AT_LEAST_X_NUMBERS",
                            "CANNOT_CONTAIN_OTHERS"
                        ],
                        "fallbackPolicies": null,
                        "name": "password",
                        "policies": [
                            {
                                "policyRequirements": [
                                    "REQUIRED"
                                ],
                                "policyId": "not-empty"
                            },
                            {
                                "policyRequirements": [
                                    "MIN_LENGTH"
                                ],
                                "policyId": "minimum-length",
                                "params": {
                                    "minLength": 8
                                }
                            },
                            {
                                "policyRequirements": [
                                    "VALID_TYPE"
                                ],
                                "policyId": "valid-type",
                                "params": {
                                    "types": [
                                        "string"
                                    ]
                                }
                            },
                            {
                                "policyId": "at-least-X-capitals",
                                "params": {
                                    "numCaps": 1
                                },
                                "policyRequirements": [
                                    "AT_LEAST_X_CAPITAL_LETTERS"
                                ]
                            },
                            {
                                "policyId": "at-least-X-numbers",
                                "params": {
                                    "numNums": 1
                                },
                                "policyRequirements": [
                                    "AT_LEAST_X_NUMBERS"
                                ]
                            },
                            {
                                "policyId": "cannot-contain-others",
                                "params": {
                                    "disallowedFields": [
                                        "userName",
                                        "givenName",
                                        "sn"
                                    ]
                                },
                                "policyRequirements": [
                                    "CANNOT_CONTAIN_OTHERS"
                                ]
                            }
                        ],
                        "conditionalPolicies": null
                    }
                },
                {
                    "name": "failedPolicies",
                    "value": []
                },
                {
                    "name": "validateOnly",
                    "value": false
                },
                {
                    "name": "prompt",
                    "value": "Password"
                }
            ],
            "input": [
                {
                    "name": "IDToken2",
                    "value": ""
                },
                {
                    "name": "IDToken2validateOnly",
                    "value": false
                }
            ],
            "_id": 3
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        
        // Try
        do {
            let callback = try ValidatedCreatePasswordCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback.type, "ValidatedCreatePasswordCallback")
            XCTAssertEqual(callback.prompt, "Password")
            XCTAssertEqual(callback.inputName, "IDToken2")
            XCTAssertEqual(callback.echoOn, false)
            
            guard let policies = callback.policies else {
                XCTFail("Failed to convert \"policies\" in Callback response")
                return
            }
            guard let policyRequirements = policies["policyRequirements"] as? [String] else {
                XCTFail("Failed to convert \"policyRequirements\" in Callback response")
                return
            }
            XCTAssertNotNil(policyRequirements)
            XCTAssertEqual(policyRequirements.count, 6)
            
            XCTAssertTrue(policyRequirements.contains("REQUIRED"))
            XCTAssertTrue(policyRequirements.contains("MIN_LENGTH"))
            XCTAssertTrue(policyRequirements.contains("VALID_TYPE"))
            XCTAssertTrue(policyRequirements.contains("AT_LEAST_X_CAPITAL_LETTERS"))
            XCTAssertTrue(policyRequirements.contains("AT_LEAST_X_NUMBERS"))
            XCTAssertTrue(policyRequirements.contains("CANNOT_CONTAIN_OTHERS"))
            XCTAssertNotNil(policies["name"])
            XCTAssertEqual(policies["name"] as? String ?? "", "password")
            
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    func testValidateCreatePasswordCallback_EchoOn() {
        
        // Given
        let jsonStr = """
        {
            "type": "ValidatedCreatePasswordCallback",
            "output": [
                {
                    "name": "echoOn",
                    "value": true
                },
                {
                    "name": "policies",
                    "value": {
                        "policyRequirements": [
                            "REQUIRED",
                            "MIN_LENGTH",
                            "VALID_TYPE",
                            "AT_LEAST_X_CAPITAL_LETTERS",
                            "AT_LEAST_X_NUMBERS",
                            "CANNOT_CONTAIN_OTHERS"
                        ],
                        "fallbackPolicies": null,
                        "name": "password",
                        "policies": [
                            {
                                "policyRequirements": [
                                    "REQUIRED"
                                ],
                                "policyId": "not-empty"
                            },
                            {
                                "policyRequirements": [
                                    "MIN_LENGTH"
                                ],
                                "policyId": "minimum-length",
                                "params": {
                                    "minLength": 8
                                }
                            },
                            {
                                "policyRequirements": [
                                    "VALID_TYPE"
                                ],
                                "policyId": "valid-type",
                                "params": {
                                    "types": [
                                        "string"
                                    ]
                                }
                            },
                            {
                                "policyId": "at-least-X-capitals",
                                "params": {
                                    "numCaps": 1
                                },
                                "policyRequirements": [
                                    "AT_LEAST_X_CAPITAL_LETTERS"
                                ]
                            },
                            {
                                "policyId": "at-least-X-numbers",
                                "params": {
                                    "numNums": 1
                                },
                                "policyRequirements": [
                                    "AT_LEAST_X_NUMBERS"
                                ]
                            },
                            {
                                "policyId": "cannot-contain-others",
                                "params": {
                                    "disallowedFields": [
                                        "userName",
                                        "givenName",
                                        "sn"
                                    ]
                                },
                                "policyRequirements": [
                                    "CANNOT_CONTAIN_OTHERS"
                                ]
                            }
                        ],
                        "conditionalPolicies": null
                    }
                },
                {
                    "name": "failedPolicies",
                    "value": []
                },
                {
                    "name": "validateOnly",
                    "value": false
                },
                {
                    "name": "prompt",
                    "value": "Password"
                }
            ],
            "input": [
                {
                    "name": "IDToken2",
                    "value": ""
                },
                {
                    "name": "IDToken2validateOnly",
                    "value": false
                }
            ],
            "_id": 3
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        
        // Try
        do {
            let callback = try ValidatedCreatePasswordCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback.type, "ValidatedCreatePasswordCallback")
            XCTAssertEqual(callback.prompt, "Password")
            XCTAssertEqual(callback.inputName, "IDToken2")
            XCTAssertEqual(callback.echoOn, true)
            
            guard let policies = callback.policies else {
                XCTFail("Failed to convert \"policies\" in Callback response")
                return
            }
            guard let policyRequirements = policies["policyRequirements"] as? [String] else {
                XCTFail("Failed to convert \"policyRequirements\" in Callback response")
                return
            }
            XCTAssertNotNil(policyRequirements)
            XCTAssertEqual(policyRequirements.count, 6)
            
            XCTAssertTrue(policyRequirements.contains("REQUIRED"))
            XCTAssertTrue(policyRequirements.contains("MIN_LENGTH"))
            XCTAssertTrue(policyRequirements.contains("VALID_TYPE"))
            XCTAssertTrue(policyRequirements.contains("AT_LEAST_X_CAPITAL_LETTERS"))
            XCTAssertTrue(policyRequirements.contains("AT_LEAST_X_NUMBERS"))
            XCTAssertTrue(policyRequirements.contains("CANNOT_CONTAIN_OTHERS"))
            XCTAssertNotNil(policies["name"])
            XCTAssertEqual(policies["name"] as? String ?? "", "password")
            
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
}

