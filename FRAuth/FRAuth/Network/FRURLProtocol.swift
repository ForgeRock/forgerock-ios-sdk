//
//  FRURLProtocol2.swift
//  FRAuth
//
//  Copyright (c) 2020-2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore

@objc open class FRURLProtocol: URLProtocol {
    
    //  MARK: - Public Property
    
    /// TokenManagementPolicy for URLProtocol
    @objc public static var tokenManagementPolicy: TokenManagementPolicy?
    /// AuthorizationPolicy for URLProtocol
    @objc public static var authorizationPolicy: AuthorizationPolicy?
    /// FRSecurityConfiguration for URLProtocol - Used for SSL Pinning
    @objc public static var frSecurityConfiguration: FRSecurityConfiguration?
    
    //  MARK: - Private Property
    
    /// Constant String key of FRURLProtocol indication
    struct Constants {
        static let FRURLProtocolHandled = "FRURLProtocolHandled"
    }
    
    /// URLSession
    var session: URLSession?
    /// Current SessionTask
    var sessionTask: URLSessionDataTask?
    /// ResponseData of the current URLSessionDataTask
    var responseData: Data?
    /// Number of retries that were attempted
    var retryCount: Int = 0
    
    
    //  MARK: - URLProtocol
    
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
    
    
    /// Returns a canonical version of the given request
    ///
    /// - Parameter request: A request to make canonical
    /// - Returns: The canonical form of the given request
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    
    //  MARK: - Method
    
