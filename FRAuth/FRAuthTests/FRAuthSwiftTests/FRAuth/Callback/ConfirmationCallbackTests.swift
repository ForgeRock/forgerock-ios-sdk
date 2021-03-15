//
//  ConfirmationCallbackTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class ConfirmationCallbackTests: FRAuthBaseTest {
    
    func test_01_CallbackConstruction_Successful() {
        
        // Given
        let options = "\"Exit\", \"Continue\""
        let optionType = -1
        let messageType = 0
        let prompt = "Confirm"
        let defaultOption = 0
        let inputName = "IDToken2"
        let inputValue = 100
        let _id = 9
        let jsonStr = """
        {
            "_id": \(_id),
            "type": "ConfirmationCallback",
            "output": [{
                "name": "prompt",
                "value": "\(prompt)"
            }, {
                "name": "messageType",
                "value": \(messageType)
            }, {
                "name": "options",
                "value": [\(options)]
            }, {
                "name": "optionType",
                "value": \(optionType)
            }, {
                "name": "defaultOption",
                "value": \(defaultOption)
            }],
            "input": [{
                "name": "\(inputName)",
                "value": \(inputValue)
            }]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            let callback = try ConfirmationCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback._id, _id)
            XCTAssertEqual(callback.prompt, prompt)
            XCTAssertEqual(callback.messageType, MessageType.information)
            XCTAssertEqual(callback.optionType, OptionType.unspecifiedOption)
            XCTAssertEqual(callback.defaultOption, defaultOption)
            XCTAssertEqual(callback.inputName, inputName)
            XCTAssertEqual(callback.value as! Int, inputValue)
            XCTAssertEqual(callback.options!.count, 2)
            XCTAssertTrue(callback.options!.contains("Exit"))
            XCTAssertTrue(callback.options!.contains("Continue"))
            
            let requestPayload = callback.buildResponse()
            XCTAssertTrue(requestPayload.description.contains(prompt))
            XCTAssertTrue(requestPayload.description.contains(inputName))
            XCTAssertTrue(requestPayload.description.contains("Exit"))
            XCTAssertTrue(requestPayload.description.contains("Continue"))
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_02_CallbackConstruction_Various_MessageTypes() {
        
        // Given
        
        //
        //  MessageType values
        //
        //  0: information
        //  1: warning
        //  2: error
        // anything else: unknown
        //
        let messageTypeExpectedValue: [MessageType] = [.information, .warning, .error, .unknown]
        for messageTypeValue in 0 ... 3 {
            let jsonStr = """
            {
            "type": "ConfirmationCallback",
            "output": [{
            "name": "prompt",
            "value": ""
            }, {
            "name": "messageType",
            "value": \(messageTypeValue)
            }, {
            "name": "options",
            "value": ["Exit"]
            }, {
            "name": "optionType",
            "value": -1
            }, {
            "name": "defaultOption",
            "value": 0
            }],
            "input": [{
            "name": "IDToken2",
            "value": 100
            }]
            }
            """
            let callbackResponse = self.parseStringToDictionary(jsonStr)
            
            // When
            do {
                let callback = try ConfirmationCallback(json: callbackResponse)
                // Then
                XCTAssertEqual(callback.messageType, messageTypeExpectedValue[messageTypeValue])
            }
            catch {
                XCTFail("Failed to construct callback: \(callbackResponse)")
            }
        }
    }
    
    
    func test_03_CallbackConstruction_Various_OptionType() {
        
        // Given
        
        //
        //  OptionType values
        //
        // -1: unspecifiedOption
        //  0: yesNoOption
        //  1: yesNoCancelOption
        //  2: okCancelOption
        // anything else: unknown
        //
        let optionTypeExpectedValue: [OptionType] = [.unspecifiedOption, .yesNoOption, .yesNoCancelOption, .okCancelOption, .unknown]
        for optionTypeValue in 0 ... 4 {
            let jsonStr = """
            {
            "type": "ConfirmationCallback",
            "output": [{
            "name": "prompt",
            "value": ""
            }, {
            "name": "messageType",
            "value": 0
            }, {
            "name": "options",
            "value": ["Exit"]
            }, {
            "name": "optionType",
            "value": \(optionTypeValue-1)
            }, {
            "name": "defaultOption",
            "value": 0
            }],
            "input": [{
            "name": "IDToken2",
            "value": 100
            }]
            }
            """
            let callbackResponse = self.parseStringToDictionary(jsonStr)
            
            // When
            do {
                let callback = try ConfirmationCallback(json: callbackResponse)
                // Then
                XCTAssertEqual(callback.optionType, optionTypeExpectedValue[optionTypeValue])
            }
            catch {
                XCTFail("Failed to construct callback: \(callbackResponse)")
            }
        }
    }
    
    
    func test_04_CallbackConstruction_Various_Options() {
        
        // Given
        
        //
        //  Option values
        //
        //  0: yes
        //  1: no
        //  2: cancel
        //  3: ok
        // anything else: unknown
        //
        let optionExpectedValue: [Option] = [.yes, .no, .cancel, .ok, .unknown]
        for optionValue in 0 ... 4 {
            let jsonStr = """
            {
            "type": "ConfirmationCallback",
            "output": [{
            "name": "prompt",
            "value": ""
            }, {
            "name": "messageType",
            "value": 0
            }, {
            "name": "options",
            "value": ["Exit"]
            }, {
            "name": "optionType",
            "value": -1
            }, {
            "name": "option",
            "value": \(optionValue)
            }, {
            "name": "defaultOption",
            "value": 0
            }],
            "input": [{
            "name": "IDToken2",
            "value": 100
            }]
            }
            """
            let callbackResponse = self.parseStringToDictionary(jsonStr)
            
            // When
            do {
                let callback = try ConfirmationCallback(json: callbackResponse)
                // Then
                XCTAssertEqual(callback.option, optionExpectedValue[optionValue])
            }
            catch {
                XCTFail("Failed to construct callback: \(callbackResponse)")
            }
        }
    }
    
    
    func test_05_CallbackConstruction_Missing_Output() {
        
        // Given
        let jsonStr = """
        {
            "type": "ConfirmationCallback",
            "input": [{
                "name": "IDToken2",
                "value": 100
            }]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Then
        do {
            let _ = try ConfirmationCallback(json: callbackResponse)
            XCTFail("Failed to validate missing output section; succeed while expecting failure: \(callbackResponse)")
        }
        catch {
        }
    }
    
    
    func test_06_CallbackConstruction_Missing_Input() {
        
        // Given
        let jsonStr = """
        {
            "type": "ConfirmationCallback",
            "output": [{
                "name": "prompt",
                "value": ""
            }, {
                "name": "messageType",
                "value": 0
            }, {
                "name": "options",
                "value": ["Exit"]
            }, {
                "name": "optionType",
                "value": -1
            }, {
                "name": "defaultOption",
                "value": 0
            }]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Then
        do {
            let _ = try ConfirmationCallback(json: callbackResponse)
            XCTFail("Failed to validate missing input section; succeed while expecting failure: \(callbackResponse)")
        }
        catch {
        }
    }
    
    
    func test_06_CallbackConstruction_Missing_Type() {
        
        // Given
        let jsonStr = """
        {
            "output": [{
                "name": "prompt",
                "value": ""
            }, {
                "name": "messageType",
                "value": 0
            }, {
                "name": "options",
                "value": ["Exit"]
            }, {
                "name": "optionType",
                "value": -1
            }, {
                "name": "defaultOption",
                "value": 0
            }],
            "input": [{
                "name": "IDToken2",
                "value": 100
            }]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Then
        do {
            let _ = try ConfirmationCallback(json: callbackResponse)
            XCTFail("Failed to validate missing type attribute; succeed while expecting failure: \(callbackResponse)")
        }
        catch {
        }
    }
    
    
    func test_06_CallbackConstruction_Missing_InputName() {
        
        // Given
        let jsonStr = """
        {
            "type": "ConfirmationCallback",
            "output": [{
                "name": "prompt",
                "value": ""
            }, {
                "name": "messageType",
                "value": 0
            }, {
                "name": "options",
                "value": ["Exit"]
            }, {
                "name": "optionType",
                "value": -1
            }, {
                "name": "defaultOption",
                "value": 0
            }],
            "input": [{
                "InvalidInputName": "IDToken2",
                "value": 100
            }]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Then
        do {
            let _ = try ConfirmationCallback(json: callbackResponse)
            XCTFail("Failed to validate missing inputName; succeed while expecting failure: \(callbackResponse)")
        }
        catch {
        }
    }
}
