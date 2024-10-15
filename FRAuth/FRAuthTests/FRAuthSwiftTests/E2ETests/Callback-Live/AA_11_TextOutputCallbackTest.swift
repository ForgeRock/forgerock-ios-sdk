//
//  AA_11_TextOutputCallbackTest.swift
//  FRAuthTests
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AA_11_TextOutputCallbackTest: CallbackBaseTest {
    
    override func setUp() {
        super.setUp()
        self.config.authServiceName = "TextOutputCallbackTest"
    }
    
    func test_01_text_output_callback() {
        var currentNode: Node?
        
        do {
            try currentNode = submitUsernameAndPassword()
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected at least one node after username/password nodes, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        // We expect 4 TextOutputCallback of all types at this point. (see the TextOutputCallbackProducer script)
        XCTAssertEqual(currentNode!.callbacks.count, 4)
        for callback in currentNode!.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                XCTAssertTrue(
                    textOutputCallback.message == "TextOutput Type 0 (INFO)" ||
                    textOutputCallback.message == "TextOutput Type 1 (WARNING)" ||
                    textOutputCallback.message == "TextOutput Type 2 (ERROR)" ||
                    textOutputCallback.message == "TextOutput Type 4 (SCRIPT)"
                )
                XCTAssertTrue(
                    textOutputCallback.messageType == MessageType.information ||
                    textOutputCallback.messageType == MessageType.warning ||
                    textOutputCallback.messageType == MessageType.error ||
                    textOutputCallback.messageType == MessageType.unknown
                )
                
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        var ex = self.expectation(description: "Submit the text output callbacks and continue...")
        currentNode?.next { (token: AccessToken?, node, error) in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Ensure that the journey finishes with success
        // Note that the SDK should NOT send TextOutput of type 4 to AM (SDKS-3226)
        // If it sends it though, the journey would fail (see the `TextOutputCallbackProducer` script...)
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    
    func submitUsernameAndPassword() throws -> Node  {
        // Start SDK
        self.startSDK()
        
        var currentNode: Node?
        
        var ex = self.expectation(description: "First Node submit")
        FRSession.authenticate(authIndexValue: self.config.authServiceName!) { (token: Token?, node, error) in
            // Validate result
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let node = currentNode else {
            XCTFail("Failed to get Node from the first request")
            throw AuthError.invalidCallbackResponse("Expected username node, but got nothing...")
        }
        
        // Provide input values for the Name callback
        for callback in node.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.setValue(config.username)
            }
            else if callback is ValidatedCreateUsernameCallback, let validatedNameCallback = callback as? ValidatedCreateUsernameCallback {
                validatedNameCallback.setValue(config.username)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Node submit")
        currentNode?.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Provide input values for the Password callback
        for callback in currentNode!.callbacks {
            if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.setValue(config.password)
            }
            else if callback is ValidatedCreatePasswordCallback, let validatedPasswordCallback = callback as? ValidatedCreatePasswordCallback {
                validatedPasswordCallback.setValue(config.password)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Node submit")
        currentNode?.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard currentNode != nil else {
            XCTFail("Failed to get Node from the second request")
            throw AuthError.invalidCallbackResponse("Expected at least one more node, but got nothing...")
        }
        return currentNode!
    }
}
