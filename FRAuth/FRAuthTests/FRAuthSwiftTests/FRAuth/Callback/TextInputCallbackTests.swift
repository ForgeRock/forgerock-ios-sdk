// 
//  TextInputCallbackTests.swift
//  FRAuthTests
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

class TextInputCallbackTests: FRAuthBaseTest {

    func testTextInputCallbackWithEmptyJSON() {
        
        // Try
        do {
            let callback = try TextInputCallback(json: [:])
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
    
    func testTextInputCallbackInit() {
        
        // Given
        let jsonStr = """
        {
        "type": "TextInputCallback",
        "output": [{
                "name": "prompt",
                "value": "One Time Pin"
            },
            {
                "name": "defaultText",
                "value": "default"
        }],
        "input": [{
            "name": "IDToken1", "value": ""
        }],
        "_id": 1
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let callback = try TextInputCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback._id, 1)
            XCTAssertEqual(callback.type, "TextInputCallback")
            XCTAssertEqual(callback.prompt, "One Time Pin")
            XCTAssertEqual(callback.getDefaultText(), "default")
            XCTAssertEqual(callback.inputName, "IDToken1")
            
            // Sets value
            callback.setValue("339709")
            
            // Builds new response
            let jsonStr2 = """
            {
            "type": "TextInputCallback",
            "output": [{
                    "name": "prompt",
                    "value": "One Time Pin"
                },
                {
                    "name": "defaultText",
                    "value": "default"
            }],
            "input": [{
                "name": "IDToken1", "value": "339709"
            }],
            "_id": 1
            }
            """
            let response = self.parseStringToDictionary(jsonStr2)
            
            // Should equal when built
            XCTAssertTrue(NSDictionary(dictionary: response).isEqual(to: callback.buildResponse()))
            
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    func testTextInputCallbackWithMultipleOutputs() {
        // Given
        let jsonStr = """
        {
        "type": "TextInputCallback",
        "output": [{
                "name": "prompt","value": "User Name"
            },{
                "name": "testing", "value": "what"
            }],
        "input": [{
            "name": "IDToken2", "value": ""
        }],
        "_id": 1
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let callback = try TextInputCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback._id, 1)
            XCTAssertEqual(callback.type, "TextInputCallback")
            XCTAssertEqual(callback.prompt, "User Name")
            XCTAssertEqual(callback.inputName, "IDToken2")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    func testTextInputCallbackMissingPrompt() {
        // Given
        let jsonStr = """
        {
        "type": "TextInputCallback",
        "output": [{
                "name": "noPrompt","value": "User Name"
            }],
        "input": [{
            "name": "IDToken2", "value": ""
        }],
        "_id": 1
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let callback = try TextInputCallback(json: callbackResponse)
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
    
    func testTextInputCallbackMissingInput() {
        
        // Given
        let jsonStr = """
        {
        "type": "TextInputCallback",
        "output": [{
                "name": "prompt","value": "User Name"
            }],
        "_id": 1
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let callback = try TextInputCallback(json: callbackResponse)
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

