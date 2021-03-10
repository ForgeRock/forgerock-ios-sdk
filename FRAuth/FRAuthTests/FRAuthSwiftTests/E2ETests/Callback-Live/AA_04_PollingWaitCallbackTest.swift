//
//  AA_04_PollingWaitCallbackTest.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AA_04_PollingWaitCallbackTest: CallbackBaseTest {
    
    override func setUp() {
        super.setUp()
        self.config.authServiceName = "PollingWaitCallbackTest"
    }
    
    func test_01_polling_wait_callback() {
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
        
        // We expect PollingWait callback here. Assert its properties. . .
        for callback in currentNode.callbacks {
            if callback is PollingWaitCallback, let pollingCallback = callback as? PollingWaitCallback {
                XCTAssertEqual(pollingCallback.waitTime, 10000)
                XCTAssertEqual(pollingCallback.message, "Please Wait")
                
                hit += 1
            }
            else if callback is ConfirmationCallback, let confirmCallback = callback as? ConfirmationCallback {
                XCTAssertEqual(confirmCallback.prompt, "")
                XCTAssertEqual(confirmCallback.messageType, MessageType.information)
                XCTAssertEqual(confirmCallback.options!.count, 1)
                XCTAssertEqual(confirmCallback.optionType, OptionType.unspecifiedOption)
                XCTAssertTrue(confirmCallback.options!.contains("Exit"))
                XCTAssertEqual(confirmCallback.defaultOption, 0)
                confirmCallback.value = 0
                
                hit += 1
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        // We expect 2 calbacks received (PollingWaitCallback and ConfirmationCallback)...
        XCTAssertEqual(hit, 2)
        
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
