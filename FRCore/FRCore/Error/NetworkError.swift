//
//  NetworkError.swift
//  FRCore
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation


/// NetworkError represents an error captured by FRCore SDK during REST API
///
/// - apiFailedWithError: Generic API request failure with error details from server side
/// - authenticationTimeout: Authentication session is timed out
/// - invalidCredentials: Authentication failed with invalid user credentials
/// - invalidResponseDataType: Invalid response data was received and the response data could not be serialized
/// - requestFailWithError: API request failed with unknown server side error
/// - invalidRequest: Invalid request is provided to the client, and failed to generate URLRequest object
public enum NetworkError: FRError {
    case invalidResponseDataType
    case invalidRequest(String)
    case apiRequestFailure(Data?, URLResponse?, Error?)
}

extension NetworkError {
    
    /// Unique error code for given error
    var code: Int {
        return self.parseErrorCode()
    }
    
    /// Parses AuthError value into integer error code
    ///
    /// - Returns: Int value of unique error code
    func parseErrorCode() -> Int {
        switch self {
        case .apiRequestFailure:
            return 5000010
        case .invalidResponseDataType:
            return 5000003
        case .invalidRequest:
            return 5000005
        }
    }
}


// MARK: - CustomNSError protocols
extension NetworkError: CustomNSError {
    
    /// An error domain for AuthError
    public static var errorDomain: String { return "com.forgerock.ios.frcore.network" }
    
    /// Error codes for each error enum
    public var errorCode: Int {
        return self.parseErrorCode()
    }
    
    /// Error UserInfo
    public var errorUserInfo: [String : Any] {
        switch self {
        case .apiRequestFailure(let data, let response, let error):
            var userInfo: [String: Any] = [:]
            userInfo[NSLocalizedDescriptionKey] = "Request failed"
            userInfo["com.forgerock.ios.frcore.network.responseData"] = data
            userInfo["com.forgerock.ios.frcore.network.urlresponse"] = response
            userInfo["com.forgerock.ios.frcore.network.error"] = error
            return userInfo
        case .invalidRequest(let requestDescription):
            return [NSLocalizedDescriptionKey: "Invalid request: " + requestDescription]
        case .invalidResponseDataType:
            return [NSLocalizedDescriptionKey: "Invalid response data type"]
        }
    }
}
