// 
//  AuthorizationPolicy.swift
//  FRAuth
//
//  Copyright (c) 2020 - 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

@objc public protocol AuthorizationPolicyDelegate {
    @objc optional func evaluateAuthorizationPolicy(responseData: Data?, response: URLResponse?, error: Error?) -> PolicyAdvice?
    @objc func onPolicyAdviseReceived(policyAdvice: PolicyAdvice, completion: @escaping FRCompletionResultCallback) -> Void
    @objc optional func updateRequest(originalRequest: URLRequest, txId: String?) -> URLRequest
}


/**
 AuthorizationPolicy is mainly responsible to handle Authorization Policy process in AM. AuthorizationPolicy evaluates responses of each request, try to recognize Authorization Policy process as much as possible, and also delegates to the application layer to determine whether or not the response is Authorization Process or not.
 
 AuthorizationPolicy proceeds following major steps:
 
        1. Upon receiving request response, or redirected request, it invokes `AuthorizationPolicy.evaluateAuthorizationPolicy` to evaluate whether or not the response is required for Authorization process. If the response is automatically recognizable by SDK (IG redirect, or response payload containing `Advice` json structure, SDK automatically parses the response into `PolicyAdvice`.
        2. If `PolicyAdvice` is found, it invokes `AuthorizationPolicyDelegate.onPolicyAdviseReceived` for the application layer to perform authorization process with given `PolicyAdvice`. The application layer should use `FRSession.authenticate` with `PolicyAdvice` to walk through authentication tree, and notify SDK with `completion` callback with the result of the authorization process.
        3. If the authorization process was successful, it invokes `AuthorizationPolicyDelegate.updateRequest` to decorate the new request with transactionId (if found). If `AuthorizationPolicyDelegate.updateRequest` is not implemented, SDK automatically injects `_txId` in URL query parameter to the original request, and retry the request with updated one. If `transactionId` is not found, then retry with the original request.

    **Note** AuthorizationPolicyDelegate only enforces its policy for given URLs. If given URLRequest does not match any of given URLs, then it proceeds as it is.
 
 ### Usage ###
 ```
  // Step 1 - Register FRURLProtocol
  URLProtocol.registerClass(FRURLProtocol.self)
  
  // Step 2 - Initialize AuthorizationPolicy object
  let authorizationPolicy = AuthorizationPolicy(validatingURL: [URL, URL,...], delegate: self)
  
  // Step 3 - Implement delegate method if needed; `AuthorizationPolicyDelegate.onPolicyAdviseReceived` is mandatory whereas others are optional
  
  // Step 4 - Assign AuthorizationPolicy in FRURLProtocol
  FRURLProtocol.authorizationPolicy = authorizationPolicy
  
  // Step 5 - Configure URLProtocol in the application's URLSessionConfiguration
  let config = URLSessionConfiguration.default
  config.protocolClasses = [FRURLProtocol.self]
  let urlSession = URLSession(configuration: config)
 ```
 */
@objc public class AuthorizationPolicy: NSObject {
    
    //  MARK: - Property
    
    //  URLs that will be enforced for AuthorizationPolicy for injecting authorization header, and renewing OAuth2 token if needed
    public let validatingURL: [URL]
    //  Delegation of AuthorizationPolicy evaluation
    public let delegate: AuthorizationPolicyDelegate?
    
    
    //  MARK: - Init
    
    /// Prevents default init
    private override init() { fatalError("TokenManagementPolicy() is prohibited. Use TokenManagementPolicy(validatingURL:delegate:)") }
    
    
    /// Initializes AuthorizationPolicy with delegation
    /// - Parameters:
    ///   - validatingURL: URLs to be validated for AuthorizationPolicy
    ///   - delegate: delegation to enforce authorization policy evaluation
    @objc public init(validatingURL: [URL], delegate: AuthorizationPolicyDelegate? = nil) {
        self.validatingURL = validatingURL
        self.delegate = delegate
    }
    
    
    //  MARK: - Public
    
