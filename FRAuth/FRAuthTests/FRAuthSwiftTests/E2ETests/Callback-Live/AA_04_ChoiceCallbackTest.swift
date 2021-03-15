//
//  AA_04_ChoiceCallbackTest.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AA_04_ChoiceCallbackTest: CallbackBaseTest {
    
    override func setUp() {
        super.setUp()
        self.config.authServiceName = "ChoiceCallbackTest"
    }
    
    func test_01_choice_callback() {
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
        
        // We expect ChoiceCallback here. Assert its properties. . . 
        for callback in currentNode.callbacks {
            if callback is ChoiceCallback, let choiceCallback = callback as? ChoiceCallback {
                XCTAssertTrue(choiceCallback.choices.count == 2, "choiceCallback does not contain 2 choices as expected")
                XCTAssertTrue(choiceCallback.choices.contains("Yes"), "choiceCallback does not contain 'Yes' as an option")
                XCTAssertTrue(choiceCallback.choices.contains("No"), "choiceCallback does not contain 'No' as an option")
                XCTAssertEqual(choiceCallback.prompt, "Choice")
                XCTAssertTrue(choiceCallback.defaultChoice == 0)
                
                // Set "Yes" as choice and continue...
                choiceCallback.setValue(0)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        let ex = self.expectation(description: "Submit choice callback and continue...")
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
