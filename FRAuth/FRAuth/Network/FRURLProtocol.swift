//
//  FRURLProtocol.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRCore


/**
 FRURLProtocol is a predefined URLProtocol class that is responsible to handle, analyze, and perfrom OAuth2 Token Management and ForgeRock AccessManagement's Authorization Policy.
 FRURLProtocol is designed to work with any type of iOS HTTP client where you can customize URLSessionConfiguration for URLsession.
 
 ### Usage Example for OAuth2 Token Management: ###
 ````
 // Step 1 - Register FRURLProtocol
 URLProtocol.registerClass(FRURLProtocol.self)
 
 // Step 2 - Define an array of URLs that you would like to validate
 // Only URLs within this array will be validated, and inject access_token in the Authorization header
 FRURLProtocol.validatedURLs = [<URL>, <URL>...]
 
 // Step 3 - Define customizable token refresh policy with given result of request
 FRURLProtocol.refreshTokenPolicy = {(responseData, response, error) in
    // With given responseData, response, and error, as a developer, you can instruct FRURLProtocol to perform token refresh or not
 
    // Return true if OAuth2 Token needs to be refreshed, and the result of the request was due to OAuth2 token expiration or invalid
    // Otherwise, return false to simply ignore the result of the request, and original requestor will recieve the result as it is
    return true
 }
 ````
 
 ### Usage Example for Authorization Policy ###
 ````
 // All optional steps shown below are not necessary if REST App is protected by IG and set-up IG routes for APIs; SDK understands the specific response from IG, and takes care of most of operations automatically
 //
 // Step 1 - Register FRURLProtocol
 URLProtocol.registerClass(FRURLProtocol.self)
 
 // Step 2 - Define an array of URLs that you would like to validate
 // Only URLs within this array will be validated, and process the authorization policy
 FRURLProtocol.validatedURLs = [<URL>, <URL>...]
 
 // (Optional) Step 3 - Define customizable authorization policy with given result of request
 // Following example basically tells SDK to perform authorization policy when the response HTTP status code is 307.
 FRURLProtocol.authorizationEvaluationPolicy = {(responseData, response, error) in
     var shouldHandle = false
     if let thisResponse = response as? HTTPURLResponse, thisResponse.statusCode == 307 {
      
         shouldHandle = true
     }
     return true
 }
 
 // (Optional) Step 4 - If SDK fails to parse the response into PolicyAdvice, construct PolicyAdvice with given response
 FRURLProtocol.parsePolicyAdviceCallback = {(responseData, response, error) in
     // Parse the response, and construct PolicyAdvice with given response payload
     let policyAdvice = PolicyAdvice(type: "TransactionConditionAdvice", value:":/TransactionalTree")
     return policyAdvice
 }
 
 // Step 5 - Initiate Authentication Tree flow with given PolicyAdvice
 FRURLProtocol.onPolicyAdviceReceived = {(policyAdvice, completion) in
     DispatchQueue.main.async {
         FRSession.authenticateWithUI(policyAdvice, self) { (token: Token?, error) in
             if let token = token, error == nil {
                 completion(true)
             }
             else {
                 completion(false)
             }
         }
     }
 }
 
 // (Optional) Step 6 - Decorate original URLRequest object with updated information; if callback is not defined, SDK appends _txid automatically in the URL query parameter
 FRURLProtocol.onUpdatingRequestCallback = {(request, txId) in
     // append txId into the request
     return request
 }
 ````
 */
@objc
public class FRURLProtocol: URLProtocol {
    
    //  MARK: - Property
    
