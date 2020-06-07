// 
//  Crypto.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import CommonCrypto

/// Crypto is responsible for cryptographic related operations for FRAuthenticator SDK
struct Crypto {
    
    
    /// Generates HMAC base64 encoded string with given challenge and shared secret strings using SHA256
    /// - Parameters:
    ///   - challenge: Challenge string provided by AM's push registration payload
    ///   - secret: Shared secret provided by AM's push registration payload
    /// - Throws: CryptoError
    /// - Returns: Base64 encoded string of HMAC data
    static func generatePushChallengeResponse(challenge: String, secret: String) throws -> String {
        guard let saltData = secret.decodeURL(), let paramData = challenge.decodeBase64() else {
            FRALog.e("Failed to decode challenge or shared secret")
            throw CryptoError.invalidParam("challenge, or secret")
        }
        FRALog.v("Starts generating HMAC with given challenge (\(challenge)), and secret (\(secret) with SHA256")
        let hmacData = hmac(algorithm: .sha256, keyData: saltData, messageData: paramData)
        FRALog.v("Finished generating HMAC generated")
        
        return hmacData.base64EncodedString()
    }
    
    
    /// Generates HMAC base64 encoded string with given secret, message, and hash algorithm
    /// - Parameters:
    ///   - algorithm: Hash algorithm to be used for HMAC
    ///   - secret: Secret string to perform HMAC
    ///   - message: Message to be hashed
    /// - Throws: CryptoError
    /// - Returns: Base64 encoded string of HMAC data
    static func hmac(algorithm: OathAlgorithm, secret: String, message: String) throws -> String {
        
        guard let messageData = message.data(using: String.Encoding.utf8, allowLossyConversion: false), let keyData = secret.decodeURL() else {
            FRALog.e("Fail to convert given secret and message string into data")
            throw CryptoError.failToConvertData
        }
        FRALog.v("Starts generating HMAC with given algorithm (\(algorithm)), message (\(message)), and secret (\(secret)")
        let hmacData = hmac(algorithm: algorithm, keyData: keyData, messageData: messageData)
        FRALog.v("Finished generating HMAC generated")
        
        return hmacData.base64EncodedString()
    }
    
    
    /// Generates HMAC data with given key, message, and hash algorithm
    /// - Parameters:
    ///   - algorithm: Hash algorithm to be used for HMAC
    ///   - keyData: Key data to perform HMAC
    ///   - messageData: MEssage data to be hashed
    /// - Returns: HMAC data
    static func hmac(algorithm: OathAlgorithm, keyData: Data, messageData: Data) -> Data {
        
        let hashAlgorithm = algorithm.getAlgorithm()
        let length = Int(algorithm.getDigestLength())
        let macData = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
        defer { macData.deallocate() }
        
        keyData.withUnsafeBytes { keyBytes in
            messageData.withUnsafeBytes { messageBytes in
                CCHmac(CCHmacAlgorithm(hashAlgorithm), keyBytes.baseAddress, keyData.count, messageBytes.baseAddress, messageData.count, macData)
            }
        }
        
        return Data(bytes: macData, count: length)
    }
    
    
    /// Parses secret value in String into bytes
    /// - Parameter secret: String value of secret key
    static func parseSecret(secret: String) -> Data? {
        return secret.base32Decode()
    }
}


extension UInt64 {
    /// Data convereted from UInt64
    var data: Data {
        var int = self
        let intData = Data(bytes: &int, count: MemoryLayout.size(ofValue: self))
        return intData
    }
}
