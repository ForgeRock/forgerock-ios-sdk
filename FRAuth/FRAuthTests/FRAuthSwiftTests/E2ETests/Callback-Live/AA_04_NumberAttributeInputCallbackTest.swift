//
//  AA_04_NumberAttributeInputCallbackTest.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AA_04_NumberAttributeInputCallbackTest: CallbackBaseTest {
    
    override func setUp() {
        super.setUp()
        self.config.authServiceName = "NumberAttributeInputCallbackTest"
    }
    
    func test_01_number_attribute_input_callback() {
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
        
        var hit: Int
        hit = 0
        
        // We expect NumberAttributeInputCallback here. Assert its properties. . .
        for callback in currentNode.callbacks {
            if callback is NumberAttributeInputCallback, let numberCallback = callback as? NumberAttributeInputCallback {
                XCTAssertEqual(numberCallback.prompt, "How old are you?")
                XCTAssertEqual(numberCallback.name, "age")
                XCTAssertTrue(numberCallback.required)
                XCTAssertFalse(numberCallback.validateOnly)
                XCTAssertNil(numberCallback.failedPolicies)
                // XCTAssertNil(numberCallback._value)
                
                numberCallback.setValue(30.0)
                hit += 1
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        // We expect 1 NumberAttributeInputCallback only...
        XCTAssertEqual(hit, 1)
        
        let ex = self.expectation(description: "Submit NumberAttributeInput callback and continue...")
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
