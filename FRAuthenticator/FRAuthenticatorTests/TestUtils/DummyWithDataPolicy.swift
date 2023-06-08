// 
//  DummyWithDataPolicy.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

class DummyWithDataPolicy: FRAPolicy {
    
    public var name: String = "dummyWithData"
    
    public var data: Any?
    
    public func evaluate() -> Bool {
        if let jsonData = self.data as? Dictionary<String, AnyObject> {
            if jsonData["result"] as! Bool == true  {
                return true
            } else {
                return false
            }
        }
        return true
    }
    
}
