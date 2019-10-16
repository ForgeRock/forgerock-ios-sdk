//
//  PKCE.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import CommonCrypto

/// PKCE class is a representation of Proof Key for Code Exchange in OAuth2 Protocol according to RFC7636: https://tools.ietf.org/html/rfc7636
struct PKCE {
    
    //  MARK: - Property
    
    /// Code Verifier
    let codeVerifider: String
    /// Code Challenge
    let codeChallenge: String
    /// Code Challenge Method
    let codeChallengeMethod: String
    /// State
    let state: String
    
    
    //  MARK: - Init
    
    /// Constructs PKCE object and produces randomly generated CodeVerifier and State
    init() {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        self.codeVerifider = String((0 ..< 43).map{ _ in letters.randomElement()!})
        self.state = String((0 ..< 32).map{ _ in letters.randomElement()!})
        self.codeChallenge = PKCE.hashAndBase64Data(self.codeVerifider.data(using: .utf8)!)
        self.codeChallengeMethod = "S256"
    }
    
    
    //  MARK: - Method
    
    /// Hashes and Base64 encodes given data
    ///
    /// - Parameter data: Data to be hashed, and base64 encoded
    /// - Returns: String value of hashed, and base64 encoded of given data
    static func hashAndBase64Data(_ data: Data) -> String {
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest)
        }
        let hashString = Data(bytes: digest, count: digest.count).base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
        return hashString
    }
}