    /// Constant String key of FRURLProtocol indication
    struct Constants {
        static let FRURLProtocolHandled = "FRURLProtocolHandled"
    }
    /// An array of URL to be validated and analyzed
    @objc
    public static var validatedURLs: [URL] = []
    /// FRURLProtocolResponseEvaluationCallback callback to be analyzed and determined for token refresh
    @objc
    public static var refreshTokenPolicy: FRURLProtocolResponseEvaluationCallback?
    /// FRURLProtocolResponseEvaluationCallback callback to be analyzed and determined for whether Authorization Policy is required or not
    @objc
    public static var authorizationEvaluationPolicy: FRURLProtocolResponseEvaluationCallback?
    /// FRURLProtocolParsePolicyAdviceCallback callback to be analyzed and parse response into PolicyAdvice; SDK initially attempts to parse PolicyAdvice with given response, when it fails to detect the PolicyAdvice, SDK notifies the application with this callback
    @objc
    public static var parsePolicyAdviceCallback: FRURLProtocolParsePolicyAdviceCallback?
    /// FRURLProtocolAuthorizationPolicyReceivedCallback callback to initiate authentication tree process with PolicyAdvice object. Application must notify SDK with completionCallback upon completion of authentication tree flow. When 'false' is returned, SDK returns the original response, otherwise, SDK attempts to retry the request with updated credentials
    @objc
    public static var onPolicyAdviceReceived: FRURLProtocolAuthorizationPolicyReceivedCallback?
    /// FRURLProtocolUpdateRequestCallback callback to update URLRequest object for retry after successful authorization process. Application may alter and/or update the original request with new credentials (Session Token, and/or txId for AM policy evaluation). If the callback is not defined, SDK automatically updates all credentials by default, and injects txId (if applicable) into the URL query parameter with key value of '_txid'.
    @objc
    public static var onUpdatingRequestCallback: FRURLProtocolUpdateRequestCallback?
    
    /// URLSession
    var session: URLSession?
    /// Current SessionTask
    var sessionTask: URLSessionDataTask?
    /// ResponseData of the current URLSessionDataTask
    var responseData: Data?
    /// Number of retries that were attempted
    var retryCount: Int = 0
    /// Boolean indicator whether the current request has been validated for authorization policy or not
    var hasAuthValidated: Bool = false
    
    
    //  MARK: - Init
    
    /// Initializes FRURLProtocol
    ///
    /// - Parameters:
    ///   - request: URLRequest object of the current request
    ///   - cachedResponse: Cached URL Response
    ///   - client: URLProtocolClient
    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        super.init(request: request, cachedResponse: cachedResponse, client: client)
        
