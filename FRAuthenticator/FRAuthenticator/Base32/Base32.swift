// 
//  Base32.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
#if SWIFT_PACKAGE
import cFRAuthenticator
#endif

extension String {
    
    /// Base32-encodes current String and returns encoded value in String
    func base32Encode() -> String? {
        if let encodedData: Data = self.base32Encode() {
            return String(bytes: encodedData, encoding: .utf8)
        }
        return nil
    }
    
    
    /// Base32-encodes current String and returns encoded value in bytes
    func base32Encode() -> Data? {
        let encoded = UnsafeMutablePointer<Int8>.allocate(capacity: 4096)
        let temp = Array(self.utf8)
        let result = base32_encode(temp, Int32(temp.count), encoded, 4096)
        
        if result < 0 {
            return nil
        }
        
        return Data.init(bytes: encoded, count: Int(result))
    }
    
    
    /// Base32-decodes current String and returns decoded value in String
    func base32Decode() -> String? {
        if let encodedData: Data = self.base32Decode() {
            return String(bytes: encodedData, encoding: .utf8)
        }
        return nil
    }
    
    
    /// Base32-decodes current String and returns decoded value in bytes
    func base32Decode() -> Data? {
        let decoded = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
        let temp = self.cString(using: .ascii)
        let result = base32_decode(temp, decoded, Int32(4096))
        
        if result < 0 {
            return nil
        }
        
        return Data.init(bytes: decoded, count: Int(result))
    }
}
