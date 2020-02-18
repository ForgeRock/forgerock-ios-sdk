//
//  OpenAM.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

/// Internal constant values related to OpenAM request/response keys
struct OpenAM {
    static let acceptAPIVersion = "accept-api-version"
    static let apiResource21 = "resource=2.1"
    static let apiResource31 = "resource=3.1"
    static let apiProtocol10 = "protocol=1.0"
    static let action = "_action"
    static let logout = "logout"
    static let tokenId = "tokenId"
    static let iPlanetDirectoryPro = "iPlanetDirectoryPro"
    static let authIndexType = "authIndexType"
    static let authIndexValue = "authIndexValue"
    static let service = "service"
    static let compositeAdvice = "composite_advice"
    static let authId = "authId"
    static let callbacks = "callbacks"
    static let stage = "stage"
    static let xRequestedWith = "X-Requested-With"
    static let xmlHTTPRequest = "XMLHTTPRequest"
}
