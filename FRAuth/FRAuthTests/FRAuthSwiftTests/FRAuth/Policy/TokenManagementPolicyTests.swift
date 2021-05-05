// 
//  TokenManagementPolicyTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class TokenManagementPolicyTests: FRAuthBaseTest {

    var list: [String] = []
    var evaluationResult: Bool = false
    
    override func tearDown() {
        self.list = []
    }
    
    
    //  MARK: - General
    
    func test_01_token_management_policy_init() {
        let urls: [URL] = [URL(string: "http://openam.example.com")!]
        var policy: TokenManagementPolicy?
            
        policy = TokenManagementPolicy(validatingURL: urls, delegate: nil)
        XCTAssertNotNil(policy)
        policy = nil
        
        policy = TokenManagementPolicy(validatingURL: urls, delegate: self)
        XCTAssertNotNil(policy)
        policy = nil
    }
    
    
    func test_02_token_management_policy_validate_url() {
        
        let urls: [URL] = [URL(string: "http://openam.example.com/anything")!, URL(string: "https://openig.example.com:443/anything")!]
        let policy = TokenManagementPolicy(validatingURL: urls, delegate: nil)
        
        var request = URLRequest(url: URL(string: "http://openam.example.com:8443/anything")!)
        XCTAssertFalse(policy.validateURL(request: request))
        
        request = URLRequest(url: URL(string: "http://openam.example.com/anything")!)
        XCTAssertTrue(policy.validateURL(request: request))
        
        request = URLRequest(url: URL(string: "https://openam.example.com/anything")!)
        XCTAssertFalse(policy.validateURL(request: request))
        
        request = URLRequest(url: URL(string: "http://openam.example.com/")!)
        XCTAssertFalse(policy.validateURL(request: request))
        
        request = URLRequest(url: URL(string: "https://openig.example.com:443/anything")!)
        XCTAssertTrue(policy.validateURL(request: request))
    }
    
    
    //  MARK: - TokenManagementPolicy.evalulateRefreshToken
    
    func test_03_delegation() {
        let urls: [URL] = [URL(string: "http://openam.example.com/anything")!]
        let policy = TokenManagementPolicy(validatingURL: urls, delegate: self)
        
        self.evaluationResult = true
        var result = policy.evalulateRefreshToken(responseData: nil, response: nil, error: nil)
        XCTAssertTrue(result)
        XCTAssertEqual(self.list.count, 1)
        XCTAssertEqual(self.list.first, "TokenManagementPolicyTests.evaluateTokenRefresh")
        
        self.evaluationResult = false
        result = policy.evalulateRefreshToken(responseData: nil, response: nil, error: nil)
        XCTAssertFalse(result)
        XCTAssertEqual(self.list.count, 2)
        XCTAssertEqual(self.list.first, "TokenManagementPolicyTests.evaluateTokenRefresh")
        XCTAssertEqual(self.list.last, "TokenManagementPolicyTests.evaluateTokenRefresh")
    }
    
    //test_04 removed due to removed deprecated calls
    func test_05_no_callback_and_delegate() {
        let urls: [URL] = [URL(string: "http://openam.example.com/anything")!]
        let policy = TokenManagementPolicy(validatingURL: urls, delegate: nil)
        let result = policy.evalulateRefreshToken(responseData: nil, response: nil, error: nil)
        XCTAssertFalse(result)
        XCTAssertEqual(self.list.count, 0)
    }
    
    
    //  MARK: - TokenManagementPolicy.updateRequest
    
    func test_06_update_request_without_delegate() {
        let tokenStr = """
        {"access_token":"access_token","scope":"scopes","id_token":"id_token","token_type":"Bearer","expires_in":3599}
        """
        let tokenJSON = self.parseStringToDictionary(tokenStr)
        guard let token = AccessToken(tokenResponse: tokenJSON) else {
            XCTFail("Failed to generate `AccessToken` for test")
            return
        }
        
        let urls: [URL] = [URL(string: "http://openam.example.com/anything")!]
        let policy = TokenManagementPolicy(validatingURL: urls, delegate: nil)
        var request = URLRequest(url: URL(string: "http://openam.example.com/anything")!)
        request = policy.updateRequest(originalRequest: request, token: token)
        
        XCTAssertEqual(request.allHTTPHeaderFields?.count, 1)
        XCTAssertEqual(request.allHTTPHeaderFields?.first?.key, "Authorization")
        XCTAssertEqual(request.allHTTPHeaderFields?.first?.value, "Bearer access_token")
    }
    
    
    func test_07_update_request_with_delegate() {
        let tokenStr = """
        {"access_token":"access_token","scope":"scopes","id_token":"id_token","token_type":"Bearer","expires_in":3599}
        """
        let tokenJSON = self.parseStringToDictionary(tokenStr)
        guard let token = AccessToken(tokenResponse: tokenJSON) else {
            XCTFail("Failed to generate `AccessToken` for test")
            return
        }
        
        let urls: [URL] = [URL(string: "http://openam.example.com/anything")!]
        let policy = TokenManagementPolicy(validatingURL: urls, delegate: self)
        var request = URLRequest(url: URL(string: "http://openam.example.com/anything")!)
        request = policy.updateRequest(originalRequest: request, token: token)
        XCTAssertEqual(self.list.count, 1)
        XCTAssertEqual(self.list.first, "TokenManagementPolicyTests.updateRequest")
        XCTAssertEqual(request.allHTTPHeaderFields?.count, 1)
        XCTAssertEqual(request.allHTTPHeaderFields?.first?.key, "auth_header_test")
        XCTAssertEqual(request.allHTTPHeaderFields?.first?.value, "Bearer access_token")
    }
}


extension TokenManagementPolicyTests: TokenManagementPolicyDelegate {
    func evaluateTokenRefresh(responseData: Data?, response: URLResponse?, error: Error?) -> Bool {
        self.list.append("TokenManagementPolicyTests.evaluateTokenRefresh")
        return self.evaluationResult
    }
    
    func updateRequest(originalRequest: URLRequest, token: AccessToken) -> URLRequest {
        self.list.append("TokenManagementPolicyTests.updateRequest")
        let mutableRequest = ((originalRequest as NSURLRequest).mutableCopy() as? NSMutableURLRequest)!
        mutableRequest.setValue(token.buildAuthorizationHeader(), forHTTPHeaderField: "auth_header_test")
        return mutableRequest as URLRequest
    }
}
