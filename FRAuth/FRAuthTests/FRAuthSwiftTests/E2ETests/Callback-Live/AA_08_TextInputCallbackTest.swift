// 
//  AA_08_TextInputCallbackTest.swift
//  FRAuthTests
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AA_08_TextInputCallbackTest: CallbackBaseTest {
    
    override func setUp() {
        super.setUp()
        self.config.authServiceName = "TextInputCallbackTest"
    }
    
    func test_01_text_input_callback() {
        var currentNode: Node?
        
        do {
            try currentNode = fulfillUsernamePasswordNodes()
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected at least one node after username/password nodes, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        // We expect TextInputCallback here. Assert its properties. . .
        for callback in currentNode!.callbacks {
            if callback is TextInputCallback, let textInputCallback = callback as? TextInputCallback {
                XCTAssertEqual(textInputCallback.prompt, "What is your username?")
                XCTAssertEqual(textInputCallback.getDefaultText(), "ForgerRocker")
                
                textInputCallback.setValue(config.username)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        var ex = self.expectation(description: "Submit the text input callback and continue...")
        currentNode?.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNotNil(node) // We expect Message node with "Success"
            XCTAssertNil(error)
            XCTAssertNil(token)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let node = currentNode else {
            XCTFail("Test Failed: Expected TextOutputCallback and ConfirmationCallback (returned by Message node), but got nothing...")
            return
        }
        
        for callback in node.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                XCTAssertEqual(textOutputCallback.message, "Success")
            }
            else if callback is ConfirmationCallback, let confirmationCallback = callback as? ConfirmationCallback {
                confirmationCallback.value = 0
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Submit value for the ConfirmationCallback and continue...")
        currentNode?.next { (token: AccessToken?, node, error) in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
}
