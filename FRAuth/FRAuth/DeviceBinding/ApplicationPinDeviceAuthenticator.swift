// 
//  ApplicationPinDeviceAuthenticator.swift
//  FRAuth
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import LocalAuthentication
import FRCore


/// DeviceAuthenticator adoption for Application Pin authentication
open class ApplicationPinDeviceAuthenticator: DeviceAuthenticator, CryptoAware {
    /// prompt  for authentication promp if applicable
    var prompt: Prompt?
    /// cryptoKey for key pair generation
    var cryptoKey: CryptoKey?
    /// AppPinAuthenticator to take care of key generation
    var appPinAuthenticator: AppPinAuthenticator?
    
    
    /// Generate public and private key pair
    open func generateKeys() throws -> KeyPair {
        guard let appPinAuthenticator = appPinAuthenticator, let prompt = prompt else {
            throw DeviceBindingStatus.unsupported(errorMessage: "Cannot generate keys, missing appPinAuthenticator or prompt")
        }
        
        return try appPinAuthenticator.generateKeys(description: prompt.description)
    }
    
    
    /// Check if authentication is supported
    open func isSupported() -> Bool {
        return true
    }
    
    
    /// Access Control for the authetication type
    open func accessControl() -> SecAccessControl? {
        return appPinAuthenticator?.accessControl()
    }
    
    
    open func type() -> DeviceBindingAuthenticationType {
        return .applicationPin
    }
    
    
    open func setKey(cryptoKey: CryptoKey) {
        self.cryptoKey = cryptoKey
        self.appPinAuthenticator = AppPinAuthenticator(cryptoKey: cryptoKey)
    }
    
    
    open func setPrompt(_ prompt: Prompt) {
        self.prompt = prompt
    }
}
