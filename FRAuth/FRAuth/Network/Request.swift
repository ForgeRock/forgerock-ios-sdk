//
//  Request.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/**
 Generic representation of API request specifically designed by, and used by ForgeRock iOS SDK core
 */
struct Request {
    
    /// Enumeration for ContentType used in request/response
    ///
    /// - plainText: "text/plain"
    /// - json: "application/json"
    /// - urlEncoded: "application/x-www-form-urlencoded"
    public enum ContentType: String {
        case plainText = "text/plain"
        case json = "application/json"
        case urlEncoded = "application/x-www-form-urlencoded"
    }
    
    /// Enumeration for HTTP methods
    ///
    /// - GET: GET
    /// - PUT: PUT
    /// - POST: POST
    /// - DELETE: DELETE
    public enum HTTPMethod: String {
        case GET = "GET"
        case PUT = "PUT"
        case POST = "POST"
        case DELETE = "DELETE"
    }
    
    
    //  MARK: - Property
    
    /// String value of request URL
    let url: String
    /// HTTP Method as String
    let method: HTTPMethod
    /// HTTP request headers as dictionary
    let headers: [String: String]
    /// HTTP body parameters as dictionary
    let bodyParams: [String: Any]
    /// URL parameters as dictionary
    let urlParams: [String: String]
    /// Response type as `ContentType`; "Accept" header will be automatically added
    let responseType: ContentType
    /// Request type as `ContentType`; "Content-type" header will be automatically added
    let requestType: ContentType
    /// Request timeout interval in second
    let timeoutInterval: Double
    
    
    //  MARK: - Init
    
    /// Initializes a Request object to invoke API request
    ///
    /// - Parameters:
    ///   - url: Full URL, including path, of API request
    ///   - method: HTTP method for the request
    ///   - headers: Additional HTTP headers for the request in dictionary
    ///   - bodyParams: HTTP body in dictionary
    ///   - urlParams: URL parameters in dictionary
    ///   - requestType: ContentType of request content; enumeration value of `ContentType`
    ///   - responseType: ContentType of expected response content; enumeration value of `ContentType`
    ///   - timeoutInterval: Timeout interval in second for the request
    init(url: String, method: HTTPMethod, headers: [String: String] = [:], bodyParams: [String: Any] = [:], urlParams: [String: String] = [:], requestType: ContentType = .json, responseType: ContentType = .json, timeoutInterval: Double = 60) {
        self.url = url
        self.method = method
        self.headers = headers
        self.bodyParams = bodyParams
        self.urlParams = urlParams
        self.requestType = requestType
        self.responseType = responseType
        self.timeoutInterval = timeoutInterval
    }
    
    
    //  MARK: - Build
    
    /// Builds `URLRequest` object based on `Request` instance
    ///
    /// - Returns: URLRequest object if `Request` object was valid; otherwise `nil` is returned
    func build() -> URLRequest? {
        
        //  Validate URL is valid
        guard var urlComponents = URLComponents(string: self.url), self.url.isValidUrl else {
            FRLog.e("Missing or invalid URL; request will fail: \(self.url)")
            return nil
        }

        if self.urlParams.count > 0 {
            //  Build URL Parameters
            urlComponents.queryItems = self.urlParams.map{ URLQueryItem(name: $0.key, value: $0.value)}
        }
        
        //  Make sure that URL can be constructed with URL string, and URL parameters
        guard let thisUrl = urlComponents.url else {
            FRLog.e("Failed to generate URL with URL parameter; request will fail: \(self.url) | \(self.urlParams)")
            return nil
        }
        
        //  Build `URLRequest` object with constructed URL object
        let thisRequest = NSMutableURLRequest(url: thisUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: self.timeoutInterval)
        //  Set HTTP method
        thisRequest.httpMethod = self.method.rawValue
        
        //  Get Cookie from Cookie Store, and set it to header
        if let cookieHeader = self.prepareCookieHeader(url: thisUrl) {
            thisRequest.allHTTPHeaderFields = cookieHeader
        }
               
        //  Set Content-Type, and Accept headers based on request/response types
        thisRequest.setValue(self.requestType.rawValue, forHTTPHeaderField: "Content-Type")
        thisRequest.setValue(self.responseType.rawValue, forHTTPHeaderField: "Accept")
        
        //  Add additional headers
        self.headers.forEach{ thisRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
        //  Build http body content
        // TODO: dynamically handle more content-type
        if self.bodyParams.keys.count > 0 {
            if self.method != .GET {
                if let httpBody = try? JSONSerialization.data(withJSONObject: self.bodyParams, options: []) {
                    thisRequest.httpBody = httpBody
                }
                else {
                    FRLog.w("Failed to generate HTTP Body: \(self.bodyParams)")
                }
            }
            else {
                FRLog.w("Ignoring body parameters for GET request; \(self.bodyParams)")
            }
        }
        
        //  Return URLRequest
        return thisRequest as URLRequest
    }
    
    
    //  MARK: - Private
    
    /// Prepares persisted Cookies from Keychain Service, and returns cookie header value
    
    /// Prepares persisted Cookies from Keychain Service, and returns cookie header value
    /// - Parameter url: URL of target server
    func prepareCookieHeader(url: URL) -> [String: String]? {
        
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
                        if let host = url.host, cookie.domain.contains(host), url.path.hasPrefix(cookie.path) {
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
    
    
    //  MARK: - Debug
    
    /// Generates debug description string of `Request` instance
    var debugDescription: String {
        var desc = "Request: \(self.url) | \(self.method.rawValue) \r\n"
        desc += "   Request Type: \(self.requestType.rawValue) | Response Type: \(self.responseType.rawValue) \r\n"
        if self.urlParams.count > 0 {
            desc += "   URL Parameters: \r\n"
            self.urlParams.forEach{ desc += "       \($0.key): \($0.value) \r\n"}
        }
        if !self.bodyParams.isEmpty {
            desc += "   Body Parameters: \r\n"
            desc += "       \(self.bodyParams)"
        }
        if self.headers.count > 0 {
            desc += "   Additional Headers: \r\n"
            self.headers.forEach{ desc += "       \($0.key): \($0.value) \r\n"}
        }
        desc += "   Timeout Interval: \(self.timeoutInterval)"
        
        return desc
    }
}

extension String {
    
    /// Validates whether given String is a valid URL or not
    var isValidUrl: Bool {
        let types: NSTextCheckingResult.CheckingType = [.link]
        let detector = try? NSDataDetector(types: types.rawValue)
        guard (detector != nil && self.count > 0) else { return false }
        if detector!.numberOfMatches(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.count)) > 0 {
            return true
        }
        return false
    }
}

