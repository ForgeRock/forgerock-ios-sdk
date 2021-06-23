//
//  CallbackBaseTest.swift
//  Callback Live Tests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class CallbackBaseTest: FRAuthBaseTest {
    
    override func setUp() {
        self.configFileName = "Config-live-01"
        self.config.authServiceName = "UsernamePassword"
        super.setUp()
        self.shouldLoadMockResponses = false;
    }
    
    // MARK: - Helper Method
    func fulfillUsernamePasswordNodes() throws -> Node  {
        
        // Start SDK
        self.startSDK()
        var currentNode: Node?
        
        var ex = self.expectation(description: "First Node submit")
        FRSession.authenticate(authIndexValue: self.config.authServiceName!) { (token: Token?, node, error) in
            // Validate result
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let node = currentNode else {
            XCTFail("Failed to get Node from the first request")
            throw AuthError.invalidCallbackResponse("Expected username/password nodes, but got nothing...")
        }
        
        // Provide input values for the Name and Password callbacks
        for callback in node.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.setValue(config.username)
            }
            else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.setValue(config.password)
            }
            else if callback is ValidatedCreateUsernameCallback, let validatedNameCallback = callback as? ValidatedCreateUsernameCallback {
                validatedNameCallback.setValue(config.username)
            }
            else if callback is ValidatedCreatePasswordCallback, let validatedPasswordCallback = callback as? ValidatedCreatePasswordCallback {
                validatedPasswordCallback.setValue(config.password)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Second Node submit")
        currentNode?.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard currentNode != nil else {
            XCTFail("Failed to get Node from the second request")
            throw AuthError.invalidCallbackResponse("Expected at least one more node, but got nothing...")
        }
        return currentNode!
    }
}
