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
