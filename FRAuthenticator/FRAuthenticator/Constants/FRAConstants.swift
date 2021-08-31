// 
//  AMConstants.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

struct FRAConstants {
    static let acceptAPIVersion = "accept-api-version"
    static let apiResource10 = "resource=1.0"
    static let apiResource21 = "resource=2.1"
    static let apiResource31 = "resource=3.1"
    static let apiProtocol10 = "protocol=1.0"
    
    static let response = "response"
    static let mechanismUid = "mechanismUid"
    static let deviceId = "deviceId"
    static let deviceType = "deviceType"
    static let communicationType = "communicationType"
    
    static let ios = "ios"
    static let apns = "apns"
    
    static let messageId = "messageId"
    static let jwt = "jwt"
    
    static let hotp = "hotp"
    static let totp = "totp"
    static let push = "push"
    
    static let oathAuth = "otpauth"
    static let pushAuth = "pushauth"
}
