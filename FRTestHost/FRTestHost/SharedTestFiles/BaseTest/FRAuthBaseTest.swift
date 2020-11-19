// 
//  FRAuthBaseTest.swift
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

let FRTest = true

class FRAuthBaseTest: FRBaseTestCase {
    
    //  MARK: - Properties
    
    var config: Config = Config()
    var configFileName: String = ""

    
    //  MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        
        //  Load Config object
        if self.configFileName.count > 0 {
            do {
                self.config = try Config(self.configFileName)
            }
            catch {
                XCTFail("Failed to load test configuration file: \(error)")
            }
        }
    }
    
    
    override func tearDown() {
        super.tearDown()
        
        if self.shouldCleanup {
            self.cleanUp()
        }
    }
    
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        if self.shouldCleanup {
            self.cleanUp()
        }
    }
    
    
    //  MARK: - Helper methods
    
    @objc func cleanUp() {
        if let frAuth = FRAuth.shared {
            frAuth.keychainManager.sharedStore.deleteAll()
            frAuth.keychainManager.privateStore.deleteAll()
            frAuth.keychainManager.cookieStore.deleteAll()
            frAuth.keychainManager.deviceIdentifierStore.deleteAll()
        }
        FRUser._staticUser = nil
        FRDevice._staticDevice = nil
        Browser.currentBrowser = nil
    }
    
    @objc static func cleanUp() {
        if let frAuth = FRAuth.shared {
            frAuth.keychainManager.sharedStore.deleteAll()
            frAuth.keychainManager.privateStore.deleteAll()
            frAuth.keychainManager.cookieStore.deleteAll()
            frAuth.keychainManager.deviceIdentifierStore.deleteAll()
        }
        FRUser._staticUser = nil
        FRDevice._staticDevice = nil
        Browser.currentBrowser = nil
    }
    
    
    func startSDK() {
        FRAuthBaseTest.startSDK(self.config)
    }
    
    
    func performUsernamePasswordLogin() {

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

        XCTAssertNotNil(FRUser.currentUser)
    }
    
    
    //  MARK: - Static helper methods
    
    @objc static func startSDK(_ config: Config) {
        // Initialize SDK
        do {
            if let _ = config.configPlistFileName {
                try FRAuth.start()
                // Make sure FRAuth.shared is not nil
                guard let _ = FRAuth.shared else {
                    XCTFail("Failed to start SDK; FRAuth.shared returns nil")
                    return
                }
            }
            else if let serverConfig = config.serverConfig,
                let oAuth2Client = config.oAuth2Client,
                let sessionManager = config.sessionManager,
                let tokenManager = config.tokenManager,
                let keychainManager = config.keychainManager,
                let authServiceName = config.authServiceName,
                let registrationServiceName = config.registrationServiceName {
                
                FRAuth.shared = FRAuth(authServiceName: authServiceName, registerServiceName: registrationServiceName, serverConfig: serverConfig, oAuth2Client: oAuth2Client, tokenManager: tokenManager, keychainManager: keychainManager, sessionManager: sessionManager)
            }
            else {
                XCTFail("Failed to start SDK: invalid configuration file.")
            }
        }
        catch {
            XCTFail("Failed to start SDK: \(error)")
        }
    }
}
