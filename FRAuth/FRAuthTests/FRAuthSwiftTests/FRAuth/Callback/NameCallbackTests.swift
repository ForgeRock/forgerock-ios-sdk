//
//  NameCallbackTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class NameCallbackTests: FRAuthBaseTest {

    func testNameCallbackWithEmptyJSON() {
        
        // Try
        do {
            let callback = try NameCallback(json: [:])
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
    
    func testNameCallbackInit() {
        
        // Given
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
        
        // Try
        do {
            let callback = try NameCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback._id, 1)
            XCTAssertEqual(callback.type, "NameCallback")
            XCTAssertEqual(callback.prompt, "User Name")
            XCTAssertEqual(callback.inputName, "IDToken2")
            
            // Sets Username
            callback.setValue("username")
            
            // Builds new response
            let jsonStr2 = """
            {
            "type": "NameCallback",
            "output": [{
                    "name": "prompt","value": "User Name"
                }],
            "input": [{
                "name": "IDToken2", "value": "username"
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
    
    func testNameCallbackWithMultipleOutputs() {
        // Given
        let jsonStr = """
        {
        "type": "NameCallback",
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
            let callback = try NameCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback._id, 1)
            XCTAssertEqual(callback.type, "NameCallback")
            XCTAssertEqual(callback.prompt, "User Name")
            XCTAssertEqual(callback.inputName, "IDToken2")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    func testNameCallbackMissingPrompt() {
        // Given
        let jsonStr = """
        {
        "type": "NameCallback",
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
            let callback = try NameCallback(json: callbackResponse)
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
    
    func testNameCallbackMissingInput() {
        
        // Given
        let jsonStr = """
        {
        "type": "NameCallback",
        "output": [{
                "name": "prompt","value": "User Name"
            }],
        "_id": 1
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let callback = try NameCallback(json: callbackResponse)
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
