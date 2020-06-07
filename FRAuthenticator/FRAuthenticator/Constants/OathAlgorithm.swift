// 
//  OathAlgorithm.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import CommonCrypto


/// OathAlgorithm is an enum representation of supported OATH algorithm in FRAuthenticator SDK
enum OathAlgorithm: Equatable {
    case md5
    case sha256
    case sha512
    case sha1
    
    /// Initializes OathAlgorithm enum
    /// - Parameter algorithm: optional case-insensitive string value of hash algorithm; default to SHA1 if invalid string value / or unsupported algorithm
    init(algorithm: String?) {
        let algorithm = algorithm ?? ""
        if algorithm.lowercased() == "md5" {
            self = .md5
        }
        else if algorithm.lowercased() == "sha256" {
            self = .sha256
        }
        else if algorithm.lowercased() == "sha512" {
            self = .sha512
        }
        else {
            self = .sha1
        }
    }
    
    
    /// Gets CommonCrypto Hmac Algorithm value for enum
    func getAlgorithm() -> Int {
        switch self {
        case .md5:
            return kCCHmacAlgMD5
        case .sha256:
            return kCCHmacAlgSHA256
        case .sha512:
            return kCCHmacAlgSHA512
        case .sha1:
            return kCCHmacAlgSHA1
        }
    }
    
    
    /// Gets CommonCrypto digest length for algorithm
    func getDigestLength() -> Int32 {
        switch self {
        case .md5:
            return CC_MD5_DIGEST_LENGTH
        case .sha256:
            return CC_SHA256_DIGEST_LENGTH
        case .sha512:
            return CC_SHA512_DIGEST_LENGTH
        case .sha1:
            return CC_SHA1_DIGEST_LENGTH
        }
    }
}
