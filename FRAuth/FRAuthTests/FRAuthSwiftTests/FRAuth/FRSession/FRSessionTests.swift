// 
//  FRSessionTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRCore
@testable import FRAuth

class FRSessionTests: FRAuthBaseTest {

    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    override func tearDown() {
        SuspendedRequestInterceptor.actions = []
        SuspendedRequestInterceptor.requests = []
        super.tearDown()
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
                nameCallback.setValue(config.username)
            }
            else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.setValue(config.password)
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
                nameCallback.setValue(config.username)
            }
            else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.setValue(config.password)
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
                                "AM_Session_Logout_Success",
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
                nameCallback.setValue(config.username)
            }
            else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.setValue(config.password)
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
                nameCallback.setValue(config.username)
            }
            else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.setValue(config.password)
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
    
    
    func test_07_authenticate_with_suspended_id() {
        
        self.startSDK()
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode"])
        
        FRRequestInterceptorRegistry.shared.registerInterceptors(interceptors: [SuspendedRequestInterceptor()])
        let url = URL(string: "http://default.iam.forgeops.com/am/XUI?realm=/&suspendedId=6IIIUln3ajONR4ySwZt15qzh8X4")!
        
        let ex = self.expectation(description: "First Node submit")
        FRSession.authenticate(resumeURI: url) { (token: Token?, node, error) in
            XCTAssertNil(error)
            XCTAssertNil(token)
            XCTAssertNotNil(node)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertEqual(SuspendedRequestInterceptor.requests.count, 1)
        XCTAssertEqual(SuspendedRequestInterceptor.actions.count, 1)
        XCTAssertEqual(SuspendedRequestInterceptor.actions.first?.type, "RESUME_AUTHENTICATE")
        let request = SuspendedRequestInterceptor.requests.first
        
        guard let urlRequest = request?.build(), let requestURL = urlRequest.url?.absoluteString else {
            XCTFail("Failed to get URL from suspendedId request using FRSession")
            return
        }
        
        XCTAssertTrue(requestURL.contains("suspendedId=6IIIUln3ajONR4ySwZt15qzh8X4"))
    }
    
    
    func test_08_authenticate_with_resume_uri_missing_suspended_id() {
        
        self.startSDK()
        
        let url = URL(string: "http://default.iam.forgeops.com/am/XUI?realm=/")!
        
        var thisError: Error?
        let ex = self.expectation(description: "First Node submit")
        FRSession.authenticate(resumeURI: url) { (token: Token?, node, error) in
            XCTAssertNotNil(error)
            thisError = error
            XCTAssertNil(token)
            XCTAssertNil(node)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let authError = thisError as? AuthError else {
            XCTFail("Authenticate with ResumeURI missing suspendedId failed with different reason")
            return
        }
        
        switch authError {
        case .invalidResumeURI:
            break
        default:
            XCTFail("Authenticate with ResumeURI missing suspendedId failed with different reason")
            break
        }
    }
    
    
    func test_09_authenticate_with_expired_suspended_id() {
        
        self.startSDK()
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_SuspendedAuthSessionException"])
        
        let url = URL(string: "http://default.iam.forgeops.com/am/XUI?realm=/&suspendedId=boPYZD4C5YogReyHSmmuDnLI2-c")!
        
        var thisError: Error?
        let ex = self.expectation(description: "First Node submit")
        FRSession.authenticate(resumeURI: url) { (token: Token?, node, error) in
            XCTAssertNotNil(error)
            thisError = error
            XCTAssertNil(token)
            XCTAssertNil(node)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let authApiError = thisError as? AuthApiError else {
            XCTFail("Authenticate with ResumeURI expired suspendedId failed with different reason")
            return
        }
        
        switch authApiError {
        case .suspendedAuthSessionError:
            break
        default:
            XCTFail("Authenticate with ResumeURI expired suspendedId failed with different reason")
            break
        }
    }
    
    
    func test_10_frsession_authenticate_without_oauth2client() {
        
        //  Switch to Config without OAuth2 client information
        let thisConfig = Config()
        thisConfig.configPlistFileName = "FRAuthConfigNoOAuth2"
        FRAuth.configPlistFileName = "FRAuthConfigNoOAuth2"
        self.config = thisConfig
        self.startSDK()
        super.setUp()
        XCTAssertNotNil(FRAuth.shared)
        XCTAssertNil(FRAuth.shared?.tokenManager)
        XCTAssertNil(FRAuth.shared?.oAuth2Client)
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success"])
        
        var currentNode: Node?
        
        var ex = self.expectation(description: "First Node submit")
        FRSession.authenticate(authIndexValue: "Login") { (token: Token?, node, error) in
            
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
                nameCallback.setValue(config.username)
            }
            else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.setValue(config.password)
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
        XCTAssertNotNil(FRSession.currentSession?.sessionToken?.value)
    }
    
    
    // MARK: - Step-Up Authentication Tests
    
    func test_11_stepup_auth_with_existing_sso_token_does_not_end_oidc_session() {
        // Scenario: User is authenticated with SSO + OAuth2 tokens, then performs a step-up
        // journey that returns a NEW SSO token (mismatch). The SDK should:
        // 1. Revoke the old SSO token via /sessions?_action=logout (NOT /connect/endSession)
        // 2. Revoke the old OAuth2 tokens
        // 3. Store the new SSO token
        // 4. NOT call endSession (which would kill all sessions including the new one)
        
        // Start SDK and perform login to get SSO + OAuth2 tokens
        self.performLogin()
        
        XCTAssertNotNil(FRUser.currentUser)
        XCTAssertNotNil(FRUser.currentUser?.token)
        XCTAssertNotNil(FRSession.currentSession?.sessionToken)
        
        let originalAccessToken = FRUser.currentUser?.token
        let originalSessionToken = FRSession.currentSession?.sessionToken
        
        // Set mock responses for step-up: new SSO token (different from original)
        // AM_Session_Logout_Success = revokeSSOToken() fire-and-forget
        // OAuth2_Token_Revoke_Success = revoke() for old OAuth2 tokens
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success2",
                                "AM_Session_Logout_Success",
                                "OAuth2_Token_Revoke_Success"])
        
        var currentNode: Node?
        
        var ex = self.expectation(description: "Step-up first node")
        FRSession.authenticate(authIndexValue: "UsernamePassword") { (token: Token?, node, error) in
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let node = currentNode else {
            XCTFail("Failed to get Node")
            return
        }
        
        for callback in node.callbacks {
            if callback is NameCallback, let cb = callback as? NameCallback { cb.setValue(config.username) }
            else if callback is PasswordCallback, let cb = callback as? PasswordCallback { cb.setValue(config.password) }
        }
        
        ex = self.expectation(description: "Step-up completion")
        node.next { (token: Token?, node, error) in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Verify: new SSO token stored, old access token revoked
        XCTAssertNotNil(FRSession.currentSession?.sessionToken)
        XCTAssertNotEqual(originalSessionToken?.value, FRSession.currentSession?.sessionToken?.value)
        // Old OAuth2 tokens should be revoked (nil)
        XCTAssertNil(FRUser.currentUser?.token)
        // But the new session token is stored and valid
        XCTAssertNotNil(FRSession.currentSession?.sessionToken?.value)
    }
    
    
    func test_12_centralized_login_then_journey_revokes_stale_oauth2_tokens() {
        // Scenario: User authenticated via Centralized Login (no SSO token stored, but
        // access token exists). Then a journey via FRSession.authenticate completes with
        // a new SSO token (potentially for a different user). The SDK MUST revoke the
        // stale OAuth2 token set and store the new SSO token to keep local credentials
        // consistent with the SSO session AM will associate with subsequent SDK requests.
        //
        // NOTE: This is a regression test for a bug where the SDK previously skipped
        // both the SSO-token store and OAuth2 revocation in this scenario, leaving
        // a stale access token paired with a different user's session cookies.
        
        self.startSDK()
        
        guard let frAuth = FRAuth.shared else {
            XCTFail("FRAuth not initialized")
            return
        }
        
        // Simulate Centralized Login state: access token exists, but NO SSO token.
        guard let tokenData = self.readDataFromJSON("AccessToken") else {
            XCTFail("Failed to read AccessToken.json")
            return
        }
        guard let accessToken = AccessToken(tokenResponse: tokenData) else {
            XCTFail("Failed to construct AccessToken")
            return
        }
        try? frAuth.keychainManager.setAccessToken(token: accessToken)
        XCTAssertNil(frAuth.keychainManager.getSSOToken())
        XCTAssertNotNil(try? frAuth.keychainManager.getAccessToken())
        
        // Mocks: journey returning an SSO token + revoke endpoint for stale OAuth2 tokens.
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success",
                                "OAuth2_Token_Revoke_Success"])
        
        var currentNode: Node?
        
        var ex = self.expectation(description: "First Node")
        FRSession.authenticate(authIndexValue: "UsernamePassword") { (token: Token?, node, error) in
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let node = currentNode else {
            XCTFail("Failed to get Node")
            return
        }
        
        for callback in node.callbacks {
            if callback is NameCallback, let cb = callback as? NameCallback { cb.setValue(config.username) }
            else if callback is PasswordCallback, let cb = callback as? PasswordCallback { cb.setValue(config.password) }
        }
        
        let requestCountBeforeJourneyCompletion = FRTestNetworkStubProtocol.requestHistory.count
        
        ex = self.expectation(description: "Journey completion")
        node.next { (token: Token?, node, error) in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // The new SSO token SHOULD now be stored.
        XCTAssertNotNil(frAuth.keychainManager.getSSOToken())
        // The stale OAuth2 access token MUST have been revoked locally.
        XCTAssertNil(try? frAuth.keychainManager.getAccessToken())
        // The SDK MUST have invoked the OAuth2 revoke endpoint for the stale token.
        let postRequests = Array(FRTestNetworkStubProtocol.requestHistory.dropFirst(requestCountBeforeJourneyCompletion))
        let didCallRevoke = postRequests.contains { req in
            (req.url?.absoluteString ?? "").contains("/token/revoke")
        }
        XCTAssertTrue(didCallRevoke,
                      "Expected /token/revoke to be invoked to clear the stale Centralized Login OAuth2 token set. Requests after journey: \(postRequests.compactMap { $0.url?.absoluteString })")
    }
    
    
    func test_13_centralized_login_then_journey_stores_sso_token_when_no_access_token() {
        // Scenario: No SSO token and no access token (fresh state after Centralized Login
        // where tokens haven't been exchanged yet). Journey returns an SSO token.
        // The SDK SHOULD store the new SSO token since there's nothing to protect.
        
        self.startSDK()
        
        guard let frAuth = FRAuth.shared else {
            XCTFail("FRAuth not initialized")
            return
        }
        
        // Ensure clean state: no SSO token, no access token
        XCTAssertNil(frAuth.keychainManager.getSSOToken())
        XCTAssertNil(try? frAuth.keychainManager.getAccessToken())
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success"])
        
        var currentNode: Node?
        
        var ex = self.expectation(description: "First Node")
        FRSession.authenticate(authIndexValue: "UsernamePassword") { (token: Token?, node, error) in
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let node = currentNode else {
            XCTFail("Failed to get Node")
            return
        }
        
        for callback in node.callbacks {
            if callback is NameCallback, let cb = callback as? NameCallback { cb.setValue(config.username) }
            else if callback is PasswordCallback, let cb = callback as? PasswordCallback { cb.setValue(config.password) }
        }
        
        ex = self.expectation(description: "Journey completion")
        node.next { (token: Token?, node, error) in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // The SSO token SHOULD be stored since no access token existed
        XCTAssertNotNil(frAuth.keychainManager.getSSOToken())
    }
    
    
    func test_14_stepup_same_token_preserves_oauth2_tokens() {
        // Scenario: Step-up journey returns the SAME SSO token.
        // OAuth2 tokens should NOT be revoked.
        
        self.performLogin()
        
        XCTAssertNotNil(FRUser.currentUser?.token)
        let originalAccessToken = FRUser.currentUser?.token
        let originalSessionToken = FRSession.currentSession?.sessionToken
        
        // Re-authenticate with the SAME SSO token
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success"])
        
        var currentNode: Node?
        
        var ex = self.expectation(description: "First Node")
        FRSession.authenticate(authIndexValue: "UsernamePassword") { (token: Token?, node, error) in
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let node = currentNode else {
            XCTFail("Failed to get Node")
            return
        }
        
        for callback in node.callbacks {
            if callback is NameCallback, let cb = callback as? NameCallback { cb.setValue(config.username) }
            else if callback is PasswordCallback, let cb = callback as? PasswordCallback { cb.setValue(config.password) }
        }
        
        ex = self.expectation(description: "Journey completion")
        node.next { (token: Token?, node, error) in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Same SSO token should be stored, OAuth2 tokens preserved
        XCTAssertEqual(originalSessionToken?.value, FRSession.currentSession?.sessionToken?.value)
        XCTAssertNotNil(FRUser.currentUser?.token)
        XCTAssertEqual(originalAccessToken, FRUser.currentUser?.token)
    }
    
    
    func test_15_user_logout_clears_all_tokens_and_sessions() {
        // Scenario: FRUser.logout() should clear SSO token, OAuth2 tokens, session, and user
        
        self.performLogin()
        
        XCTAssertNotNil(FRUser.currentUser)
        XCTAssertNotNil(FRUser.currentUser?.token)
        XCTAssertNotNil(FRSession.currentSession)
        XCTAssertNotNil(FRSession.currentSession?.sessionToken)
        
        // Load mocks for logout: revokeSSOToken + revoke OAuth2
        self.loadMockResponses(["AM_Session_Logout_Success",
                                "OAuth2_Token_Revoke_Success"])
        
        FRUser.currentUser?.logout()
        
        // Wait for async logout requests
        sleep(5)
        
        XCTAssertNil(FRUser.currentUser)
        XCTAssertNil(FRSession.currentSession)
    }
    
    
    func test_16_user_logout_with_sso_token_only_revokes_session() {
        // Regression: After authenticating via FRSession.authenticate (SSO token only,
        // no OAuth2 access token), calling FRUser.currentUser?.logout() must still
        // revoke the SSO session and clear cookies.
        //
        // Previously, revokeAndEndSession() would short-circuit with TokenError.nullToken
        // because no access token was found, never invoking /sessions?_action=logout,
        // leaving the SSO token cookie active for subsequent AM requests.
        
        self.startSDK()
        self.config.authServiceName = "UsernamePassword"
        
        guard let frAuth = FRAuth.shared else {
            XCTFail("FRAuth not initialized")
            return
        }
        
        // Authenticate via FRSession only — produces an SSO token, no OAuth2 tokens.
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success"])
        
        var currentNode: Node?
        
        var ex = self.expectation(description: "First Node submit")
        FRSession.authenticate(authIndexValue: self.config.authServiceName!) { (token: Token?, node, error) in
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
        
        for callback in node.callbacks {
            if callback is NameCallback, let cb = callback as? NameCallback { cb.setValue(config.username) }
            else if callback is PasswordCallback, let cb = callback as? PasswordCallback { cb.setValue(config.password) }
        }
        
        ex = self.expectation(description: "Journey completion")
        node.next { (token: Token?, node, error) in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Pre-conditions: SSO token present, NO OAuth2 access token.
        XCTAssertNotNil(frAuth.keychainManager.getSSOToken())
        XCTAssertNotNil(FRUser.currentUser)
        XCTAssertNil(FRUser.currentUser?.token)
        XCTAssertNotNil(FRSession.currentSession?.sessionToken)
        
        // Snapshot request count before logout so we can verify the logout call was issued.
        let requestCountBeforeLogout = FRTestNetworkStubProtocol.requestHistory.count
        
        // Mock the SSO session logout response.
        self.loadMockResponses(["AM_Session_Logout_Success"])
        
        FRUser.currentUser?.logout()
        
        // Wait for async logout request to flush.
        sleep(5)
        
        // The SDK must have issued the AM session logout request even though no
        // OAuth2 access token was present.
        let postLogoutRequests = Array(FRTestNetworkStubProtocol.requestHistory.dropFirst(requestCountBeforeLogout))
        let didCallSessionLogout = postLogoutRequests.contains { request in
            guard let url = request.url?.absoluteString else { return false }
            return url.contains("/sessions") && url.contains("_action=logout")
        }
        XCTAssertTrue(didCallSessionLogout,
                      "Expected /sessions?_action=logout to be invoked when logging out with SSO token only. Requests after logout: \(postLogoutRequests.compactMap { $0.url?.absoluteString })")
        
        // Local state must be cleared.
        XCTAssertNil(FRUser.currentUser)
        XCTAssertNil(FRSession.currentSession)
        XCTAssertNil(frAuth.keychainManager.getSSOToken())
    }
    
    
    func test_17_user_logout_force_end_session_invokes_both_endpoints() {
        // Scenario: User has BOTH an SSO token and an OAuth2 token set with an id_token.
        // Calling FRUser.logout(forceEndSession: true) must invoke /sessions?_action=logout
        // AND /connect/endSession AND /token/revoke, instead of the default behavior which
        // skips /connect/endSession when an SSO token is present.
        
        self.performLogin()
        
        guard let frAuth = FRAuth.shared else {
            XCTFail("FRAuth not initialized")
            return
        }
        
        // Pre-conditions: SSO token + access token (with id_token) both present.
        XCTAssertNotNil(frAuth.keychainManager.getSSOToken())
        guard let accessToken = try? frAuth.keychainManager.getAccessToken() else {
            XCTFail("Expected access token after login")
            return
        }
        XCTAssertNotNil(accessToken.idToken, "Test fixture must include an id_token to validate endSession invocation")
        
        // Mocks for all three logout endpoints.
        self.loadMockResponses(["AM_Session_Logout_Success",
                                "OAuth2_EndSession_Success",
                                "OAuth2_Token_Revoke_Success"])
        
        let requestCountBeforeLogout = FRTestNetworkStubProtocol.requestHistory.count
        
        FRUser.currentUser?.logout(forceEndSession: true)
        
        // Wait for async logout requests to flush.
        sleep(5)
        
        let postLogoutRequests = Array(FRTestNetworkStubProtocol.requestHistory.dropFirst(requestCountBeforeLogout))
        let urls = postLogoutRequests.compactMap { $0.url?.absoluteString }
        
        let didCallSessionLogout = urls.contains { $0.contains("/sessions") && $0.contains("_action=logout") }
        let didCallEndSession = urls.contains { $0.contains("/connect/endSession") }
        let didCallRevoke = urls.contains { $0.contains("/token/revoke") }
        
        XCTAssertTrue(didCallSessionLogout,
                      "Expected /sessions?_action=logout to be invoked. Requests after logout: \(urls)")
        XCTAssertTrue(didCallEndSession,
                      "Expected /connect/endSession to be invoked when forceEndSession is true. Requests after logout: \(urls)")
        XCTAssertTrue(didCallRevoke,
                      "Expected /token/revoke to be invoked. Requests after logout: \(urls)")
        
        // Local state must be cleared.
        XCTAssertNil(FRUser.currentUser)
        XCTAssertNil(FRSession.currentSession)
    }
    
    
    func test_18_journey_with_empty_token_preserves_existing_credentials() {
        // Scenario: A journey runs as passthrough or with the NoSession flag and returns an
        // empty tokenId. The SDK must NOT wipe the existing stored SSO token or revoke
        // existing OAuth2 tokens — there is nothing new to install and nothing to invalidate.
        
        // Start in a fully-authenticated state: SSO token + OAuth2 token set.
        self.performLogin()
        
        guard let frAuth = FRAuth.shared else {
            XCTFail("FRAuth not initialized")
            return
        }
        
        let originalSSO = frAuth.keychainManager.getSSOToken()
        let originalAccessToken = try? frAuth.keychainManager.getAccessToken()
        XCTAssertNotNil(originalSSO)
        XCTAssertNotNil(originalAccessToken)
        
        let requestCountBeforeJourney = FRTestNetworkStubProtocol.requestHistory.count
        
        // Directly exercise handleSessionToken with an empty Token to simulate the
        // passthrough / NoSession journey response producing an empty tokenId.
        let emptyToken = Token("", successUrl: "", realm: "/")
        let ex = self.expectation(description: "handleSessionToken with empty token")
        frAuth.keychainManager.handleSessionToken(emptyToken,
                                                  tokenManager: frAuth.tokenManager) { (token, node, error) in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            XCTAssertEqual(token?.value, "")
            ex.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        // Stored credentials must be unchanged.
        XCTAssertEqual(frAuth.keychainManager.getSSOToken()?.value, originalSSO?.value,
                       "Existing SSO token should be preserved when journey returns an empty token")
        let postAccessToken = try? frAuth.keychainManager.getAccessToken()
        XCTAssertNotNil(postAccessToken,
                        "Existing OAuth2 access token should be preserved when journey returns an empty token")
        XCTAssertEqual(postAccessToken?.value, originalAccessToken?.value)
        
        // No revoke / endSession / sessions-logout request should have been issued.
        let postRequests = Array(FRTestNetworkStubProtocol.requestHistory.dropFirst(requestCountBeforeJourney))
        let urls = postRequests.compactMap { $0.url?.absoluteString }
        XCTAssertFalse(urls.contains { $0.contains("/token/revoke") },
                       "Did not expect /token/revoke to be invoked. Requests: \(urls)")
        XCTAssertFalse(urls.contains { $0.contains("/connect/endSession") },
                       "Did not expect /connect/endSession to be invoked. Requests: \(urls)")
        XCTAssertFalse(urls.contains { $0.contains("/sessions") && $0.contains("_action=logout") },
                       "Did not expect /sessions?_action=logout to be invoked. Requests: \(urls)")
    }
}


class SuspendedRequestInterceptor: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        SuspendedRequestInterceptor.requests.append(request)
        SuspendedRequestInterceptor.actions.append(action)
        
        return request
    }
    
    static var requests: [Request] = []
    static var actions: [Action] = []
}
