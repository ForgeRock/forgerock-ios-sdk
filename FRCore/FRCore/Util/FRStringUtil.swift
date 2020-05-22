// 
//  String+FRCore.swift
//  FRCore
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

//  String class extension for FRCore utilities
extension String {
    
    /// Encodes current String into Base64 encoded string
    public func base64Encoded() -> String? {
        return data(using: .utf8)?.base64EncodedString()
    }

    
    public func base64URLSafeEncoded() -> String? {
        return data(using: .utf8)?.base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
    
    
    /// Decodes current Base64 encoded string
    public func base64Decoded() -> String? {
        let padded = self.base64Pad()
        guard let data = Data(base64Encoded: padded) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    
    /// Validates whether current String is base64 encoded or not
    public func isBase64Encoded() -> Bool {
        if let _ = Data(base64Encoded: self) {
            return true
        }
        else {
            return false
        }
    }
    
    
    public func decodeURL() -> Data? {
        let fixed = self.urlSafeDecoding()
        return fixed.decodeBase64()
    }
    
    
    public func base64Pad() -> String {
        return self.padding(toLength: ((self.count+3)/4)*4, withPad: "=", startingAt: 0)
    }
    
    
    public func decodeBase64() -> Data? {
        let padded = self.base64Pad()
        let encodedData = Data(base64Encoded: padded)
        return encodedData
    }
    
    
    public func urlSafeDecoding() -> String {
        let str = self.replacingOccurrences(of: "-", with: "+")
        return str.replacingOccurrences(of: "_", with: "/")
    }
    
    
    public func urlSafeEncoding() -> String {
        return self.replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
}
