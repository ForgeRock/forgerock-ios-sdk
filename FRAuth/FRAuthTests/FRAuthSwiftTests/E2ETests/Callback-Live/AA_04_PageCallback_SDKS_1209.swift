// 
//  AA_04_PageCallback_SDKS_1209.swift
//  FRAuthTests
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AA_04_PageCallback_SDKS_1209: FRAuthBaseTest {
    
    override func setUp() {
        self.configFileName = "Config-live-01"
        super.setUp()
        self.config.authServiceName = "SDKS-1209"
        self.shouldLoadMockResponses = false;
    }
    
    // MARK: - Helper Method
    func test_01_test_page_node_SDKS_1209()  {
        
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
            return
        }
        
        // When both page node and metadata callbacks are present, then the stage from the page node should take
        // precedence. In our case, in the test tree, the stage is set to "Test", and in the metadata callback
        // it is set to "UsernamePassword"
        XCTAssertEqual(node.stage, "Test");
        
        // Provide input values for the name and password callbacks
        for callback in node.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.setValue(config.username)
            }
            else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.setValue(config.password)
            }
            else if callback is MetadataCallback {
                continue // ignore the MetadataCallback callback...
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Second Node submit")
        currentNode?.next { (token: AccessToken?, node, error) in
            
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
