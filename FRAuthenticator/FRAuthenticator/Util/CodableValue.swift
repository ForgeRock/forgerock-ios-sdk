// 
//  CodableValue.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation


/// CodableValue is a representation of specific data types that are encodable and is used for JWT payload encoding
struct CodableValue: Encodable {
    let value: Encodable
    
    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
    
    init(_ value: Encodable) {
        self.value = value
    }
}
