// 
//  AccountError.swift
//  FRAuthenticator
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore


/// AccountError represents an error captured by FRAuthenticator SDK for any operations related to Account class
///
/// - accountLocked: Operation cannot be completed, Account is locked
/// - failToLockMissingPolicyName: Missing or invalid name for the given Policy
/// - failToLockInvalidPolicy: Given policy was not attached during Account registration.
/// - failToLockAccountAlreadyLocked: Given Account is already locked
/// - failToUnlockAccountNotLocked: Given Account is not locked
/// - failToRegisterPolicyViolation: Account cannot be registered on the device due to policy violation
public enum AccountError: FRError {
    case accountLocked(String)
    case failToLockMissingPolicyName
    case failToLockInvalidPolicy
    case failToLockAccountAlreadyLocked
    case failToUnlockAccountNotLocked
    case failToRegisterPolicyViolation(String)
}


public extension AccountError {
    
    /// Unique error code for given error
    var code: Int {
        return self.parseErrorCode()
    }
    
    /// Parses AccountError value into integer error code
    ///
    /// - Returns: Int value of unique error code
    func parseErrorCode() -> Int {
        switch self {
        case .accountLocked:
            return 6100000
        case .failToLockMissingPolicyName:
            return 6100001
        case .failToLockInvalidPolicy:
            return 6100002
        case .failToLockAccountAlreadyLocked:
            return 6100003
        case .failToUnlockAccountNotLocked:
            return 6100004
        case .failToRegisterPolicyViolation:
            return 6100005
        }
    }
}


// MARK: - CustomNSError protocols
extension AccountError: CustomNSError {
    
    /// An error domain for AccountError
    public static var errorDomain: String { return "com.forgerock.ios.frauthenticator.account" }
    
    /// Error codes for each error enum
    public var errorCode: Int {
        return self.parseErrorCode()
    }
    
    /// Error UserInfo
    public var errorUserInfo: [String : Any] {
        switch self {
        case .accountLocked(let param):
            return [NSLocalizedDescriptionKey: "This account is locked. It violates the following policy: (\(param))"]
        case .failToLockMissingPolicyName:
            return [NSLocalizedDescriptionKey: "The policy name is required"]
        case .failToLockInvalidPolicy:
            return [NSLocalizedDescriptionKey: "The given policy was not attached during Account registration."]
        case .failToRegisterPolicyViolation(let param):
            return [NSLocalizedDescriptionKey: "This account cannot be registered on this device. It violates the following policy: (\(param))"]
        case .failToUnlockAccountNotLocked:
            return [NSLocalizedDescriptionKey: "Account is not locked"]
        case .failToLockAccountAlreadyLocked:
            return [NSLocalizedDescriptionKey: "Account is already locked"]
        }
    }
}

