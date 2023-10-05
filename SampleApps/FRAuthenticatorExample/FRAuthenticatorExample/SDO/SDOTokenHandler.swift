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
                if let sdoToken = mechanism.decryptTokenWithSecret(encryptedToken: encryptedToken) {
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
    
}
