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

    
    /// Decodes current Base64 encoded string
    public func base64Decoded() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
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
}
