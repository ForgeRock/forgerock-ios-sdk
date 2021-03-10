// 
//  AuthorizationPolicyTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AuthorizationPolicyTests: FRAuthBaseTest {

    var list: [String] = []
    var onPolicyAdviceReceiveResult: Bool = false
    var policyAdvice: PolicyAdvice?
    
    override func tearDown() {
        self.list = []
        self.policyAdvice = nil
        self.onPolicyAdviceReceiveResult = false
    }
    
    
    //  MARK: - General
    
    func test_01_authorization_policy_init() {
        let urls: [URL] = [URL(string: "https://openam.example.com")!]
        var policy: AuthorizationPolicy?
            
        policy = AuthorizationPolicy(validatingURL: urls, delegate: nil)
        XCTAssertNotNil(policy)
        policy = nil
        
        policy = AuthorizationPolicy(validatingURL: urls, delegate: self)
        XCTAssertNotNil(policy)
        policy = nil
    }
    
    
    func test_02_authorization_policy_validate_url() {
        
        let urls: [URL] = [URL(string: "https://openam.example.com/anything")!, URL(string: "https://openig.example.com:443/anything")!]
        let policy = AuthorizationPolicy(validatingURL: urls, delegate: nil)
        
        var request = URLRequest(url: URL(string: "https://openam.example.com:8443/anything")!)
        XCTAssertFalse(policy.validateURL(request: request))
        
        request = URLRequest(url: URL(string: "https://openam.example.com/anything")!)
        XCTAssertTrue(policy.validateURL(request: request))
        
        request = URLRequest(url: URL(string: "http://openam.example.com/anything")!)
        XCTAssertFalse(policy.validateURL(request: request))
        
        request = URLRequest(url: URL(string: "https://openam.example.com/")!)
        XCTAssertFalse(policy.validateURL(request: request))
        
        request = URLRequest(url: URL(string: "https://openig.example.com:443/anything")!)
        XCTAssertTrue(policy.validateURL(request: request))
    }
    
    
    //  MARK: - AuthorizationPolicy.updateRequest
    func test_03_update_request_without_delegate_and_txId() {
        
        let policy = AuthorizationPolicy(validatingURL: [URL(string: "https://openam.example.com/anything")!], delegate: nil)
        let request = URLRequest(url: URL(string: "https://openam.example.com:8443/anything")!)
        let updatedRequest = policy.updateRequest(originalRequest: request, txId: nil)
        XCTAssertEqual(request, updatedRequest)
    }
    
    
    func test_04_update_request_without_delegate_and_with_txId() {
        
        //  Without URLQueryParam
        let policy = AuthorizationPolicy(validatingURL: [URL(string: "https://openam.example.com/anything")!], delegate: nil)
        let request = URLRequest(url: URL(string: "https://openam.example.com:8443/anything")!)
        
        let updatedRequest = policy.updateRequest(originalRequest: request, txId: "603c9ba4-73d4-4687-9509-a30bdbf0c8b0-54030")
        guard let url = updatedRequest.url, let urlComponent = URLComponents(string: url.absoluteString) else {
            XCTFail("Failed to generate URLComponents with given URLRequest: \(updatedRequest)")
            return
        }
        
        XCTAssertEqual(urlComponent.queryItems?.count, 1)
        XCTAssertEqual(urlComponent.queryItems?.first?.name, "_txid")
        XCTAssertEqual(urlComponent.queryItems?.first?.value, "603c9ba4-73d4-4687-9509-a30bdbf0c8b0-54030")
        XCTAssertNotEqual(request, updatedRequest)
        
        
        //  With URLQueryParam
        let policy2 = AuthorizationPolicy(validatingURL: [URL(string: "https://openam.example.com/anything?test=test")!], delegate: nil)
        let request2 = URLRequest(url: URL(string: "https://openam.example.com:8443/anything?test=test")!)
        let updatedRequest2 = policy2.updateRequest(originalRequest: request2, txId: "603c9ba4-73d4-4687-9509-a30bdbf0c8b0-54030")
        guard let url2 = updatedRequest2.url, let urlComponent2 = URLComponents(string: url2.absoluteString) else {
            XCTFail("Failed to generate URLComponents with given URLRequest: \(request2)")
            return
        }
        XCTAssertEqual(urlComponent2.queryItems?.count, 2)
        XCTAssertNotEqual(request2, updatedRequest2)
        for (_, item) in urlComponent2.queryItems!.enumerated() {
            if (item.name == "_txid" && item.value == "603c9ba4-73d4-4687-9509-a30bdbf0c8b0-54030") || item.name == "test" && item.value == "test" {
            }
            else {
                XCTFail("Unexpected URL query parameters added: \(urlComponent2)")
            }
        }
    }
    
    
    func test_05_update_request_with_delegate_and_txId() {
        
        let policy = AuthorizationPolicy(validatingURL: [URL(string: "https://openam.example.com/anything")!], delegate: self)
        let request = URLRequest(url: URL(string: "https://openam.example.com:8443/anything")!)
        
        let updatedRequest = policy.updateRequest(originalRequest: request, txId: "603c9ba4-73d4-4687-9509-a30bdbf0c8b0-54030")
        XCTAssertEqual(self.list.count, 1)
        XCTAssertEqual(self.list.first, "AuthorizationPolicyTests.updateRequest")
        XCTAssertEqual(updatedRequest.allHTTPHeaderFields?.count, 1)
        XCTAssertEqual(updatedRequest.allHTTPHeaderFields?.first?.key, "transactionId")
        XCTAssertEqual(updatedRequest.allHTTPHeaderFields?.first?.value, "603c9ba4-73d4-4687-9509-a30bdbf0c8b0-54030")
        XCTAssertNotEqual(request, updatedRequest)
    }
    
    
    func test_06_update_request_with_delegate_and_no_txId() {
        
        let policy = AuthorizationPolicy(validatingURL: [URL(string: "https://openam.example.com/anything")!], delegate: self)
        let request = URLRequest(url: URL(string: "https://openam.example.com:8443/anything")!)
        
        let updatedRequest = policy.updateRequest(originalRequest: request, txId: nil)
        XCTAssertEqual(self.list.count, 1)
        XCTAssertEqual(self.list.first, "AuthorizationPolicyTests.updateRequest")
        XCTAssertEqual(request, updatedRequest)
    }
    
    
    //  MARK: - AuthorizationPolicy.onPolicyAdviceReceived
    
    func test_07_on_policy_advice_received_without_delegate() {
        
        let policy = AuthorizationPolicy(validatingURL: [URL(string: "https://openam.example.com/anything")!], delegate: nil)
        let advice = PolicyAdvice(type: "TransactionConditionAdvice", value: "5afff42a-2715-40c8-98e7-919abc1b2dfc")
        XCTAssertNotNil(advice)
        
        let ex = self.expectation(description: "AuthorizationPolicy.onPolicyAdviceReceived")
        self.onPolicyAdviceReceiveResult = true
        policy.onPolicyAdviceReceived(policyAdvice: advice!) { (result) in
            XCTAssertFalse(result)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        XCTAssertEqual(self.list.count, 0)
    }
    
    
    func test_08_on_policy_advice_received_with_delegate() {
        
        let policy = AuthorizationPolicy(validatingURL: [URL(string: "https://openam.example.com/anything")!], delegate: self)
        let advice = PolicyAdvice(type: "TransactionConditionAdvice", value: "5afff42a-2715-40c8-98e7-919abc1b2dfc")
        XCTAssertNotNil(advice)
        
        //  Result returning true
        var ex = self.expectation(description: "AuthorizationPolicy.onPolicyAdviceReceived")
        self.onPolicyAdviceReceiveResult = true
        policy.onPolicyAdviceReceived(policyAdvice: advice!) { (result) in
            XCTAssertTrue(result)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        XCTAssertEqual(self.list.count, 1)
        XCTAssertEqual(self.list.first, "AuthorizationPolicyTests.onPolicyAdviseReceived")
        
        //  Result returning false
        ex = self.expectation(description: "AuthorizationPolicy.onPolicyAdviceReceived")
        self.onPolicyAdviceReceiveResult = false
        policy.onPolicyAdviceReceived(policyAdvice: advice!) { (result) in
            XCTAssertFalse(result)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        XCTAssertEqual(self.list.count, 2)
        XCTAssertEqual(self.list.first, "AuthorizationPolicyTests.onPolicyAdviseReceived")
        XCTAssertEqual(self.list.last, "AuthorizationPolicyTests.onPolicyAdviseReceived")
    }

    
    //  MARK: - AuthorizationPolicy.evaluateAuthorizationPolicyWithRedirect
    
    func test_09_redirect_evaluation_without_delegate() {
        let policy = AuthorizationPolicy(validatingURL: [URL(string: "https://openam.example.com/anything")!], delegate: nil)
        let advice = policy.evaluateAuthorizationPolicyWithRedirect(responseData: nil, session: URLSession(), task: URLSessionTask(), willPerformHTTPRedirection: HTTPURLResponse(), newRequest: URLRequest(url: URL(string: "https://www.forgerock.com")!))
        XCTAssertEqual(self.list.count, 0)
        XCTAssertNil(advice)
    }
    
    
    func test_10_redirect_evaluation_with_307_status() {
        let policy = AuthorizationPolicy(validatingURL: [URL(string: "https://openam.example.com/anything")!], delegate: self)
        let header: [String: String] = ["Location": "https://openam.example.com/openam/?goto=https://openam.example.com:443/anything?_txid%3D88d1d52a-5d6b-4c66-9130-3ad78e9395de&realm=/sdk&authIndexType=composite_advice&authIndexValue=%3CAdvices%3E%3CAttributeValuePair%3E%3CAttribute%20name%3D%22TransactionConditionAdvice%22/%3E%3CValue%3E88d1d52a-5d6b-4c66-9130-3ad78e9395de%3C/Value%3E%3C/AttributeValuePair%3E%3C/Advices%3E"]
        let response = HTTPURLResponse(url: URL(string: "https://openam.example.com/anything")!, statusCode: 307, httpVersion: nil, headerFields: header)!
        let advice = policy.evaluateAuthorizationPolicyWithRedirect(responseData: nil, session: URLSession(), task: URLSessionTask(), willPerformHTTPRedirection: response, newRequest: URLRequest(url: URL(string: "https://www.forgerock.com")!))
        XCTAssertNotNil(advice)
        XCTAssertEqual(self.list.count, 0)
    }
    
    
    func test_11_redirect_evaluation_with_30x_status() {
        let policy = AuthorizationPolicy(validatingURL: [URL(string: "https://openam.example.com/anything")!], delegate: self)
        let header: [String: String] = ["Location": "https://openam.example.com/openam/?goto=https://openam.example.com:443/anything?_txid%3D88d1d52a-5d6b-4c66-9130-3ad78e9395de&realm=/sdk&authIndexType=composite_advice&authIndexValue=%3CAdvices%3E%3CAttributeValuePair%3E%3CAttribute%20name%3D%22TransactionConditionAdvice%22/%3E%3CValue%3E88d1d52a-5d6b-4c66-9130-3ad78e9395de%3C/Value%3E%3C/AttributeValuePair%3E%3C/Advices%3E"]
        let response = HTTPURLResponse(url: URL(string: "https://openam.example.com/anything")!, statusCode: 302, httpVersion: nil, headerFields: header)!
        let advice = policy.evaluateAuthorizationPolicyWithRedirect(responseData: nil, session: URLSession(), task: URLSessionTask(), willPerformHTTPRedirection: response, newRequest: URLRequest(url: URL(string: "https://www.forgerock.com")!))
        XCTAssertNotNil(advice)
        XCTAssertEqual(self.list.count, 0)
    }
    
    
    func test_12_redirect_evaluation_with_delegate_method() {
        let policy = AuthorizationPolicy(validatingURL: [URL(string: "https://openam.example.com/anything")!], delegate: self)
        self.policyAdvice = PolicyAdvice(type: "TransactionConditionAdvice", value: "5afff42a-2715-40c8-98e7-919abc1b2dfc")
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: URL(string: "https://httpbin.org/anything")!)
        let advice = policy.evaluateAuthorizationPolicyWithRedirect(responseData: nil, session: URLSession(), task: task, willPerformHTTPRedirection: HTTPURLResponse(), newRequest: URLRequest(url: URL(string: "https://www.forgerock.com")!))
        XCTAssertEqual(advice, self.policyAdvice)
        XCTAssertEqual(self.list.count, 1)
        XCTAssertEqual(self.list.first, "AuthorizationPolicyTests.evaluateAuthorizationPolicy")
    }

    
    //  MARK: - AuthorizationPolicy.evaluateAuthorizationPolicy
    
    func test_13_evaluate_without_delegate_no_response_data() {
        let policy = AuthorizationPolicy(validatingURL: [URL(string: "https://openam.example.com/anything")!], delegate: nil)
        let advice = policy.evaluateAuthorizationPolicy(responseData: "some data".data(using: .utf8), response: nil, error: AuthError.invalidGenericType)
        XCTAssertNil(advice)
        XCTAssertEqual(self.list.count, 0)
    }
    
    
    func test_14_evaluate_with_response_data() {
        
        let adviceString = """
        {
            "advices": {
                "AuthenticateToServiceConditionAdvice": ["/:UsernamePassword"]
            },
            "ttl": 9223372036854775807,
            "resource": "https://localhost:9888/policy/transfer",
            "actions": [],
            "attributes": []
        }
        """
        
        let policy = AuthorizationPolicy(validatingURL: [URL(string: "https://openam.example.com/anything")!], delegate: self)
        let advice = policy.evaluateAuthorizationPolicy(responseData: adviceString.data(using: .utf8), response: nil, error: nil)
        XCTAssertNotNil(advice)
        XCTAssertEqual(self.list.count, 0)
        
        let adviceStringArray = """
        [{
            "advices": {
                "AuthenticateToServiceConditionAdvice": ["/:UsernamePassword"]
            },
            "ttl": 9223372036854775807,
            "resource": "https://localhost:9888/policy/transfer",
            "actions": [],
            "attributes": []
        }]
        """
        
        let policy2 = AuthorizationPolicy(validatingURL: [URL(string: "https://openam.example.com/anything")!], delegate: self)
        let advice2 = policy2.evaluateAuthorizationPolicy(responseData: adviceStringArray.data(using: .utf8), response: nil, error: nil)
        XCTAssertNotNil(advice2)
        XCTAssertEqual(self.list.count, 0)
    }
    
    
    func test_15_evaluate_with_delegate() {
        self.policyAdvice = PolicyAdvice(type: "TransactionConditionAdvice", value: "5afff42a-2715-40c8-98e7-919abc1b2dfc")
        let policy = AuthorizationPolicy(validatingURL: [URL(string: "https://openam.example.com/anything")!], delegate: self)
        let advice = policy.evaluateAuthorizationPolicy(responseData: "test".data(using: .utf8), response: nil, error: nil)
        XCTAssertEqual(advice, self.policyAdvice)
        XCTAssertEqual(self.list.count, 1)
        XCTAssertEqual(self.list.first, "AuthorizationPolicyTests.evaluateAuthorizationPolicy")
    }
}


extension AuthorizationPolicyTests: AuthorizationPolicyDelegate {
    
    func evaluateAuthorizationPolicy(responseData: Data?, response: URLResponse?, error: Error?) -> PolicyAdvice? {
        self.list.append("AuthorizationPolicyTests.evaluateAuthorizationPolicy")
        return self.policyAdvice
    }
    
    func onPolicyAdviseReceived(policyAdvice: PolicyAdvice, completion: @escaping FRCompletionResultCallback) {
        self.list.append("AuthorizationPolicyTests.onPolicyAdviseReceived")
        completion(self.onPolicyAdviceReceiveResult)
    }
    
    func updateRequest(originalRequest: URLRequest, txId: String?) -> URLRequest {
        self.list.append("AuthorizationPolicyTests.updateRequest")
        let mutableRequest = ((originalRequest as NSURLRequest).mutableCopy() as? NSMutableURLRequest)!
        mutableRequest.setValue(txId, forHTTPHeaderField: "transactionId")
        return mutableRequest as URLRequest
    }
}
