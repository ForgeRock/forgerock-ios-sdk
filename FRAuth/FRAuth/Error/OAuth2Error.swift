// 
//  OAuth2Error.swift
//  FRAuth
//
//  Copyright (c) 2020-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore


/// OAuth2Error represents an error captured by FRAuth SDK for OAuth2 related operation
///
public enum OAuth2Error: FRError {
    case invalidAuthorizeRequest(String?)
    case invalidClient(String?)
    case invalidGrant(String?)
    case unauthorizedClient(String?)
    case unsupportedGrantType(String?)
    case unsupportedResponseType(String?)
    case invalidScope(String?)
    case missingOrInvalidRedirectURI(String?)
    case accessDenied(String?)
    case invalidPKCEState
    case other(String?)
    case unknown(String?)
}

public extension OAuth2Error {
    
    /// Unique error code for given error
    var code: Int {
        return self.parseErrorCode()
    }
    
    /// Parses OAuth2Error value into integer error code
    ///
    /// - Returns: Int value of unique error code
    func parseErrorCode() -> Int {
        switch self {
        case .invalidAuthorizeRequest:
            return 1500001
        case .invalidClient:
            return 1500002
        case .invalidGrant:
            return 1500003
        case .unauthorizedClient:
            return 1500004
        case .unsupportedGrantType:
            return 1500005
        case .unsupportedResponseType:
            return 1500006
        case .invalidScope:
            return 1500007
        case .missingOrInvalidRedirectURI:
            return 1500008
        case .accessDenied:
            return 1500009
        case .invalidPKCEState:
            return 1500010
        case .other:
            return 1500098
        case .unknown:
            return 1500099
        }
    }
}

// MARK: - CustomNSError protocols
extension OAuth2Error: CustomNSError {
    
    /// An error domain for OAuth2Error
    public static var errorDomain: String { return "com.forgerock.ios.frauth.oauth2" }
    
    /// Error codes for each error enum
    public var errorCode: Int {
        return self.parseErrorCode()
    }
    
    
    /// Error UserInfo
    public var errorUserInfo: [String : Any] {
        switch self {
        case .invalidAuthorizeRequest(let url):
            return self.converURLToUserInfo(url, "Invalid /authorize request")
        case .invalidClient(let url):
            return self.converURLToUserInfo(url, "Invalid client")
        case .invalidGrant(let url):
            return self.converURLToUserInfo(url, "Invalid grant")
        case .unauthorizedClient(let url):
            return self.converURLToUserInfo(url, "Unauthorized client")
        case .unsupportedGrantType(let url):
            return self.converURLToUserInfo(url, "Unsupported grant_type")
        case .unsupportedResponseType(let url):
            return self.converURLToUserInfo(url, "Unsupported response_type")
        case .invalidScope(let url):
            return self.converURLToUserInfo(url, "Invalid scope")
        case .missingOrInvalidRedirectURI(let url):
            return self.converURLToUserInfo(url, "Missing or invalid redirect_uri")
        case .accessDenied(let url):
            return self.converURLToUserInfo(url, "Resource owner did not authorize the request")
        case .invalidPKCEState:
            return [NSLocalizedDescriptionKey: "Invalid request with wrong PKCE state; invalid credentials"]
        case .other(let url):
            return self.converURLToUserInfo(url, "OAuth2 /authorize Error")
        case .unknown(let url):
            return self.converURLToUserInfo(url, "Unknown error")
        }
    }
    
    
    public var error: String {
        switch self {
        case .invalidAuthorizeRequest(let url):
            return self.extractError(url)
        case .invalidClient(let url):
            return self.extractError(url)
        case .invalidGrant(let url):
            return self.extractError(url)
        case .unauthorizedClient(let url):
            return self.extractError(url)
        case .unsupportedGrantType(let url):
            return self.extractError(url)
        case .unsupportedResponseType(let url):
            return self.extractError(url)
        case .invalidScope(let url):
            return self.extractError(url)
        case .missingOrInvalidRedirectURI(let url):
            return self.extractError(url)
        case .accessDenied(let url):
            return self.extractError(url)
        case .invalidPKCEState:
            return "invalid_pkce_state"
        case .other(let url):
            return self.extractError(url)
        default:
            return "unknown"
        }
    }
        
    
    static func convertOAuth2Error(urlValue: String?) -> OAuth2Error {
        guard let urlString = urlValue, let url = URL(string: urlString) else {
            return OAuth2Error.unknown(nil)
        }
        
        if let error = url.valueOf("error") {
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
                return OAuth2Error.other(urlString)
            }
        }
        else {
            return OAuth2Error.unknown(urlString)
        }
    }
    
    
    func converURLToUserInfo(_ urlValue: String?, _ defaultMessage: String) -> [String: String] {
        guard let urlString = urlValue, let url = URL(string: urlString) else {
            return [NSLocalizedDescriptionKey: defaultMessage, "error_description": "Unknown error occurred: \(urlValue ?? "")", "error": "unknown"]
        }
        
        var userInfo: [String: String] = [:]
        if let errorMessage = url.valueOf("error_description") {
            userInfo[NSLocalizedDescriptionKey] = errorMessage
            userInfo["error_description"] = errorMessage
        }
        else {
            userInfo[NSLocalizedDescriptionKey] = defaultMessage
            userInfo["error_description"] = defaultMessage
        }
        
        if let error = url.valueOf("error") {
            userInfo["error"] = error
        }
        else {
            userInfo["error"] = "unknown"
        }
        
        if let errorUri = url.valueOf("error_uri") {
            userInfo["error_uri"] = errorUri
        }
        
        return userInfo
    }
    
    
    func extractError(_ urlValue: String?) -> String {
        
        switch self {
        case .missingOrInvalidRedirectURI:
            return "redirect_uri_error"
        default:
            break
        }
        
        guard let urlString = urlValue, let url = URL(string: urlString) else {
            return "unknown"
        }
        
        return url.valueOf("error") ?? "unknown"
    }
}
