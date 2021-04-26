//
//  Bytes.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Original work Copyright © 2018 Lyo Kato. All rights reserved.
//  Modified work Copyright © 2021 ForgeRock, Inc.
//

import Foundation

class Bytes {
    
    static func fromHex(_ value: String) -> [UInt8] {
        return value.hexBytes
    }
    
    static func fromString(_ value: String) -> [UInt8] {
        return value.bytes // This is CryptoSwift method
    }

    static func fromUInt64(_ value: UInt64) -> [UInt8] {
       return [
            UInt8((value & 0xff00000000000000) >> 56),
            UInt8((value & 0x00ff000000000000) >> 48),
            UInt8((value & 0x0000ff0000000000) >> 40),
            UInt8((value & 0x000000ff00000000) >> 32),
            UInt8((value & 0x00000000ff000000) >> 24),
            UInt8((value & 0x0000000000ff0000) >> 16),
            UInt8((value & 0x000000000000ff00) >> 8),
            UInt8(value & 0x00000000000000ff),
        ]
    }

    static func toUInt64(_ bytes: [UInt8]) -> UInt64 {
        var b = bytes
        while b.count < 8 {
            b.insert(UInt8(0x00), at: 0)
        }
        while b.count > 8 {
           b.removeFirst()
        }
        
        let a1 = (UInt64(b[0]) << 56)
        let a2 = (UInt64(b[1]) << 48)
        let a3 = (UInt64(b[2]) << 40)
        let a4 = (UInt64(b[3]) << 32)
        let result1 = UInt64(a1 | a2 | a3 | a4)
        
        let b1 = (UInt64(b[4]) << 24)
        let b2 = (UInt64(b[5]) << 16)
        let b3 = (UInt64(b[6]) << 8)
        let b4 = UInt64(b[7])
        let result2 = UInt64(b1 | b2 | b3 | b4)
        return result1 | result2
    }

    static func fromUInt32(_ value: UInt32) -> [UInt8] {
        return [
            UInt8((value & 0xff000000) >> 24),
            UInt8((value & 0x00ff0000) >> 16),
            UInt8((value & 0x0000ff00) >> 8),
            UInt8(value & 0x000000ff),
        ]
    }

    static func toUInt32(_ bytes: [UInt8]) -> UInt32 {
        var b = bytes
        while b.count < 4 {
            b.insert(UInt8(0x00), at: 0)
        }
        while b.count > 4 {
            b.removeFirst()
        }
        return UInt32((UInt32(b[0]) << 24) | (UInt32(b[1]) << 16) | (UInt32(b[2]) << 8) | UInt32(b[3]))
    }

    static func fromUInt16(_ value: UInt16) -> [UInt8] {
        return [
            UInt8((value & 0xff00) >> 8),
            UInt8(value & 0x00ff),
        ]
    }

    static func toUInt16(_ bytes: [UInt8]) -> UInt16 {
        var b = bytes
        while b.count < 2 {
            b.insert(UInt8(0x00), at: 0)
        }
        while b.count > 2 {
            b.removeFirst()
        }
        return UInt16(UInt16(b[1]) << 8 | UInt16(b[0]))
    }
}
