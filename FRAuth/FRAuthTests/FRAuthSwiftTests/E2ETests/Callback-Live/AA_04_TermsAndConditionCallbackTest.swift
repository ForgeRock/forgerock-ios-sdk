//
//  AA_04_TermsAndConditionCallbackTest.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AA_04_TermsAndConditionCallbackTest: CallbackBaseTest {
    
    override func setUp() {
        super.setUp()
        self.config.authServiceName = "TermsAndConditionCallbackTest"
    }
    
    func test_01_terms_and_conditions_callback() {
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
        
        // We expect TermsAndConditionsCallback here. Assert its properties. . .
        for callback in currentNode.callbacks {
            if callback is TermsAndConditionsCallback, let termsCallback = callback as? TermsAndConditionsCallback {
                XCTAssertTrue (((termsCallback.terms?.starts(with: "Lorem ipsum dolor sit amet, consectetur adipiscing elit")) != nil))
                XCTAssertEqual(termsCallback.version, "0.0")
                XCTAssertEqual(termsCallback.createDate, "2019-10-28T04:20:11.320Z")
                termsCallback.setValue(true) // Set callback to "accepted"
                
                hit += 1
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        // We expect 1 TermsAndConditionsCallback only...
        XCTAssertEqual(hit, 1)
        
        let ex = self.expectation(description: "Submit TermsAndConditions callback and continue...")
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
