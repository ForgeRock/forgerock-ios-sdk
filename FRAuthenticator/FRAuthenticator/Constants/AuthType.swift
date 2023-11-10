// 
//  AuthType.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

enum AuthType: String {
    case totp = "totp"
    case hotp = "hotp"
    case push = "push"
    case unknown
}
