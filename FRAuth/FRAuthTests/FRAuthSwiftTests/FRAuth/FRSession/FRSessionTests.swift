// 
//  FRSessionTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest

class FRSessionTests: FRBaseTest {

    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    func test_01_basic_FRSession_authenticate() {
        
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success"])
        
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
        
        XCTAssertNotNil(FRSession.currentSession)
        XCTAssertNotNil(FRSession.currentSession?.sessionToken)
        
        
        // Should not clean up session for next test
        self.shouldCleanup = false
    }
    

    func test_02_check_persisted_session() {
        
        // Given previous test of authenticating, and persisting FRSession, and FRUser
        self.startSDK()
        
        // Then
        XCTAssertNotNil(FRUser.currentUser)
        XCTAssertNotNil(FRSession.currentSession)
        XCTAssertNotNil(FRSession.currentSession?.sessionToken)
        
        // Should not clean up session for next test
        self.shouldCleanup = false
    }
    
    
    func test_03_reauthenticating_session() {
        
        // Given previous test of authenticating, and persisting FRSession, and FRUser
        self.startSDK()
        self.config.authServiceName = "UsernamePassword"
        
        // Get Session Token from previous test
        guard let sessionToken = FRSession.currentSession?.sessionToken else {
            XCTFail("Failed to retrieve Session Token from previous tests; aborting the test")
            return
        }
                
        // Set mock responses with different SSO Token
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success2"])
        
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
        
        // Then
        XCTAssertNotNil(FRUser.currentUser)
        XCTAssertNotNil(FRSession.currentSession)
        XCTAssertNotNil(FRSession.currentSession?.sessionToken)
        XCTAssertNotEqual(sessionToken.value, FRSession.currentSession?.sessionToken?.value)
                
        // Should not clean up session for next test
        self.shouldCleanup = false
    }
    
    func test_04_validate_oauth2_revoke_with_frsession_authenticate() {
        
        // Given previous test of authenticating, and persisting FRSession, and FRUser
        self.startSDK()
        self.config.authServiceName = "UsernamePassword"
        
        // Set mock responses
        self.loadMockResponses(["OAuth2_AuthorizeRedirect_Success",
                                "OAuth2_Token_Success"])
        
        // Then
        XCTAssertNotNil(FRUser.currentUser)
        XCTAssertNotNil(FRSession.currentSession)
        XCTAssertNotNil(FRSession.currentSession?.sessionToken)
        
        var ex = self.expectation(description: "Get User Info")
        FRUser.currentUser?.getAccessToken() { (user, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let token = FRUser.currentUser?.token else {
            XCTFail("Failed to retrieve AccessToken from Session Token; aborting the test")
            return
        }
        
        // Set mock responses with different SSO Token
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success",
                                "OAuth2_Token_Revoke_Success"])
        
        var currentNode: Node?
        
        ex = self.expectation(description: "First Node submit")
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
        
        // Upon first node of Authentication Tree; as flow isn't finished yet; Access Token should still be valid and the same
        XCTAssertEqual(token, FRUser.currentUser?.token)
        
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
        
        // Upon completion of Authentication Tree flow, and getting Session Token, Access Token must be invalidated
        XCTAssertNotEqual(token, FRUser.currentUser?.token)
        XCTAssertNil(FRUser.currentUser?.token)
        
        // Set mock responses
        self.loadMockResponses(["OAuth2_AuthorizeRedirect_Success",
                                "OAuth2_Token_Success"])
        
        // Get AccessToken with newly grnated Session Token for next test
        ex = self.expectation(description: "Get User Info")
        FRUser.currentUser?.getAccessToken() { (user, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser?.token)
        
        // Should not clean up session for next test
        self.shouldCleanup = false
    }
    
    
    func test_05_validate_frsession_authenticate_returning_same_session_token() {
        
        self.startSDK()
        self.config.authServiceName = "UsernamePassword"
        
        // Set mock responses with same SSO Token
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success"])
        
        // Get Session Token from previous test
        guard let sessionToken = FRSession.currentSession?.sessionToken else {
            XCTFail("Failed to retrieve Session Token from previous tests; aborting the test")
            return
        }
        
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
        
        // Session Token should still be the same, and OAuth2 token should exist
        XCTAssertNotNil(FRUser.currentUser?.token)
        XCTAssertEqual(sessionToken.value, FRSession.currentSession?.sessionToken?.value)
        
        // Should not clean up session for next test
        self.shouldCleanup = false
    }
    
    
    func test_06_verify_session_logout_invalidates_oauth2_token() {
        
        self.startSDK()
        
        // Load mock responses for AM Session revoke, and OAuth2 token revoke
        self.loadMockResponses(["AM_Session_Logout_Success"])
                
        XCTAssertNotNil(FRUser.currentUser)
        XCTAssertNotNil(FRSession.currentSession)
        XCTAssertNotNil(FRSession.currentSession?.sessionToken)
        
        // Perform session logout
        FRSession.currentSession?.logout()
        
        XCTAssertNil(FRUser.currentUser?.token)
        XCTAssertNil(FRSession.currentSession)
    }
}
