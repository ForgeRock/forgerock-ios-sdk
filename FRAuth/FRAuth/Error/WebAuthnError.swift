// 
//  WebAuthnError.swift
//  FRAuth
//
//  Copyright (c) 2021-2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore

///
/// WebAuthnError represents an error captured by FRAuth SDK for WebAuthn related operation
///

public enum WebAuthnError: Error {
    case badData(platformError: Error?, message: String?)
    case badOperation(platformError: Error?, message: String?)
    case invalidState(platformError: Error?, message: String?)
    case constraint(platformError: Error?, message: String?)
    case cancelled(platformError: Error?, message: String?)
    case timeout(platformError: Error?, message: String?)
    case notAllowed(platformError: Error?, message: String?)
    case unsupported(platformError: Error?, message: String?)
    case unknown(platformError: Error?, message: String?)
    
    public func platformError() -> Error? {
        switch self {
        case .badData(platformError: let platformError, message: _),
                .badOperation(platformError: let platformError, message: _),
                .invalidState(platformError: let platformError, message: _),
                .constraint(platformError: let platformError, message: _),
                .cancelled(platformError: let platformError, message: _),
                .timeout(platformError: let platformError, message: _),
                .notAllowed(platformError: let platformError, message: _),
                .unsupported(platformError: let platformError, message: _),
                .unknown(platformError: let platformError, message: _):
            return platformError
        }
    }
    
    public func message() -> String? {
        switch self {
        case .badData(platformError: _, message: let message),
                .badOperation(platformError: _, message: let message),
                .invalidState(platformError: _, message: let message),
                .constraint(platformError: _, message: let message),
                .cancelled(platformError: _, message: let message),
                .timeout(platformError: _, message: let message),
                .notAllowed(platformError: _, message: let message),
                .unsupported(platformError: _, message: let message),
                .unknown(platformError: _, message: let message):
            return message
        }
    }
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
    
    func extractErrorDescription() -> String? {
        if let nsError = self.platformError() as? NSError {
            return (nsError.userInfo["NSDebugDescription"] as? String) ?? nsError.localizedDescription
        } else if let errorDescription = self.message() {
            return errorDescription
        } else {
            return nil
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
            return "ERROR::" + self.convertToAMErrorType() + ":" + (self.extractErrorDescription() ?? "")
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

extension FRWAKError {
    func convert() -> WebAuthnError {
        switch self {
        case .badData:
            return WebAuthnError.badData(platformError: self.platformError(), message: self.message())
        case .badOperation:
            return WebAuthnError.badOperation(platformError: self.platformError(), message: self.message())
        case .invalidState:
            return WebAuthnError.invalidState(platformError: self.platformError(), message: self.message())
        case .constraint:
            return WebAuthnError.constraint(platformError: self.platformError(), message: self.message())
        case .cancelled:
            return WebAuthnError.cancelled(platformError: self.platformError(), message: self.message())
        case .timeout:
            return WebAuthnError.timeout(platformError: self.platformError(), message: self.message())
        case .notAllowed:
            return WebAuthnError.notAllowed(platformError: self.platformError(), message: self.message())
        case .unsupported:
            return WebAuthnError.unsupported(platformError: self.platformError(), message: self.message())
        case .unknown:
            return WebAuthnError.unknown(platformError: self.platformError(), message: self.message())
        }
    }
}
