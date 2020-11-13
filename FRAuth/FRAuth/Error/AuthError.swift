//
//  AuthError.swift
//  FRAuth
//
//  Copyright (c) 2019-2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRCore


/// AuthError represents an error captured by FRAuth SDK during authentication
///
/// - invalidTokenResponse: Invalid response from OAuth2 protocol for exchanging SSO Token with OAuth2 token set; token response must contain at least followings: access_token, scope, token_type, expires_in
/// - invalidCallbackResponse: Invalid AuthService response for parsing Callback(s)
/// - unsupportedCallback: Invalid AuthService response containing unsupported Callback type(s)
/// - invalidAuthServiceResponse: Invalid AuthService response for missing/invalid authId
/// - invalidOAuth2Client: Invalid AuthService or Node object without OAuth2Client while expecting to process OAuth2 protocol
/// - invalidGenericType: Invalid generic type
/// - userAlreadyAuthenticated: An error when there is already authenticated session (Session Token and/or OAuth2 token set)
/// - authenticationCancelled: An error when the authentication process is cancelled
public enum AuthError: FRError {
    case invalidTokenResponse([String: Any]?)
    case invalidCallbackResponse(String)
    case unsupportedCallback(String)
    case invalidAuthServiceResponse(String)
    case invalidOAuth2Client
    case invalidGenericType
    case userAlreadyAuthenticated(Bool)
    case authenticationCancelled
    case invalidResumeURI(String)
    case userAuthenticationRequired
}

public extension AuthError {
    
    /// Unique error code for given error
    var code: Int {
        return self.parseErrorCode()
    }
}

extension AuthError {
    
    /// Parses AuthError value into integer error code
    ///
    /// - Returns: Int value of unique error code
    func parseErrorCode() -> Int {
        switch self {
        case .invalidTokenResponse:
            return 1000006
        case .invalidCallbackResponse:
            return 1000007
        case .unsupportedCallback:
            return 1000008
        case .invalidAuthServiceResponse:
            return 1000009
        case .invalidOAuth2Client:
            return 1000010
        case .invalidGenericType:
            return 1000011
        case .userAlreadyAuthenticated:
            return 1000020
        case .authenticationCancelled:
            return 1000030
        case .invalidResumeURI:
            return 1000031
        case .userAuthenticationRequired:
            return 1000035
        }
        
    }
}


// MARK: - CustomNSError protocols
extension AuthError: CustomNSError {
    
    /// An error domain for AuthError
    public static var errorDomain: String { return "com.forgerock.ios.frauth.authentication" }
    
    /// Error codes for each error enum
    public var errorCode: Int {
        return self.parseErrorCode()
    }
    
    /// Error UserInfo
    public var errorUserInfo: [String : Any] {
        switch self {
        case .invalidTokenResponse(let responsePayload):
            return [NSLocalizedDescriptionKey: "Invalid token response: access_token, token_type, expires_in and scope are required, but missing in the response. \(String(describing: responsePayload))"]
        case .invalidCallbackResponse(let callbackResponse):
            return [NSLocalizedDescriptionKey: "Invalid callback response: \(callbackResponse)"]
        case .unsupportedCallback(let callbackResponse):
            return [NSLocalizedDescriptionKey: "Unsupported callback: \(callbackResponse)"]
        case .invalidAuthServiceResponse(let message):
            return [NSLocalizedDescriptionKey: "Invalid AuthService response: \(message)"]
        case .invalidOAuth2Client:
            return [NSLocalizedDescriptionKey: "Invalid OAuth2Client: no OAuth2Client object was found"]
        case .invalidGenericType:
            return [NSLocalizedDescriptionKey: "Invalid generic type: Only Token, AccessToken, and FRUser are allowed"]
        case .userAlreadyAuthenticated(let hasAccessToken):
            return [NSLocalizedDescriptionKey: "User is already authenticated\(hasAccessToken ? "" : " and has Session Token; use FRUser.currentUser.getAccessToken to obtian OAuth2 tokens")"]
        case .authenticationCancelled:
            return [NSLocalizedDescriptionKey: "Authentication is cancelled"]
        case .invalidResumeURI(let message):
            return [NSLocalizedDescriptionKey: "Invalid Resume URI; missing \(message)"]
        case .userAuthenticationRequired:
            return [NSLocalizedDescriptionKey: "All user credentials are expired or invalid; user authentication is required"]
        }
    }
}
