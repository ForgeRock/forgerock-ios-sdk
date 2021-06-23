//
//  AA_04_ConfirmationCallbackTest.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AA_04_ConfirmationCallbackTest: CallbackBaseTest {
    
    override func setUp() {
        super.setUp()
        self.config.authServiceName = "ConfirmationCallbackTest"
    }
    
    func test_01_confirmation_callback() {
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
        // We expect ConfirmationCallback and  TextOutputCallback here. Assert their properties. . .
        for callback in currentNode.callbacks {
            if callback is ConfirmationCallback, let cCallback = callback as? ConfirmationCallback {
                XCTAssertEqual(cCallback.prompt, "")
                XCTAssertEqual(cCallback.messageType, MessageType.information)
                XCTAssertEqual(cCallback.options!.count, 2)
                XCTAssertEqual(cCallback.optionType, OptionType.unspecifiedOption)
                XCTAssertTrue(cCallback.options!.contains("Yes"))
                XCTAssertTrue(cCallback.options!.contains("No"))
                XCTAssertEqual(cCallback.defaultOption, 1)
                
                cCallback.value = 0
                hit += 1
            }
            else if callback is TextOutputCallback, let tCallback = callback as? TextOutputCallback {
                XCTAssertEqual(tCallback.message, "Test")
                XCTAssertEqual(tCallback.messageType, MessageType.information)
                hit += 1
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        XCTAssertEqual(hit, 2) // confirm that we received 2 callbacks
        
        let ex = self.expectation(description: "Submit confirmation callback and continue...")
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
