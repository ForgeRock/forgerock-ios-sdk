//
//  TextOutputCallback.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class TextOutputCallbackTests: FRAuthBaseTest {

    func test_01_CallbackConstruction_Successful() {
        
        // Given
        let message = "This is message"
        let messageType: String = "0"
        let jsonStr = """
        {
        "type": "TextOutputCallback",
        "output": [{
        "name": "message",
        "value": "\(message)"
        }, {
        "name": "messageType",
        "value": "\(messageType)"
        }]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            let callback = try TextOutputCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback.message, message)
            XCTAssertEqual(callback.messageType, MessageType.information)
            let requestPayload = callback.buildResponse()
            XCTAssertTrue(requestPayload == callbackResponse)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_02_CallbackConstruction_With_InputSection_Successful() {
        
        // Given
        let message = "This is message"
        let messageType: String = "0"
        let inputName = "IDToken1"
        let jsonStr = """
        {
            "type": "TextOutputCallback",
            "output": [{
                "name": "message",
                "value": "\(message)"
            }, {
                "name": "messageType",
                "value": "\(messageType)"
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
            let callback = try TextOutputCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback.message, message)
            XCTAssertEqual(callback.messageType.rawValue, Int(messageType))
            let requestPayload = callback.buildResponse()
            XCTAssertTrue(requestPayload == callbackResponse)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_03_CallbackConstruction_Missing_Output() {
        
        // Given
        let jsonStr = """
        {
            "type": "TextOutputCallback"
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Then
        do {
            let _ = try TextOutputCallback(json: callbackResponse)
            XCTFail("Failed to validate missing output section; succeed while expecting failure: \(callbackResponse)")
        }
        catch {
        }
    }
    
    
    func test_04_CallbackConstruction_Missing_Message() {
        
        // Given
        let messageType: String = "0"
        let jsonStr = """
        {
        "type": "TextOutputCallback",
        "output": [{
        "name": "messageType",
        "value": "\(messageType)"
        }]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        
        // When
        do {
            let callback = try TextOutputCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback.message.count, 0)
            XCTAssertEqual(callback.messageType.rawValue, Int(messageType))
            let requestPayload = callback.buildResponse()
            XCTAssertTrue(requestPayload == callbackResponse)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_05_CallbackConstruction_Invalid_MessageType() {
        
        // Given
        let message = "This is message"
        let messageType: String = "5"
        let jsonStr = """
        {
        "type": "TextOutputCallback",
        "output": [{
        "name": "message",
        "value": "\(message)"
        }, {
        "name": "messageType",
        "value": "\(messageType)"
        }]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        
        // When
        do {
            let callback = try TextOutputCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback.message, message)
            XCTAssertEqual(callback.messageType, .unknown)
            let requestPayload = callback.buildResponse()
            XCTAssertTrue(requestPayload == callbackResponse)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_05_CallbackConstruction_Warning_MessageType() {
        
        // Given
        let message = "This is message"
        let messageType: String = "1"
        let jsonStr = """
        {
        "type": "TextOutputCallback",
        "output": [{
        "name": "message",
        "value": "\(message)"
        }, {
        "name": "messageType",
        "value": "\(messageType)"
        }]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            let callback = try TextOutputCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback.message, message)
            XCTAssertEqual(callback.messageType, MessageType.warning)
            let requestPayload = callback.buildResponse()
            XCTAssertTrue(requestPayload == callbackResponse)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_05_CallbackConstruction_Error_MessageType() {
        
        // Given
        let message = "This is message"
        let messageType: String = "2"
        let jsonStr = """
        {
        "type": "TextOutputCallback",
        "output": [{
        "name": "message",
        "value": "\(message)"
        }, {
        "name": "messageType",
        "value": "\(messageType)"
        }]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            let callback = try TextOutputCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback.message, message)
            XCTAssertEqual(callback.messageType, MessageType.error)
            let requestPayload = callback.buildResponse()
            XCTAssertTrue(requestPayload == callbackResponse)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
}


// Reference: https://stackoverflow.com/a/56773151

func areEqual (_ left: Any, _ right: Any) -> Bool {
    if  type(of: left) == type(of: right) &&
        String(describing: left) == String(describing: right) { return true }
    if let left = left as? [Any], let right = right as? [Any] { return left == right }
    if let left = left as? [AnyHashable: Any], let right = right as? [AnyHashable: Any] { return left == right }
    return false
}


extension Array where Element: Any {
    static func != (left: [Element], right: [Element]) -> Bool { return !(left == right) }
    static func == (left: [Element], right: [Element]) -> Bool {
        if left.count != right.count { return false }
        var right = right
        loop: for leftValue in left {
            for (rightIndex, rightValue) in right.enumerated() where areEqual(leftValue, rightValue) {
                right.remove(at: rightIndex)
                continue loop
            }
            return false
        }
        return true
    }
}


extension Dictionary where Value: Any {
    static func != (left: [Key : Value], right: [Key : Value]) -> Bool { return !(left == right) }
    static func == (left: [Key : Value], right: [Key : Value]) -> Bool {
        if left.count != right.count { return false }
        for element in left {
            guard   let rightValue = right[element.key],
                areEqual(rightValue, element.value) else { return false }
        }
        return true
    }
}
