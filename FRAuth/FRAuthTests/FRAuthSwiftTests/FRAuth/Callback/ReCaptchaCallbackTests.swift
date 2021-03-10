//
//  ReCaptchaCallbackTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class ReCaptchaCallbackTests: FRAuthBaseTest {

    func test_01_CallbackConstruction_Successful() {
        
        // Given
        let siteKey = "6Lf28rYUAAAAABBBJRo4wfESx3_-OYji9Dp-pRa3"
        let inputName = "IDToken1"
        let jsonStr = """
        {
            "type": "ReCaptchaCallback",
            "output": [{
                "name": "recaptchaSiteKey",
                "value": "\(siteKey)"
            }],
            "input": [{
                "name": "\(inputName)",
                "value": ""
            }]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            let callback = try ReCaptchaCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback.recaptchaSiteKey, siteKey)
            XCTAssertEqual(callback.inputName, inputName)
            
            let requestPayload = callback.buildResponse()
            XCTAssertTrue(requestPayload.description.contains(siteKey))
            XCTAssertTrue(requestPayload.description.contains(inputName))
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }

    func test_02_CallbackConstruction_Missing_Input() {
        // Given
        let siteKey = "6Lf28rYUAAAAABBBJRo4wfESx3_-OYji9Dp-pRa3"
        let jsonStr = """
        {
        "type": "ReCaptchaCallback",
        "output": [{
        "name": "recaptchaSiteKey",
        "value": "\(siteKey)"
        }]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Then
        do {
            let _ = try ReCaptchaCallback(json: callbackResponse)
            XCTFail("Failed to validate missing input section; succeed while expecting failure: \(callbackResponse)")
        }
        catch {
        }
    }
    
    
    func test_03_CallbackConstruction_Missing_Output() {
        
        // Given
        let inputName = "IDToken1"
        let jsonStr = """
        {
            "type": "ReCaptchaCallback",
            "input": [{
                "name": "\(inputName)",
                "value": ""
            }]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Then
        do {
            let _ = try ReCaptchaCallback(json: callbackResponse)
            XCTFail("Failed to validate missing output section; succeed while expecting failure: \(callbackResponse)")
        }
        catch {
        }
    }

    
    func test_04_CallbackConstruction_Missing_Type() {
        
        // Given
        let siteKey = "6Lf28rYUAAAAABBBJRo4wfESx3_-OYji9Dp-pRa3"
        let inputName = "IDToken1"
        let jsonStr = """
        {
        "output": [{
        "name": "recaptchaSiteKey",
        "value": "\(siteKey)"
        }],
        "input": [{
        "name": "\(inputName)",
        "value": ""
        }]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            let _ = try ReCaptchaCallback(json: callbackResponse)
            XCTFail("Failed to validate missing type value; succeed while expecting failure: \(callbackResponse)")
        }
        catch {
        }
    }
    
    
    func test_05_CallbackConstruction_Missing_SiteKey() {
        
        // Given
        let siteKey = "6Lf28rYUAAAAABBBJRo4wfESx3_-OYji9Dp-pRa3"
        let inputName = "IDToken1"
        let jsonStr = """
        {
            "type": "ReCaptchaCallback",
            "output": [{
                "name": "somethingElse",
                "value": "\(siteKey)"
            }],
            "input": [{
                "name": "\(inputName)",
                "value": ""
            }]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            let _ = try ReCaptchaCallback(json: callbackResponse)
            XCTFail("Failed to validate missing SiteKey value; succeed while expecting failure: \(callbackResponse)")
        }
        catch {
        }
    }
}
