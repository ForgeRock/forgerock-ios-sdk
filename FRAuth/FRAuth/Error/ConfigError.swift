//
//  ConfigError.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRCore


/// ConfigError represents an error captured by FRAuth SDK for missing or invalid configuration
///
/// - emptyConfiguration: Empty configuration is provided for initialization
/// - invalidConfiguration: Missing or invalid configuration is provided
/// - invalidAccessGroup: Invalid Access Group; given Access Group is not accessible with Keychain Service
/// - invalidSDKState: Invalid SDK state; SDK may need to be initialized before performing certain action
public enum ConfigError: FRError {
    case emptyConfiguration
    case invalidConfiguration(String)
    case invalidAccessGroup(String)
    case invalidSDKState
}

public extension ConfigError {
    
    /// Unique error code for given error
    var code: Int {
        return self.parseErrorCode()
    }
    
    /// Parses ConfigError value into integer error code
    ///
    /// - Returns: Int value of unique error code
    func parseErrorCode() -> Int {
        switch self {
        case .emptyConfiguration:
            return 2000000
        case .invalidConfiguration:
            return 2000001
        case .invalidAccessGroup:
            return 2000002
        case .invalidSDKState:
            return 2000003
        }
    }
}

// MARK: - CustomNSError protocols
extension ConfigError: CustomNSError {
    
    /// An error domain for ConfigError
    public static var errorDomain: String { return "com.forgerock.ios.frauth.configuration" }
    
    /// Error codes for each error enum
    public var errorCode: Int {
        return self.parseErrorCode()
    }
    
    /// Error UserInfo
    public var errorUserInfo: [String : Any] {
        switch self {
        case .emptyConfiguration:
            return [NSLocalizedDescriptionKey: "Invalid configuration: configuration Dictionary is empty or 'server'/'oauth' section is missing"]
        case .invalidConfiguration(let errorMessage):
            return [NSLocalizedDescriptionKey: "Invalid configuration: " + errorMessage]
        case .invalidAccessGroup(let accessGroup):
            return [NSLocalizedDescriptionKey: "Invalid access group: \(accessGroup). Unable to access Keychain Service with given Access group. Validate Access Group with Keychain Group Identifier defined in XCode's Capabilities tab."]
        case .invalidSDKState:
            return [NSLocalizedDescriptionKey: "Invalid SDK State: initialize SDK using FRAuth.start() first"]
        }
    }
}


