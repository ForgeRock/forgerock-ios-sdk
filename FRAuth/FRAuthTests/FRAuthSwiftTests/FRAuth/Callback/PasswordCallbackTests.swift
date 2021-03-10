//
//  PasswordCallbackTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class PasswordCallbackTests: FRAuthBaseTest {

    func testPasswordCallbackWithEmptyJSON() {
        
        // Try
        do {
            let callback = try PasswordCallback(json: [:])
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
    
    func testPasswordCallbackInit() {
        
        // Given
        let jsonStr = """
        {
        "type": "PasswordCallback",
        "output": [{
                "name": "prompt","value": "Password"
            }],
        "input": [{
            "name": "IDToken3", "value": ""
        }],
        "_id": 2
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let callback = try PasswordCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback._id, 2)
            XCTAssertEqual(callback.type, "PasswordCallback")
            XCTAssertEqual(callback.prompt, "Password")
            XCTAssertEqual(callback.inputName, "IDToken3")
            
            
            // Sets Username
            callback.setValue("Password123!")
            
            // Builds new response
            let jsonStr2 = """
            {
            "type": "PasswordCallback",
            "output": [{
                    "name": "prompt","value": "Password"
                }],
            "input": [{
                "name": "IDToken3", "value": "Password123!"
            }],
            "_id": 2
            }
            """
            let response = self.parseStringToDictionary(jsonStr2)
            
            // Should equal when built
            XCTAssertTrue(NSDictionary(dictionary: response).isEqual(to: callback.buildResponse()))
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    func testPasswordCallbackWithMultipleOutputs() {
        // Given
        let jsonStr = """
        {
        "type": "PasswordCallback",
        "output": [{
                "name": "prompt","value": "Password"
            },{
                "name": "testing", "value": "what"
            }],
        "input": [{
            "name": "IDToken3", "value": ""
        }],
        "_id": 2
        }
        """
        
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let callback = try PasswordCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback._id, 2)
            XCTAssertEqual(callback.type, "PasswordCallback")
            XCTAssertEqual(callback.prompt, "Password")
            XCTAssertEqual(callback.inputName, "IDToken3")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    func testNameCallbackMissingPrompt() {
        // Given
        let jsonStr = """
        {
        "type": "PasswordCallback",
        "output": [{
                "name": "noPrompt","value": "Password"
            }],
        "input": [{
            "name": "IDToken3", "value": ""
        }],
        "_id": 2
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let callback = try PasswordCallback(json: callbackResponse)
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
        "type": "PasswordCallback",
        "output": [{
                "name": "noPrompt","value": "Password"
            }],
        "_id": 2
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let callback = try PasswordCallback(json: callbackResponse)
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
