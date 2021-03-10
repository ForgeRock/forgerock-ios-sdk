//
//  AA_04_StringAttributeInputCallbackTest.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AA_04_StringAttributeInputCallbackTest: CallbackBaseTest {
    
    override func setUp() {
        super.setUp()
        self.config.authServiceName = "StringAttributeInputCallbackTest"
    }
    
    func test_01_string_attribute_input_callback() {
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
        
        // We expect 3 StringAttributeInputCallback here. Assert their properties. . .
        XCTAssertEqual(currentNode.callbacks.count, 3)
        XCTAssertTrue(currentNode.callbacks[0] is StringAttributeInputCallback)
        XCTAssertTrue(currentNode.callbacks[1] is StringAttributeInputCallback)
        XCTAssertTrue(currentNode.callbacks[2] is StringAttributeInputCallback)
        
        // Assert first StringAttributeInputCallback properties
        let callbackMail = currentNode.callbacks[0] as! StringAttributeInputCallback
        XCTAssertEqual(callbackMail.name, "mail")
        XCTAssertEqual(callbackMail.prompt, "Email Address")
        XCTAssertTrue(callbackMail.required)
        XCTAssertNotNil(callbackMail.policies)
        XCTAssertNil(callbackMail.failedPolicies)
        XCTAssertFalse(callbackMail.validateOnly)
        
        let callbackGivenName = currentNode.callbacks[1] as! StringAttributeInputCallback
        XCTAssertEqual(callbackGivenName.name, "givenName")
        XCTAssertEqual(callbackGivenName.prompt, "First Name")
        XCTAssertTrue(callbackGivenName.required)
        XCTAssertNotNil(callbackGivenName.policies)
        XCTAssertNil(callbackMail.failedPolicies)
        XCTAssertFalse(callbackGivenName.validateOnly)
        
        let callbackSN = currentNode.callbacks[2] as! StringAttributeInputCallback
        XCTAssertEqual(callbackSN.name, "sn")
        XCTAssertEqual(callbackSN.prompt, "Last Name")
        XCTAssertTrue(callbackSN.required)
        XCTAssertNotNil(callbackSN.policies)
        XCTAssertNil(callbackMail.failedPolicies)
        XCTAssertFalse(callbackSN.validateOnly)
        
        // Set values to the StringAttributeInput callbacks:
        callbackMail.setValue(config.userEmail)
        callbackGivenName.setValue(config.userFirstName)
        callbackSN.setValue(config.userLastName)
        
        let ex = self.expectation(description: "Submit StringAttributeInput callbacks and continue...")
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