    public override class func canInit(with request: URLRequest) -> Bool {
        
        if FRURLProtocol.property(forKey: Constants.FRURLProtocolHandled, in: request) != nil {
            return false
        }
        
        //  TokenManagementPolicy evaluation
        if let tokenManagementPolicy = FRURLProtocol.tokenManagementPolicy, tokenManagementPolicy.validateURL(request: request) {
            return true
        }
        //  AuthorizationPolicy evaluation
        else if let authPolicy = FRURLProtocol.authorizationPolicy, authPolicy.validateURL(request: request) {
            return true
        }
        
        return false
    }
    
    
    /// Starts loading, and validating the request
    public override func startLoading() {
        FRLog.i("[FRURLProtocol] [\(String(describing:request))] Start intercepting the request")
        let mutableRequest = ((request as NSURLRequest).mutableCopy() as? NSMutableURLRequest)!
        
        // Setting all persistent cookies for the domain
        if let cookieHeader = FRRestClient.prepareCookieHeader(url: mutableRequest.url!) {
            cookieHeader.forEach{ mutableRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
        }
        
        //  TokenManagementPolicy requires modification of current URLRequest to inject authorization header
        if let tokenManagementPolicy = FRURLProtocol.tokenManagementPolicy {
            FRLog.i("[FRURLProtocol] TokenManagementPolicy found; evaluating currently authenticated session")
            if let user = FRUser.currentUser {
                FRLog.i("[FRURLProtocol] [\(String(describing:request))] Authenticated user found; proceeding on getting access_token")
                var tokenRequest = self.request
                do {
                    let newUser = try user.getAccessToken()
                    if let token = newUser.token {
                        FRLog.i("[FRURLProtocol] [\(String(describing: self.request))] User's access_token retrieved; injecting Authorization header")
                        tokenRequest = tokenManagementPolicy.updateRequest(originalRequest: tokenRequest, token: token)
                    }
                    else {
                        FRLog.w("[FRURLProtocol] [\(String(describing: self.request))] User's access_token is nil; proceeding with the original request")
                    }
                }
                catch {
                    FRLog.w("[FRURLProtocol] [\(String(describing: self.request))] Failed to retrieve valid access_token; ignoring Authorization Header injection")
                    FRLog.w("[FRURLProtocol] Retrieving AccessToken error: \(error.localizedDescription)")
                }
                FRURLProtocol.setProperty(true, forKey: Constants.FRURLProtocolHandled, in: mutableRequest)
                self.sessionTask = self.session?.dataTask(with: tokenRequest)
                self.sessionTask?.resume()
                return
            }
            else {
                FRLog.w("[FRURLProtocol] [\(String(describing: request))] No authenticated user found; proceeding with original request")
            }
        }
        
        if let _ = FRURLProtocol.authorizationPolicy {
            FRLog.i("[FRURLProtocol] AuthorizationPolicy found; proceeding with AuthorizationPolicy")
            FRURLProtocol.setProperty(true, forKey: Constants.FRURLProtocolHandled, in: mutableRequest)
            self.sessionTask = self.session?.dataTask(with: mutableRequest as URLRequest)
            self.sessionTask?.resume()
            return
        }
        
        FRURLProtocol.setProperty(true, forKey: Constants.FRURLProtocolHandled, in: mutableRequest)
        session?.dataTask(with: mutableRequest as URLRequest, completionHandler: { (data, response, error) in
            if let returnData = data {
                self.client?.urlProtocol(self, didLoad: returnData)
            }
            self.client?.urlProtocolDidFinishLoading(self)
        }).resume()
    }
    
    
    /// Stops loading, and indicates that the request has finished
    public override func stopLoading() {
        FRLog.i("[FRURLProtocol] [\(String(describing:request))] Request completed")
        sessionTask?.cancel()
    }
    
    
    //  MARK: - Helper methods
    
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
    
    
    /// Compares two URL objects with host, scheme, relativePath, and port comparison
    ///
    /// - Parameters:
    ///   - lhs: URL object to be compared
    ///   - rhs: URL object to be compared
    /// - Returns: Boolean result of whether two given URLs are same or not
    static func compareTwoURLs(lhs: URL, rhs: URL) -> Bool {
        return (lhs.host == rhs.host && lhs.scheme == rhs.scheme && lhs.relativePath == rhs.relativePath && lhs.port == rhs.port)
    }
    
    
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
        
        var originalRequest: URLRequest = request
        var shouldRetry: Bool = false
        var token: AccessToken?
        if let tokenManagementPolicy = FRURLProtocol.tokenManagementPolicy {
            FRLog.i("[FRURLProtocol] TokenManagementPolicy found; evaluating refreshTokenPolicy")
            token = FRUser.currentUser?.token
            if tokenManagementPolicy.evalulateRefreshToken(responseData: self.responseData, response: task.response, error: error) {
                FRLog.i("[FRURLProtocol] [\(String(describing:request))] Refresh Token policy satisfied; entering refreshing OAuth2 token protocol")
                // if refresh token policy exists, validate refresh token policy,
                if let user = FRUser.currentUser, self.retryCount < 1 {
                    // make sure if current user exists, and original request was captured
                    do {
                        self.retryCount += 1
                        let newUser = try user.refreshSync()
                        token = newUser.token
                        shouldRetry = true
                        FRLog.i("[FRURLProtocol] [\(String(describing:self.request))] OAuth2 Token refresh succeeded; retrying original request with new auth header")
                    }
                    catch {
                        FRLog.e("[FRURLProtocol] [\(String(describing:self.request))] OAuth2 Token refresh failed; returning original response: \(error.localizedDescription)")
                    }
                }
                else {
                    if self.retryCount >= 1 {
                        FRLog.w("[FRURLProtocol] [\(String(describing:request))] Retry count limit (\(self.retryCount) time) reached, returnign original response")
                    }
                    else {
                        FRLog.w("[FRURLProtocol] [\(String(describing:request))] FRUser.currentUser does not exist, returning original response")
                    }
                }
            }
            else {
                FRLog.i("[FRURLProtocol] [\(String(describing:request))] Refresh Token policy not satisfied; returning original response")
            }
        }
        
        if let authPolicy = FRURLProtocol.authorizationPolicy {
            FRLog.i("[FRURLProtocol] AuthorizationPolicy found; evaluating for Authorization")
            
            if let policyAdvice = authPolicy.evaluateAuthorizationPolicy(responseData: self.responseData, response: task.response, error: error) {
                FRLog.i("[FRURLProtocol] PolicyAdvice received from AuthorizationPolicy; proceeding with PolicyAdvice for authorization process")
                
                var adviceResult: Bool = false
                let semaphore = DispatchSemaphore(value: 0)
                authPolicy.onPolicyAdviceReceived(policyAdvice: policyAdvice) { (result) in
                    adviceResult = result
                    semaphore.signal()
                }
                _ = semaphore.wait(timeout: DispatchTime.now() + request.timeoutInterval)
                
                if adviceResult {
                    FRLog.i("[FRURLProtocol] PolicyAdvice processed, and received successful result of authorization; proceeding with updating request")
                    originalRequest = authPolicy.updateRequest(originalRequest: request, txId: policyAdvice.txId)
                    shouldRetry = true
                }
                else {
                    FRLog.w("[FRURLProtocol] PolicyAdvice processed, but AuthorizationPolicyDelegate.onPolicyAdviceReceived returned failure; proceeding with the original request")
                }
            }
            else {
                FRLog.i("[FRURLProtocol] AuthorizationPolicyDelegate.evaluateAuthorizationPolicy not satisfied for the current request's response; proceeding with the original request")
            }
        }
        
        
        if shouldRetry {
            self.responseData = nil
            self.client?.urlProtocol(self, didLoad: Data())
            
            if let token = token, let tokenManagementPolicy = FRURLProtocol.tokenManagementPolicy {
                FRLog.i("[FRURLProtocol] Building new URLRequest with TokenManagementPolicy")
                originalRequest = tokenManagementPolicy.updateRequest(originalRequest: originalRequest, token: token)
            }
            
            self.sessionTask = self.session?.dataTask(with: originalRequest)
            self.sessionTask?.resume()
        }
        else {
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
        
        if let authPolicy = FRURLProtocol.authorizationPolicy {
            if let policyAdvice = authPolicy.evaluateAuthorizationPolicyWithRedirect(responseData: self.responseData, session: session, task: task, willPerformHTTPRedirection: response, newRequest: request) {
                
                authPolicy.onPolicyAdviceReceived(policyAdvice: policyAdvice) { (result) in
                    if result {
                        FRLog.i("[FRURLProtocol] PolicyAdvice processed, and received successful result of authorization; proceeding with updating request")
                        self.responseData = nil
                        self.client?.urlProtocol(self, didLoad: Data())
                        var newRequest = self.updateRequest(request: self.request)
                        newRequest = authPolicy.updateRequest(originalRequest: self.request, txId: policyAdvice.txId)
                        session.dataTask(with: newRequest).resume()
                    }
                    else {
                        FRLog.w("[FRURLProtocol] PolicyAdvice processed, but AuthorizationPolicyDelegate.onPolicyAdviceReceived returned failure; proceeding with the original request")
                        self.client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
                        completionHandler(request)
                    }
                }
                return
            }
            else {
                FRLog.i("[FRURLProtocol] AuthorizationPolicyDelegate.evaluateAuthorizationPolicy not satisfied for the current redirect request; proceeding with the original request")
            }
        }
        client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
        completionHandler(request)
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
    
    
    /// URLSessionDelegate method for Authentication Challenge
    ///
    /// - Parameters:
    ///   - session: URLSession
    ///   - challenge: URLAuthenticationChallenge
    ///   - completionHandler: Completion callback
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let frSecurityConfiguration = FRURLProtocol.frSecurityConfiguration {
            frSecurityConfiguration.validateSessionAuthChallenge(session: session, challenge: challenge, completionHandler: completionHandler)
        } else {
            let protectionSpace = challenge.protectionSpace
            let sender = challenge.sender
            
            if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                if let serverTrust = protectionSpace.serverTrust {
                    let credential = URLCredential(trust: serverTrust)
                    sender?.use(credential, for: challenge)
                    completionHandler(.useCredential, credential)
                    return
                }
            } else {
                completionHandler(.performDefaultHandling, nil)
                return
            }
        }
        
    }
    
    /// URLSessionTaskDelegate method for Authentication Challenge
    ///
    /// - Parameters:
    ///   - session: URLSession
    ///   - task: URLSessionTask
    ///   - challenge: URLAuthenticationChallenge
    ///   - completionHandler: Completion callback
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let frSecurityConfiguration = FRURLProtocol.frSecurityConfiguration {
            frSecurityConfiguration.validateTaskAuthChallenge(session: session, task: task, challenge: challenge, completionHandler: completionHandler)
        } else {
            let protectionSpace = challenge.protectionSpace
            let sender = challenge.sender
            
            if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                if let serverTrust = protectionSpace.serverTrust {
                    let credential = URLCredential(trust: serverTrust)
                    sender?.use(credential, for: challenge)
                    completionHandler(.useCredential, credential)
                    return
                }
            } else {
                completionHandler(.performDefaultHandling, nil)
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
}
