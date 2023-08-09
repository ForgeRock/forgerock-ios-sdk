//
//  SDOTokenHandler.swift
//  FRAuthenticatorExample
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//
//

import Foundation
import FRAuthenticator
import CommonCrypto

/// This class is responsible to handle SDO Token operations.
class SDOTokenHandler {
    let sdoSecureStorage = SDOSecureStorage()
    
    /// Process the sdoToken sent via PushNotification payload and securely store it.
    /// - Parameters:
    ///   - notification: the PushNotification object
    ///   - mechanism:  the PushMechanism associated with the notification.
    public func processSdoTokenFromPushNotification(notification: PushNotification, mechanism: Mechanism) {
        if let customPaylod = notification.customPayload, !customPaylod.isEmpty {
            if let payload = FRJSONEncoder.jsonStringToDictionary(jsonString: customPaylod),
               let encryptedToken = payload["sdoToken"] as? String {
                NSLog("SDO token found in the notification payload")
                
                NSLog("Decrypting SDO token...")
                if let sdoToken = decryptToken(encryptedToken: encryptedToken, sharedSecret: mechanism.secret) {
                    NSLog("Saving SDO Token: \(sdoToken)")
                    sdoSecureStorage.setToken(token: sdoToken)
                } else {
                    NSLog("Could not decrypt SDO Token")
                }
            } else {
                NSLog("No SDO token found in the notification payload")
            }
        } else {
            NSLog("No custom payload in the notification. Skipping SDO Token processing.")
        }
    }
    
    
    /// Retrieves the SDO token.
    /// - Returns: The SDO token as string
    public func getToken() -> String? {
        return sdoSecureStorage.getToken()
    }
    
    
    private func decryptToken(encryptedToken: String, sharedSecret: String) -> String? {
        let encryptedPair = encryptedToken.split(separator: ".")
        let iv = String(encryptedPair[0])
        let cipherText = String(encryptedPair[1])
        
        if let keyData = sharedSecret.decodeURL(),
           let cipherData = cipherText.decodeURL(),
           let decryptedTokenBytes = try? QCCAESPadCBCDecrypt(key: keyData.bytes, iv: iv.bytes, cyphertext: cipherData.bytes),
           let decryptedToken = String(bytes: decryptedTokenBytes, encoding: .utf8) {
            return decryptedToken
        } else {
            NSLog("Unable to decrypt SDO Token")
            return nil
        }
    }
    
    
    private func QCCAESPadCBCDecrypt(key: [UInt8], iv: [UInt8], cyphertext: [UInt8]) throws -> [UInt8] {
        // The key size must be 128, 192, or 256.
        // The IV size must match the block size.
        // The ciphertext must be a multiple of the block size.
        guard
            [kCCKeySizeAES128, kCCKeySizeAES192, kCCKeySizeAES256].contains(key.count),
            iv.count == kCCBlockSizeAES128,
            cyphertext.count.isMultiple(of: kCCBlockSizeAES128)
        else {
            throw QCCError(code: kCCParamError)
        }
        
        // Padding can expand the data on encryption, but on decryption the data can
        // only shrink so we use the cyphertext size as our plaintext size.
        var plaintext = [UInt8](repeating: 0, count: cyphertext.count)
        var plaintextCount = 0
        let err = CCCrypt(
            CCOperation(kCCDecrypt),
            CCAlgorithm(kCCAlgorithmAES),
            CCOptions(kCCOptionPKCS7Padding),
            key, key.count,
            iv,
            cyphertext, cyphertext.count,
            &plaintext, plaintext.count,
            &plaintextCount
        )
        guard err == kCCSuccess else {
            throw QCCError(code: err)
        }
        
        // Trim any unused bytes off the plaintext.
        assert(plaintextCount <= plaintext.count)
        plaintext.removeLast(plaintext.count - plaintextCount)
        
        return plaintext
    }
}

/// Wraps `CCCryptorStatus` for use in Swift.
struct QCCError: Error {
    var code: CCCryptorStatus
}

extension QCCError {
    init(code: Int) {
        self.init(code: CCCryptorStatus(code))
    }
}
