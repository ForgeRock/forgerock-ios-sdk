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
    static func invoke(request: Request, action: Action? = nil, completion: @escaping ResultCallback) {
        
        var newRequest = request
        //  Get Cookie from Cookie Store, and set it to header
        if let thisURL = URL(string: request.url), let cookieHeader = FRRestClient.prepareCookieHeader(url: thisURL) {
            var newHeaders = request.headers
            newHeaders.merge(cookieHeader) { (_, new) in new }
            newRequest = Request(url: request.url, method: request.method, headers: newHeaders, bodyParams: request.bodyParams, urlParams: request.urlParams, requestType: request.requestType, responseType: request.responseType, timeoutInterval: request.timeoutInterval)
        }
        
        RestClient.shared.invoke(request: newRequest, action: action) { (result) in
            switch result {
            case .success(let response, let httpResponse):
                FRRestClient.parseResponseForCookie(response: response, httpResponse: httpResponse as? HTTPURLResponse)
                break
            case .failure(let error):
                if let networkError: NetworkError = error as? NetworkError {
                    switch networkError {
                    case .apiRequestFailure(let data, let response, let error):
                        //  Parse and convert NetworkError.apiRequestFailure to AuthApiError
                        completion(Result.failure(error: AuthApiError.convertToAuthApiError(data: data, response: response, error: error)))
                        return
                    default:
                        //  Otherwise, return as it is
                        break
                    }
                }
                break
            }
            completion(result)
        }
    }
    
    
    /// Invokes synchronously REST API Request with `Request` object
    ///
    /// - Parameter request: `Request` object for API request which should contain all information regarding the request
    /// - Returns: `Result` instance of API Request
    static func invokeSync(request: Request, action: Action? = nil) -> Result {
        
        var newRequest = request
        //  Get Cookie from Cookie Store, and set it to header
        if let thisURL = URL(string: request.url), let cookieHeader = FRRestClient.prepareCookieHeader(url: thisURL) {
            var newHeaders = request.headers
            newHeaders.merge(cookieHeader) { (_, new) in new }
            newRequest = Request(url: request.url, method: request.method, headers: newHeaders, bodyParams: request.bodyParams, urlParams: request.urlParams, requestType: request.requestType, responseType: request.responseType, timeoutInterval: request.timeoutInterval)
        }
        var result = RestClient.shared.invokeSync(request: newRequest, action: action)
        
        switch result {
        case .success(let response, let httpResponse):
            FRRestClient.parseResponseForCookie(response: response, httpResponse: httpResponse as? HTTPURLResponse)
            break
        case .failure(let error):
            if let networkError = error as? NetworkError {
                switch networkError {
                case .apiRequestFailure(let data, let response, let error):
                    //  Parse and convert NetworkError.apiRequestFailure to AuthApiError
                    result = Result.failure(error: AuthApiError.convertToAuthApiError(data: data, response: response, error: error))
                default:
                    //  Otherwise, return as it is
                    break
                }
            }
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
                    if cookie.isExpired {
                        frAuth.keychainManager.cookieStore.delete(cookie.name + "-" + cookie.domain)
                        FRLog.v("[Cookies] Delete - Expired - Cookie Name: \(cookie.name)")
                    }
                    else {
                        if !cookie.validateIsSecure(url) {
                            FRLog.v("[Cookies] Ignore - isSecure validation failed - Domain: \(url)\n\nCookie: \(cookie.name)")
                        }
                        else if !cookie.validateURL(url) {
                            FRLog.v("[Cookies] Ignore - Domain validation failed - Domain: \(url)\n\nCookie: \(cookie.name)")
                        }
                        else {
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


extension HTTPCookie {
    
    var isExpired: Bool {
        get {
            if let expDate = self.expiresDate, expDate.timeIntervalSince1970 < Date().timeIntervalSince1970 {
                return true
            }
            return false
        }
    }
    
    
    func validateIsSecure(_ url: URL) -> Bool {
        if !self.isSecure {
            return true
        }
        if let urlScheme = url.scheme, urlScheme.lowercased() == "https" {
            return true
        }
        return false
    }
    
    
    func validateURL(_ url: URL) -> Bool {
        return self.validateDomain(url: url) && self.validatePath(url: url)
    }
    
    
    private func validatePath(url: URL) -> Bool {
        let path = url.path.count == 0 ? "/" : url.path
        
        //  For exact matching i.e. /path == /path
        if path == self.path {
            return true
        }
        
        //  For partial matching
        if path.hasPrefix(self.path) {
            //  if Cookie path ends with /
            //  i.e. /abc == / or /abc/def == /abc/
            if self.path.hasSuffix("/") {
                return true
            }
            
            //  making sure to validate exact path matching
            //  i.e. /abcd != /abc, /abc/def == /abc
            if path.hasPrefix(self.path + "/") {
                return true
            }
        }
        return false
    }
    
    private func validateDomain(url: URL) -> Bool {
        
        guard let host = url.host else {
            //  Invalid URL host
            return false
        }
        
        //  For exact matching i.e. forgerock.com == forgerock.com or am.forgerock.com == am.forgerock.com
        if host == self.domain {
            return true
        }
        //  For sub domain matching i.e. demo.forgerock.com == .forgerock.com
        if host.hasSuffix(self.domain) {
            return true
        }
        //  For ignoring leading dot
        if (self.domain.count - host.count == 1) && self.domain.hasPrefix(".") {
            return true
        }
        return false
    }
}
