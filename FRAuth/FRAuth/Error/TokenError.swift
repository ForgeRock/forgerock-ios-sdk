//
//  TokenRefreshError.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRCore


/// ConfigError represents an error captured by FRAuth SDK for invalid operation related to Token with given state
///
/// - failToParseToken: Failed to parse token from secure storage
/// - nullRefreshToken: Missing refresh_token while it's required
/// - nullToken: Missing token value while it's required
public enum TokenError: FRError {
    case failToParseToken(String)
    case nullRefreshToken
    case nullToken
}

public extension TokenError {
    
    /// Unique error code for given error
    var code: Int {
        return self.parseErrorCode()
    }
    
    /// Parses TokenError value into integer error code
    ///
    /// - Returns: Int value of unique error code
    func parseErrorCode() -> Int {
        switch self {
        case .failToParseToken:
            return 3000000
        case .nullRefreshToken:
            return 3000001
        case .nullToken:
            return 3000002
        }
    }
}

// MARK: - CustomNSError protocols
extension TokenError: CustomNSError {
    
    /// An error domain for TokenError
    public static var errorDomain: String { return "com.forgerock.ios.frauth.token" }
    
    /// Error codes for each error enum
    public var errorCode: Int {
        return self.parseErrorCode()
    }
    
    /// Error UserInfo
    public var errorUserInfo: [String : Any] {
        switch self {
        case .failToParseToken(let error):
            return [NSLocalizedDescriptionKey: "Failed to persist Token: \((error))"]
        case .nullRefreshToken:
            return [NSLocalizedDescriptionKey: "Invalid refresh_token: refresh_token is not found"]
        case .nullToken:
            return [NSLocalizedDescriptionKey: "Invalid token: token is not found"]
        }
    }
}

