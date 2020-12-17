// 
//  AuthApiError.swift
//  FRAuth
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore

public enum AuthApiError: FRError {
    case apiRequestFailure(Data?, URLResponse?, Error?)
    case authenticationTimout(String, String, Int?, [String: Any]?)
    case apiFailureWithMessage(String, String, Int?, [String: Any]?)
    case suspendedAuthSessionError(String, String, Int?, [String: Any]?)
}

extension AuthApiError {
    
    /// Unique error code for given error
    var code: Int {
        return self.parseErrorCode()
    }
    
    /// Parses AuthApiError value into integer error code
    ///
    /// - Returns: Int value of unique error code
    func parseErrorCode() -> Int {
        switch self {
        case .apiRequestFailure:
            return 1300000
        case .authenticationTimout:
            return 1300001
        case .apiFailureWithMessage:
            return 1300002
        case .suspendedAuthSessionError:
            return 1300003
        }
    }
    
    
    /// Parses and converts response data into AuthApiError
    /// - Parameters:
    ///   - data: Data response body
    ///   - response: URLResponse of the request
    ///   - error: Error returned from the request
    /// - Returns: AuthApiError
    static func convertToAuthApiError(data: Data?, response: URLResponse?, error: Error?) -> AuthApiError {
        if let data = data, let jsonData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            
            let errorMessage: String? = jsonData["message"] as? String
            let errorReason: String? = jsonData["reason"] as? String
            
            if let errorMessage = errorMessage, let errorReason = errorReason {
                
                if let apiErrorCodeJSON: [String: Any] = jsonData["detail"] as? [String : Any], let apiErrorCode: String = apiErrorCodeJSON["errorCode"] as? String {
                    if apiErrorCode == "110" {
                        return AuthApiError.authenticationTimout(errorReason, errorMessage, jsonData["code"] as? Int, jsonData["detail"] as? [String: Any])
                    }
                }
                
                if errorMessage.contains("org.forgerock.openam.auth.nodes.framework.token.SuspendedAuthSessionException")
                {
                    return AuthApiError.suspendedAuthSessionError(errorReason, errorMessage, jsonData["code"] as? Int, jsonData["detail"] as? [String: Any])
                }
                
                return AuthApiError.apiFailureWithMessage(errorReason, errorMessage, jsonData["code"] as? Int, jsonData["detail"] as? [String: Any])
            }
        }
        return AuthApiError.apiRequestFailure(data, response, error)
    }
    
    
    func convertToOAuth2Error() -> OAuth2Error? {
        switch self {
        case .apiRequestFailure(let data, _, _):
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let error = json["error"] as? String {
                    let errorDesc = json["error_description"] as? String ?? ""
                    let urlString = "http://localhost.com?error=\(error)&error_description=" + errorDesc
                    
                    switch error {
                    case "invalid_request":
                        return OAuth2Error.invalidAuthorizeRequest(urlString)
                    case "invalid_client":
                        return OAuth2Error.invalidClient(urlString)
                    case "invalid_grant":
                        return OAuth2Error.invalidGrant(urlString)
                    case "unauthorized_client":
                        return OAuth2Error.unauthorizedClient(urlString)
                    case "unsupported_grant_type":
                        return OAuth2Error.unsupportedGrantType(urlString)
                    case "unsupported_response_type":
                        return OAuth2Error.unsupportedResponseType(urlString)
                    case "invalid_scope":
                        return OAuth2Error.invalidScope(urlString)
                    case "access_denied":
                        return OAuth2Error.accessDenied(urlString)
                    default:
                        break
                    }
                }
            }
            break
        default:
            break
        }
        
        return nil
    }
}

extension AuthApiError: CustomNSError {
    
    /// An error domain for AuthApiError
    public static var errorDomain: String { return "com.forgerock.ios.frauth.authapierror" }
    
    /// Error codes for each error enum
    public var errorCode: Int {
        return self.parseErrorCode()
    }
    
    /// Error UserInfo
    public var errorUserInfo: [String : Any] {
        var userInfo: [String: Any] = [:]
        switch self {
        case .apiRequestFailure(let data, let response, let error):
            userInfo[NSLocalizedDescriptionKey] = "Request failed"
            userInfo["com.forgerock.ios.frauth.authapierror.responseData"] = data
            userInfo["com.forgerock.ios.frauth.authapierror.urlresponse"] = response
            userInfo["com.forgerock.ios.frauth.authapierror.error"] = error
            return userInfo
        case .authenticationTimout(let reason, let message, let code, let detail):
            userInfo[NSLocalizedDescriptionKey] = "Authentication timed out"
            userInfo["com.forgerock.ios.frauth.authapierror.reason"] = reason
            userInfo["com.forgerock.ios.frauth.authapierror.message"] = message
            userInfo["com.forgerock.ios.frauth.authapierror.code"] = code
            userInfo["com.forgerock.ios.frauth.authapierror.detail"] = detail
            return userInfo
        case .apiFailureWithMessage(let reason, let message, let code, let detail):
            userInfo[NSLocalizedDescriptionKey] = message
            userInfo["com.forgerock.ios.frauth.authapierror.reason"] = reason
            userInfo["com.forgerock.ios.frauth.authapierror.message"] = message
            userInfo["com.forgerock.ios.frauth.authapierror.code"] = code
            userInfo["com.forgerock.ios.frauth.authapierror.detail"] = detail
            return userInfo
        case .suspendedAuthSessionError(let reason, let message, let code, let detail):
            userInfo[NSLocalizedDescriptionKey] = message.replacingOccurrences(of: "org.forgerock.openam.auth.nodes.framework.token.SuspendedAuthSessionException:", with: "")
            userInfo["com.forgerock.ios.frauth.authapierror.reason"] = reason
            userInfo["com.forgerock.ios.frauth.authapierror.message"] = message
            userInfo["com.forgerock.ios.frauth.authapierror.code"] = code
            userInfo["com.forgerock.ios.frauth.authapierror.detail"] = detail
            return userInfo
        }
    }
}
