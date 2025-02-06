//
//  Session.swift
//  FRAuth
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// Struct representing a user session.
struct Session: Codable {
    let username: String
    let universalId: String
    let realm: String
    let latestAccessTime: String
    let maxIdleExpirationTime: String
    let maxSessionExpirationTime: String
}