    /// Validates whether or not current URLRequest should be enforced for AuthorizationPolicy
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
    
    
    /// Evaluates Authorization Policy with given redirect response data and returns PolicyAdvice
    /// - Parameters:
    ///   - responseData: response data
    ///   - session: current URLSession
    ///   - task: current URLSessionTask
    ///   - response: current HTTPURLResponse
    ///   - request: new request that will be re-directed
    /// - Returns: PolicyAdvice if given redirect response matches with any of conditions
    func evaluateAuthorizationPolicyWithRedirect(responseData: Data?, session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) -> PolicyAdvice? {
        FRLog.v("[AuthorizationPolicy] Evaluating Authorization Policy started")
        if response.statusCode == 307, let redirectUrl = response.allHeaderFields["Location"] as? String, let policyAdvise = PolicyAdviceCreator().parse(advice: redirectUrl) {
            FRLog.i("[AuthorizationPolicy] IG request redirect (307) for Authorization Policy found; constructed PolicyAdvice based on IG redirection")
            return policyAdvise
        }
        
        if let redirectUrl = response.allHeaderFields["Location"] as? String, let policyAdvise = PolicyAdvice(redirectUrl: redirectUrl) {
            FRLog.i("[AuthorizationPolicy] Request redirect URL is recognized as PolicyAdvice; returning PolicyAdvice from redirect URL")
            return policyAdvise
        }
        
        if let delegate = self.delegate, let policyAdvice = delegate.evaluateAuthorizationPolicy?(responseData: responseData, response: response, error: task.error) {
            FRLog.i("[AuthorizationPolicy] Authorization Policy evaluation has been completed and received PolicyAdvice: \(policyAdvice)")
            return policyAdvice
        }
        else {
            FRLog.w("[AuthorizationPolicy] Authorization Policy evaluation not satisfied; proceeding with the original request")
        }
        
        return nil
    }
    
    
    /// Evaluates Authorization Policy with given response data and returns PolicyAdvice
    /// - Parameters:
    ///   - responseData: response data
    ///   - response: current URLResponse
    ///   - error: an error from the request
    /// - Returns: PolicyAdvice if given redirect response matches with any of conditions
    func evaluateAuthorizationPolicy(responseData: Data?, response: URLResponse?, error: Error?) -> PolicyAdvice? {
        FRLog.v("[AuthorizationPolicy] Evaluating Authorization Policy started")
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401, let json = httpResponse.allHeaderFields["Www-Authenticate"] as? String,
           let policyAdvice = PolicyAdviceCreator().parseAsBase64(advice: json) {
            FRLog.i("[AuthorizationPolicy] PolicyAdvice JSON object found from response JSON payload; returning PolicyAdvice")
            return policyAdvice
        }
        
        if let data = responseData, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]], let evalResult = json.first, let policyAdvice = PolicyAdvice(json: evalResult) {
            FRLog.i("[AuthorizationPolicy] PolicyAdvice JSON object found from response JSON payload; returning PolicyAdvice")
            return policyAdvice
        }
        
        if let data = responseData, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let policyAdvice = PolicyAdvice(json: json) {
            FRLog.i("[AuthorizationPolicy] PolicyAdvice JSON object found from response JSON payload; returning PolicyAdvice")
            return policyAdvice
        }
        
        if let delegate = self.delegate, let policyAdvice = delegate.evaluateAuthorizationPolicy?(responseData: responseData, response: response, error: error) {
            FRLog.i("[AuthorizationPolicy] Authorization Policy evaluation has been completed and received PolicyAdvice: \(policyAdvice)")
            return policyAdvice
        }
        else {
            FRLog.w("[AuthorizationPolicy] Authorization Policy evaluation not satisfied; proceeding with the original request")
        }
        
        return nil
    }
    
    
    /// Invokes AuthorizationPolicyDelegate.onPolicyAdviceReceived to notify the application layer for PolicyAdvice, and expects result of the authorization
    /// - Parameters:
    ///   - policyAdvice: PolicyAdvice object to be invoked with FRSession.authenticate
    ///   - completion: completion callback to notify whether or not authorization process was successful
    /// - Returns: Void
    func onPolicyAdviceReceived(policyAdvice: PolicyAdvice, completion: @escaping FRCompletionResultCallback) -> Void {
        FRLog.v("[AuthorizationPolicy] PolicyAdvice received started")
        if let delegate = self.delegate {
            FRLog.i("[AuthorizationPolicy] PolicyAdvice received; invoking AuthorizationPolicyDelegate.onPolicyAdviseReceived")
            delegate.onPolicyAdviseReceived(policyAdvice: policyAdvice) { (result) in
                FRLog.i("[AuthorizationPolicy] AuthorizationPolicyDelegate.onPolicyAdviseReceived received result: \(result)")
                completion(result)
            }
        }
        else {
            FRLog.w("[AuthorizationPolicy] PolicyAdvice received, but AuthorizationPolicyDelegate not defined")
            completion(false)
        }
    }
    
    
    /// Notifies the application layer if any changes need to be made for the original request with newly given transaction id
    /// - Parameters:
    ///   - originalRequest: original URLRequest object
    ///   - txId: transaction identifier for Transactional Authorization
    /// - Returns: URLRequest object to be invoked
    func updateRequest(originalRequest: URLRequest, txId: String?) -> URLRequest {
        FRLog.v("[AuthorizationPolicy] Update URLRequest started")
        if let delegate = self.delegate, let newRequest = delegate.updateRequest?(originalRequest: originalRequest, txId: txId) {
            FRLog.i("[AuthorizationPolicy] AuthorizationPolicyDelegate.updateRequest found, proceeding with the updated URLRequest")
            return newRequest
        }
        else if let txId = txId {
            FRLog.i("[AuthorizationPolicy] AuthorizationPolicyDelegate.updateRequest not found, and txId is found, appending '_txId' in URL query parameter, and proceeding with updated URLRequest")
            return self.modifyRequestForQueryParam(request: originalRequest, key: "_txid", value: txId)
        }
        FRLog.w("[AuthorizationPolicy] AuthorizationPolicyDelegate.updateRequest and txId not found; proceeding with the original URLRequest")
        return originalRequest
    }
    
    
    /// Updates existing URLRequest object with new URL query parameter
    /// - Parameter request: Original URLRequest object
    /// - Parameter key: String value of key for URL parameter
    /// - Parameter value: String value for URL parameter
    func modifyRequestForQueryParam(request: URLRequest, key: String, value: String?) -> URLRequest {
        
        let mutableRequest = ((request as NSURLRequest).mutableCopy() as? NSMutableURLRequest)!
        
        if let url = request.url, var urlComponent = URLComponents(string: url.absoluteString) {
            let queryElement = URLQueryItem(name: key, value: value)
            
            if let _ = urlComponent.queryItems {
                urlComponent.queryItems?.append(queryElement)
            }
            else {
                urlComponent.queryItems = [queryElement]
            }
            
            if let newURL = urlComponent.url {
                mutableRequest.url = newURL
            }
        }
        
        return mutableRequest as URLRequest
    }
}
