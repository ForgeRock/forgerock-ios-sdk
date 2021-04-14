// 
//  IdPValue.swift
//  FRAuth
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation


/**
 IdPValue is a representation of Social Identity Provider available through `SelectIdPCallback`
 */
public struct IdPValue {
    /// Provider string value
    public let provider: String
    /// UI configuration JSON value
    public let uiConfig: [String: String]?
}