        if session == nil {
            session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        }
    }
    
    
    //  MARK: - Method
    
    /// Validates whether the current request should perform through FRURLProtocol or not; if the current request is not being made to any one of *validatedURLs*, then FRURLProtocol is ignored, and proceeds the request as it is.
    ///
    /// - Parameter request: Current URLRequest object
    /// - Returns: Boolean indicator whether the request will be handled through FRURLProtocol or not
    public override class func canInit(with request: URLRequest) -> Bool {
        if FRURLProtocol.shouldHandleRequest(request: request) {
            if FRURLProtocol.property(forKey: Constants.FRURLProtocolHandled, in: request) != nil {
                return false
            }
            return true
        }
        else {
            return false
        }
    }
    
    
    /// Validates whether the current request should perform through FRURLProtocol or not; if the current request is not being made to any one of *validatedURLs*, then FRURLProtocol is ignored, and proceeds the request as it is.
    ///
    /// - Parameter request: Current URLRequest object
    /// - Returns: Boolean indicator whether the request will be handled through FRURLProtocol or not
    static func shouldHandleRequest(request: URLRequest) -> Bool {
        if let requestURL = request.url {
            for url in FRURLProtocol.validatedURLs {
                if FRURLProtocol.compareTwoURLs(lhs: requestURL, rhs: url) {
                    return true
                }
            }
        }
        
        return false
    }
    
    
    /// Compares two URL objects with host, scheme, relativePath, and port comparison
    ///
    /// - Parameters:
    ///   - lhs: URL object to be compared
    ///   - rhs: URL object to be compared
    /// - Returns: Boolean result of whether two given URLs are same or not
    static func compareTwoURLs(lhs: URL, rhs: URL) -> Bool {
        return (lhs.host == rhs.host && lhs.scheme == rhs.scheme && lhs.relativePath == rhs.relativePath && lhs.port == rhs.port)
    }
    
    
    /// Returns a canonical version of the given request
    ///
    /// - Parameter request: A request to make canonical
    /// - Returns: The canonical form of the given request
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    
    /// Starts loading, and validating the request
    public override func startLoading() {
        FRLog.i("[FRURLProtocol] [\(String(describing:request))] Start intercepting the request")
        let mutableRequest = ((request as NSURLRequest).mutableCopy() as? NSMutableURLRequest)!
        
        // Setting all persistent cookies for the domain
        if let cookieHeader = FRRestClient.prepareCookieHeader(url: mutableRequest.url!) {
            cookieHeader.forEach{ mutableRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
        }
        
        if let user = FRUser.currentUser {
            FRLog.i("[FRURLProtocol] [\(String(describing:request))] Authenticated user found; proceeding on getting access_token")
            user.getAccessToken { (user, error) in
                if let user = user {
                    FRLog.i("[FRURLProtocol] [\(String(describing: self.request))] User's access_token retrieved; injecting Authorization header")
                    FRLog.v("[FRURLProtocol] [\(String(describing: self.request))] Injected Authorization Header: \(user.buildAuthHeader())")
                    mutableRequest.setValue(user.buildAuthHeader(), forHTTPHeaderField: "Authorization")
                }
                else {
                    FRLog.w("[FRURLProtocol] [\(String(describing: self.request))] Failed to retrieve valid access_token; ignoring Authorization Header injection")
                }
                FRURLProtocol.setProperty(true, forKey: Constants.FRURLProtocolHandled, in: mutableRequest)
                self.sessionTask = self.session?.dataTask(with: mutableRequest as URLRequest)
                self.sessionTask?.resume()
            }
        }
        else {
            FRLog.w("[FRURLProtocol] [\(String(describing:request))] No authenticated user found; proceeding with original request")
            FRURLProtocol.setProperty(true, forKey: Constants.FRURLProtocolHandled, in: mutableRequest)
            session?.dataTask(with: mutableRequest as URLRequest, completionHandler: { (data, response, error) in
                if let returnData = data {
                    self.client?.urlProtocol(self, didLoad: returnData)
                }
                self.client?.urlProtocolDidFinishLoading(self)
            }).resume()
        }
    }
    
    /// Stops loading, and indicates that the request has finished
    public override func stopLoading() {
        FRLog.i("[FRURLProtocol] [\(String(describing:request))] Request completed")
        sessionTask?.cancel()
    }
}


extension FRURLProtocol: URLSessionDataDelegate {

