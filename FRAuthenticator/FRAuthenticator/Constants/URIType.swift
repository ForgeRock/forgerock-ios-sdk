// 
//  URIType.swift
//  FRAuthenticator
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

enum URIType: String {
    case otpauth = "otpauth"
    case pushauth = "pushauth"
    case mfauth = "mfauth"
    case unknown
}
