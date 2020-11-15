//
//  UserSignUpFlowTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest

class UserSignUpFlowTests: FRAuthBaseTest {

    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    /// Tests simple AuthTree flow for user registration
    func testUserSignUpFlow() {
        
        // Start SDK
        self.config.registrationServiceName = "UserSignUp"
        self.startSDK()
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_PlatformUsernamePasswordNode",
                                "AuthTree_AttributeCollectorsNode",
                                "AuthTree_KBACreateNode",
                                "AuthTree_TermsAndConditionsNode",
                                "AuthTree_SSOToken_Success",
                                "OAuth2_AuthorizeRedirect_Success",
                                "OAuth2_Token_Success"])
        
        var currentNode: Node?
        
        // Define user registration username with timestamp to avoid conflict
        let username = config.username + String(describing: Date().timeIntervalSince1970)
        
        var ex = self.expectation(description: "First Node submit: Platform Username/Password creation")
        FRUser.register { (user: FRUser?, node, error) in
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
                usernameCallback.setValue(username)
            }
            else if callback is ValidatedCreatePasswordCallback, let passwordCallback = callback as? ValidatedCreatePasswordCallback {
                passwordCallback.setValue(config.password)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Second Node submit: Attribute Collection")
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
            if callback is StringAttributeInputCallback, let inputCallback = callback as? StringAttributeInputCallback {
                
                if inputCallback.name == "sn" {
                    inputCallback.setValue(config.userLastName)
                }
                else if inputCallback.name == "givenName" {
                    inputCallback.setValue(config.userFirstName)
                }
                else if inputCallback.name == "mail" {
                    inputCallback.setValue(config.userEmail)
                }
                else {
                    XCTFail("Received unexpected callback \(callback)")
                }
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Third Node submit: KBA Create Node")
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
        var counter = 0
        for callback in thirdNode.callbacks {
            if callback is KbaCreateCallback, let kbaCallback = callback as? KbaCreateCallback {
                kbaCallback.setAnswer("Answer" + String(describing: counter))
                kbaCallback.setQuestion(kbaCallback.predefinedQuestions[counter])
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
            counter += 1
        }
        
        ex = self.expectation(description: "Third Node submit: Terms & Conditions")
        thirdNode.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        
        guard let fourthNode = currentNode else {
            XCTFail("Failed to get Node from the third request")
            return
        }
        
        // Provide input value for callbacks
        for callback in fourthNode.callbacks {
            if callback is TermsAndConditionsCallback, let tocCallback = callback as? TermsAndConditionsCallback {
                tocCallback.setValue(true)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Fourth Node submit: SSO Token and OAuth2 Tokens")
        fourthNode.next { (token: AccessToken?, node, error) in
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
