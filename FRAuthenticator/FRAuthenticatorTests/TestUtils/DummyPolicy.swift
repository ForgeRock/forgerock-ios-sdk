// 
//  DummyPolicy.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2023 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

class DummyPolicy: FRAPolicy {
    
    public var name: String = "dummy"
    
    public var data: Any?
    
    public func evaluate() -> Bool {
        return true
    }
    
}
