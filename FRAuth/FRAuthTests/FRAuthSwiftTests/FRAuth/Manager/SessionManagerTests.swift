// 
//  SessionManagerTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest

class SessionManagerTests: FRBaseTest {
    
    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    
    func test_01_SessionManager_Init() {

        // Given
        let config = self.readConfigFile(fileName: "FRAuthConfig")
        guard let baseUrl = config["forgerock_url"] as? String, let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to load url from configuration file")
            return
        }
        guard let keychainManager = try? KeychainManager(baseUrl: baseUrl) else {
            XCTFail("Failed to initialize KeychainManager")
            return
        }
        
        // Then
        let sessionManager = SessionManager(keychainManager: keychainManager, serverConfig: serverConfig)
        // Should
        XCTAssertNotNil(sessionManager)
    }
    
    
    func test_02_SessionManagerSingleton() {
            
        // Given
        self.startSDK()
        
        // Then
        XCTAssertNotNil(SessionManager.currentManager)
    }
    
    
    func test_03_ManageToken() {
        
        // Given
        guard let sessionManager = constructSessionManager() else {
            XCTFail("Failed to construct SessionManager")
            return
        }
        let token = Token("tokenValue")
        
        sessionManager.setSSOToken(ssoToken: token)
        
        // Then
        XCTAssertNotNil(sessionManager.getSSOToken())
        XCTAssertEqual(sessionManager.getSSOToken()?.value, token.value)
        
        // When
        sessionManager.setSSOToken(ssoToken: nil)
        
        // Then
        XCTAssertNil(sessionManager.getSSOToken())
    }
    
    
    func test_04_ManageAccessToken() {
        
        // Given
        guard let sessionManager = constructSessionManager() else {
            XCTFail("Failed to construct SessionManager")
            return
        }
        
        guard let tokenData = self.readDataFromJSON("AccessToken"), let at = AccessToken(tokenResponse: tokenData) else {
            XCTFail("Failed to read 'AccessToken.json' for \(String(describing: self)) testing")
            return
        }
        
        // Then
        do {
            try sessionManager.setAccessToken(token: at)
            let accessToken = try sessionManager.getAccessToken()
            XCTAssertNotNil(accessToken)
            XCTAssertEqual(accessToken, at)
            XCTAssertEqual(accessToken?.value, at.value)
        }
        catch {
            XCTFail("Failed to store AccessToken into SessionManager")
        }
        
        
        do {
            // When
            try sessionManager.setAccessToken(token: nil)
            
            // Then
            let accessToken = try sessionManager.getAccessToken()
            XCTAssertNil(accessToken)
        }
        catch {
            XCTFail("Failed to delete AccessToken from SessionManager")
        }
    }
    
    
    func test_05_ManageUser() {
        
        // Given
        guard let sessionManager = constructSessionManager() else {
            XCTFail("Failed to construct SessionManager")
            return
        }
        
        guard let tokenData = self.readDataFromJSON("AccessToken"), let at = AccessToken(tokenResponse: tokenData) else {
            XCTFail("Failed to read 'AccessToken.json' for \(String(describing: self)) testing")
            return
        }
        
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to load Config for ServerConfig")
            return
        }
        
        let user = FRUser(token: at, serverConfig: serverConfig)
        sessionManager.setCurrentUser(user: user)
        
        // Then
        XCTAssertNotNil(sessionManager.getCurrentUser())
        
        // When
        sessionManager.setCurrentUser(user: nil)
        
        // Then
        XCTAssertNil(sessionManager.getCurrentUser())
    }
    
    
    func test_06_RevokeSSOToken() {
        
        // Given
        self.startSDK()
        performUserLogin()
        
        // Then
        guard let sessionManager = SessionManager.currentManager else {
            XCTFail("Failed to retrieve SessionManager singleton object after SDK initialization")
            return
        }
        XCTAssertNotNil(sessionManager.getSSOToken())
        
        // When
        sessionManager.revokeSSOToken()
        
        // Should
        XCTAssertNil(sessionManager.getSSOToken())
    }
    
    
    // MARK: - Helper Method
    
    func constructSessionManager() -> SessionManager? {
        // Given
        let config = self.readConfigFile(fileName: "FRAuthConfig")
        guard let baseUrl = config["forgerock_url"] as? String, let serverConfig = self.config.serverConfig else {
           XCTFail("Failed to load url from configuration file")
           return nil
        }
        guard let keychainManager = try? KeychainManager(baseUrl: baseUrl) else {
           XCTFail("Failed to initialize KeychainManager")
           return nil
        }

        // Then
        let sessionManager = SessionManager(keychainManager: keychainManager, serverConfig: serverConfig)
        // Should
        XCTAssertNotNil(sessionManager)
        
        return sessionManager
    }
    
        
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
}
