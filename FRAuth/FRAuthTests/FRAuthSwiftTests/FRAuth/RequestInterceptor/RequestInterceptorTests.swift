// 
//  RequestInterceptorTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest

class RequestInterceptorTests: FRBaseTest {
    
    static var intercepted: [String] = []
    
    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    override func tearDown() {
        RequestInterceptorTests.intercepted = []
        super.tearDown()
    }
    
    func test_01_fruser_login_flow_interceptors() {
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()
        
        // Register RequestInterceptors
        FRRequestInterceptorFactory.shared.registerInterceptors(interceptors: [FRAuthInterceptor()])
        
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
        
        XCTAssertEqual(RequestInterceptorTests.intercepted.count, 4)
        let interceptorsInOrder: [String] = ["START_AUTHENTICATE", "AUTHENTICATE", "AUTHORIZE", "EXCHANGE_TOKEN"]
        for (index, intercepted) in RequestInterceptorTests.intercepted.enumerated() {
            XCTAssertEqual(interceptorsInOrder[index], intercepted)
        }
        
        self.shouldCleanup = false
    }
    
    
    func test_02_refresh_token_interceptor() {
        // Start SDK
        self.startSDK()
        
        // Register RequestInterceptors
        FRRequestInterceptorFactory.shared.registerInterceptors(interceptors: [FRAuthInterceptor()])
        
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
        
        XCTAssertEqual(RequestInterceptorTests.intercepted.count, 1)
        let interceptorsInOrder: [String] = ["REFRESH_TOKEN"]
        for (index, intercepted) in RequestInterceptorTests.intercepted.enumerated() {
            XCTAssertEqual(interceptorsInOrder[index], intercepted)
        }
        
        self.shouldCleanup = false
    }
    
    
    func test_03_logout_interceptor() {
        // Start SDK
        self.startSDK()
        
        // Register RequestInterceptors
        FRRequestInterceptorFactory.shared.registerInterceptors(interceptors: [FRAuthInterceptor()])
        
        // Set mock responses
        self.loadMockResponses(["OAuth2_Token_Revoke_Success", "AM_Session_Logout_Success"])
        
        //  Make sure user already exists
        XCTAssertNotNil(FRUser.currentUser)
        
        //  Logout
        FRUser.currentUser?.logout()
        
        //  Sleep to make sure that logout requests are successfully made
        sleep(5)
        
        XCTAssertNil(FRUser.currentUser)
        
        XCTAssertEqual(RequestInterceptorTests.intercepted.count, 2)
        let interceptorsInOrder: [String] = ["REVOKE_TOKEN", "LOGOUT"]
        for intercepted in RequestInterceptorTests.intercepted {
            XCTAssertTrue(interceptorsInOrder.contains(intercepted))
        }
    }
}
