//
//  FRURLProtocolTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
import FRCore

class FRURLProtocolTests: FRBaseTest {
    
    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
        URLProtocol.registerClass(FRURLProtocol.self)
    }
    
    
    func test_01_Validate_AuthHeader_For_URLSessionRequest_With_FRURLPRotocol_WithoutUserSession() {
        
        // If user session is not valid, clean it up before test
        FRTestUtils.cleanUpAfterTearDown()
        
        // SDK Init
        self.startSDK()
        
        // Given URLSession with FRURLProtocol
        let config = URLSessionConfiguration.default
        config.protocolClasses = [FRURLProtocol.self]
        let urlSession: URLSession = URLSession(configuration: config)
        
        // Register whitelist URLs
        FRURLProtocol.validatedURLs = [URL(string: "https://httpbin.org/anything")!]
        
        // When
        let ex = self.expectation(description: "Making request")
        urlSession.dataTask(with: URL(string: "https://httpbin.org/anything")!) { (data, response, error) in
            let response = Response(data: data, response: response, error: error).parseReponse()
            
            // Only validate specific case as request is being made to external API
            switch response {
            case .success(let result, _):
                if let headers = result["headers"] as? [String: String] {
                    XCTAssertFalse(headers.keys.contains("Authorization"))
                    XCTAssertFalse(headers.keys.contains("authorization"))
                }
                break
            case .failure(_):
                break;
            }
            ex.fulfill()
            }.resume()
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_02_Validate_AuthHeader_For_URLSessionRequest_Without_FRURLProtocol() {
        
        // Initial user session check
        self.startSDK()
        if let user = FRUser.currentUser, let userToken = user.token, !userToken.isExpired {
        }
        else {
            // If user session is not valid, clean it up before test
            FRTestUtils.cleanUpAfterTearDown()
            self.performUserLogin()
        }
        
        // Validate session status
        guard let user = FRUser.currentUser, let userToken = user.token, !userToken.isExpired else {
            XCTFail("Unexpected authentication status: no authenticated user found to perform test")
            return
        }
        
        // Given plain URLSession
        let urlSession: URLSession = URLSession(configuration: .default)
        
        // When
        let ex = self.expectation(description: "Making request")
        urlSession.dataTask(with: URL(string: "https://httpbin.org/anything")!) { (data, response, error) in
            let response = Response(data: data, response: response, error: error).parseReponse()

            // Only validate specific case as request is being made to external API
            switch response {
            case .success(let result, _):
                if let headers = result["headers"] as? [String: String] {
                    XCTAssertFalse(headers.keys.contains("Authorization"))
                    XCTAssertFalse(headers.keys.contains("authorization"))
                }
                break
            case .failure(_):
                break;
            }
            ex.fulfill()
        }.resume()
        waitForExpectations(timeout: 60, handler: nil)
        
        // Ignore cleanup to reuse session for further tests
        self.shouldCleanup = false
    }
    
    
    func test_03_Validate_AuthHeader_For_URLSessionRequest_With_FRURLPRotocol() {
        
        // Initial user session check
        self.startSDK()
        if let user = FRUser.currentUser, let userToken = user.token, !userToken.isExpired {
        }
        else {
            // If user session is not valid, clean it up before test
            FRTestUtils.cleanUpAfterTearDown()
            self.performUserLogin()
        }
        
        // Validate session status
        guard let user = FRUser.currentUser, let userToken = user.token, !userToken.isExpired else {
            XCTFail("Unexpected authentication status: no authenticated user found to perform test")
            return
        }
        
        // Given URLSession with FRURLProtocol
        let config = URLSessionConfiguration.default
        config.protocolClasses = [FRURLProtocol.self]
        let urlSession: URLSession = URLSession(configuration: config)
        
        // Register whitelist URLs
        FRURLProtocol.validatedURLs = [URL(string: "https://httpbin.org/anything")!]
        
        // When
        let ex = self.expectation(description: "Making request")
        urlSession.dataTask(with: URL(string: "https://httpbin.org/anything")!) { (data, response, error) in
            let response = Response(data: data, response: response, error: error).parseReponse()
            
            // Only validate specific case as request is being made to external API
            switch response {
            case .success(let result, _):
                if let headers = result["headers"] as? [String: String] {
                    if let authHeader = headers["Authorization"] {
                        XCTAssertEqual(userToken.buildAuthorizationHeader(), authHeader)
                    }
                    else {
                        XCTFail("Failed to locate Authorization header using FRURLProtocol")
                    }
                }
                break
            case .failure(_):
                break;
            }
            ex.fulfill()
            }.resume()
        waitForExpectations(timeout: 60, handler: nil)
        
        // Ignore cleanup to reuse session for further tests
        self.shouldCleanup = false
    }
    
    
    func test_04_Validate_AuthHeader_For_URLSessionRequest_With_FRURLPRotocol_NotInWhitelist() {
        
        // Initial user session check
        self.startSDK()
        
        if let user = FRUser.currentUser, let userToken = user.token, !userToken.isExpired {
        }
        else {
            // If user session is not valid, clean it up before test
            FRTestUtils.cleanUpAfterTearDown()
            self.performUserLogin()
        }
        
        // Validate session status
        guard let user = FRUser.currentUser, let userToken = user.token, !userToken.isExpired else {
            XCTFail("Unexpected authentication status: no authenticated user found to perform test")
            return
        }
        
        // Given URLSession with FRURLProtocol
        let config = URLSessionConfiguration.default
        config.protocolClasses = [FRURLProtocol.self]
        let urlSession: URLSession = URLSession(configuration: config)
        
        // Register whitelist URLs
        FRURLProtocol.validatedURLs = [URL(string: "https://httpbin.org/notcorrect")!]
        
        // When
        let ex = self.expectation(description: "Making request")
        urlSession.dataTask(with: URL(string: "https://httpbin.org/anything")!) { (data, response, error) in
            let response = Response(data: data, response: response, error: error).parseReponse()
            
            // Only validate specific case as request is being made to external API
            switch response {
            case .success(let result, _):
                if let headers = result["headers"] as? [String: String] {
                    XCTAssertFalse(headers.keys.contains("Authorization"))
                    XCTAssertFalse(headers.keys.contains("authorization"))
                }
                break
            case .failure(_):
                break;
            }
            ex.fulfill()
            }.resume()
        waitForExpectations(timeout: 60, handler: nil)
        
        // Ignore cleanup to reuse session for further tests
        self.shouldCleanup = false
    }
    
    
    func test_05_Validate_AuthHeader_For_URLSessionRequest_With_FRURLPRotocol_TokenRefresh_With_UnsatisfiedRefreshPolicy() {
        
        // Initial user session check
        self.startSDK()
        
        if let user = FRUser.currentUser, let userToken = user.token, !userToken.isExpired {
        }
        else {
            // If user session is not valid, clean it up before test
            FRTestUtils.cleanUpAfterTearDown()
            self.performUserLogin()
        }
        
        // Validate session status
        guard let user = FRUser.currentUser, let userToken = user.token, !userToken.isExpired else {
            XCTFail("Unexpected authentication status: no authenticated user found to perform test")
            return
        }
        
        // Load mock response for refresh token
        self.loadMockResponses(["OAuth2_Token_Refresh_Success"])
        
        // Given URLSession with FRURLProtocol
        let config = URLSessionConfiguration.default
        config.protocolClasses = [FRURLProtocol.self]
        let urlSession: URLSession = URLSession(configuration: config)
        
        // Register whitelist URLs
        FRURLProtocol.validatedURLs = [URL(string: "https://httpbin.org/anything")!]
        
        // Only satisfy refresh policy upon HTTP 401
        FRURLProtocol.refreshTokenPolicy = {(responseData, response, error) in
            var shouldHandle = false
            // refresh token policy will only be enforced when HTTP status code is equal to 401 in this case
            // Developers can define their own policy based on response data, URLResponse, and/or error from the request
            if let thisResponse = response as? HTTPURLResponse, thisResponse.statusCode == 401 {
                
                shouldHandle = true
            }
            return shouldHandle
        }
        
        // When
        let ex = self.expectation(description: "Making request")
        urlSession.dataTask(with: URL(string: "https://httpbin.org/anything")!) { (data, response, error) in
            let response = Response(data: data, response: response, error: error).parseReponse()
            
            // Only validate specific case as request is being made to external API
            switch response {
            case .success(let result, _):
                if let headers = result["headers"] as? [String: String] {
                    if let authHeader = headers["Authorization"] {
                        // Auth header must be different from initial token
                        XCTAssertEqual(userToken.buildAuthorizationHeader(), authHeader)
                    }
                    else {
                        XCTFail("Failed to locate Authorization header using FRURLProtocol")
                    }
                }
                break
            case .failure(_):
                break;
            }
            ex.fulfill()
            }.resume()
        waitForExpectations(timeout: 60, handler: nil)
        
        // Ignore cleanup to reuse session for further tests
        self.shouldCleanup = false
    }
    
    
    func test_06_Validate_AuthHeader_For_URLSessionRequest_With_FRURLPRotocol_TokenRefresh_With_SatisfiedRefreshPolicy() {
        
        // Initial user session check
        self.startSDK()
        if let user = FRUser.currentUser, let userToken = user.token, !userToken.isExpired {
        }
        else {
            // If user session is not valid, clean it up before test
            FRTestUtils.cleanUpAfterTearDown()
            self.performUserLogin()
        }
        
        // Validate session status
        guard let user = FRUser.currentUser, let userToken = user.token, !userToken.isExpired else {
            XCTFail("Unexpected authentication status: no authenticated user found to perform test")
            return
        }
    
        // Load mock response for refresh token
        self.loadMockResponses(["OAuth2_Token_Refresh_Success"])
        
        // Given URLSession with FRURLProtocol
        let config = URLSessionConfiguration.default
        config.protocolClasses = [FRURLProtocol.self]
        let urlSession: URLSession = URLSession(configuration: config)
        
        // Register whitelist URLs
        FRURLProtocol.validatedURLs = [URL(string: "https://httpbin.org/anything")!]
        
        // Should always satisfy refresh policy
        FRURLProtocol.refreshTokenPolicy = {(responseData, response, error) in
            return true
        }
        
        // When
        let ex = self.expectation(description: "Making request")
        urlSession.dataTask(with: URL(string: "https://httpbin.org/anything")!) { (data, response, error) in
            let response = Response(data: data, response: response, error: error).parseReponse()
            
            // Only validate specific case as request is being made to external API
            switch response {
            case .success(let result, _):
                if let headers = result["headers"] as? [String: String] {
                    if let authHeader = headers["Authorization"] {
                        // Auth header must be different from initial token
                        XCTAssertNotEqual(userToken.buildAuthorizationHeader(), authHeader)
                    }
                    else {
                        XCTFail("Failed to locate Authorization header using FRURLProtocol")
                    }
                }
                break
            case .failure(_):
                break;
            }
            ex.fulfill()
            }.resume()
        waitForExpectations(timeout: 60, handler: nil)
        
        // Should cleanup for further tests
        self.shouldCleanup = true
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
