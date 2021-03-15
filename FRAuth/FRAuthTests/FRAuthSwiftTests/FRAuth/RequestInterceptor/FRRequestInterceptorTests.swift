// 
//  FRRequestInterceptorTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class FRRequestInterceptorTests: FRAuthBaseTest {
    
    static var intercepted: [String] = []
    static var payload: [[String: Any]] = []
    
    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    override func tearDown() {
        FRRequestInterceptorTests.intercepted = []
        FRRequestInterceptorTests.payload = []
        super.tearDown()
    }
    
    func test_01_fruser_login_flow_interceptors() {
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()
        
        // Register RequestInterceptors
        FRRequestInterceptorRegistry.shared.registerInterceptors(interceptors: [FRAuthInterceptor()])
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
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
        
        guard let node = currentNode else {
            XCTFail("Failed to get Node from the first request")
            return
        }
        
        guard let payload = FRRequestInterceptorTests.payload.first else {
            XCTFail("Failed to retrieve Action.payload")
            return
        }
        XCTAssertEqual(FRRequestInterceptorTests.payload.count, 1)
        XCTAssertTrue(payload.keys.contains("tree"))
        XCTAssertTrue(payload.keys.contains("type"))
        XCTAssertEqual(payload["tree"] as? String, "UsernamePassword")
        XCTAssertEqual(payload["type"] as? String, "service")
        
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
        node.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let payload2 = FRRequestInterceptorTests.payload.last else {
            XCTFail("Failed to retrieve Action.payload")
            return
        }
        XCTAssertEqual(FRRequestInterceptorTests.payload.count, 2)
        XCTAssertTrue(payload2.keys.contains("tree"))
        XCTAssertTrue(payload2.keys.contains("type"))
        XCTAssertEqual(payload2["tree"] as? String, "UsernamePassword")
        XCTAssertEqual(payload2["type"] as? String, "service")
        
        XCTAssertNotNil(FRUser.currentUser)
        
        XCTAssertEqual(FRRequestInterceptorTests.intercepted.count, 4)
        let interceptorsInOrder: [String] = ["START_AUTHENTICATE", "AUTHENTICATE", "AUTHORIZE", "EXCHANGE_TOKEN"]
        for (index, intercepted) in FRRequestInterceptorTests.intercepted.enumerated() {
            XCTAssertEqual(interceptorsInOrder[index], intercepted)
        }
        
        self.shouldCleanup = false
    }
    
    
    func test_02_refresh_token_interceptor() {
        // Start SDK
        self.startSDK()
        
        // Register RequestInterceptors
        FRRequestInterceptorRegistry.shared.registerInterceptors(interceptors: [FRAuthInterceptor()])
        
        // Set mock responses
        self.loadMockResponses(["OAuth2_Token_Refresh_Success"])
        
        //  Make sure user already exists
        XCTAssertNotNil(FRUser.currentUser)
        
        //  Refresh token
        let ex = self.expectation(description: "Refresh Token")
        FRUser.currentUser?.refresh(completion: { (user, error) in
            ex.fulfill()
        })
        waitForExpectations(timeout: 60, handler: nil)
        XCTAssertEqual(FRRequestInterceptorTests.payload.count, 0)
        
        XCTAssertEqual(FRRequestInterceptorTests.intercepted.count, 1)
        let interceptorsInOrder: [String] = ["REFRESH_TOKEN"]
        for (index, intercepted) in FRRequestInterceptorTests.intercepted.enumerated() {
            XCTAssertEqual(interceptorsInOrder[index], intercepted)
        }
        
        self.shouldCleanup = false
    }
    
    
    func test_03_userinfo_interceptor() {
        // Start SDK
        self.startSDK()
        
        // Register RequestInterceptors
        FRRequestInterceptorRegistry.shared.registerInterceptors(interceptors: [FRAuthInterceptor()])
        // Set mock responses
        self.loadMockResponses(["OAuth2_UserInfo_Success"])
        
        //  Make sure user already exists
        XCTAssertNotNil(FRUser.currentUser)
        
        //  Refresh token
        let ex = self.expectation(description: "Userinfo")
        FRUser.currentUser?.getUserInfo(completion: { (userinfo, error) in
            ex.fulfill()
        })
        waitForExpectations(timeout: 60, handler: nil)
        XCTAssertEqual(FRRequestInterceptorTests.payload.count, 0)
        
        XCTAssertEqual(FRRequestInterceptorTests.intercepted.count, 1)
        let interceptorsInOrder: [String] = ["USER_INFO"]
        for (index, intercepted) in FRRequestInterceptorTests.intercepted.enumerated() {
            XCTAssertEqual(interceptorsInOrder[index], intercepted)
        }
        
        self.shouldCleanup = false
    }
    
    
    func test_04_logout_interceptor() {
        // Start SDK
        self.startSDK()
        
        // Register RequestInterceptors
        FRRequestInterceptorRegistry.shared.registerInterceptors(interceptors: [FRAuthInterceptor()])
        
        // Set mock responses
        self.loadMockResponses(["OAuth2_Token_Revoke_Success", "AM_Session_Logout_Success"])
        
        //  Make sure user already exists
        XCTAssertNotNil(FRUser.currentUser)
        
        //  Logout
        FRUser.currentUser?.logout()
        
        //  Sleep to make sure that logout requests are successfully made
        sleep(5)
        
        XCTAssertEqual(FRRequestInterceptorTests.payload.count, 0)
        XCTAssertNil(FRUser.currentUser)
        
        XCTAssertEqual(FRRequestInterceptorTests.intercepted.count, 2)
        let interceptorsInOrder: [String] = ["REVOKE_TOKEN", "LOGOUT"]
        for intercepted in FRRequestInterceptorTests.intercepted {
            XCTAssertTrue(interceptorsInOrder.contains(intercepted))
        }
    }
    
    
    func test_05_resume_authenticate() {
        // Start SDK
        self.startSDK()
        
        // Register RequestInterceptors
        FRRequestInterceptorRegistry.shared.registerInterceptors(interceptors: [FRAuthInterceptor()])
        
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to retrieve ServerConfig")
            return
        }
        
        let authService = AuthService(suspendedId: "6IIIUln3ajONR4ySwZt15qzh8X4", serverConfig: serverConfig, oAuth2Config: nil)
        
        let ex = self.expectation(description: "Userinfo")
        authService.next { (token: Token?, node, error) in
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        XCTAssertEqual(FRRequestInterceptorTests.payload.count, 0)
        XCTAssertEqual(FRRequestInterceptorTests.intercepted.count, 1)
        XCTAssertEqual(FRRequestInterceptorTests.intercepted.first, "RESUME_AUTHENTICATE")
    }
}
