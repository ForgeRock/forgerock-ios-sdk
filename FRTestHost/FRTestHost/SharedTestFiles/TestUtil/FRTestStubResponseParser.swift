//
//  FRTestStubResponseParser.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

@objc
class FRTestStubResponseParser: NSObject {
    
    var jsonContent: [String: Any]
    
    @objc public var responsePayload: Data?
    @objc public var response: URLResponse?
    @objc public var error: Error?
    @objc public var redirectRequest: URLRequest?
    
    @objc init? ( _ fileName: String, _ baseUrl: String? = nil) {
        guard let json = FRTestStubResponseParser.readResponseJSON(fileName: fileName) else {
            return nil
        }
        
        self.jsonContent = json
        
        if let responsePayloadJSON = self.jsonContent["responsePayload"] as? [String: Any],
            let jsonData = try? JSONSerialization.data(withJSONObject: responsePayloadJSON, options: .prettyPrinted) {
            self.responsePayload = jsonData
        }
        
        if let responseJSON = self.jsonContent["response"] as? [String: Any],
            let statusCode = responseJSON["statusCode"] as? Int,
            let urlString = responseJSON["url"] as? String,
            let url = URL(string: urlString),
            let headerFields = responseJSON["headerFields"] as? [String: String],
            let httpVersion = responseJSON["httpVersion"] as? String {
            
            if let baseUrl = baseUrl, let configBaseUrl = URL(string: baseUrl), let originalHost = url.host, let configHost = configBaseUrl.host, let newUrl = URL(string: urlString.replacingOccurrences(of: originalHost, with: configHost)) {
                self.response = HTTPURLResponse(url: newUrl, statusCode: statusCode, httpVersion: httpVersion, headerFields: FRTestStubResponseParser.swapCookieDomain(cookieHeaders: headerFields, newUrl: configHost, originalUrl: originalHost))
            }
            else {
                self.response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: httpVersion, headerFields: headerFields)
            }
        }
        
        if let redirectRequest = self.jsonContent["redirectRequest"] as? [String: Any],
            let urlStr = redirectRequest["url"] as? String,
            let url = URL(string: urlStr),
            let timeout = redirectRequest["timeout"] as? Double,
            let headers = redirectRequest["headers"] as? [String: String]{
            
            let request = NSMutableURLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)
            
            for (key, val) in headers {
                request.setValue(val, forHTTPHeaderField: key)
            }
            
            self.redirectRequest = request as URLRequest
        }
    }
    
    static func readResponseJSON(fileName: String) -> [String: Any]? {
        
        if let jsonPath = Bundle(for: FRTestStubResponseParser.self).path(forResource: fileName, ofType: "json"),
            let jsonString = try? String(contentsOfFile: jsonPath),
            let jsonData = jsonString.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [String: Any]
        {
            return json
        }
        else {
            return nil
        }
    }
    
    static func swapCookieDomain(cookieHeaders: [String: String], newUrl: String, originalUrl: String) -> [String: String] {
        var cookieHeaders = cookieHeaders
        if let setCookie = cookieHeaders["Set-Cookie"] {
            cookieHeaders["Set-Cookie"] = setCookie.replacingOccurrences(of: originalUrl, with: newUrl)
        }
        return cookieHeaders
    }
}
