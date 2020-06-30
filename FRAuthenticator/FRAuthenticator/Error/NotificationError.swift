// 
//  NotificationError.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore


/// NotificationError represents an error captured by FRAuthenticator SDK for any operation related to Notification
///
/// - invalidPayload: Given payload contains invalid information to construct Notification object
public enum NotificationError: FRError {
    case invalidPayload(String)
}


public extension NotificationError {
    
    /// Unique error code for given error
    var code: Int {
        return self.parseErrorCode()
    }
    
    /// Parses NotificationError value into integer error code
    ///
    /// - Returns: Int value of unique error code
    func parseErrorCode() -> Int {
        switch self {
        case .invalidPayload:
            return 7000000
        }
    }
}


// MARK: - CustomNSError protocols
extension NotificationError: CustomNSError {
    
    /// An error domain for NotificationError
    public static var errorDomain: String { return "com.forgerock.ios.frauthenticator.notification" }
    
    /// Error codes for each error enum
    public var errorCode: Int {
        return self.parseErrorCode()
    }
    
    /// Error UserInfo
    public var errorUserInfo: [String : Any] {
        switch self {
        case .invalidPayload(let param):
            return [NSLocalizedDescriptionKey: "Invalid notification payload: \(param)"]
        }
    }
}
