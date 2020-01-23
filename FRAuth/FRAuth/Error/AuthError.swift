//
//  AuthError.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// AuthError represents an error captured by FRAuth SDK during authentication
///
/// - requestFailWithError: API request failed with unknown server side error
/// - invalidResponseDataType: Invalid response data was received and the response data could not be serialized
/// - invalidRequest: Invalid request is provided to the client, and failed to generate URLRequest object
/// - invalidCredentials: Authentication failed with invalid user credentials
/// - authenticationTimeout: Authentication session is timed out
/// - apiFailedWithError: Generic API request failure with error details from server side
/// - invalidTokenResponse: Invalid response from OAuth2 protocol for exchanging SSO Token with OAuth2 token set; token response must contain at least followings: access_token, scope, token_type, expires_in
/// - invalidCallbackResponse: Invalid AuthService response for parsing Callback(s)
/// - unsupportedCallback: Invalid AuthService response containing unsupported Callback type(s)
/// - invalidAuthServiceResponse: Invalid AuthService response for missing/invalid authId
/// - invalidOAuth2Client: Invalid AuthService or Node object without OAuth2Client while expecting to process OAuth2 protocol
/// - invalidGenericType: Invalid generic type
/// - userAlreadyAuthenticated: An error when there is already authenticated session (Session Token and/or OAuth2 token set)
public enum AuthError: FRError {
    case requestFailWithError
    case invalidResponseDataType
    case invalidRequest(String)
    case invalidCredentials(Int, String, [String: Any]?)
    case authenticationTimeout(Int, String, [String: Any]?)
    case apiFailedWithError(Int, String, [String: Any]?)
    case invalidTokenResponse([String: Any]?)
    case invalidCallbackResponse(String)
    case unsupportedCallback(String)
    case invalidAuthServiceResponse(String)
    case invalidOAuth2Client
    case invalidGenericType
    case userAlreadyAuthenticated(Bool)
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
        case .requestFailWithError:
            return 1000000
        case .invalidResponseDataType:
            return 1000001
        case .invalidRequest:
            return 1000002
        case .invalidCredentials:
            return 1000003
        case .authenticationTimeout:
            return 1000004
        case .apiFailedWithError:
            return 1000005
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
        }
        
    }
    
    /// Parses an error payload, and result into AuthError
    ///
    /// - Parameters:
    ///   - data: Data from API response
    ///   - response: URLResponse object from API response
    ///   - error: Error from API response
    /// - Returns: Any of AuthError based on the response received
    static func converToAuthError(data: Data?, response: URLResponse?, error: Error?) -> AuthError{
        
        if let data = data, let jsonData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let httpResponse = response as? HTTPURLResponse {
            let errorMessage: String = jsonData["message"] as? String ?? ""
            
            if httpResponse.statusCode == 401 {
                
                if let apiErrorCodeJSON: [String: Any] = jsonData["detail"] as? [String : Any], let apiErrorCode: String = apiErrorCodeJSON["errorCode"] as? String {
                    
                    if apiErrorCode == "110" {
                        return AuthError.authenticationTimeout(httpResponse.statusCode, errorMessage, jsonData)
                    }
                    else {
                        return AuthError.invalidCredentials(httpResponse.statusCode, errorMessage, jsonData)
                    }
                }
            }
            return AuthError.apiFailedWithError(httpResponse.statusCode, errorMessage, jsonData)
        }
        else {
            return AuthError.requestFailWithError
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
        case .requestFailWithError:
            return [NSLocalizedDescriptionKey: "Request was failed with an unknown error"]
        case .invalidResponseDataType:
            return [NSLocalizedDescriptionKey: "Invalid response data type"]
        case .invalidRequest(let requestDescription):
            return [NSLocalizedDescriptionKey: "Invalid request: "+requestDescription]
        case .invalidCredentials(_, let errorMessage, let userInfo):
            return self.buildErrorUserInfo(errorMessage: errorMessage, additionalInfo: userInfo)
        case .authenticationTimeout(_, let errorMessage, let userInfo):
            return self.buildErrorUserInfo(errorMessage: errorMessage, additionalInfo: userInfo)
        case .apiFailedWithError(_, let errorMessage, let userInfo):
            return self.buildErrorUserInfo(errorMessage: errorMessage, additionalInfo: userInfo)
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
        }
    }
}
