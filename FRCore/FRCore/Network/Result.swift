//
//  Result.swift
//  FRCore
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// This enumeration is a representation for FRAuth's API result
///
/// - success: request successfully completed with its response data, and URLResponse object
/// - failure: request failed with an error
public enum Result {
    case success(result: [String:Any], httpResponse: URLResponse?)
    case failure(error: Error)
}
