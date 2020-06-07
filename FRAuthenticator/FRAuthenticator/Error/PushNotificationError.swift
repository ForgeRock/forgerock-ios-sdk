// 
//  PushNotificationError.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore


/// PushNotificationError represents an error captured or created by FRAuthenticator SDK for any operation related to Push Notification registration / authentication process
///
/// - missingDeviceToken: Device Token to be used for push registration is missing
public enum PushNotificationError: FRError {
    case missingDeviceToken
    case notificationInvalidStatus
    case storageError(String)
}


public extension PushNotificationError {
    
    /// Unique error code for given error
    var code: Int {
        return self.parseErrorCode()
    }
    
    /// Parses PushNotificationError value into integer error code
    ///
    /// - Returns: Int value of unique error code
    func parseErrorCode() -> Int {
        switch self {
        case .missingDeviceToken:
            return 1100000
        case .notificationInvalidStatus:
            return 1100001
        case .storageError:
            return 1100002
        }
    }
}


// MARK: - CustomNSError protocols
extension PushNotificationError: CustomNSError {
    
    /// An error domain for PushNotificationError
    public static var errorDomain: String { return "com.forgerock.ios.frauthenticator.pushnotification" }
    
    /// Error codes for each error enum
    public var errorCode: Int {
        return self.parseErrorCode()
    }
    
    /// Error UserInfo
    public var errorUserInfo: [String : Any] {
        switch self {
        case .missingDeviceToken:
            return [NSLocalizedDescriptionKey: "Device Token for Push Notification is missing"]
        case .notificationInvalidStatus:
            return [NSLocalizedDescriptionKey: "PushNotification is not in a valid status to authenticate; either PushNotification has already been authenticated or expired"]
        case .storageError(let message):
            return [NSLocalizedDescriptionKey: "Storage error: \(message)"]
        }
    }
}
