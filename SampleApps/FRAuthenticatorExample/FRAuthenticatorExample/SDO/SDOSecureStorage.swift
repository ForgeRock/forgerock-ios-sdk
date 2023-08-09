//
//  SDOSecureStorage.swift
//  FRAuthenticatorExample
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//
//

import Foundation
import FRCore
import FRAuthenticator


/// This class is responsible to securely store and retrieve the SDO token.
struct SDOSecureStorage {
    var tokenStorage: KeychainService
    let keychainServiceIdentifier = "com.forgerock.authenticator.keychainservice.local"
    let tokenKey = "token"
    
    init() {
        self.tokenStorage = KeychainService(service: keychainServiceIdentifier + ".\(tokenKey)")
    }
    
    /// Stores the SDO token.
    ///  - Parameters:
    ///     - token: the SDO token as string
    /// - Returns: Boolean result of the operation
    @discardableResult func setToken(token: String) -> Bool {
        do {
            let tokenData = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
            return self.tokenStorage.set(tokenData, key: tokenKey)
        }
        catch {
            NSLog("Failed to serialize Token object: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Retrieves the SDO token.
    /// - Returns: The SDO token as string
    func getToken() -> String? {
        if let tokenData = self.tokenStorage.getData(tokenKey),
           let data = NSKeyedUnarchiver.unarchiveObject(with: tokenData) as? String {
            return data
        }
        else {
            return nil
        }
    }
}


