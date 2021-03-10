//
//  AA_03_SecondFactorAuthenticationTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AA_03_SecondFactorAuthenticationTests: FRAuthBaseTest {

    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    /// Tests simple AuthTree flow with Username Collector and Password Collector in Page Node, OTP Selection Node, and OTP Validation Node to obtain SSOToken
    func testSecondFactorFlow() {
        
        // Start SDK
        self.config.authServiceName = "SecondFactor"
        self.startSDK()
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SecondFactorChoiceNode",
                                "AuthTree_SecondFactorOTPNode",
                                "AuthTree_SSOToken_Success",
                                "OAuth2_AuthorizeRedirect_Success",
                                "OAuth2_Token_Success"])
        
        var currentNode: Node?
        
        var ex = self.expectation(description: "First Node submit: Username / Password Collector Nodes")
        FRUser.login { (user: FRUser?, node, error) in
            // Validate result
            XCTAssertNil(user)
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
        
        // Provide input value for callbacks
        for callback in node.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.setValue(config.username)
            }
            else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.setValue(config.password)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Second Node submit: Choice Callback for OTP Channel Selection")
        node.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let secondNode = currentNode else {
            XCTFail("Failed to get Node from the second request")
            return
        }
        
        // Provide input value for callbacks
        for callback in secondNode.callbacks {
            if callback is ChoiceCallback, let choiceCallback = callback as? ChoiceCallback {
                choiceCallback.setValue(choiceCallback.defaultChoice)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        if !self.shouldLoadMockResponses {
            // Stop testing for SecondFactor as this is testing against actual server, and requires valid OTP credentials
            return
        }
        
        ex = self.expectation(description: "Third Node submit: OTP Credentials Node")
        secondNode.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let thirdNode = currentNode else {
            XCTFail("Failed to get Node from the third request")
            return
        }
        
        // Provide input value for callbacks
        for callback in thirdNode.callbacks {
            if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.setValue("OTP Dummy Credentials")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Fourth Node submit: After OTP Credentials submit; OAuth2 Token is expected to be returned for this flow")
        thirdNode.next { (token: AccessToken?, node, error) in
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
