// 
//  AccountMigrationError.swift
//  FRAuthenticator
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore


/// AccountMigrationError represents an error captured by FRAuthenticator SDK for any operations related to Account Migration
///
/// - invalidScheme: Unsupported scheme
/// - invalidHost: Unsupported host
/// - missingData: Missing `data` parameter
/// - failToDecodeData: Unable to decode data
public enum AccountMigrationError: FRError {
    case invalidScheme
    case invalidHost
    case missingData
    case failToDecodeData
}


public extension AccountMigrationError {
    
    /// Unique error code for given error
    var code: Int {
        return self.parseErrorCode()
    }
    
    /// Parses AccountMigrationError value into integer error code
    ///
    /// - Returns: Int value of unique error code
    func parseErrorCode() -> Int {
        switch self {
        case .invalidScheme:
            return 1500000
        case .invalidHost:
            return 1500001
        case .missingData:
            return 1500002
        case .failToDecodeData:
            return 1500003
        }
    }
}


// MARK: - CustomNSError protocols
extension AccountMigrationError: CustomNSError {
    
    /// An error domain for AccountMigrationError
    public static var errorDomain: String { return "com.forgerock.ios.frauthenticator.accountmigration" }
    
    /// Error codes for each error enum
    public var errorCode: Int {
        return self.parseErrorCode()
    }
    
    /// Error UserInfo
    public var errorUserInfo: [String : Any] {
        switch self {
        case .invalidScheme:
            return [NSLocalizedDescriptionKey: "Invalid schem in url given for Account Migration"]
        case .invalidHost:
            return [NSLocalizedDescriptionKey: "Invalid schem in url given for Account Migration"]
        case .missingData:
            return [NSLocalizedDescriptionKey: "Missing data parameter in url given for Account Migration"]
        case .failToDecodeData:
            return [NSLocalizedDescriptionKey: "failed to decode data parameter avlue in url given for Account Migration"]
        }
    }
}
