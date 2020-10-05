// 
//  BrowserError.swift
//  FRAuth
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore


/// BrowserError represents an error captured by FRAuth SDK for Browser (external user-agent) related operation
///
public enum BrowserError: FRError {
    case externalUserAgentFailure
    case externalUserAgentAuthenticationInProgress
    case externalUserAgentCancelled
    case missingAuthCode
}

public extension BrowserError {
    
    /// Unique error code for given error
    var code: Int {
        return self.parseErrorCode()
    }
    
    /// Parses ConfigError value into integer error code
    ///
    /// - Returns: Int value of unique error code
    func parseErrorCode() -> Int {
        switch self {
        case .externalUserAgentFailure:
            return 1400000
        case .externalUserAgentAuthenticationInProgress:
            return 1400001
        case .externalUserAgentCancelled:
            return 1400002
        case .missingAuthCode:
            return 1400003
        }
    }
}

// MARK: - CustomNSError protocols
extension BrowserError: CustomNSError {
    
    /// An error domain for ConfigError
    public static var errorDomain: String { return "com.forgerock.ios.frauth.browser" }
    
    /// Error codes for each error enum
    public var errorCode: Int {
        return self.parseErrorCode()
    }
    
    /// Error UserInfo
    public var errorUserInfo: [String : Any] {
        switch self {
        case .externalUserAgentFailure:
            return [NSLocalizedDescriptionKey: "Fail to luanch the external user-agent"]
        case .externalUserAgentAuthenticationInProgress:
            return [NSLocalizedDescriptionKey: "External user-agent authentication is currently in progress"]
        case .externalUserAgentCancelled:
            return [NSLocalizedDescriptionKey: "External user-agent authentication is cancelled"]
        case .missingAuthCode:
            return [NSLocalizedDescriptionKey: "redirect_uri is missing authorization_code; cancelling external user-agent flow"]
        }
    }
}


