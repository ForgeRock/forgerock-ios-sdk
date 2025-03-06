// 
//  PushDeviceTokenManager.swift
//  FRAuthenticator
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// The PushDeviceTokenManager is used to manage the APNS device token. It is responsible for
/// keeping track of the current device token and updating it when necessary.
class PushDeviceTokenManager {

    //  MARK: - Properties
    
    // Keep track of the current APNS device token
    public internal(set) var deviceToken: String?

    
    //  MARK: - Init
    
    /// Constructor
    ///
    /// - Parameters:
    ///   - deviceToken: The FCM device token
    init(_ deviceToken: String? = nil) {
        if let token = deviceToken {
            self.deviceToken = token
        } else {
            self.deviceToken = FRAClient.storage.getPushDeviceToken()?.tokenId
        }
    }

    
    //  MARK: - Functions
    
    /// Get the current Push device token stored in the storage client.
    /// - Returns: The current Push device token object
    func getPushDeviceToken() -> PushDeviceToken? {
        return FRAClient.storage.getPushDeviceToken()
    }

    
    /// Set the push device token. If the token has changed, it will be stored in the storage client.
    /// - Parameter deviceToken: The device token
    func setDeviceToken(_ deviceToken: String) {
        // Compare deviceToken with the current stored token
        if shouldUpdateToken(deviceToken) {
            FRALog.i("Previous stored APNS token: \(self.deviceToken ?? "nil")")

            // Update device token in storage
            self.updateLocalToken(deviceToken)
        } else {
            FRALog.i("APNS device token has not changed.")
        }
    }
    
    
    /// Clear the push device token
    func clearDeviceToken() {
        FRALog.i("Clearing APNS device token.")
        self.deviceToken = nil
    }
    
    
    /// Check if the device token has changed.
    /// - Parameter token: The new device token
    /// - Returns: True if the device token has changed, false otherwise
    func shouldUpdateToken(_ token: String) -> Bool {
        if self.deviceToken == nil {
            if let currentToken = FRAClient.storage.getPushDeviceToken() {
                self.deviceToken = currentToken.tokenId
                return currentToken.tokenId != token
            } else {
                return true
            }
        } else {
            return self.deviceToken != token
        }
    }

    
    // MARK: - Private
    
    private func updateLocalToken(_ newDeviceToken: String) {
        // Update device token in storage
        if !storePushDeviceToken(newDeviceToken) {
            FRALog.e("Error storing APNS device token.")
        }
        self.deviceToken = newDeviceToken // Update the current token
    }


    private func storePushDeviceToken(_ newDeviceToken: String) -> Bool {
        FRALog.i("Storing APNS device token: \(newDeviceToken)")
        let pushDeviceToken = PushDeviceToken(tokenId: newDeviceToken)
        return FRAClient.storage.setPushDeviceToken(pushDeviceToken: pushDeviceToken)
    }
    
}
