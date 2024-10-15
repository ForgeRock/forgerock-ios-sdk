// 
//  DerivableCallback.swift
//  FRAuth
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// Protocol for `Callback` that can be derived.
protocol DerivableCallback {

    /// Retrieve the derived callback class, return nil if no derived callback found.
    static func getDerivedCallback(json: [String: Any]) -> Callback.Type?
}
