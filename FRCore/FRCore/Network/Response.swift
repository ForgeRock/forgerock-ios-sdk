//
//  Response.swift
//  FRCore
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// This struct is a representation of FRAuth's API request response data structure, and is responsible to handle response serialization
public struct Response {
    
    /// response Data
    let data: Data?
    /// URLResponse object containing HTTP information of the response
    let response: URLResponse?
    /// API request failure error
    let error: Error?
    
    public init(data: Data?, response: URLResponse?, error: Error?) {
        self.data = data
        self.response = response
        self.error = error
    }
    
    /// Parses response into Result object
    ///
    /// - Returns: Result object notifying whether the request was successful, or failed with an error
    public func parseReponse() -> Result {

        if let error = self.error {
            return Result.failure(error: error)
        }
        else if let httpResponse = self.response as? HTTPURLResponse, (200 ..< 303) ~= httpResponse.statusCode {
            if let responseData = self.data, responseData.isEmpty {
                return Result.success(result: [:], httpResponse: self.response)
            }
            else {
                //  TODO: Response handling as per Accept header
                if let jsonData = try? JSONSerialization.jsonObject(with: self.data ?? Data(), options: []) as? [String:AnyObject] {
                    return Result.success(result: jsonData, httpResponse: self.response)
                }
                else {
                    return Result.failure(error: NetworkError.invalidResponseDataType)
                }
            }
        }
        else {
            return Result.failure(error: NetworkError.apiRequestFailure(self.data, self.response, self.error))
        }
    }
}
