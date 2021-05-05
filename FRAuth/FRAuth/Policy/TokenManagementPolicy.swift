// 
//  TokenManagementPolicy.swift
//  FRAuth
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore

@objc(FRTokenManagementPolicyDelegate) public protocol TokenManagementPolicyDelegate {
    @objc optional func evaluateTokenRefresh(responseData: Data?, response: URLResponse?, error: Error?) -> Bool
    @objc optional func updateRequest(originalRequest: URLRequest, token: AccessToken) -> URLRequest
}


/**
    TokenManagementPolicy is mainly responsible to determine to inject OAuth2 authorization header in the request, and whether or not response of the request is OAuth2 token validation failure, so that SDK should renew OAuth2 token, and retry request with updated OAuth2 token
 
    TokenManagementPolicy performs two major responsibilities:
 
        1. Automatically injects `Authorization` header in the request with currently authenticated `FRUser.currentUser.token` value; if no currently authenticated user session is found, then it continues with the original request
        2. Upon receiving request response, it invokes `TokenManagementPolicyDelegate.evaluateTokenRefresh` to evaluate whether or not the response is due to OAuth2 token validation failure (i.e. token expired). The application layer can determine if the response is required to renew OAuth2 token set, and return `true` in the delegation method which then enforce SDK to renew OAuth2 token set with `refresh_token`, and/or `SSOToken`, and retry the original request with updated OAuth2 token set. If OAuth2 token renewal fails, or same response is returned after renewing OAuth2 tokens, SDK terminates the request, and returns the failure response.
 
    **Note** TokenManagementPolicy only enforces its policy for given URLs. If given URLRequest does not match any of given URLs, then it proceeds as it is.
 
### Usage ###
```
 // Step 1 - Register FRURLProtocol
 URLProtocol.registerClass(FRURLProtocol.self)
 
 // Step 2 - Initialize TokenManagementPolicy object
 let tokenManagementPolicy = TokenManagementPolicy(validatingURL: [URL, URL,...], delegate: self)
 
 // Step 3 - Implement delegate method if needed
 
 // Step 4 - Assign TokenManagementPolicy in FRURLProtocol
 FRURLProtocol.tokenManagementPolicy = tokenManagementPolicy
 
 // Step 5 - Configure URLProtocol in the application's URLSessionConfiguration
 let config = URLSessionConfiguration.default
 config.protocolClasses = [FRURLProtocol.self]
 let urlSession = URLSession(configuration: config)
```
 */
@objc(FRTokenManagementPolicy) public class TokenManagementPolicy: NSObject {
    
    //  MARK: - Property
    //  URLs that will be enforced for TokenManagement for injecting authorization header, and renewing OAuth2 token if needed
    public var validatingURL: [URL]
    //  Delegation of TokenManagementPolicy evaluation
    public var delegate: TokenManagementPolicyDelegate?
    
    //  MARK: - Init
    
    /// Prevents default init
    private override init() { fatalError("TokenManagementPolicy() is prohibited. Use TokenManagementPolicy(validatingURL:delegate:)") }
    
    
    /// Initializes TokenManagementPolicy with delegation
    /// - Parameters:
    ///   - validatingURL: URLs to be validated for TokenManagementPolicy
    ///   - delegate: delegation to enforce token policy evaluation
    @objc public init(validatingURL: [URL], delegate: TokenManagementPolicyDelegate? = nil) {
        self.validatingURL = validatingURL
        self.delegate = delegate
    }
    
    
    //  MARK: - Public
    
    /// Validates whether or not current URLRequest should be enforced for TokenManagementPolicy
    /// - Parameter request: current URLRequest to be validated
    /// - Returns: Boolean result whether or not that given URLRequest should be enforced
    func validateURL(request: URLRequest) -> Bool {
        if let requestURL = request.url {
            for url in self.validatingURL {
                if url.isSame(requestURL) {
                    return true
                }
            }
        }
        return false
    }
    
    
    /// Evaluates given response should enforce token management refresh policy; this deteremines if SDK needs to refresh given OAuth2 token set and retry with updated token set
    /// - Parameters:
    ///   - responseData: response data
    ///   - response: URLResponse of the request
    ///   - error: response error
    /// - Returns: Boolean result whether or not TokenManagementPolicy should refresh OAuth2 token
    func evalulateRefreshToken(responseData: Data?, response: URLResponse?, error: Error?) -> Bool {
        FRLog.v("[TokenManagementPolicy] Evaluating Token Refresh Policy started")
        if let delegate = self.delegate, let evaluation = delegate.evaluateTokenRefresh?(responseData: responseData, response: response, error: error) {
            FRLog.i("[TokenManagementPolicy] TokenManagementPolicy.evaluateTokenRefresh found, and refresh policy result received from delegate: \(evaluation)")
            return evaluation
        }
        FRLog.w("[TokenManagementPolicy] No delegation, nor evaluationCallback found; returning false for token refresh evaluation")
        return false
    }
    
    
    /// Updates original URLRequest with either of delegation method, or default 'Authorization' header
    /// - Parameters:
    ///   - originalRequest: original URLRequest object
    ///   - token: current `AccessToken` object that can be used for authorization header
    /// - Returns: Updated URLRequest to be invoked
    func updateRequest(originalRequest: URLRequest, token: AccessToken) -> URLRequest {
        FRLog.v("[TokenManagementPolicy] Update URLRequest started")
        if let delegate = self.delegate, let newRequest = delegate.updateRequest?(originalRequest: originalRequest, token: token) {
            FRLog.i("[TokenManagementPolicy] TokenManagementPolicy.updateRequest found, proceeding with the updated URLRequest")
            return newRequest
        }
        else {
            FRLog.i("[TokenManagementPolicy] TokenManagementPolicy.updateRequest not found, injecting `access_token` in `Authorization` header")
            let mutableRequest = ((originalRequest as NSURLRequest).mutableCopy() as? NSMutableURLRequest)!
            mutableRequest.setValue(token.buildAuthorizationHeader(), forHTTPHeaderField: "Authorization")
            return mutableRequest as URLRequest
        }
    }
}