    /// URLSessionDataDelegate method for receiving data
    ///
    /// - Parameters:
    ///   - session: URLSession
    ///   - dataTask: Current URLSessionDataTask
    ///   - data: Data received
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if var responseData = self.responseData {
            responseData.append(data)
            self.responseData = responseData
        }
        else {
            self.responseData = data
        }
    }

    
    /// URLSessionDataDelegate method for receiving response
    ///
    /// - Parameters:
    ///   - session: URLSession
    ///   - dataTask: Current URLSessionDataTask
    ///   - response: Response received
    ///   - completionHandler: Completion callback
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        let policy = URLCache.StoragePolicy(rawValue: request.cachePolicy.rawValue) ?? .notAllowed
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: policy)
        completionHandler(.allow)
    }
    

    /// URLSessionDataDelegate method to notify completion of the request
    ///
    /// In this delegation method, FRURLProtocol will validate the result of the request with given ValidatedURLs, RefreshTokenPolicy, and maximum retry attempt, and perform token refresh if necessary
    ///
    /// - Parameters:
    ///   - session: URLSession
    ///   - task: Current URLSessionDataTask
    ///   - error: An error occurred during the request
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if let originalData = self.responseData {
            let string = String(decoding: originalData, as: UTF8.self)
            
            if let response = task.response as? HTTPURLResponse
            {
                FRLog.i("[FRURLProtocol] [\(String(describing: request))] Response #\((self.retryCount + 1)): received | Status Code: \(response.statusCode)")
                FRLog.v("[FRURLProtocol] [\(String(describing: request))] Response #\((self.retryCount + 1))\n\tResponse: \(string)\n\tResponse Header: \(response.allHeaderFields)")
            }
            else {
                FRLog.i("[FRURLProtocol] [\(String(describing: request))] Response #\((self.retryCount + 1)): received")
                FRLog.v("[FRURLProtocol] [\(String(describing: request))] Response #\((self.retryCount + 1))\n\tResponse: \(string)")
            }
        }
        
        //  If Authorization Policy is defined in the application layer, and evaluated by auth policy
        if let authorizationPolicy = FRURLProtocol.authorizationEvaluationPolicy, authorizationPolicy(self.responseData, task.response, error) {
            // Mark the current request as auth validated
            hasAuthValidated = true
            FRLog.i("[FRURLProtocol][AuthPolicy] FRURLProtocol.authorizationEvaluationPolicy has been satisfied, preparing Authorization process")
            var policyAdvice: PolicyAdvice?
            
            // Try to extract PolicyAdvise response from the response payload
            if let data = self.responseData,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]],
                let evalResult = json.first,
                let thisPolicyAdvice = PolicyAdvice(json: evalResult)
            {
                FRLog.i("[FRURLProtocol][AuthPolicy] SDK detected PolicyAdvice in the response")
                policyAdvice = thisPolicyAdvice
            }
            // Return the response payload for application layer to parse and prepare PolicyAdvice object
            else if let parsingAdviceCallback = FRURLProtocol.parsePolicyAdviceCallback, let parsedAdvice = parsingAdviceCallback(self.responseData, task.response, nil) {
                FRLog.i("[FRURLProtocol][AuthPolicy] PolicyAdvice is parsed with FRURLProtocol.parsePolicyAdviceCallback")
                policyAdvice = parsedAdvice
            }
            
            if let policyAdvice = policyAdvice {
                if let policyAdviceReceivedCallback = FRURLProtocol.onPolicyAdviceReceived {
                    FRLog.i("[FRURLProtocol][AuthPolicy] FRURLProtocol.onPolicyAdviceReceived detected, returning PolicyAdvice and waiting for the response")
                    policyAdviceReceivedCallback(policyAdvice, {(result: Bool) in
                        if result {
                            FRLog.i("[FRURLProtocol][AuthPolicy] FRURLProtocol.onPolicyAdviceReceived completion callback has been notified; preparing new URLRequest object for retry")
                            // Reset response data
                            self.responseData = nil
                            self.client?.urlProtocol(self, didLoad: Data())
                            
                            if let updatingNewRequestCallback = FRURLProtocol.onUpdatingRequestCallback, let txId = policyAdvice.txId {
                                FRLog.i("[FRURLProtocol][AuthPolicy] TransactionId and FRURLProtocol.onUpdatingRequestCallback have been found, URLRequest is returned with transactionId for constructing new URLRequest.")
                                let newRequest = updatingNewRequestCallback(self.request, txId)
                                session.dataTask(with: newRequest).resume()
                            }
                            else {
                                FRLog.i("[FRURLProtocol][AuthPolicy] FRURLProtocol.onUpdatingRequestCallback is not found, SDK updates the URLRequest with new credentials")
                                var newRequest = self.updateRequest(request: self.request)
                                if let txId = policyAdvice.txId {
                                    FRLog.i("[FRURLProtocol][AuthPolicy] FRURLProtocol.onUpdatingRequestCallback is not found, SDK appends _txid in URL parameter")
                                    newRequest = self.modifyRequestForQueryParam(request: newRequest, key: "_txid", value: txId)
                                }
                                session.dataTask(with: newRequest).resume()
                            }
                        }
                        else {
                            FRLog.w("[FRURLProtocol][AuthPolicy] FRURLProtocol.onPolicyAdviceReceived completion callback has been notified with negative result; returning original response")
                            self.completeRequest(error: error)
                        }
                    })
                }
                else {
                    FRLog.w("[FRURLProtocol][AuthPolicy] Authorization Policy has been identified and PolicyAdvice is found; but FRURLProtocol.onPolicyAdviceReceived is not defined. Returning original response.")
                    self.completeRequest(error: error)
                }
            }
            else {
                if !hasAuthValidated {
                    FRLog.w("[FRURLProtocol][AuthPolicy] Authorization Policy has been identified; but failed to parse PolicyAdvice. Returning original response.")
                }
                self.completeRequest(error: error)
            }

            return
        }
        
        
        if let refreshTokenPolicy = FRURLProtocol.refreshTokenPolicy, refreshTokenPolicy(self.responseData, task.response, error) {
            
            FRLog.i("[FRURLProtocol] [\(String(describing:request))] Refresh Token policy satisfied; entering refreshing OAuth2 token protocol")
            // if refresh token policy exists, validate refresh token policy,
            if let user = FRUser.currentUser, self.retryCount < 1 {
                // make sure if current user exists, and original request was captured
                user.refresh { (thisUser, tokenError) in
                    
                    if let newUser = thisUser {
                        FRLog.i("[FRURLProtocol] [\(String(describing:self.request))] OAuth2 Token refresh succeeded; retrying original request with new auth header")
                        FRLog.v("[FRURLProtocol] [\(String(describing: self.request))] Injected Authorization Header: \(user.buildAuthHeader())")
                        self.retryCount += 1
                        self.responseData = nil
                        self.client?.urlProtocol(self, didLoad: Data())
                        // if token was successfully refreshed, retry the request
                        let mutableRequest = ((self.request as NSURLRequest).mutableCopy() as? NSMutableURLRequest)!
                        mutableRequest.setValue(newUser.buildAuthHeader(), forHTTPHeaderField: "Authorization")
                        session.dataTask(with: mutableRequest as URLRequest).resume()
                    }
                    else {
                        FRLog.e("[FRURLProtocol] [\(String(describing:self.request))] OAuth2 Token refresh failed; returning original response")
                        self.completeRequest(error: error)
                    }
                }
            }
            else {
                if self.retryCount >= 1 {
                    FRLog.w("[FRURLProtocol] [\(String(describing:request))] Retry count limit (\(self.retryCount) time) reached, returnign original response")
                }
                else {
                    FRLog.w("[FRURLProtocol] [\(String(describing:request))] FRUser.currentUser does not exist, returning original response")
                }
                // if user does not exists, or original request for some reason was not captured, return the original error
                self.completeRequest(error: error)
            }
        }
        else {
            FRLog.i("[FRURLProtocol] [\(String(describing:request))] Refresh Token policy not satisfied; returning original response")
            // if refresh token policy does not exist, return the original error
            self.completeRequest(error: error)
        }
    }

    
    /// URLSessionDataDelegate method for HTTP Redirection
    ///
    /// - Parameters:
    ///   - session: URLSession
    ///   - task: Current URLSessionTask
    ///   - response: HTTPURLResponse which may explain reason for redirection
    ///   - request: Newly constructed URLRequest object
    ///   - completionHandler: Completion callback
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        
        // When redirection happens with HTTP Status code 307 and Location response header is parsable into PolicyAdvice, IG is handling the authorization process
        if response.statusCode == 307, let redirectUrl = response.allHeaderFields["Location"] as? String, let policyAdvice = PolicyAdvice(redirectUrl: redirectUrl) {
            FRLog.i("[FRURLProtocol][AuthPolicy] Found PolicyAdvice in redirect location response (HTTP Status Code 307); notifying FRURLProtocol.onPolicyAdviceReceived")
            
            if let policyAdviceReceivedCallback = FRURLProtocol.onPolicyAdviceReceived {
                FRLog.i("[FRURLProtocol][AuthPolicy] FRURLProtocol.onPolicyAdviceReceived detected, returning PolicyAdvice and waiting for the response")
                policyAdviceReceivedCallback(policyAdvice, {(result: Bool) in
                    if result {
                        FRLog.i("[FRURLProtocol][AuthPolicy] FRURLProtocol.onPolicyAdviceReceived completion callback has been notified; preparing new URLRequest object for retry")
                        // Reset response data
                        self.responseData = nil
                        self.client?.urlProtocol(self, didLoad: Data())
                        
                        if let updatingNewRequestCallback = FRURLProtocol.onUpdatingRequestCallback, let txId = policyAdvice.txId {
                            FRLog.i("[FRURLProtocol][AuthPolicy] TransactionId and FRURLProtocol.onUpdatingRequestCallback have been found, URLRequest is returned with transactionId for constructing new URLRequest.")
                            let newRequest = updatingNewRequestCallback(self.request, txId)
                            session.dataTask(with: newRequest).resume()
                        }
                        else {
                            // Copy the original request
                            FRLog.i("[FRURLProtocol][AuthPolicy] FRURLProtocol.onUpdatingRequestCallback is not found, SDK updates the URLRequest with new credentials")
                            var newRequest = self.updateRequest(request: self.request)
                            if let txId = policyAdvice.txId {
                                FRLog.i("[FRURLProtocol][AuthPolicy] FRURLProtocol.onUpdatingRequestCallback is not found, SDK appends _txid in URL parameter")
                                newRequest = self.modifyRequestForQueryParam(request: newRequest, key: "_txid", value: txId)
                            }
                            session.dataTask(with: newRequest).resume()
                        }
                    }
                    else {
                        FRLog.w("[FRURLProtocol][AuthPolicy] FRURLProtocol.onPolicyAdviceReceived completion callback has been notified with negative result; continue on redirection")
                        self.client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
                        completionHandler(request)
                    }
                })
            }
            else {
                FRLog.w("[FRURLProtocol][AuthPolicy] Found PolicyAdvice, but FRURLProtocol.onPolicyAdviceReceived is not defined; ignore authorization process, and continue on redirection")
                client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
                completionHandler(request)
            }
            return
        }
        
        if let authorizationPolicy = FRURLProtocol.authorizationEvaluationPolicy, authorizationPolicy(self.responseData, response, nil) {
            hasAuthValidated = true
            FRLog.i("[FRURLProtocol][AuthPolicy] FRURLProtocol.authorizationEvaluationPolicy has been satisfied, preparing Authorization process")
            var policyAdvice: PolicyAdvice?
            
            if let redirectUrl = response.allHeaderFields["Location"] as? String, let thisPolicyAdvice = PolicyAdvice(redirectUrl: redirectUrl) {
                FRLog.i("[FRURLProtocol][AuthPolicy] PolicyAdvice is found in redirect location's URL; notifying FRURLProtocol.onPolicyAdviceReceived")
                policyAdvice = thisPolicyAdvice
            }
            else if let parsingAdviceCallback = FRURLProtocol.parsePolicyAdviceCallback, let parsedAdvice = parsingAdviceCallback(self.responseData, response, nil) {
                FRLog.i("[FRURLProtocol][AuthPolicy] PolicyAdvice is parsed from FRURLProtocol.parsePolicyAdviceCallback; notifying FRURLProtocol.parsePolicyAdviceCallback")
                policyAdvice = parsedAdvice
            }
            
            if let policyAdvice = policyAdvice {
                if let policyAdviceReceivedCallback = FRURLProtocol.onPolicyAdviceReceived {
                    FRLog.i("[FRURLProtocol][AuthPolicy] FRURLProtocol.onPolicyAdviceReceived detected, returning PolicyAdvice and waiting for the response")
                    policyAdviceReceivedCallback(policyAdvice, {(result: Bool) in
                        if result {
                            FRLog.i("[FRURLProtocol][AuthPolicy] FRURLProtocol.onPolicyAdviceReceived completion callback has been notified; preparing new URLRequest object for retry")
                            // Reset response data
                            self.responseData = nil
                            self.client?.urlProtocol(self, didLoad: Data())
                            
                            if let updatingNewRequestCallback = FRURLProtocol.onUpdatingRequestCallback, let txId = policyAdvice.txId {
                                FRLog.i("[FRURLProtocol][AuthPolicy] TransactionId and FRURLProtocol.onUpdatingRequestCallback have been found, URLRequest is returned with transactionId for constructing new URLRequest.")
                                let newRequest = updatingNewRequestCallback(self.request, txId)
                                session.dataTask(with: newRequest).resume()
                            }
                            else {
                                // Copy the original request
                                FRLog.i("[FRURLProtocol][AuthPolicy] FRURLProtocol.onUpdatingRequestCallback is not found, SDK updates the URLRequest with new credentials")
                                var newRequest = self.updateRequest(request: self.request)
                                if let txId = policyAdvice.txId {
                                    FRLog.i("[FRURLProtocol][AuthPolicy] FRURLProtocol.onUpdatingRequestCallback is not found, SDK appends _txid in URL parameter")
                                    newRequest = self.modifyRequestForQueryParam(request: newRequest, key: "_txid", value: txId)
                                }
                            }
                        }
                        else {
                            FRLog.w("[FRURLProtocol][AuthPolicy] FRURLProtocol.onPolicyAdviceReceived completion callback has been notified with negative result; continue on redirection")
                            self.client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
                            completionHandler(request)
                        }
                    })
                }
                else {
                    FRLog.w("[FRURLProtocol][AuthPolicy] Authorization Policy has been identified and PolicyAdvice is found; but FRURLProtocol.onPolicyAdviceReceived is not defined. Continue on redirection")
                    client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
                    completionHandler(request)
                }
            }
            else {
                if !hasAuthValidated {
                    FRLog.w("[FRURLProtocol][AuthPolicy] Authorization Policy has been identified; but failed to parse PolicyAdvice. Continue on redirection")
                }
                client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
                completionHandler(request)
            }
        }
        else {
            client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
            completionHandler(request)
        }
    }

    
    /// URLSessionDataDelegate method for invalidating the current request with an error
    ///
    /// - Parameters:
    ///   - session: URLSession
    ///   - error: An error occurred during the request
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        guard let error = error else { return }
        client?.urlProtocol(self, didFailWithError: error)
    }

    
    /// URLSessionDataDelegate method for Authentication Challenge
    ///
    /// - Parameters:
    ///   - session: URLSession
    ///   - challenge: URLAuthenticationChallenge
    ///   - completionHandler: Completion callback
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let protectionSpace = challenge.protectionSpace
        let sender = challenge.sender

        if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                sender?.use(credential, for: challenge)
                completionHandler(.useCredential, credential)
                return
            }
        }
    }

    
    /// URLSessionDataDelegate method
    ///
    /// - Parameter session: URLSession
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        client?.urlProtocolDidFinishLoading(self)
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
    
    
    
    /// Updates existing URLRequest object with new credentials, and additional header
    /// - Parameter request: Original URLRequest object
    /// - Parameter key: String value of key for header
    /// - Parameter value: String value for header
    func updateRequest(request: URLRequest, key: String? = nil, value: String? = nil) -> URLRequest {
        let mutableRequest = ((request as NSURLRequest).mutableCopy() as? NSMutableURLRequest)!
        
        // Setting all persistent cookies for the domain
        if let cookieHeader = FRRestClient.prepareCookieHeader(url: mutableRequest.url!) {
            cookieHeader.forEach{ mutableRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
        }
        
        if let keyValue = key, let headerValue = value {
            mutableRequest.setValue(headerValue, forHTTPHeaderField: keyValue)
        }
        
        return mutableRequest as URLRequest
    }
    
    
    
    /// Completes current URLRequest with result
    /// - Parameter error: error object that may or may not be returned from the original request.
    func completeRequest(error: Error?) {
        if let error = error {
            if let response = self.responseData {
                self.client?.urlProtocol(self, didLoad: response)
            }
            self.client?.urlProtocol(self, didFailWithError: error)
        }
        else {
            if let response = self.responseData {
                self.client?.urlProtocol(self, didLoad: response)
            }
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }
}

