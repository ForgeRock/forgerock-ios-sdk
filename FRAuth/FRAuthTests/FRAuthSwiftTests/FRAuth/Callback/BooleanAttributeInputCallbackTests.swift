// 
//  BooleanAttributeInputCallbackTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class BooleanAttributeInputCallbackTests: FRAuthBaseTest {
    
    func test_01_bool_attribute_init() {
        let jsonStr = """
        {
            "type": "BooleanAttributeInputCallback",
            "output": [
                {
                    "name": "name",
                    "value": "booleanAttribute"
                },
                {
                    "name": "prompt",
                    "value": "This is boolean attribute"
                },
                {
                    "name": "required",
                    "value": true
                },
                {
                    "name": "policies",
                    "value": {}
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
                    "value": false
                }
            ],
            "input": [
                {
                    "name": "IDToken1",
                    "value": false
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
            let callback = try BooleanAttributeInputCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            XCTAssertTrue(callback.required)
            XCTAssertFalse(callback.validateOnly)
            
            guard let theValue = callback.getValue() as? Bool else {
                XCTFail("Failed to parse value in the callback")
                return
            }
            
            XCTAssertFalse(theValue)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_02_bool_attribute_init_default_true() {
        let jsonStr = """
        {
            "type": "BooleanAttributeInputCallback",
            "output": [
                {
                    "name": "name",
                    "value": "booleanAttribute"
                },
                {
                    "name": "prompt",
                    "value": "This is boolean attribute"
                },
                {
                    "name": "required",
                    "value": false
                },
                {
                    "name": "policies",
                    "value": {}
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
                    "value": true
                }
            ],
            "input": [
                {
                    "name": "IDToken1",
                    "value": true
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
            let callback = try BooleanAttributeInputCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            XCTAssertFalse(callback.required)
            XCTAssertTrue(callback.validateOnly)
            
            guard let theValue = callback.getValue() as? Bool else {
                XCTFail("Failed to parse value in the callback")
                return
            }
            
            XCTAssertTrue(theValue)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_03_bool_attribute_input_build_response() {
        let jsonStr = """
        {
            "type": "BooleanAttributeInputCallback",
            "output": [
                {
                    "name": "name",
                    "value": "booleanAttribute"
                },
                {
                    "name": "prompt",
                    "value": "This is boolean attribute"
                },
                {
                    "name": "required",
                    "value": true
                },
                {
                    "name": "policies",
                    "value": {}
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
                    "value": false
                }
            ],
            "input": [
                {
                    "name": "IDToken1",
                    "value": false
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
            let callback = try BooleanAttributeInputCallback(json: callbackResponse)
            
            // Then
            XCTAssertNotNil(callback)
            
            //  Set value
            callback.setValue(true)
            callback.validateOnly = true
            
            // Builds new response
            let jsonStr2 = """
            {
                "type": "BooleanAttributeInputCallback",
                "output": [
                    {
                        "name": "name",
                        "value": "booleanAttribute"
                    },
                    {
                        "name": "prompt",
                        "value": "This is boolean attribute"
                    },
                    {
                        "name": "required",
                        "value": true
                    },
                    {
                        "name": "policies",
                        "value": {}
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
                        "value": false
                    }
                ],
                "input": [
                    {
                        "name": "IDToken1",
                        "value": true
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
