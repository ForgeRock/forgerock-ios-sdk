//
//  FRAuthFlowTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest

class FRAuthFlowTests: FRBaseTest {

    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    
    func test_01_Get_SSOTokenWithoutCleanup() {
        
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()
        
        guard let frAuth = FRAuth.shared else {
            XCTFail("Failed to initialize SDK; FRAuth.shared returning nil")
            return
        }
        
        // Should not clean up session for next test
        self.shouldCleanup = false
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success"])
        
        // Initiate Auth flow
        var currentNode: Node?
        var ex = self.expectation(description: "First Node submit")
        frAuth.next(flowType: .authentication, completion: { (token: Token?, node, error) in
            
            // Validate result
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        })
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let node = currentNode else {
            XCTFail("Failed to get Node from the first request")
            return
        }
        
        // Provide input value for callbacks
        for callback in node.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.value = config.username
            }
            else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.value = config.password
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Second Node submit")
        node.next { (token: Token?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_02_Get_SSOTokenFromPreviousTest() {
        
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()
        
        guard let frAuth = FRAuth.shared else {
            XCTFail("Failed to initialize SDK; FRAuth.shared returning nil")
            return
        }
        
        // Should not clean up session for next test
        self.shouldCleanup = false
        
        // Initiate Auth flow
        let ex = self.expectation(description: "First Node submit")
        frAuth.next(flowType: .authentication, completion: { (token: Token?, node, error) in
            
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        })
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_03_Get_AccessTokenFromPreviousSSOToken() {
        
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()
        
        guard let frAuth = FRAuth.shared else {
            XCTFail("Failed to initialize SDK; FRAuth.shared returning nil")
            return
        }
        
        // Set mock responses
        self.loadMockResponses(["OAuth2_AuthorizeRedirect_Success",
                                "OAuth2_Token_Success"])
        
        // Should clean up session for next test
        self.shouldCleanup = true
        
        // Initiate Auth flow
        let ex = self.expectation(description: "First Node submit")
        frAuth.next(flowType: .authentication, completion: { (token: AccessToken?, node, error) in
            
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        })
        waitForExpectations(timeout: 60, handler: nil)
    }

    
    func test_04_Get_AccessTokenWithoutPreviousSession() {
        
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()
        
        guard let frAuth = FRAuth.shared else {
            XCTFail("Failed to initialize SDK; FRAuth.shared returning nil")
            return
        }
        
        // Should not clean up session for next test
        self.shouldCleanup = false
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success",
                                "OAuth2_AuthorizeRedirect_Success",
                                "OAuth2_Token_Success"])
        
        // Initiate Auth flow
        var currentNode: Node?
        var ex = self.expectation(description: "First Node submit")
        frAuth.next(flowType: .authentication, completion: { (token: AccessToken?, node, error) in
            
            // Validate result
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        })
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let node = currentNode else {
            XCTFail("Failed to get Node from the first request")
            return
        }
        
        // Provide input value for callbacks
        for callback in node.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.value = config.username
            }
            else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.value = config.password
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Second Node submit")
        node.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_05_Get_AccessTokenFromPreviousAccessToken() {
        
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()
        
        guard let frAuth = FRAuth.shared else {
            XCTFail("Failed to initialize SDK; FRAuth.shared returning nil")
            return
        }
        
        // Should not clean up session for next test
        self.shouldCleanup = false
        
        // Initiate Auth flow
        let ex = self.expectation(description: "First Node submit")
        frAuth.next(flowType: .authentication, completion: { (token: AccessToken?, node, error) in
            
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        })
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_06_Get_FRUserFromPreviousAccessToken() {
        
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()
        
        guard let frAuth = FRAuth.shared else {
            XCTFail("Failed to initialize SDK; FRAuth.shared returning nil")
            return
        }
        
        // Should not clean up session for next test
        self.shouldCleanup = true
        
        // Initiate Auth flow
        let ex = self.expectation(description: "First Node submit")
        frAuth.next(flowType: .authentication, completion: { (user: FRUser?, node, error) in
            
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            ex.fulfill()
        })
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_07_Get_FRUserWithoutPreviousSession() {
        
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()
        
        guard let frAuth = FRAuth.shared else {
            XCTFail("Failed to initialize SDK; FRAuth.shared returning nil")
            return
        }
        
        // Should not clean up session for next test
        self.shouldCleanup = false
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success",
                                "OAuth2_AuthorizeRedirect_Success",
                                "OAuth2_Token_Success"])
        
        // Initiate Auth flow
        var currentNode: Node?
        var ex = self.expectation(description: "First Node submit")
        frAuth.next(flowType: .authentication, completion: { (user: FRUser?, node, error) in
            
            // Validate result
            XCTAssertNil(user)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        })
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let node = currentNode else {
            XCTFail("Failed to get Node from the first request")
            return
        }
        
        // Provide input value for callbacks
        for callback in node.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.value = config.username
            }
            else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.value = config.password
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Second Node submit")
        node.next { (user: FRUser?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    
    func test_08_Get_FRUserFromPreviousLogin() {
        
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()
        
        guard let frAuth = FRAuth.shared else {
            XCTFail("Failed to initialize SDK; FRAuth.shared returning nil")
            return
        }
        
        // Should not clean up session for next test
        self.shouldCleanup = true
        
        // Initiate Auth flow
        let ex = self.expectation(description: "First Node submit")
        frAuth.next(flowType: .authentication, completion: { (user: FRUser?, node, error) in
            
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            ex.fulfill()
        })
        waitForExpectations(timeout: 60, handler: nil)
    }
}
