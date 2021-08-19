// 
//  FRJSONEncoder.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 - 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation


/// FRJSONEncoder class is a helper class that is responsible to help JSON encoding operation using JSONEncoder
class FRJSONEncoder: JSONEncoder {
    
    /// shared instance of FRAPushHandler
    static var shared: FRJSONEncoder = FRJSONEncoder()
    
    public func encodeToString<T: Encodable>(value: T) throws -> String {
        return try Base64Utils.base64EncodeURLSafe(data: try super.encode(value))
    }
    
    
    /// Convert Dictionary to JSON string
    /// - Throws: exception if dictionary cannot be converted to JSON data or when data cannot be converted to UTF8 string
    /// - Returns: JSON string
    static func dictionaryToJsonString(dictionary: [String: Any]) -> String? {
        if let theJSONData = try?  JSONSerialization.data(withJSONObject: dictionary),
           let jsonString = String(data: theJSONData, encoding: String.Encoding.utf8) {
            return jsonString
          }

        return nil
    }
    
    
    /// Convert  JSON string to Dictionary
    /// - Throws: exception if JSON string cannot be converted to dictionary
    /// - Returns: Dictionary
    static func jsonStringToDictionary(jsonString: String) -> [String:AnyObject]? {
        if let data = jsonString.data(using: .utf8) {
           do {
               let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
               return json
           } catch {
               return nil
           }
        }
        return nil
    }
    
}
