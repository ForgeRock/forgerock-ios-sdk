// 
//  OathError.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore


/// OathError represents an error captured by FRAuthenticator SDK for any operations related to Oath
///
/// - invalidQRCode: Fail to parse or validate given secret
public enum OathError: FRError {
    case invalidSecret
}


public extension OathError {
    
    /// Unique error code for given error
    var code: Int {
        return self.parseErrorCode()
    }
    
    /// Parses OathError value into integer error code
    ///
    /// - Returns: Int value of unique error code
    func parseErrorCode() -> Int {
        switch self {
        case .invalidSecret:
            return 9000000
        }
    }
}


// MARK: - CustomNSError protocols
extension OathError: CustomNSError {
    
    /// An error domain for OathError
    public static var errorDomain: String { return "com.forgerock.ios.frauthenticator.oath" }
    
    /// Error codes for each error enum
    public var errorCode: Int {
        return self.parseErrorCode()
    }
    
    /// Error UserInfo
    public var errorUserInfo: [String : Any] {
        switch self {
        case .invalidSecret:
            return [NSLocalizedDescriptionKey: "Invalid secret value; failed to parse secret"]
        }
    }
}
