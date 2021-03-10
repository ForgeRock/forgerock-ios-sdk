// 
//  NumberAttributeInputCallback.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class NumberAttributeInputCallbackTests: FRAuthBaseTest {

    func test_01_number_attribute_init() {
        let jsonStr = """
        {
            "type": "NumberAttributeInputCallback",
            "output": [
                {
                    "name": "name",
                    "value": "testNumber"
                },
                {
                    "name": "prompt",
                    "value": "Test Number"
                },
                {
                    "name": "required",
                    "value": true
                },
                {
                    "name": "policies",
                    "value": {
                        "policyRequirements": [
                            "VALID_TYPE"
                        ],
                        "fallbackPolicies": null,
                        "name": "testNumber",
                        "policies": [
                            {
                                "policyRequirements": [
                                    "VALID_TYPE"
                                ],
                                "policyId": "valid-type",
                                "params": {
                                    "types": [
                                        "number"
                                    ]
                                }
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
                    "name": "value",
                    "value": null
                }
            ],
            "input": [
                {
                    "name": "IDToken1",
                    "value": null
                },
                {
                    "name": "IDToken1validateOnly",
                    "value": false
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            let callback = try NumberAttributeInputCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            XCTAssertTrue(callback.required)
            XCTAssertFalse(callback.validateOnly)
            
            guard let theValue = callback.getValue() else {
                return
            }
            XCTAssertTrue(theValue is NSNull)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_02_number_attribute_init_default_value() {
        let jsonStr = """
        {
            "type": "NumberAttributeInputCallback",
            "output": [
                {
                    "name": "name",
                    "value": "testNumber"
                },
                {
                    "name": "prompt",
                    "value": "Test Number"
                },
                {
                    "name": "required",
                    "value": false
                },
                {
                    "name": "policies",
                    "value": {
                        "policyRequirements": [
                            "VALID_TYPE"
                        ],
                        "fallbackPolicies": null,
                        "name": "testNumber",
                        "policies": [
                            {
                                "policyRequirements": [
                                    "VALID_TYPE"
                                ],
                                "policyId": "valid-type",
                                "params": {
                                    "types": [
                                        "number"
                                    ]
                                }
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
                    "value": true
                },
                {
                    "name": "value",
                    "value": 123
                }
            ],
            "input": [
                {
                    "name": "IDToken1",
                    "value": 123
                },
                {
                    "name": "IDToken1validateOnly",
                    "value": true
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            let callback = try NumberAttributeInputCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            XCTAssertFalse(callback.required)
            XCTAssertTrue(callback.validateOnly)
            
            guard let theValue = callback.getValue() as? Double else {
                XCTFail("Failed to parse value in the callback")
                return
            }
            
            XCTAssertEqual(theValue, 123)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    
    func test_03_number_attribute_input_build_response() {
        let jsonStr = """
        {
            "type": "NumberAttributeInputCallback",
            "output": [
                {
                    "name": "name",
                    "value": "testNumber"
                },
                {
                    "name": "prompt",
                    "value": "Test Number"
                },
                {
                    "name": "required",
                    "value": true
                },
                {
                    "name": "policies",
                    "value": {
                        "policyRequirements": [
                            "VALID_TYPE"
                        ],
                        "fallbackPolicies": null,
                        "name": "testNumber",
                        "policies": [
                            {
                                "policyRequirements": [
                                    "VALID_TYPE"
                                ],
                                "policyId": "valid-type",
                                "params": {
                                    "types": [
                                        "number"
                                    ]
                                }
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
                    "name": "value",
                    "value": null
                }
            ],
            "input": [
                {
                    "name": "IDToken1",
                    "value": null
                },
                {
                    "name": "IDToken1validateOnly",
                    "value": false
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            let callback = try NumberAttributeInputCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            
            //  Set value
            callback.setValue(321)
            callback.validateOnly = true
            
            // Builds new response
            let jsonStr2 = """
            {
                "type": "NumberAttributeInputCallback",
                "output": [
                    {
                        "name": "name",
                        "value": "testNumber"
                    },
                    {
                        "name": "prompt",
                        "value": "Test Number"
                    },
                    {
                        "name": "required",
                        "value": true
                    },
                    {
                        "name": "policies",
                        "value": {
                            "policyRequirements": [
                                "VALID_TYPE"
                            ],
                            "fallbackPolicies": null,
                            "name": "testNumber",
                            "policies": [
                                {
                                    "policyRequirements": [
                                        "VALID_TYPE"
                                    ],
                                    "policyId": "valid-type",
                                    "params": {
                                        "types": [
                                            "number"
                                        ]
                                    }
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
                        "name": "value",
                        "value": null
                    }
                ],
                "input": [
                    {
                        "name": "IDToken1",
                        "value": 321
                    },
                    {
                        "name": "IDToken1validateOnly",
                        "value": true
                    }
                ]
            }
            """
            let response = self.parseStringToDictionary(jsonStr2)
            // Should equal when built
            XCTAssertTrue(NSDictionary(dictionary: response).isEqual(to: callback.buildResponse()))
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
}
