//
//  FRSecurityConfiguration.swift
//  FRCore
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import CryptoKit
import CommonCrypto

@objc
public class FRSecurityConfiguration: NSObject {
    /// Stored public key hashes
    private let hashes: [String]
    
    public init(hashes: [String]) {
        self.hashes = hashes
    }
    
    /// ASN1 header for our public key to re-create the subject public key info
    private let rsa2048Asn1Header: [UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
    ]
    
    private let rsa4096Asn1Header: [UInt8] = [
        0x30, 0x82, 0x02, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x02, 0x0f, 0x00
    ]
    
    public func validateSessionAuthChallenge(session: URLSession, challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        let protectionSpace = challenge.protectionSpace
        let sender = challenge.sender
        
        if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = protectionSpace.serverTrust {
                if self.validate(serverTrust: serverTrust, domain: protectionSpace.host) {
                    let credential = URLCredential(trust: serverTrust)
                    sender?.use(credential, for: challenge)
                    completionHandler(.useCredential, credential)
                    return
                }
            }
        }
        
        //Challenge Failed
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
    
    public func validateTaskAuthChallenge(session: URLSession, task: URLSessionTask, challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        let protectionSpace = challenge.protectionSpace
        let sender = challenge.sender
        
        if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = protectionSpace.serverTrust {
                if self.validate(serverTrust: serverTrust, domain: protectionSpace.host) {
                    let credential = URLCredential(trust: serverTrust)
                    sender?.use(credential, for: challenge)
                    completionHandler(.useCredential, credential)
                    return
                }
            }
        }
        //Challenge Failed
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
    
    /// Validates an object used to evaluate trust's certificate by comparing their's public key hashes to the known, trused key hashes stored in the app
    /// Configuration.
    /// - Parameter serverTrust: The object used to evaluate trust.
    internal func validate(serverTrust: SecTrust, domain: String?) -> Bool {
        // Set SSL policies for domain name check, if needed
        if let domain = domain {
            let policies = NSMutableArray()
            policies.add(SecPolicyCreateSSL(true, domain as CFString))
            SecTrustSetPolicies(serverTrust, policies)
        }
        
        // Check if the trust is valid
        var secresult = SecTrustResultType.invalid
        let status = SecTrustEvaluate(serverTrust, &secresult)
        
        guard status == errSecSuccess else { return false }
        var validated = false
        
        // For each certificate in the valid trust:
        if #available(iOS 15.0, *) {
            guard let certArray = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] else {
                return false
            }
            for certificate in certArray {
                // Get the public key data for the certificate at the current index of the loop.
                guard let publicKey = publicKey(for: certificate),
                      let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) else {
                          return false
                      }
                
                // Hash the key, and check it's validity.
                let keyHash = hash(data: (publicKeyData as NSData) as Data, size: SecKeyGetBlockSize(publicKey))
                Log.v("Server Cert key hash: \(keyHash)")
                if hashes.contains(keyHash) {
                    // Success! This is our server!
                    validated = true
                }
            }
        } else {
            // Fallback on earlier versions
            for index in 0..<SecTrustGetCertificateCount(serverTrust) {
                // Get the public key data for the certificate at the current index of the loop.
                guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, index),
                      let publicKey = publicKey(for: certificate),
                      let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) else {
                          return false
                      }
                
                // Hash the key, and check it's validity.
                let keyHash = hash(data: (publicKeyData as NSData) as Data, size: SecKeyGetBlockSize(publicKey))
                print("Cert key hash: \(keyHash)")
                if hashes.contains(keyHash) {
                    // Success! This is our server!
                    validated = true
                }
            }
        }
        
        // If none of the calculated hashes match any of our stored hashes, the connection we tried to establish is untrusted.
        return validated
    }
    
    /// Extracts public key from the certificate
    private func publicKey(for certificate: SecCertificate) -> SecKey? {
        if #available(iOS 12.0, *) {
            return SecCertificateCopyKey(certificate)
        } else {
            return SecCertificateCopyPublicKey(certificate)
        }
    }
    
    /// Creates a hash from the received data using the `sha256` algorithm.
    /// `Returns` the `base64` encoded representation of the hash.
    ///
    /// To replicate the output of the `openssl dgst -sha256` command, an array of specific bytes need to be appended to
    /// the beginning of the data to be hashed.
    /// - Parameter data: The data to be hashed.
    private func hash(data: Data, size: Int) -> String {
        // Add the missing ASN1 header for public keys to re-create the subject public key info
        var keyWithHeader: Data
        
        if size == 256 {
            // 2048
            keyWithHeader = Data(rsa2048Asn1Header)
        } else {
            // 4096
            keyWithHeader = Data(rsa4096Asn1Header)
        }
        
        keyWithHeader.append(data)
        
        // Using CryptoKit
        if #available(iOS 13, *) {
            return Data(SHA256.hash(data: keyWithHeader)).base64EncodedString()
        } else {
            // Using CommonCrypto's CC_SHA256 method
            var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
            _ = keyWithHeader.withUnsafeBytes {
                CC_SHA256($0.baseAddress!, CC_LONG(keyWithHeader.count), &hash)
            }
            return Data(hash).base64EncodedString()
        }
    }
}
