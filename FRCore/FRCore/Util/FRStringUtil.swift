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
    /// - Returns: Base64 encoded string
    public func base64Encoded() -> String? {
        return data(using: .utf8)?.base64EncodedString()
    }

    
    /// Decodes current String into Base64 decoded string
    /// - Returns: Base64 decoded string
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
        return false
    }
    
    
    /// Decodes URL string
    /// - Returns: URL safe decoded bytes array
    public func decodeURL() -> Data? {
        let fixed = self.urlSafeDecoding()
        return fixed.decodeBase64()
    }
    
    
    /// Adds base64 pad
    /// - Returns: Base64 pad added string
    public func base64Pad() -> String {
        return self.padding(toLength: ((self.count+3)/4)*4, withPad: "=", startingAt: 0)
    }
    
    
    /// Decodes base64 and converts it into bytes array
    /// - Returns: Base64 decoded bytes array
    public func decodeBase64() -> Data? {
        let padded = self.base64Pad()
        let encodedData = Data(base64Encoded: padded)
        return encodedData
    }
    
    
    /// Converts String to URL safe decoded string
    /// - Returns: URL safe decoded string
    public func urlSafeDecoding() -> String {
        let str = self.replacingOccurrences(of: "-", with: "+")
        return str.replacingOccurrences(of: "_", with: "/")
    }
    
    
    /// Converts String to URL safe encoded string
    /// - Returns: URL safe encoded string
    public func urlSafeEncoding() -> String {
        return self.replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
    
    
    /// Converts String to bytes array
    public var bytes: Array<UInt8> {
        return data(using: String.Encoding.utf8, allowLossyConversion: true)?.bytes ?? Array(utf8)
    }

    
    /// Converts String to SHA256 bytes array
    public var sha256: Data? {
        let data = self.data(using: .utf8)
        return data?.sha256
    }
    
    
    /// Extracts Recovery Codes from HTML scripts from AM's Display Recovery Code Node
    /// - Returns: An array of strings for recovery codes
    public func extractRecoveryCodes() -> [String]? {
        if let regex = try? NSRegularExpression(pattern: "\\s[\\w\\W]\"([\\w]*)\\\\", options: []) {
            var results = [String]()
            regex.enumerateMatches(in: self, options: [], range: NSMakeRange(0, self.utf16.count)) { result, flags, stop in
                if let r = result?.range(at: 1), let range = Range(r, in: self) {
                    results.append(String(self[range]))
                }
            }
            return (results.count > 0) ? results : nil
        }
        else {
            return nil
        }
    }
}


extension StringProtocol {
    public var hexData: Data { .init(hex) }
    public var hexBytes: [UInt8] { .init(hex) }
    private var hex: UnfoldSequence<UInt8, Index> {
        sequence(state: startIndex) { startIndex in
            guard startIndex < self.endIndex else { return nil }
            let endIndex = self.index(startIndex, offsetBy: 2, limitedBy: self.endIndex) ?? self.endIndex
            defer { startIndex = endIndex }
            return UInt8(self[startIndex..<endIndex], radix: 16)
        }
    }
}
