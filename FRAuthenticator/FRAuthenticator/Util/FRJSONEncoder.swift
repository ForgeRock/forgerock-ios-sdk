// 
//  FRJSONEncoder.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation


/// FRJSONEncoder class is a helper class that is responsible to help JSON encoding operation using JSONEncoder
class FRJSONEncoder: JSONEncoder {
    
    /// shared instance of FRAPushHandler
    static var shared: FRJSONEncoder = FRJSONEncoder()
    
    public func encodeToString<T: Encodable>(value: T) throws -> String {
        return try Base64Utils.base64EncodeURLSafe(data: try super.encode(value))
    }
}
