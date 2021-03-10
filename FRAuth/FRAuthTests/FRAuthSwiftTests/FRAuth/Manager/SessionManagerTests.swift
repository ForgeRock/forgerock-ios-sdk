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
@testable import FRAuth

class SessionManagerTests: FRAuthBaseTest {
    
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
    
    
    func test_03_RevokeSSOToken() {
        
        // Given
        self.startSDK()
        self.performLogin()
        
        // Then
        guard let sessionManager = SessionManager.currentManager else {
            XCTFail("Failed to retrieve SessionManager singleton object after SDK initialization")
            return
        }
        XCTAssertNotNil(sessionManager.keychainManager.getSSOToken())
        
        // When
        sessionManager.revokeSSOToken()
        
        // Should
        XCTAssertNil(sessionManager.keychainManager.getSSOToken())
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
}
