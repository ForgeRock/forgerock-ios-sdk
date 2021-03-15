//
//  AA_02_KBAAuthenticationTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AA_02_KBAAuthenticationTests: FRAuthBaseTest {

    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    /// Tests simple AuthTree flow with Username Collector and Password Collector in Page Node to obtain SSOToken
    func testKBAAuthenticationFlow() {
        
        // Start SDK
        self.config.authServiceName = "KBAAuthentication"
        self.startSDK()
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_PlatformUsernamePasswordNode",
                                "AuthTree_KBAVerificationNode",
                                "AuthTree_SSOToken_Success",
                                "OAuth2_AuthorizeRedirect_Success",
                                "OAuth2_Token_Success"])
        
        var currentNode: Node?
        
        var ex = self.expectation(description: "First Node submit")
        FRUser.login { (user: FRUser?, node, error) in
            // Validate result
            XCTAssertNil(user)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let firstNode = currentNode else {
            XCTFail("Failed to get Node from the first request")
            return
        }
        
        // Provide input value for callbacks
        for callback in firstNode.callbacks {
            if callback is ValidatedCreateUsernameCallback, let usernameCallback = callback as? ValidatedCreateUsernameCallback {
                usernameCallback.setValue(config.username)
            }
            else if callback is ValidatedCreatePasswordCallback, let passwordCallback = callback as? ValidatedCreatePasswordCallback {
                passwordCallback.setValue(config.password)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Second Node submit")
        firstNode.next { (token: AccessToken?, node, error) in
            
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
            if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                if let kba = config.kba, let kbaQuestion = passwordCallback.prompt, let kbaAnswer = kba[kbaQuestion] {
                    passwordCallback.setValue(kbaAnswer)
                }
                else {
                    XCTFail("KBA Answer was not identified \(callback)")
                }
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Third Node submit")
        secondNode.next { (token: AccessToken?, node, error) in
            
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
