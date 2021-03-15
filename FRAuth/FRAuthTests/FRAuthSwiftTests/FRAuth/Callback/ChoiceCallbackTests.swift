//
//  ChoiceCallback.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class ChoiceCallbackTests: FRAuthBaseTest {

    func testChoiceCallbackWithEmptyJSON() {
        
        // Try
        do {
            let callback = try ChoiceCallback(json: [:])
            // If not fail, should fail
            XCTFail("Passed while expecting failure with empty Dictionary, and callback obj: \(callback)")
        } catch let error as AuthError {
            // Catch AuthError
            switch error {
            // Should only fail with this error
            case .invalidCallbackResponse:
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    func testChoiceCallbackInit() {
        // Given
        let jsonStr = """
        {
            "type": "ChoiceCallback",
            "output": [
                {
                    "name": "prompt",
                    "value": "SecondFactorChoice"
                },
                {
                    "name": "choices",
                    "value": [
                        "Email",
                        "SMS"
                    ]
                },
                {
                    "name": "defaultChoice",
                    "value": 0
                }
            ],
            "input": [
                {
                    "name": "IDToken2",
                    "value": 0
                }
            ],
            "_id": 5
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let callback = try ChoiceCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback._id, 5)
            XCTAssertEqual(callback.type, "ChoiceCallback")
            XCTAssertEqual(callback.prompt, "SecondFactorChoice")
            XCTAssertEqual(callback.inputName, "IDToken2")
            XCTAssertEqual(callback.defaultChoice, 0)
            XCTAssertEqual(callback.getValue() as? String, "0")
            XCTAssertEqual(callback.choices, ["Email", "SMS"])
            
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    func testChoiceCallbackInitWithAdditionalOutput() {
        // Given
        let jsonStr = """
        {
            "type": "ChoiceCallback",
            "output": [
                {
                    "name": "prompt",
                    "value": "SecondFactorChoice"
                },
                {
                    "name": "choices",
                    "value": [
                        "Email",
                        "SMS"
                    ]
                },
                {
                    "name": "defaultChoice",
                    "value": 0
                },
                {
                    "name": "additionalOuput",
                    "value": "additional output value"
                }
            ],
            "input": [
                {
                    "name": "IDToken2",
                    "value": 0
                }
            ],
            "_id": 5
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let callback = try ChoiceCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback._id, 5)
            XCTAssertEqual(callback.type, "ChoiceCallback")
            XCTAssertEqual(callback.prompt, "SecondFactorChoice")
            XCTAssertEqual(callback.inputName, "IDToken2")
            XCTAssertEqual(callback.defaultChoice, 0)
            XCTAssertEqual(callback.getValue() as? String, "0")
            XCTAssertEqual(callback.choices, ["Email", "SMS"])
            
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    func testChoiceCallbackInitWithDefaultChoice() {
        // Given
        let jsonStr = """
        {
            "type": "ChoiceCallback",
            "output": [
                {
                    "name": "prompt",
                    "value": "SecondFactorChoice"
                },
                {
                    "name": "choices",
                    "value": [
                        "Email",
                        "SMS1",
                        "SMS2",
                        "SMS3",
                        "SMS4",
                    ]
                },
                {
                    "name": "defaultChoice",
                    "value": 3
                }
            ],
            "input": [
                {
                    "name": "IDToken2",
                    "value": 0
                }
            ],
            "_id": 5
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let callback = try ChoiceCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback._id, 5)
            XCTAssertEqual(callback.type, "ChoiceCallback")
            XCTAssertEqual(callback.prompt, "SecondFactorChoice")
            XCTAssertEqual(callback.inputName, "IDToken2")
            XCTAssertEqual(callback.defaultChoice, 3)
            XCTAssertEqual(callback.getValue() as? String, "3")
            XCTAssertEqual(callback.choices, ["Email", "SMS1", "SMS2", "SMS3", "SMS4"])
            
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    func testChoiceCallbackMissingInput() {
        // Given
        let jsonStr = """
        {
            "type": "ChoiceCallback",
            "output": [
                {
                    "name": "prompt",
                    "value": "SecondFactorChoice"
                },
                {
                    "name": "choices",
                    "value": [
                        "Email",
                        "SMS1",
                        "SMS2",
                        "SMS3",
                        "SMS4",
                    ]
                },
                {
                    "name": "defaultChoice",
                    "value": 3
                }
            ],
            "_id": 5
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let callback = try ChoiceCallback(json: callbackResponse)
            // If not fail, should fail
            XCTFail("Passed while expecting failure with \(callbackResponse), and callback obj: \(callback)")
        } catch let error as AuthError {
            // Catch AuthError
            switch error {
            // Should only fail with this error
            case .invalidCallbackResponse:
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    func testChoiceCallbackMissingPrompt() {
        // Given
        let jsonStr = """
        {
            "type": "ChoiceCallback",
            "output": [
                {
                    "name": "noPrompt",
                    "value": "SecondFactorChoice"
                },
                {
                    "name": "choices",
                    "value": [
                        "Email",
                        "SMS1",
                        "SMS2",
                        "SMS3",
                        "SMS4",
                    ]
                },
                {
                    "name": "defaultChoice",
                    "value": 3
                }
            ],
            "input": [
                {
                    "name": "IDToken2",
                    "value": 0
                }
            ],
            "_id": 5
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let callback = try ChoiceCallback(json: callbackResponse)
            // If not fail, should fail
            XCTFail("Passed while expecting failure with \(callbackResponse), and callback obj: \(callback)")
        } catch let error as AuthError {
            // Catch AuthError
            switch error {
            // Should only fail with this error
            case .invalidCallbackResponse:
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    func testChoiceCallbackEmptyChoice() {
        // Given
        let jsonStr = """
        {
            "type": "ChoiceCallback",
            "output": [
                {
                    "name": "noPrompt",
                    "value": "SecondFactorChoice"
                },
                {
                    "name": "defaultChoice",
                    "value": 3
                }
            ],
            "input": [
                {
                    "name": "IDToken2",
                    "value": 0
                }
            ],
            "_id": 5
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let callback = try ChoiceCallback(json: callbackResponse)
            // If not fail, should fail
            XCTFail("Passed while expecting failure with \(callbackResponse), and callback obj: \(callback)")
        } catch let error as AuthError {
            // Catch AuthError
            switch error {
            // Should only fail with this error
            case .invalidCallbackResponse:
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func testChoiceCallbackEmptyOutput() {
        // Given
        let jsonStr = """
        {
            "type": "ChoiceCallback",
            "input": [
                {
                    "name": "IDToken2",
                    "value": 0
                }
            ],
            "_id": 5
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let callback = try ChoiceCallback(json: callbackResponse)
            // If not fail, should fail
            XCTFail("Passed while expecting failure with \(callbackResponse), and callback obj: \(callback)")
        } catch let error as AuthError {
            // Catch AuthError
            switch error {
            // Should only fail with this error
            case .invalidCallbackResponse:
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
}
