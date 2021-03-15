//
//  AA_04_KbaCreateCallbackTest.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AA_04_KbaCreateCallbackTest: CallbackBaseTest {
    
    override func setUp() {
        super.setUp()
        self.config.authServiceName = "KbaCreateCallbackTest"
    }
    
    func test_01_kba_create_callback() {
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
        
        // We expect KbaCreateCallbackTest here. Assert its properties. . .
        for callback in currentNode.callbacks {
            if callback is KbaCreateCallback, let kbaCallback = callback as? KbaCreateCallback {
                XCTAssertEqual(kbaCallback.prompt, "Security questions")
                XCTAssertTrue(kbaCallback.predefinedQuestions.contains("What's your favorite color?"))
                XCTAssertTrue(kbaCallback.predefinedQuestions.contains("Who was your first employer?"))
                
                kbaCallback.setQuestion(kbaCallback.predefinedQuestions[hit])
                kbaCallback.setAnswer("test")
                hit += 1
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        // We expect 2 kbaCallbacks with the same content...
        XCTAssertEqual(hit, 2)
        
        let ex = self.expectation(description: "Submit KbaCreate callback and continue...")
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
