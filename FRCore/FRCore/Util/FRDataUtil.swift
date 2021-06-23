//
//  FRDataUtil.swift
//  FRCore
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import CommonCrypto

extension Data {
    
    /// Converts Data object into byte (UInt8) array
    public var bytes: Array<UInt8> {
        return Array(self)
    }
    
    
    /// Converts Data into SHA256 hashed Data
    public var sha256: Data {
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash)
    }
}


extension Array where Element == UInt8 {
    
    /// Converts bytes (UInt8) array into hex string
    /// - Returns: Hex string of bytes array
    public func toHexString() -> String {
        return `lazy`.reduce("") {
            var s = String($1, radix: 16)
            if s.count == 1 {
                s = "0" + s
            }
            return $0 + s
        }
    }
}
