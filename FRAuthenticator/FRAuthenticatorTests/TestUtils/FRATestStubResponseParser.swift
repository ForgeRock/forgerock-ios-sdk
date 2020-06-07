//
//  FRATestStubResponseParser.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

@objc
class FRATestStubResponseParser: NSObject {
    
    var jsonContent: [String: Any]
    
    @objc public var responsePayload: Data?
    @objc public var response: URLResponse?
    @objc public var error: Error?
    @objc public var redirectRequest: URLRequest?
    
    @objc init? ( _ fileName: String) {
        guard let json = FRATestStubResponseParser.readResponseJSON(fileName: fileName) else {
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
            self.response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: httpVersion, headerFields: headerFields)
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
        
        if let jsonPath = Bundle(for: FRATestStubResponseParser.self).path(forResource: fileName, ofType: "json"),
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
}
