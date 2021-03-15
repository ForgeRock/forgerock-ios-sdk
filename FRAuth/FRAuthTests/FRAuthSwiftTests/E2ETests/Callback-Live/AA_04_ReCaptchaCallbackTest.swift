//
//  AA_04_ReCaptchaCallbackTest.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AA_04_ReCaptchaCallbackTest: CallbackBaseTest {
    
    override func setUp() {
        super.setUp()
        self.config.authServiceName = "RecaptchaCallbackTest"
    }
    
    func test_01_recaptcha_callback() {
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
        
        // We expect ReCaptchaCallback here. Assert its properties. . .
        for callback in currentNode.callbacks {
            if callback is ReCaptchaCallback, let rCallback = callback as? ReCaptchaCallback {
                XCTAssertEqual(rCallback.recaptchaSiteKey, "siteKey")
                
                rCallback.value = "dummy"
                hit += 1
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        // We expect 1 ReCaptchaCallback only...
        XCTAssertEqual(hit, 1)
        
        let ex = self.expectation(description: "Submit ReCaptchaCallback callback and continue...")
        currentNode.next { (token: AccessToken?, node, error) in
            
            // Validate result
            XCTAssertNil(node)
            // ReCaptcha node should fail!
            XCTAssertNotNil(error)
            XCTAssertTrue((error?.localizedDescription.contains("Unauthorized")) != nil)
            XCTAssertNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Make sure we don't endup with user object
        XCTAssertNil(FRUser.currentUser)
    }
}
