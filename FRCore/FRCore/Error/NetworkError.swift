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
    case apiFailedWithError(Int, String, [String: Any]?)
    case authenticationTimeout(Int, String, [String: Any]?)
    case invalidCredentials(Int, String, [String: Any]?)
    case invalidResponseDataType
    case invalidRequest(String)
    case requestFailWithError
}

extension NetworkError {
    
    /// Parses AuthError value into integer error code
    ///
    /// - Returns: Int value of unique error code
    func parseErrorCode() -> Int {
        switch self {
        case .apiFailedWithError:
            return 5000000
        case .authenticationTimeout:
            return 5000001
        case .invalidCredentials:
            return 5000002
        case .invalidResponseDataType:
            return 5000003
        case .requestFailWithError:
            return 5000004
        case .invalidRequest:
            return 5000005
        }
        
    }
    
    /// Parses an error payload, and result into NetworkError
    ///
    /// - Parameters:
    ///   - data: Data from API response
    ///   - response: URLResponse object from API response
    ///   - error: Error from API response
    /// - Returns: Any of NetworkError based on the response received
    static func converToNetworkError(data: Data?, response: URLResponse?, error: Error?) -> NetworkError{
        
        if let data = data, let jsonData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let httpResponse = response as? HTTPURLResponse {
            let errorMessage: String = jsonData["message"] as? String ?? ""
            
            if httpResponse.statusCode == 401 {
                
                if let apiErrorCodeJSON: [String: Any] = jsonData["detail"] as? [String : Any], let apiErrorCode: String = apiErrorCodeJSON["errorCode"] as? String {
                    
                    if apiErrorCode == "110" {
                        return NetworkError.authenticationTimeout(httpResponse.statusCode, errorMessage, jsonData)
                    }
                    else {
                        return NetworkError.invalidCredentials(httpResponse.statusCode, errorMessage, jsonData)
                    }
                }
            }
            return NetworkError.apiFailedWithError(httpResponse.statusCode, errorMessage, jsonData)
        }
        else {
            return NetworkError.requestFailWithError
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
        case .invalidRequest(let requestDescription):
            return [NSLocalizedDescriptionKey: "Invalid request: "+requestDescription]
        case .apiFailedWithError(_, let errorMessage, let userInfo):
            return self.buildErrorUserInfo(errorMessage: errorMessage, additionalInfo: userInfo)
        case .authenticationTimeout(_, let errorMessage, let userInfo):
            return self.buildErrorUserInfo(errorMessage: errorMessage, additionalInfo: userInfo)
        case .invalidCredentials(_, let errorMessage, let userInfo):
            return self.buildErrorUserInfo(errorMessage: errorMessage, additionalInfo: userInfo)
        case .invalidResponseDataType:
            return [NSLocalizedDescriptionKey: "Invalid response data type"]
        case .requestFailWithError:
            return [NSLocalizedDescriptionKey: "Request was failed with an unknown error"]
        }
    }
}
