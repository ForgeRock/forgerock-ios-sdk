//
//  PollingWaitCallbackTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class PollingWaitCallbackTests: FRAuthBaseTest {
    
    func test_01_CallbackConstruction_Successful() {
        
        // Given
        let message = "Waiting..."
        let waitTime = 8000
        let jsonStr = """
        {
            "type": "PollingWaitCallback",
            "output": [{
                "name": "waitTime",
                "value": "\(waitTime)"
            }, {
                "name": "message",
                "value": "\(message)"
            }]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            let callback = try PollingWaitCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback.waitTime, waitTime)
            XCTAssertEqual(callback.message, message)
            
            let requestPayload = callback.buildResponse()
            XCTAssertTrue(requestPayload.description.contains(String(waitTime)))
            XCTAssertTrue(requestPayload.description.contains(message))
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }


    func test_02_CallbackConstruction_Missing_Output() {

        // Given
        let jsonStr = """
        {
            "type": "ReCaptchaCallback"
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)

        // Then
        do {
            let _ = try PollingWaitCallback(json: callbackResponse)
            XCTFail("Failed to validate missing output section; succeed while expecting failure: \(callbackResponse)")
        }
        catch {
        }
    }
    
    
    func test_03_CallbackConstruction_Missing_Type() {
        
        // Given
        let message = "Waiting..."
        let waitTime = 8000
        let jsonStr = """
        {
        "output": [{
        "name": "waitTime",
        "value": "\(waitTime)"
        }, {
        "name": "message",
        "value": "\(message)"
        }]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            let _ = try PollingWaitCallback(json: callbackResponse)
            XCTFail("Failed to validate missing type value; succeed while expecting failure: \(callbackResponse)")
        }
        catch {
        }
    }
    
    
    func test_04_CallbackConstruction_Missing_Message() {
        
        // Given
        let waitTime = 8000
        let jsonStr = """
        {
            "type": "ReCaptchaCallback",
            "output": [{
                "name": "waitTime",
                "value": "\(waitTime)"
            }]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            let _ = try PollingWaitCallback(json: callbackResponse)
            XCTFail("Failed to validate missing type value; succeed while expecting failure: \(callbackResponse)")
        }
        catch {
        }
    }
    
    
    func test_04_CallbackConstruction_Missing_WaitTime() {
        
        // Given
        let message = "Waiting..."
        let jsonStr = """
        {
            "type": "ReCaptchaCallback",
            "output": [{
            "name": "message",
                "value": "\(message)"
            }]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            let _ = try PollingWaitCallback(json: callbackResponse)
            XCTFail("Failed to validate missing type value; succeed while expecting failure: \(callbackResponse)")
        }
        catch {
        }
    }
}
