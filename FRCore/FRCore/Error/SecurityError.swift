// 
//  SecurityError.swift
//  FRCore
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// SecurityError represents an error captured by FRCore SDK's security operations
public enum SecurityError: FRError {
    case failToExtractPublicKey
}


extension SecurityError {
    
    /// Unique error code for given error
    var code: Int {
        return self.parseErrorCode()
    }
    
    /// Parses SecurityError value into integer error code
    ///
    /// - Returns: Int value of unique error code
    func parseErrorCode() -> Int {
        switch self {
        case .failToExtractPublicKey:
            return 5100001
        }
    }
}


// MARK: - CustomNSError protocols
extension SecurityError: CustomNSError {
    
    /// An error domain for SecurityError
    public static var errorDomain: String { return "com.forgerock.ios.frcore.security" }
    
    /// Error codes for each error enum
    public var errorCode: Int {
        return self.parseErrorCode()
    }
    
    /// Error UserInfo
    public var errorUserInfo: [String : Any] {
        switch self {
        case .failToExtractPublicKey:
            return [NSLocalizedDescriptionKey: "Failed to extract Public Key representation into bytes array"]
        }
    }
}
