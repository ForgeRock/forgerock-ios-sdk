// 
//  AA_01_LoginTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AA_01_LoginTests: FRAuthBaseTest {

    override func setUp() {
        self.configFileName = "Config-live-01"
        super.setUp()
        self.shouldLoadMockResponses = false
    }
    
    func test_01_perform_Login_tree() {
        // Start SDK
        self.config.authServiceName = "Login"
        
        self.startSDK()

        // Set mock responses
        self.loadMockResponses(["AuthTree_LoginNode",
                                "AuthTree_SSOToken_Success",
                                "OAuth2_AuthorizeRedirect_Success",
                                "OAuth2_Token_Success"])
        
        //  variable to capture the current Node object
        var currentNode: Node?
        
        //  To handle async operation for test; this allows async operation to be sync
        var ex = self.expectation(description: "First Node submit for Login")
        FRUser.login { (user: FRUser?, node, error) in
            //  Validate result
            XCTAssertNil(error)
            XCTAssertNil(user)
            XCTAssertNotNil(node)
            currentNode = node
            //  Exit the async operation
            ex.fulfill()
        }
        //  Wait for async operation to be finished
        waitForExpectations(timeout: 60, handler: nil)
        
        //  To make sure that we captured Node object, and unwrap optional value of currentNode
        guard let node = currentNode else {
            XCTFail("Failed to get Node from the first request from Registration tree")
            return
        }
        
        var username = config.username
        var password = config.password
        
        if let randomUsername = FRAuthBaseTest.randomeUser?.username, let randomPassword = FRAuthBaseTest.randomeUser?.password {
            username = randomUsername
            password = randomPassword
        }
        
        // Provide input value for callbacks
        for callback in node.callbacks {
            if callback is ValidatedCreateUsernameCallback, let usernameCallback = callback as? ValidatedCreateUsernameCallback {
                usernameCallback.setValue(username)
            }
            else if callback is ValidatedCreatePasswordCallback, let passwordCallback = callback as? ValidatedCreatePasswordCallback {
                passwordCallback.setValue(password)
            }
            else if callback is NameCallback, let usernameCallback = callback as? NameCallback {
                usernameCallback.setValue(username)
            }
            else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.setValue(password)
            }
            else {
                //  If Registration tree returns unexpected Callback, fail the test
                XCTFail("Received unexpected Callback from Login tree: \(callback.response)")
            }
        }
                
        ex = self.expectation(description: "Submit Node with inputs to complete Login tree")
        node.next { (user: FRUser?, node, error) in
            //  Validate result
            XCTAssertNil(error)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        
        //  If Node is returned after user credentials with callback from Login tree
        //  it must be ProgressiveProfile tree, so handle it accordingly
        if let node = currentNode {
            // Provide input value for callbacks
            for callback in node.callbacks {
                if callback is BooleanAttributeInputCallback, let boolCallback = callback as? BooleanAttributeInputCallback {
                    //  If the Callback is BooleanAttributeInputCallback; provide appropriate value based on name of attribute
                    if boolCallback.name == "preferences/marketing" {
                        boolCallback.setValue(true)
                    }
                    else if boolCallback.name == "preferences/updates" {
                        boolCallback.setValue(true)
                    }
                    else {
                        //  If BooleanAttributeInputCallback attribute name is not known, fail the test
                        XCTFail("Received unexpected Callback from Registration tree: \(boolCallback.response)")
                    }
                }
                else {
                    //  If Registration tree returns unexpected Callback, fail the test
                    XCTFail("Received unexpected Callback from Registration tree: \(callback.response)")
                }
            }
            
            ex = self.expectation(description: "Submit Node with inputs to complete Login tree for ProgressiveProfile tree")
            node.next { (user: FRUser?, node, error) in
                //  Validate result
                XCTAssertNil(error)
                currentNode = node
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        
        //  Either with or without ProgressiveProfile, at this point, currentNode should be null
        //  and user must be authenticated
        XCTAssertNil(currentNode)
        XCTAssertNotNil(FRUser.currentUser)
        XCTAssertNotNil(FRUser.currentUser?.token)
        XCTAssertNotNil(FRSession.currentSession?.sessionToken)
    }
}
