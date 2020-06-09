//
//  Request.swift
//  FRCore
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/**
 Generic representation of API request specifically designed by, and used by ForgeRock iOS SDK core
 */
public struct Request {
    
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
    public let url: String
    /// HTTP Method as String
    public let method: HTTPMethod
    /// HTTP request headers as dictionary
    private(set) public var headers: [String: String]
    /// HTTP body parameters as dictionary
    public let bodyParams: [String: Any]
    /// URL parameters as dictionary
    public let urlParams: [String: String]
    /// Response type as `ContentType`; "Accept" header will be automatically added
    public let responseType: ContentType
    /// Request type as `ContentType`; "Content-type" header will be automatically added
    public let requestType: ContentType
    /// Request timeout interval in second
    public let timeoutInterval: Double
    
    
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
    public init(url: String, method: HTTPMethod, headers: [String: String] = [:], bodyParams: [String: Any] = [:], urlParams: [String: String] = [:], requestType: ContentType = .json, responseType: ContentType = .json, timeoutInterval: Double = 60) {
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
    
    /// Updates and merges HTTP header with new header values
    /// - Parameter headers: merged HTTP header dictionary
    public mutating func updateHeader(headers: [String: String]) {
        self.headers.merge(headers) { (_, new) in new }
    }
    
    
    /// Builds `URLRequest` object based on `Request` instance
    ///
    /// - Returns: URLRequest object if `Request` object was valid; otherwise `nil` is returned
    public func build() -> URLRequest? {
        
        //  Validate URL is valid
        guard var urlComponents = URLComponents(string: self.url), self.url.isValidUrl else {
            Log.e("Missing or invalid URL; request will fail: \(self.url)")
            return nil
        }

        if self.urlParams.count > 0 {
            //  Build URL Parameters
            urlComponents.queryItems = self.urlParams.map{ URLQueryItem(name: $0.key, value: $0.value)}
        }
        
        //  Make sure that URL can be constructed with URL string, and URL parameters
        guard let thisUrl = urlComponents.url else {
            Log.e("Failed to generate URL with URL parameter; request will fail: \(self.url) | \(self.urlParams)")
            return nil
        }
        
        //  Build `URLRequest` object with constructed URL object
        let thisRequest = NSMutableURLRequest(url: thisUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: self.timeoutInterval)
        //  Set HTTP method
        thisRequest.httpMethod = self.method.rawValue
               
        //  Set Content-Type, and Accept headers based on request/response types
        thisRequest.setValue(self.requestType.rawValue, forHTTPHeaderField: "Content-Type")
        thisRequest.setValue(self.responseType.rawValue, forHTTPHeaderField: "Accept")
        
        //  Add additional headers
        self.headers.forEach{ thisRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
        //  Build http body content
        // TODO: dynamically handle more content-type
        if self.bodyParams.keys.count > 0 {
            if ![HTTPMethod.DELETE, HTTPMethod.GET].contains(method) {
                if requestType == .json {
                    do {
                        thisRequest.httpBody = try JSONSerialization.data(withJSONObject: self.bodyParams, options: [])
                    }
                    catch {
                        Log.e("Failed to serialize HTTP Body: \(self.bodyParams)")
                    }
                }
                else if requestType == .urlEncoded {
                    let urlEncoded = bodyParams.map{ "\($0)=\($1)" }.joined(separator: "&")
                    thisRequest.httpBody = Data(urlEncoded.utf8)
                }
            }
            else {
                Log.w("Ignoring body parameters for GET/DELETE request; \(self.bodyParams)")
            }
        }
        
        let debugDesc = "\n**URLRequest built**\nURLRequest: URL: [\(thisRequest.httpMethod)] \(thisRequest.url?.absoluteString ?? "")\nHeaders: \(String(describing: thisRequest.allHTTPHeaderFields))\nBody: \(String(describing: String(data: thisRequest.httpBody ?? Data(), encoding: .utf8)))\nTimeout: \(thisRequest.timeoutInterval)"
        Log.v(debugDesc)
        
        //  Return URLRequest
        return thisRequest as URLRequest
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
    public var isValidUrl: Bool {
        let types: NSTextCheckingResult.CheckingType = [.link]
        let detector = try? NSDataDetector(types: types.rawValue)
        guard (detector != nil && self.count > 0) else { return false }
        if detector!.numberOfMatches(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.count)) > 0 {
            return true
        }
        return false
    }
}

