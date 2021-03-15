//
//  AuthServiceTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019-2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AuthServiceTests: FRAuthBaseTest {

    var serverURL = "http://localhost:8080/am"
    var realm = "customRealm"
    var timeout = 90.0
    var authServiceName = "loginService"
    
    var clientId = "a09a42d7-b2f2-47f2-a3eb-a3c15e8008e8"
    var scope = "openid email phone"
    var redirectUri = "http://redirect.uri"
    
    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    func test_01_AuthServicePublicInit() {
        
        // Given
        let serverConfig = ServerConfigBuilder(url: URL(string: self.serverURL)!, realm: self.realm).set(timeout: self.timeout).build()
        let authService: AuthService = AuthService(name: "loginService", serverConfig: serverConfig)
        
        // Then
        XCTAssertEqual(authService.serviceName, self.authServiceName)
        XCTAssertEqual(authService.serverConfig.baseURL.absoluteString, self.serverURL)
        XCTAssertEqual(authService.serverConfig.authenticateURL, self.serverURL + "/json/realms/\(self.realm)/authenticate")
        XCTAssertEqual(authService.serverConfig.tokenURL, self.serverURL + "/oauth2/realms/\(self.realm)/access_token")
        XCTAssertEqual(authService.serverConfig.authorizeURL, self.serverURL + "/oauth2/realms/\(self.realm)/authorize")
        XCTAssertEqual(authService.serverConfig.timeout, 90)
        XCTAssertEqual(authService.serverConfig.realm, self.realm)
        XCTAssertNil(authService.oAuth2Config)
    }
    
    func test_02_AuthServicePrivateInit() {
        // Given
        let serverConfig = ServerConfigBuilder(url: URL(string: self.serverURL)!, realm: self.realm).set(timeout: self.timeout).build()
        let oAuth2Client = OAuth2Client(clientId: self.clientId, scope: self.scope, redirectUri: URL(string: self.redirectUri)!, serverConfig: serverConfig)
        let authService: AuthService = AuthService(authIndexValue: "loginService", serverConfig: serverConfig, oAuth2Config: oAuth2Client)
        
        // Then
        XCTAssertEqual(authService.serviceName, self.authServiceName)
        XCTAssertEqual(authService.serverConfig.baseURL.absoluteString, self.serverURL)
        XCTAssertEqual(authService.serverConfig.authenticateURL, self.serverURL + "/json/realms/\(self.realm)/authenticate")
        XCTAssertEqual(authService.serverConfig.tokenURL, self.serverURL + "/oauth2/realms/\(self.realm)/access_token")
        XCTAssertEqual(authService.serverConfig.authorizeURL, self.serverURL + "/oauth2/realms/\(self.realm)/authorize")
        XCTAssertEqual(authService.serverConfig.timeout, 90)
        XCTAssertEqual(authService.serverConfig.realm, "customRealm")
        XCTAssertNotNil(authService.oAuth2Config)
        XCTAssertEqual(authService.oAuth2Config?.clientId, self.clientId)
        XCTAssertEqual(authService.oAuth2Config?.redirectUri.absoluteString, self.redirectUri)
        XCTAssertEqual(authService.oAuth2Config?.scope, self.scope)
    }
    
    
    func test_03_no_session_auth_service_next() {
        
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to retrieve ServerConfig")
            return
        }
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_NoSession_Success"])
        
        //  noSession interceptor
        FRRequestInterceptorRegistry.shared.registerInterceptors(interceptors: [NoSessionInterceptor()])
        
        var currentNode: Node?
        let authService = AuthService(name: "UsernamePassword", serverConfig: serverConfig)
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
            XCTAssertNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_04_auth_service_with_suspended_id() {
        
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to retrieve ServerConfig")
            return
        }
        
        let authService = AuthService(suspendedId: "6IIIUln3ajONR4ySwZt15qzh8X4", serverConfig: serverConfig, oAuth2Config: nil)
        XCTAssertNotNil(authService)
        XCTAssertEqual(authService.authIndexType, "suspendedId")
        XCTAssertEqual(authService.serviceName, "6IIIUln3ajONR4ySwZt15qzh8X4")
        
        let request = authService.buildAuthServiceRequest()
        let urlRequest = request.build()
        let urlStr = urlRequest?.url?.absoluteString
        XCTAssertNotNil(urlRequest)
        XCTAssertNotNil(urlStr)
        guard let urlString = urlStr else {
            XCTFail("Failed to construct URLRequest object with AuthService and suspendedId")
            return
        }
        XCTAssertTrue(urlString.contains("suspendedId=6IIIUln3ajONR4ySwZt15qzh8X4"))
        XCTAssertFalse(urlString.contains("authIndexType"))
        XCTAssertFalse(urlString.contains("authIndexValue"))
    }
}

