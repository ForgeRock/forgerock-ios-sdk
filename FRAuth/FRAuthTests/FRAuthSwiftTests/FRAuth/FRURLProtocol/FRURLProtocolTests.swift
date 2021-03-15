// 
//  FRURLProtocolTests.swift
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

class FRURLProtocolTests: FRAuthBaseTest {

    var shouldUpdateRequest: Bool = false
    var evaluateTokenRefresh: Bool = false
    var evaluateTokenRefreshCount: Int = 0
    
    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
        URLProtocol.registerClass(FRURLProtocol.self)
    }
    
    override func tearDown() {
        super.tearDown()
        shouldUpdateRequest = false
        evaluateTokenRefresh = false
        evaluateTokenRefreshCount = 0
        FRURLProtocol.authorizationPolicy = nil
        FRURLProtocol.tokenManagementPolicy = nil
    }
    
    
    //  MARK: - TokenManagementPolicy
    
    func test_01_validate_auth_header_for_not_configured_frurlprotocol() {
        
        //  Given URLSession with FRURLProtocol
        let config = URLSessionConfiguration.default
        config.protocolClasses = [FRURLProtocol.self]
        let urlSession: URLSession = URLSession(configuration: config)
        
        //  Invalidate all configuration for FRURLProtocol
        FRURLProtocol.authorizationPolicy = nil
        FRURLProtocol.tokenManagementPolicy = nil
        
        //  Perform login
        self.performLogin()
        
        //  When
        let ex = self.expectation(description: "Making request")
        urlSession.dataTask(with: URL(string: "https://httpbin.org/anything")!) { (data, response, error) in
            let response = Response(data: data, response: response, error: error).parseReponse()
            
            // Authorization header should have not been sent
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
        
        //  Keep current session for further testing
        self.shouldCleanup = false
    }
    
    
    func test_02_validate_auth_header_for_non_validating_url() {
        
        //  Init SDK
        self.startSDK()
        
        //  Validate current session from previous test
        guard let user = FRUser.currentUser, let _ = user.token else {
            XCTFail("Failed to retreive previous authenticated session")
            return
        }
        
        //  Given URLSession with FRURLProtocol
        let config = URLSessionConfiguration.default
        config.protocolClasses = [FRURLProtocol.self]
        let urlSession: URLSession = URLSession(configuration: config)
        
        //  Set TokenManagementPolicy, but with different URL for validation
        let tokenManagementPolicy = TokenManagementPolicy(validatingURL: [URL(string: "https://httpbin.org/any")!], delegate: nil)
        FRURLProtocol.authorizationPolicy = nil
        FRURLProtocol.tokenManagementPolicy = tokenManagementPolicy
        
        //  When
        let ex = self.expectation(description: "Making request")
        urlSession.dataTask(with: URL(string: "https://httpbin.org/anything")!) { (data, response, error) in
            let response = Response(data: data, response: response, error: error).parseReponse()
            
            // Authorization header should have not been sent
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
        
        //  Keep current session for further testing
        self.shouldCleanup = false
    }
    
    
    func test_03_validate_auth_header_with_validating_url() {
        //  Init SDK
        self.startSDK()
        
        //  Validate current session from previous test
        guard let user = FRUser.currentUser, let _ = user.token else {
            XCTFail("Failed to retreive previous authenticated session")
            return
        }
        
        //  Given URLSession with FRURLProtocol
        let config = URLSessionConfiguration.default
        config.protocolClasses = [FRURLProtocol.self]
        let urlSession: URLSession = URLSession(configuration: config)
        
        //  Set TokenManagementPolicy without delegate for default Authorization header, and validating URL
        let tokenManagementPolicy = TokenManagementPolicy(validatingURL: [URL(string: "https://httpbin.org/anything")!], delegate: nil)
        FRURLProtocol.authorizationPolicy = nil
        FRURLProtocol.tokenManagementPolicy = tokenManagementPolicy
        
        //  When
        let ex = self.expectation(description: "Making request")
        urlSession.dataTask(with: URL(string: "https://httpbin.org/anything")!) { (data, response, error) in
            let response = Response(data: data, response: response, error: error).parseReponse()
            
            // Authorization header should have been sent
            switch response {
            case .success(let result, _):
                if let headers = result["headers"] as? [String: String] {
                    XCTAssertTrue(headers.keys.contains("Authorization"))
                    let authHeader = headers["Authorization"]
                    XCTAssertEqual(user.buildAuthHeader(), authHeader)
                }
                break
            case .failure(_):
                break;
            }
            ex.fulfill()
            }.resume()
        waitForExpectations(timeout: 60, handler: nil)
        
        //  Keep current session for further testing
        self.shouldCleanup = false
    }
        
        
    func test_04_validate_auth_header_with_validating_url_in_custom_header() {
        //  Init SDK
        self.startSDK()
        
        //  Validate current session from previous test
        guard let user = FRUser.currentUser, let _ = user.token else {
            XCTFail("Failed to retreive previous authenticated session")
            return
        }
        
        //  Given URLSession with FRURLProtocol
        let config = URLSessionConfiguration.default
        config.protocolClasses = [FRURLProtocol.self]
        let urlSession: URLSession = URLSession(configuration: config)
        
        //  Set TokenManagementPolicy with delegate, and let delegation method to update request
        let tokenManagementPolicy = TokenManagementPolicy(validatingURL: [URL(string: "https://httpbin.org/anything")!], delegate: self)
        FRURLProtocol.authorizationPolicy = nil
        FRURLProtocol.tokenManagementPolicy = tokenManagementPolicy
        
        //  When
        let ex = self.expectation(description: "Making request")
        urlSession.dataTask(with: URL(string: "https://httpbin.org/anything")!) { (data, response, error) in
            let response = Response(data: data, response: response, error: error).parseReponse()
            
            // Authorization header should have been sent with customized header name in delegation method
            switch response {
            case .success(let result, _):
                if let headers = result["headers"] as? [String: String] {
                    XCTAssertTrue(headers.keys.contains("Auth"))
                    let authHeader = headers["Auth"]
                    XCTAssertEqual(user.buildAuthHeader(), authHeader)
                }
                break
            case .failure(_):
                break;
            }
            ex.fulfill()
            }.resume()
        waitForExpectations(timeout: 60, handler: nil)
        
        //  Keep current session for further testing
        self.shouldCleanup = false
    }
            
            
    func test_05_validate_token_refresh_evaluation_and_token_renewal() {
        //  Init SDK
        self.startSDK()
        
        //  Mock update token response
        self.loadMockResponses(["OAuth2_Token_Refresh_Success"])
        
        //  Validate current session from previous test
        guard let user = FRUser.currentUser, let token = user.token else {
            XCTFail("Failed to retreive previous authenticated session")
            return
        }
        
        //  Given URLSession with FRURLProtocol
        let config = URLSessionConfiguration.default
        config.protocolClasses = [FRURLProtocol.self]
        let urlSession: URLSession = URLSession(configuration: config)
        
        //  Set TokenManagementPolicy with delegate, and let delegation method to update request
        self.evaluateTokenRefresh = true
        let tokenManagementPolicy = TokenManagementPolicy(validatingURL: [URL(string: "https://httpbin.org/anything")!], delegate: self)
        FRURLProtocol.authorizationPolicy = nil
        FRURLProtocol.tokenManagementPolicy = tokenManagementPolicy
        
        //  When
        let ex = self.expectation(description: "Making request")
        urlSession.dataTask(with: URL(string: "https://httpbin.org/anything")!) { (data, response, error) in
            let response = Response(data: data, response: response, error: error).parseReponse()
            
            // Authorization header should have been sent with customized header name in delegation method
            switch response {
            case .success(let result, _):
                if let headers = result["headers"] as? [String: String] {
                    XCTAssertTrue(headers.keys.contains("Auth"))
                    let authHeader = headers["Auth"]
                    XCTAssertEqual(FRUser.currentUser?.buildAuthHeader(), authHeader)
                    XCTAssertNotEqual(token.buildAuthorizationHeader(), authHeader)
                }
                break
            case .failure(_):
                break;
            }
            ex.fulfill()
            }.resume()
        waitForExpectations(timeout: 60, handler: nil)
        if let _ = FRUser.currentUser {
            print("user found")
        }
        else {
            print("user not found")
        }
        //  Keep current session for further testing
        self.shouldCleanup = false
    }
    
                
    func test_06_validate_token_refresh_evaluation_keep_failing_and_test_max_retry_count() {
        //  Init SDK
        self.startSDK()
        if let _ = FRUser.currentUser {
            print("user found")
        }
        else {
            print("user not found")
        }
        //  Mock update token response
        self.loadMockResponses(["OAuth2_Token_Refresh_Success"])
        
        //  Validate current session from previous test
        guard let user = FRUser.currentUser, let _ = user.token else {
            XCTFail("Failed to retreive previous authenticated session")
            return
        }
        
        //  Given URLSession with FRURLProtocol
        let config = URLSessionConfiguration.default
        config.protocolClasses = [FRURLProtocol.self]
        let urlSession: URLSession = URLSession(configuration: config)
        
        //  Set TokenManagementPolicy with delegate, and let delegation method to handle evaluation for 401 status code
        let tokenManagementPolicy = TokenManagementPolicy(validatingURL: [URL(string: "https://httpbin.org/status/401")!], delegate: self)
        FRURLProtocol.authorizationPolicy = nil
        FRURLProtocol.tokenManagementPolicy = tokenManagementPolicy
        
        //  When
        let ex = self.expectation(description: "Making request")
        urlSession.dataTask(with: URL(string: "https://httpbin.org/status/401")!) { (data, response, error) in
            let response = Response(data: data, response: response, error: error).parseReponse()
            
            // Request must fail with status code 401, even though evaluationRefreshToken policy satsifies, it must receive 401 if it keeps failing
            switch response {
            case .success(_, _):
                XCTFail("While expecting request failure with 401 status code; it succeeded")
                break
            case .failure(_):
                break;
            }
            ex.fulfill()
            }.resume()
        waitForExpectations(timeout: 60, handler: nil)
        
        //  While API keeps returning 401; TokenManagementPolicyDelegate.evaluateTokenRefresh must only be invoked twice due to maximum retry count
        XCTAssertEqual(evaluateTokenRefreshCount, 2)
    }
    
    func test_07_should_manual_cleanup() {
        self.shouldCleanup = true
    }
}


extension FRURLProtocolTests: TokenManagementPolicyDelegate {
    
    func evaluateTokenRefresh(responseData: Data?, response: URLResponse?, error: Error?) -> Bool {
        evaluateTokenRefreshCount += 1
        if evaluateTokenRefresh {
            evaluateTokenRefresh = false
            return true
        }
        else {
            //  if evaluateTokenRefresh is false, and response status code is 401, then force refresh
            if let thisResponse = response as? HTTPURLResponse, thisResponse.statusCode == 401 {
                return true
            }
            return false
        }
    }
    
    func updateRequest(originalRequest: URLRequest, token: AccessToken) -> URLRequest {
        let mutableRequest = ((originalRequest as NSURLRequest).mutableCopy() as? NSMutableURLRequest)!
        mutableRequest.setValue(token.buildAuthorizationHeader(), forHTTPHeaderField: "Auth")
        return mutableRequest as URLRequest
    }
}
