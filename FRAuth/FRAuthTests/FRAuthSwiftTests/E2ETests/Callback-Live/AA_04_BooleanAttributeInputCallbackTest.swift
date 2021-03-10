//
//  AA_04_BooleanAttributeInputCallbackTest.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AA_04_BooleanAttributeInputCallbackTest: CallbackBaseTest {
    
    override func setUp() {
        super.setUp()
        self.config.authServiceName = "BooleanAttributeInputCallbackTest"
    }
    
    func test_01_boolean_attribute_input_callback() {
        var currentNode: Node
        
        do {
            try currentNode = fulfillUsernamePasswordNodes()
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected at least one node after username/password nodes, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        // We expect BooleanAttributeInputCallback here. Assert its properties. . .
        for callback in currentNode.callbacks {
            if callback is BooleanAttributeInputCallback, let bCallback = callback as? BooleanAttributeInputCallback {
                XCTAssertEqual(bCallback.name, "preferences/marketing")
                XCTAssertEqual(bCallback.prompt, "Send me special offers and services")
                XCTAssertTrue(bCallback.required)
                XCTAssertFalse(bCallback.validateOnly)
                XCTAssertNotNil(bCallback.policies)
                XCTAssertNil(bCallback.failedPolicies)
                guard let bValue = bCallback.getValue() as? Bool else {
                    XCTFail("The callback does not contain boolean value!")
                    return
                }
                
                XCTAssertFalse(bValue)
                
                bCallback.setValue(true)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        let ex = self.expectation(description: "Submit boolean input callback and continue...")
        currentNode.next { (token: AccessToken?, node, error) in
            
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
}
