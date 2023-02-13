// 
//  FRAError.swift
//  FRAuthenticator
//
//  Copyright (c) 2020-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore

/// FRAError represents an error captured by FRAuthenticator SDK for any operation related to FRAuthenticator class
///
/// - invalidStateForChangingStorage: Storage Client is being set after SDK initialization which is prohibited
public enum FRAError: FRError {
    case invalidStateForChangingStorage
    case failToSaveIntoStorageClient(String)
    case invalidStateForChangingPolicyEvaluator
    case invalidPolicyRegisteredWithPolicyEvaluator(String)
}


public extension FRAError {
    
    /// Unique error code for given error
    var code: Int {
        return self.parseErrorCode()
    }
    
    /// Parses FRAError value into integer error code
    ///
    /// - Returns: Int value of unique error code
    func parseErrorCode() -> Int {
        switch self {
        case .invalidStateForChangingStorage:
            return 8000000
        case .failToSaveIntoStorageClient:
            return 8000001
        case .invalidStateForChangingPolicyEvaluator:
            return 8000002
        case .invalidPolicyRegisteredWithPolicyEvaluator:
            return 8000003
        }
    }
}


// MARK: - CustomNSError protocols
extension FRAError: CustomNSError {
    
    /// An error domain for FRAError
    public static var errorDomain: String { return "com.forgerock.ios.frauthenticator.fra" }
    
    /// Error codes for each error enum
    public var errorCode: Int {
        return self.parseErrorCode()
    }
    
    /// Error UserInfo
    public var errorUserInfo: [String : Any] {
        switch self {
        case .invalidStateForChangingStorage:
            return [NSLocalizedDescriptionKey: "SDK has already started; StorageClient cannot be changed after initialization"]
        case .failToSaveIntoStorageClient(let message):
            return [NSLocalizedDescriptionKey: "Failed to save data into StorageClient: \(message)"]
        case .invalidStateForChangingPolicyEvaluator:
            return [NSLocalizedDescriptionKey: "SDK has already started; FRAPolicyEvaluator cannot be changed after initialization"]
        case .invalidPolicyRegisteredWithPolicyEvaluator(let policy):
            return [NSLocalizedDescriptionKey: "Failed to register the policy: \(policy). The policy name cannot be null or empty."]
        }
    }
}

