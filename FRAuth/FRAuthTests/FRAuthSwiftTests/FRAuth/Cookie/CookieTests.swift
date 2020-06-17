// 
//  CookieTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest

class CookieTests: FRBaseTest {

    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
        self.shouldLoadMockResponses = true
    }
    
    
    func test_01_validate_cookie_after_login() {
           
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()

        self.performUserLogin()
        
        // Given last authentication request is OAuth2 token endpoint which should contain Session Token Cookie
        let request = FRTestNetworkStubProtocol.requestHistory.last
        XCTAssertNotNil(request)
        
        // Then
        let sessionToken = FRSession.currentSession?.sessionToken?.value
        let cookieHeader = request?.allHTTPHeaderFields?.string("Cookie")
        XCTAssertNotNil(sessionToken)
        XCTAssertNotNil(cookieHeader)
        XCTAssertTrue(cookieHeader!.contains(sessionToken!))
        
        // Should not clean up session for next test
        self.shouldCleanup = false
    }
    
    
    func test_02_validate_cookie_from_existing_session() {
        
        // Start SDK
        self.startSDK()
        
        // Load mock responses for retrieving UserInfo from /userinfo
        self.loadMockResponses(["OAuth2_UserInfo_Success"])
        
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to get user object")
            return
        }
        
        // Given
        let ex = self.expectation(description: "Get User Info")
        var receivedUserInfo: UserInfo? = nil
        user.getUserInfo { (userInfo, error) in
            XCTAssertNotNil(userInfo)
            XCTAssertNil(error)
            receivedUserInfo = userInfo
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        XCTAssertNotNil(receivedUserInfo)
        
        // With /userinfo request
        let request = FRTestNetworkStubProtocol.requestHistory.last
        XCTAssertNotNil(request)
        
        // Then
        let sessionToken = FRSession.currentSession?.sessionToken?.value
        let cookieHeader = request?.allHTTPHeaderFields?.string("Cookie")
        XCTAssertNotNil(sessionToken)
        XCTAssertNotNil(cookieHeader)
        XCTAssertTrue(cookieHeader!.contains(sessionToken!))
        
        // Should not clean up session for next test
        self.shouldCleanup = false
    }
    
    
    func test_03_validate_cookie_does_not_injected_with_disabled() {
        
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to get Config obj")
            return
        }
        
        self.config.serverConfig = ServerConfig(url: serverConfig.baseURL, realm: serverConfig.realm, timeout: serverConfig.timeout, enableCookie: false)
        
        // Start SDK
        self.startSDK()
        
        // Load mock responses for retrieving UserInfo from /userinfo
        self.loadMockResponses(["OAuth2_UserInfo_Success"])
        
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to get user object")
            return
        }
        
        // Given
        let ex = self.expectation(description: "Get User Info")
        var receivedUserInfo: UserInfo? = nil
        user.getUserInfo { (userInfo, error) in
            XCTAssertNotNil(userInfo)
            XCTAssertNil(error)
            receivedUserInfo = userInfo
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        XCTAssertNotNil(receivedUserInfo)
        
        // With /userinfo request
        let request = FRTestNetworkStubProtocol.requestHistory.last
        XCTAssertNotNil(request)
        
        // Then
        let sessionToken = FRSession.currentSession?.sessionToken?.value
        let cookieHeader = request?.allHTTPHeaderFields?.string("Cookie")
        XCTAssertNotNil(sessionToken)
        XCTAssertNil(cookieHeader)
    }
    
    
    func test_04_validate_no_persistent_cookie_when_disabled() {
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to get Config obj")
            return
        }
        
        self.config.serverConfig = ServerConfig(url: serverConfig.baseURL, realm: serverConfig.realm, timeout: serverConfig.timeout, enableCookie: false)
        
        // Start SDK
        self.startSDK()
        
        self.performUserLogin()
        
        // Given last authentication request is OAuth2 token endpoint which should contain Session Token Cookie
        let request = FRTestNetworkStubProtocol.requestHistory.last
        XCTAssertNotNil(request)
        
        // Then
        let cookieHeader = request?.allHTTPHeaderFields?.string("Cookie")
        XCTAssertNil(cookieHeader)
        
        // Also
        guard let count = self.config.keychainManager?.cookieStore.allItems()?.count else {
            return
        }
        XCTAssertEqual(count, 0)
    }
    
    
    func test_05_validate_cookie_deleted_after_successful_logout() {
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()

        self.performUserLogin()
        
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Load mock responses for AM Session revoke, and OAuth2 token revoke
        self.loadMockResponses(["AM_Session_Logout_Success",
                                "OAuth2_Token_Revoke_Success"])
        user.logout()
        
        // Sleep for 5 seconds to wait for async logout requests go through
        sleep(5)
        
        // Then
        guard let count = self.config.keychainManager?.cookieStore.allItems()?.count else {
            return
        }
        XCTAssertEqual(count, 0)
    }
    
    
    func test_06_validate_cookie_deleted_after_unsuccessful_logout() {
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()

        self.performUserLogin()
        
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Load mock responses for AM Session revoke, and OAuth2 token revoke
        self.loadMockResponses(["AM_Session_Logout_Failure",
                                "OAuth2_Token_Revoke_Success"])
        user.logout()
        
        // Sleep for 5 seconds to wait for async logout requests go through
        sleep(5)
        
        // Then
        guard let count = self.config.keychainManager?.cookieStore.allItems()?.count else {
            return
        }
        XCTAssertEqual(count, 0)
    }
    
    
    // MARK: - Helper Method
    
    func performUserLogin() {
        
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success",
                                "OAuth2_AuthorizeRedirect_Success",
                                "OAuth2_Token_Success"])
        
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
        node.next { (token: AccessToken?, node, error) in
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
