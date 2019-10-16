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


/**
 FRURLProtocol is a predefined URLProtocol class that is responsible to handle, analyze, and perfrom OAuth2 Token Management with predefined configuration.
 FRURLProtocol only validates, and performs Token Injection, and/or Refresh on predefined ValidatedURLs; any other URL is ignored.
 
 FRURLProtocol is designed to work with any type of iOS HTTP client where you can customize URLSessionConfiguration for URLsession.
 
 ### Usage Example: ###
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
    /// FRURLProtocolRefreshTokenPolicy callback to be analyzed and determined for token refresh
    @objc
    public static var refreshTokenPolicy: FRURLProtocolRefreshTokenPolicy?
    /// URLSession
    var session: URLSession?
    /// Current SessionTask
    var sessionTask: URLSessionDataTask?
    /// ResponseData of the current URLSessionDataTask
    var responseData: Data?
    /// Number of retries that were attempted
    var retryCount: Int = 0
    
    
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
            }
            else {
                if self.retryCount >= 1 {
                    FRLog.w("[FRURLProtocol] [\(String(describing:request))] Retry count limit (\(self.retryCount) time) reached, returnign original response")
                }
                else {
                    FRLog.w("[FRURLProtocol] [\(String(describing:request))] FRUser.currentUser does not exist, returning original response")
                }
                // if user does not exists, or original request for some reason was not captured, return the original error
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
        else {
            FRLog.i("[FRURLProtocol] [\(String(describing:request))] Refresh Token policy not satisfied; returning original response")
            // if refresh token policy does not exist, return the original error
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

    
    /// URLSessionDataDelegate method for HTTP Redirection
    ///
    /// - Parameters:
    ///   - session: URLSession
    ///   - task: Current URLSessionTask
    ///   - response: HTTPURLResponse which may explain reason for redirection
    ///   - request: Newly constructed URLRequest object
    ///   - completionHandler: Completion callback
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
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
}

