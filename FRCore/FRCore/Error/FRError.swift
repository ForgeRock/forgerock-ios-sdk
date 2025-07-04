//
//  FRError.swift
//  FRCore
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// This protocol is a base representation of Error object generated by FRAuth framework
public protocol FRError: Error {
}

extension FRError {
    
    /// Builds Dictionary for NSError
    ///
    /// - Parameters:
    ///   - errorMessage: Error message for NSError's localized error description
    ///   - additionalInfo: Additional information about the error (error response payload) as Dictionary with key 'com.forgerock.auth.errorInfoKey'
    /// - Returns: Dictionary containing a localized error message and optional additional error payload
    public func buildErrorUserInfo(errorMessage: String, additionalInfo: [String: Any]? ) -> [String: Any] {
        var userInfo: [String: Any] = [:]
        userInfo[NSLocalizedDescriptionKey] = errorMessage
        
        if let additionalInfo = additionalInfo {
            userInfo["com.forgerock.auth.errorInfoKey"] = additionalInfo
        }
        
        return userInfo
    }
}
