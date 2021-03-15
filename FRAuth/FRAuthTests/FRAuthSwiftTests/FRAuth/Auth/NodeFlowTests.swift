//
//  NodeFlowTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class NodeFlowTests: FRAuthBaseTest {
    
    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    
    func test_01_Get_SSOToken() {
        
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to retrieve ServerConfig")
            return
        }
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success"])
        
        // Init AuthService
        let authService = AuthService(name: "UsernamePassword", serverConfig: serverConfig)
        var currentNode: Node?
        
        var ex = self.expectation(description: "First Node submit")
        authService.next { (token: Token?, node, error) in
            
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
    }
    
    
    func test_02_Get_AccessToken_FailedDueToMissingOAuth2Client() {
        
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to retrieve ServerConfig")
            return
        }
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success",
                                "OAuth2_AuthorizeRedirect_Success",
                                "OAuth2_Token_Success"])
        
        // Start SDK
        self.startSDK()
        
        let authService = AuthService(name: "UsernamePassword", serverConfig: serverConfig)
        var currentNode: Node?
        
        var ex = self.expectation(description: "First Node submit")
        authService.next { (token: AccessToken?, node, error) in
            
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
        node.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(token)
            XCTAssertNotNil(error)
            
            guard let authError = error as? AuthError else {
                XCTFail("Failed with unexpected error")
                ex.fulfill()
                return
            }
            
            switch authError {
            case .invalidOAuth2Client:
                break
            default:
                XCTFail("Failed with unexpected error")
                break
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_03_Get_FRUser_FailedDueToMissingOAuth2Client() {
        
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to retrieve ServerConfig")
            return
        }
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success",
                                "OAuth2_AuthorizeRedirect_Success",
                                "OAuth2_Token_Success"])
        
        // Start SDK
        self.startSDK()
        
        let authService = AuthService(name: "UsernamePassword", serverConfig: serverConfig)
        var currentNode: Node?
        
        var ex = self.expectation(description: "First Node submit")
        authService.next { (user: FRUser?, node, error) in
            
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
        
        ex = self.expectation(description: "Second Node submit")
        node.next { (user: FRUser?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(user)
            XCTAssertNotNil(error)
            
            guard let authError = error as? AuthError else {
                XCTFail("Failed with unexpected error")
                ex.fulfill()
                return
            }
            
            switch authError {
            case .invalidOAuth2Client:
                break
            default:
                XCTFail("Failed with unexpected error")
                break
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_04_no_session_test() {
        
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to retrieve ServerConfig")
            return
        }
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_NoSession_Success"])
        
        //  noSession interceptor
        FRRequestInterceptorRegistry.shared.registerInterceptors(interceptors: [NoSessionInterceptor()])
        
        // Start SDK
        self.startSDK()
        
        let authService = AuthService(name: "UsernamePassword", serverConfig: serverConfig)
        var currentNode: Node?
        
        var ex = self.expectation(description: "First Node submit")
        authService.next { (user: FRUser?, node, error) in
            
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
        
        ex = self.expectation(description: "Second Node submit")
        node.next { (user: FRUser?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(user)
            XCTAssertNil(error)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
}
