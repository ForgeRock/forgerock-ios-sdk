//
//  CustomCallbackTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class CustomCallbackTests: FRAuthBaseTest {
    
    var originalSupportedCallbacks: [String: Callback.Type]?
    
    override func setUp() {
        self.configFileName = "Config"
        self.originalSupportedCallbacks = CallbackFactory.shared.supportedCallbacks
        super.setUp()
    }
    
    
    override func tearDown() {
        if let callbacks = self.originalSupportedCallbacks {
            CallbackFactory.shared.supportedCallbacks = callbacks
        }
        print(CallbackFactory.shared.supportedCallbacks)
        super.tearDown()
    }
    
    func test_01_Validate_CustomCallback_Registration() {
        
        // Given
        CallbackFactory.shared.registerCallback(callbackType: "CustomCallback", callbackClass: CustomCallback.self)
        
        // Then
        XCTAssertTrue(CallbackFactory.shared.supportedCallbacks.keys.contains("CustomCallback"))
        XCTAssertTrue((CallbackFactory.shared.supportedCallbacks["CustomCallback"] == CustomCallback.self))
        
        // Cleanup
        CallbackFactory.shared.supportedCallbacks.removeValue(forKey: "CustomCallback")
    }
    
    
    func test_02_Validate_CustomCallback_Building_Response() {
        
        // Given
        let jsonStr = """
        {
        "type": "CustomCallback",
        "output": [{
                "name": "prompt",
                "value": "Custom Input"
            },
            {
                "name": "customAttribute",
                "value": "CustomAttributeValue"
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
            let callback = try CustomCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback._id, 1)
            XCTAssertEqual(callback.type, "CustomCallback")
            XCTAssertEqual(callback.prompt, "Custom Input")
            XCTAssertEqual(callback.customAttribute, "CustomAttributeValue")
            XCTAssertEqual(callback.inputName, "IDToken1")
            
            let response = callback.buildResponse()
            
            guard let custom = response["custom"] as? [String: String] else {
                XCTFail("Failed to parse CustomCallback.swift paylaod")
                return
            }
            
            XCTAssertTrue(custom.keys.contains("CustomCallbackInput"))
            XCTAssertEqual(custom["CustomCallbackInput"], "CustomCallbackValue")
            
            guard let outputs = response["output"] as? [[String: String]] else {
                XCTFail("Failed to retrieve input attribute from CustomCallback.swift paylaod")
                return
            }
            
            var customInputValidated = false
            
            for output in outputs {
                if let outputName = output["name"], let outputValue = output["value"], outputName == "customAttribute", outputValue == "CustomAttributeValue" {
                    customInputValidated = true
                }
            }
            XCTAssertTrue(customInputValidated)
            
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func test_03_Validate_Unsupported_Callback() {
        
        guard self.shouldLoadMockResponses else {
            // Ignoring test if test is against actual server, and not against mock response
            return
        }
        
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to load ServerConfig from test configuration")
            return
        }
        
        // Load mock responses for AuthTree with custom callback
        self.loadMockResponses(["AuthTree_UsernamePasswordNodeWithCustomCallback"])
        
        // Given
        let authService = AuthService(name: "CustomCallbackService", serverConfig: serverConfig)
        
        // When
        let ex = self.expectation(description: "Node Submit")
        authService.next { (token: Token?, node, error) in
            
            // Then
            
            // Validate response
            XCTAssertNil(token)
            XCTAssertNil(node)
            XCTAssertNotNil(error)
            
            // Validate correct error is returned
            if let authError = error as? AuthError {
                switch authError {
                case .unsupportedCallback:
                    break
                default:
                    XCTFail("Received unexpected AuthError: expecting .unsupportedCallback, but received \(authError)")
                    break
                }
            }
            else {
                XCTFail("Received unexpected error: expecting AuthError, but received \(String(describing: error))")
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_04_Validate_Node_With_CustomCallback() {
        
        guard self.shouldLoadMockResponses else {
            // Ignoring test if test is against actual server, and not against mock response
            return
        }
        
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to load ServerConfig from test configuration")
            return
        }
        
        // Load mock responses for AuthTree with custom callback
        self.loadMockResponses(["AuthTree_UsernamePasswordNodeWithCustomCallback"])
        
        // Given
        let customCallbackValue = "Custom Value"
        let customAttributeInputValue = "Custom Attribute Test"
        let authService = AuthService(name: "CustomCallbackService", serverConfig: serverConfig)
        
        // Register
        CallbackFactory.shared.registerCallback(callbackType: "CustomCallback", callbackClass: CustomCallback.self)
        
        // When
        var currentNode: Node?
        let ex = self.expectation(description: "Node Submit")
        authService.next { (token: Token?, node, error) in
            
            // Then
            
            // Validate response
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let node = currentNode else {
            XCTFail("Failed to received Node object with CustomCallback AuthTree response")
            return
        }
        
        // Validate received Callbacks
        for callback in node.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.setValue(config.username)
            }
            else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.setValue(config.password)
            }
            else if callback is CustomCallback, let customCallback = callback as? CustomCallback {
                customCallback.value = customCallbackValue
                customCallback.customAttribute = customAttributeInputValue
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        let requestPayload = node.buildRequestPayload()
        
        guard let callbacks = requestPayload["callbacks"] as? [[String: Any]] else {
            XCTFail("Failed to get callback array from AuthTree request payload")
            return
        }
        
        for callback in callbacks {
            if let type = callback["type"] as? String, type == "CustomCallback" {
                
                guard let inputs = callback["input"] as? [[String: String]], let outputs = callback["output"] as? [[String: String]] else {
                    XCTFail("Failed to parse CustomCallback request payload")
                    return
                }
                
                guard let custom = callback["custom"] as? [String: String] else {
                    XCTFail("Failed to parse CustomCallback.swift request paylaod")
                    return
                }
                
                XCTAssertTrue(custom.keys.contains("CustomCallbackInput"))
                XCTAssertEqual(custom["CustomCallbackInput"], "CustomCallbackValue")
                
                var customOutputValidated = false
                for output in outputs {
                    if let outputName = output["name"], let outputValue = output["value"], outputName == "customAttribute", outputValue == "CustomAttributeValue" {
                        customOutputValidated = true
                    }
                }
                XCTAssertTrue(customOutputValidated)
                
                var customAttributeInputValidated = false
                var customCallbackValueInputValidated = false
                for input in inputs {
                    if let inputName = input["name"], let inputValue = input["value"], inputName == "customAttribute", inputValue == customAttributeInputValue {
                        customAttributeInputValidated = true
                    }
                    
                    if let inputName = input["name"], let inputValue = input["value"], inputName == "IDToken3", inputValue == customCallbackValue {
                        customCallbackValueInputValidated = true
                    }
                }
                XCTAssertTrue(customAttributeInputValidated)
                XCTAssertTrue(customCallbackValueInputValidated)
            }
        }
    }
    
    
    func test_05_Validate_Overriding_Exisiting_CallbackType() {
        
        guard self.shouldLoadMockResponses else {
            // Ignoring test if test is against actual server, and not against mock response
            return
        }
        
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to load ServerConfig from test configuration")
            return
        }
        
        // Load mock responses for AuthTree with custom callback
        self.loadMockResponses(["AuthTree_UsernamePasswordNode"])
        
        // Given
        let customCallbackValue = "Custom Value"
        let customAttributeInputValue = "Custom Attribute Test"
        let authService = AuthService(name: "CustomCallbackService", serverConfig: serverConfig)
        
        // Register
        CallbackFactory.shared.registerCallback(callbackType: "NameCallback", callbackClass: CustomCallback.self)
        
        // When
        var currentNode: Node?
        let ex = self.expectation(description: "Node Submit")
        authService.next { (token: Token?, node, error) in
            
            // Then
            
            // Validate response
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let node = currentNode else {
            XCTFail("Failed to received Node object with CustomCallback AuthTree response")
            return
        }
        
        // Validate received Callbacks
        for callback in node.callbacks {
            if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.setValue(config.password)
            }
            else if callback is CustomCallback, let customCallback = callback as? CustomCallback {
                customCallback.value = customCallbackValue
                customCallback.customAttribute = customAttributeInputValue
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        let requestPayload = node.buildRequestPayload()
        
        guard let callbacks = requestPayload["callbacks"] as? [[String: Any]] else {
            XCTFail("Failed to get callback array from AuthTree request payload")
            return
        }
        
        for callback in callbacks {
            if let type = callback["type"] as? String, type == "NameCallback" {
                
                guard let inputs = callback["input"] as? [[String: String]] else {
                    XCTFail("Failed to parse CustomCallback request payload")
                    return
                }
                
                guard let custom = callback["custom"] as? [String: String] else {
                    XCTFail("Failed to parse CustomCallback.swift request paylaod")
                    return
                }
                
                XCTAssertTrue(custom.keys.contains("CustomCallbackInput"))
                XCTAssertEqual(custom["CustomCallbackInput"], "CustomCallbackValue")
                
                var customAttributeInputValidated = false
                var customCallbackValueInputValidated = false
                for input in inputs {
                    if let inputName = input["name"], let inputValue = input["value"], inputName == "customAttribute", inputValue == customAttributeInputValue {
                        customAttributeInputValidated = true
                    }
                    
                    if let inputName = input["name"], let inputValue = input["value"], inputName == "IDToken1", inputValue == customCallbackValue {
                        customCallbackValueInputValidated = true
                    }
                }
                XCTAssertTrue(customAttributeInputValidated)
                XCTAssertTrue(customCallbackValueInputValidated)
            }
        }
    }
}
