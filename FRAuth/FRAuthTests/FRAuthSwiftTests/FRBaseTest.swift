//
//  FRAuthTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

let FRTest = true

class FRBaseTest: XCTestCase {

    var shouldCleanup: Bool = true
    var shouldLoadMockResponses: Bool = true
    var config: Config = Config()
    var configFileName: String = ""
    
    override func setUp() {
        FRLog.setLogLevel(.all)
        self.continueAfterFailure = false
        
        if self.configFileName.count > 0 {
            do {
                self.config = try Config(self.configFileName)
            }
            catch {
                XCTFail("Failed to load test configuration file: \(error)")
            }
        }
        
        if self.shouldLoadMockResponses {
            // Register FRURLProtocol
            URLProtocol.registerClass(FRTestNetworkStubProtocol.self)
            
            // Construct URLSession with FRURLProtocol
            let config = URLSessionConfiguration.default
            config.protocolClasses = [FRTestNetworkStubProtocol.self]
            FRRestClient.setURLSessionConfiguration(config: config)
        }
    }

    override func tearDown() {
        if shouldCleanup {
            FRTestUtils.cleanUpAfterTearDown()
            FRRequestInterceptorRegistry.shared.registerInterceptors(interceptors: nil)
        }
    }
    
    func startSDK() {
        FRTestUtils.startSDK(self.config)
    }
    
    func parseStringToDictionary(_ str: String) -> [String: Any] {
        return FRTestUtils.parseStringToDictionary(str)
    }
    
    func loadMockResponses(_ responseFileNames: [String]) {
        FRTestUtils.loadMockResponses(responseFileNames)
    }
    
    func readDataFromJSON(_ fileName: String) -> [String: Any]? {
        return FRTestUtils.readDataFromJSON(fileName)
    }
    
    func readConfigFile(fileName: String) -> [String: Any] {
        
        guard let path = Bundle.main.path(forResource: fileName, ofType: "plist"), let config = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            XCTFail("Failed to read \(fileName).plist file")
            return [:]
        }
        
        return config
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
