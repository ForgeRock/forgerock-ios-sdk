// 
//  OathCodeGenerator.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// OathCodeGenerator is responsible to generate OATH code regardless of OATH type and algorithm
struct OathCodeGenerator {
    
    /// Generates OATH OTP code based on given OATH mechanism information
    /// - Parameter secret: secret key as in String for OATH mechanism
    /// - Parameter algorithm: Hash algorithm that will be used to generate OATH code
    /// - Parameter counter: counter of OATH
    /// - Parameter digits: length of code to be generated
    static func generateOTP(secret: String, algorithm: OathAlgorithm, counter: UInt64, digits: Int) throws -> String {
        
        guard let key = Crypto.parseSecret(secret: secret) else {
            FRALog.e("Failed to convert given secret")
            throw CryptoError.failToConvertData
        }
    
        let message = counter.bigEndian.data
        let hmacData = Crypto.hmac(algorithm: algorithm, keyData: key, messageData: message)
        
        var truncated = hmacData.withUnsafeBytes { pointer -> UInt32 in
            let offset = pointer[hmacData.count - 1] & 0x0f
            let truncatedHmac = pointer.baseAddress! + Int(offset)
            return truncatedHmac.bindMemory(to: UInt32.self, capacity: 1).pointee
        }
        
        truncated = UInt32(bigEndian: truncated)
        let discard = truncated & 0x7fffffff
        let modulus = UInt32(pow(10, Float(digits)))
        let tmpCode = String(discard % modulus)
        
        if (digits - tmpCode.count) > 0 {
            let code = String(repeating: "0", count: (digits - tmpCode.count)) + tmpCode
            FRALog.v("OathCode generated: \(code)")
            return code
        }
        else {
            FRALog.v("OathCode generated: \(tmpCode)")
            return tmpCode
        }
    }
}
