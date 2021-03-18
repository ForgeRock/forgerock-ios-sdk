// 
//  SocialLoginError.swift
//  FRAuth
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRCore

public enum SocialLoginError: FRError {
    case notSupported(String)
    case unsupportedCredentials(String)
    case cancelled
    case missingIdPHandler
}

public extension SocialLoginError {
    
    /// Unique error code for given error
    var code: Int {
        return self.parseErrorCode()
    }
    
    /// Parses SocialLoginError value into integer error code
    ///
    /// - Returns: Int value of unique error code
    func parseErrorCode() -> Int {
        switch self {
        case .notSupported:
            return 1600000
        case .unsupportedCredentials:
            return 1600001
        case .cancelled:
            return 1600002
        case .missingIdPHandler:
            return 1600003
        }
    }
}

// MARK: - CustomNSError protocols
extension SocialLoginError: CustomNSError {
    
    /// An error domain for OAuth2Error
    public static var errorDomain: String { return "com.forgerock.ios.frauth.sociallogin" }
    
    /// Error codes for each error enum
    public var errorCode: Int {
        return self.parseErrorCode()
    }
    
    /// Error UserInfo
    public var errorUserInfo: [String : Any] {
        switch self {
        case .notSupported(let message):
            return [NSLocalizedDescriptionKey: "Selected Social Login Provider is not supported: \(message)"]
        case .unsupportedCredentials(let message):
            return [NSLocalizedDescriptionKey: "Returned credentials is not supported: \(message)"]
        case .cancelled:
            return [NSLocalizedDescriptionKey: "Operation is cancelled"]
        case .missingIdPHandler:
            return [NSLocalizedDescriptionKey: "IdPHandler is missing; the given provider does not match with any of default IdPHandler implementation"]
        }
    }
}
