// 
//  CryptoError.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore


/// CryptoError represents an error captured or created by FRAuthenticator SDK for any operation related to cryptographic process; such as HMAC, base64 encoding/decoding, and etc
///
public enum CryptoError: FRError {
    case invalidParam(String)
    case failToConvertData
    case invalidJWT
    case unsupportedJWTType
}


public extension CryptoError {
    
    /// Unique error code for given error
    var code: Int {
        return self.parseErrorCode()
    }
    
    /// Parses CryptoError value into integer error code
    ///
    /// - Returns: Int value of unique error code
    func parseErrorCode() -> Int {
        switch self {
        case .invalidParam:
            return 1200000
        case .failToConvertData:
            return 1200001
        case .invalidJWT:
            return 1200002
        case .unsupportedJWTType:
            return 1200003
        }
    }
}


// MARK: - CustomNSError protocols
extension CryptoError: CustomNSError {
    
    /// An error domain for CryptoError
    public static var errorDomain: String { return "com.forgerock.ios.frauthenticator.crypto" }
    
    /// Error codes for each error enum
    public var errorCode: Int {
        return self.parseErrorCode()
    }
    
    /// Error UserInfo
    public var errorUserInfo: [String : Any] {
        switch self {
        case .invalidParam(let message):
            return [NSLocalizedDescriptionKey: "Invalid or fail to decode parameters: \(message)"]
        case .failToConvertData:
            return [NSLocalizedDescriptionKey: "Failed to convert given data"]
        case .invalidJWT:
            return [NSLocalizedDescriptionKey: "Given JWT is invalid"]
        case .unsupportedJWTType:
            return [NSLocalizedDescriptionKey: "Given JWT type is not supported"]
        }
    }
}
