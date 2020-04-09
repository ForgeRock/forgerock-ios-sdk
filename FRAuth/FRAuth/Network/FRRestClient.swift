// 
//  FRRestClient.swift
//  FRAuth
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRCore


/// FRRestclient is FRCore's RestClient wrapper with additional functionalities for Cookie management
@objc
class FRRestClient: NSObject {
    
    
    //  MARK: - Invoke
    
    /// Invokes REST API Request with `Request` object
    ///
    /// - Parameters:
    ///   - request: `Request` object for API request which should contain all information regarding the request
    ///   - completion: `Result` completion callback
    static func invoke(request: Request, completion: @escaping ResultCallback) {
        
        var newRequest = request
        //  Get Cookie from Cookie Store, and set it to header
        if let thisURL = URL(string: request.url), let cookieHeader = FRRestClient.prepareCookieHeader(url: thisURL) {
            var newHeaders = request.headers
            newHeaders.merge(cookieHeader) { (_, new) in new }
            newRequest = Request(url: request.url, method: request.method, headers: newHeaders, bodyParams: request.bodyParams, urlParams: request.urlParams, requestType: request.requestType, responseType: request.responseType, timeoutInterval: request.timeoutInterval)
        }
        
        RestClient.shared.invoke(request: newRequest) { (result) in
            switch result {
            case .success(let response, let httpResponse):
                FRRestClient.parseResponseForCookie(response: response, httpResponse: httpResponse as? HTTPURLResponse)
                break
            case .failure(_):
                break
            }
            
            completion(result)
        }
    }
    
    
    /// Invokes synchronously REST API Request with `Request` object
    ///
    /// - Parameter request: `Request` object for API request which should contain all information regarding the request
    /// - Returns: `Result` instance of API Request
    static func invokeSync(request: Request) -> Result {
        
        var newRequest = request
        //  Get Cookie from Cookie Store, and set it to header
        if let thisURL = URL(string: request.url), let cookieHeader = FRRestClient.prepareCookieHeader(url: thisURL) {
            var newHeaders = request.headers
            newHeaders.merge(cookieHeader) { (_, new) in new }
            newRequest = Request(url: request.url, method: request.method, headers: newHeaders, bodyParams: request.bodyParams, urlParams: request.urlParams, requestType: request.requestType, responseType: request.responseType, timeoutInterval: request.timeoutInterval)
        }
        let result = RestClient.shared.invokeSync(request: newRequest)
        
        switch result {
        case .success(let response, let httpResponse):
            FRRestClient.parseResponseForCookie(response: response, httpResponse: httpResponse as? HTTPURLResponse)
            break
        case .failure(_):
            break
        }
        
        return result
    }
    
    
    //  MARK: - Cookie
    
    /// Parses response header for Cookie, and persists into storage
    /// - Parameter response: response JSON object
    /// - Parameter httpResponse: HTTPURLResponse object
    static func parseResponseForCookie(response: [String: Any]?, httpResponse: HTTPURLResponse?) {
        
        //  Parse Cookies from response headers, and persist
        if let httpResponse = httpResponse, let responseHeader = httpResponse.allHeaderFields as? [String: String], let url = httpResponse.url, let frAuth = FRAuth.shared, frAuth.serverConfig.enableCookie {

            let cookies = HTTPCookie.cookies(withResponseHeaderFields: responseHeader, for: url)
            for cookie in cookies {
                if let cookieExpDate = cookie.expiresDate, cookieExpDate.timeIntervalSince1970 < Date().timeIntervalSince1970 {
                    frAuth.keychainManager.cookieStore.delete(cookie.name + "-" + cookie.domain)
                    FRLog.v("[Cookies] Delete - Cookie Name: \(cookie.name)")
                }
                else {
                    let cookieData = NSKeyedArchiver.archivedData(withRootObject: cookie)
                    frAuth.keychainManager.cookieStore.set(cookieData, key: cookie.name + "-" + cookie.domain)
                    FRLog.v("[Cookies] Update - Cookie Name: \(cookie.name) | Cookie Value: \(cookie.value)")
                }
            }
        }
    }
    
    
    /// Prepares persisted Cookies from Keychain Service, and returns cookie header value
    /// - Parameter url: URL of target server
    static func prepareCookieHeader(url: URL) -> [String: String]? {
        // Retrieves all cookie items from cookie store
        if let frAuth = FRAuth.shared, frAuth.serverConfig.enableCookie, let cookieItems = frAuth.keychainManager.cookieStore.allItems() {
            
            var cookieList: [HTTPCookie] = []
            
            // Iterate Cookie List and validate
            for cookieObj in cookieItems {
                if let cookieData = cookieObj.value as? Data, let cookie = NSKeyedUnarchiver.unarchiveObject(with: cookieData) as? HTTPCookie {
                    // When Cookie is expired, remove it from the Cookie Store
                    if let expDate = cookie.expiresDate, expDate.timeIntervalSince1970 < Date().timeIntervalSince1970 {
                        frAuth.keychainManager.cookieStore.delete(cookie.name + "-" + cookie.domain)
                        FRLog.v("[Cookies] Delete - Expired - Cookie Name: \(cookie.name)")
                    }
                    else {
                        // Validate isSecure attribute
                        var isSecureValidated = true
                        if cookie.isSecure, let urlScheme = url.scheme, urlScheme.lowercased() != "https" {
                            FRLog.v("[Cookies] Ignore - isSecure validation failed - Cookie Name: \(cookie.name)")
                            isSecureValidated = false
                        }
                        
                        // Validate domain, and path
                        var domainValidated = false
                        if let host = url.host, host.contains(cookie.domain), url.path.hasPrefix(cookie.path) {
                            domainValidated = true
                        }
                        else {
                            FRLog.v("[Cookies] Ignore - Domain validation failed - Cookie Name: \(cookie.name)")
                        }
                        
                        if isSecureValidated, domainValidated {
                            FRLog.v("[Cookies] Injected for the request - Cookie Name: \(cookie.name) | Cookie Value \(cookie.value)")
                            cookieList.append(cookie)
                        }
                    }
                }
            }
            // Generate and return the Cookie List as in header format
            return HTTPCookie.requestHeaderFields(with: cookieList)
        }
        
        return nil
    }
    
    
    //  MARK: - Config
    
    /// Sets custom URLSessionConfiguration for RestClient's URLSession object
    ///
    /// - Parameter config: custom URLSessionConfiguration object
    @objc
    static func setURLSessionConfiguration(config: URLSessionConfiguration) {
        RestClient.shared.setURLSessionConfiguration(config: config)
    }
}
