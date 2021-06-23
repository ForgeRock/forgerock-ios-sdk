// 
//  WebAuthnError.swift
//  FRAuth
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore

///
/// WebAuthnError represents an error captured by FRAuth SDK for WebAuthn related operation
///
public enum WebAuthnError: FRError {
    case badData
    case badOperation
    case invalidState
    case constraint
    case cancelled
    case timeout
    case notAllowed
    case unsupported
    case unknown
}


extension WebAuthnError {
    
    /// Converts WebAuthnError to matching type of AM's Error enum
    /// - Returns: String value of matching error type in AM
    func convertToAMErrorType() -> String {
        switch self {
        case .badData:
            return "DataError"
        case .badOperation:
            return "UnknownError"
        case .invalidState:
            return "InvalidStateError"
        case .constraint:
            return "ConstraintError"
        case .cancelled:
            return "UnknownError"
        case .timeout:
            return "TimeoutError"
        case .notAllowed:
            return "NotAllowedError"
        case .unsupported:
            return "NotSupportedError"
        case .unknown:
            return "UnknownError"
        }
    }
}


public extension WebAuthnError {
    
    /// Unique error code for given error
    var code: Int {
        return self.parseErrorCode()
    }
    
    /// Parses WebAuthnError value into integer error code
    ///
    /// - Returns: Int value of unique error code
    func parseErrorCode() -> Int {
        switch self {
        case .badData:
            return 1600001
        case .badOperation:
            return 1600002
        case .invalidState:
            return 1600003
        case .constraint:
            return 1600004
        case .cancelled:
            return 1600005
        case .timeout:
            return 1600006
        case .notAllowed:
            return 1600007
        case .unsupported:
            return 1600008
        case .unknown:
            return 1600099
        }
    }
    
    /// Converts WebAuthnError into String representation of error that can be used as WebAuthn outcome in WebAuthn HiddenValueCallback
    /// - Returns: String value of WebAuthn error outcome
    func convertToWebAuthnOutcome() -> String {
        switch self {
        case .unsupported:
            return "unsupported"
        default:
            return "ERROR::" + self.convertToAMErrorType() + ":"
        }
    }
}


// MARK: - CustomNSError protocols
extension WebAuthnError: CustomNSError {
    
    /// An error domain for WebAuthnError
    public static var errorDomain: String { return "com.forgerock.ios.frauth.webauthn" }
    
    /// Error codes for each error enum
    public var errorCode: Int {
        return self.parseErrorCode()
    }
    
    /// Error UserInfo
    public var errorUserInfo: [String : Any] {
        switch self {
        case .badData:
            return [NSLocalizedDescriptionKey: "Provided data is inadequate"]
        case .badOperation:
            return [NSLocalizedDescriptionKey: "The operation failed for operation-specific reason"]
        case .invalidState:
            return [NSLocalizedDescriptionKey: "The object is in an invalid state"]
        case .constraint:
            return [NSLocalizedDescriptionKey: "A mutation operation in a transaction failed because a constraint was not satisfied"]
        case .cancelled:
            return [NSLocalizedDescriptionKey: "The operation is cancelled"]
        case .timeout:
            return [NSLocalizedDescriptionKey: "The operation timed out"]
        case .notAllowed:
            return [NSLocalizedDescriptionKey: "The request is not allowed by the user agent or the platform in the current context"]
        case .unsupported:
            return [NSLocalizedDescriptionKey: "The operation is not supported"]
        case .unknown:
            return [NSLocalizedDescriptionKey: "The operation failed for an unknown reason"]
        }
    }
}

extension WAKError {
    func convert() -> WebAuthnError {
        switch self {
        case .badData:
            return WebAuthnError.badData
        case .badOperation:
            return WebAuthnError.badOperation
        case .invalidState:
            return WebAuthnError.invalidState
        case .constraint:
            return WebAuthnError.constraint
        case .cancelled:
            return WebAuthnError.cancelled
        case .timeout:
            return WebAuthnError.timeout
        case .notAllowed:
            return WebAuthnError.notAllowed
        case .unsupported:
            return WebAuthnError.unsupported
        case .unknown:
            return WebAuthnError.unknown
        }
    }
}
