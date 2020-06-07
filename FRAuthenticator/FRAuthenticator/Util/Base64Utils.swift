// 
//  Base64Utils.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// Base64Utils is a set of methods to help base64 encoding/decoding operations
struct Base64Utils {
    
    /// Encodes given data using base64 into URL safe encoded string
    /// - Parameter data: Data object to be encoded
    /// - Throws: CryptoError
    /// - Returns: Base64 URL safe encoded string
    static func base64EncodeURLSafe(data: Data) throws -> String {
        let encoded = data.base64EncodedData()
        guard let encodedStr = String(data: encoded, encoding: .utf8) else {
            FRALog.e("Failed to convert given data to base64 encoded string")
            throw CryptoError.failToConvertData
        }
        
        return encodedStr.urlSafeEncoding()
    }
}
