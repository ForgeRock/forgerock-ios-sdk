// 
//  PlatformAuthenticatorConfig.swift
//  FRAuth
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/**
 PlatformAuthenticatorConfig class is a representation of PlatformAuthenticator configurations
 */
struct PlatformAuthenticatorConfig {
    
    //  MARK: - Properties
    
    /// Authenticator attachment option; PlatformAuthenticator currently only supports platform, and cross-platform is not supported
    let attachment: AuthenticatorAttachment = .platform
    /// Authenticator transport option; PlatformAuthenticator currently only supports internal transport, and usb, nfc, and ble are not supported
    let transport: AuthenticatorTransport = .internal_
    /// Resident key boolean option; PlatformAuthenticator supports Resident Key
    let allowResidentKey: Bool
    /// Counter step for PlatformAuthenticator
    var counterStep: UInt32
    /// Boolean indicator of whether or not PlatformAuthenticator supports User Verification
    var allowUserVerification: Bool
    
    
    //  MARK: - Lifecycle
    
    /// Initializes PlatformAuthenticatorConfig object with configurations
    /// - Parameters:
    ///   - counterStep: Counter step for Authenticator
    ///   - allowUserVerification: Boolean indicator of whether or not User Verification is supported
    ///   - allowResidentKey: Boolean indicator of whether or not Resident Key is allowed for the authenticator
    init(counterStep: UInt32 = 1, allowUserVerification: Bool = true, allowResidentKey: Bool = true) {
        self.counterStep = counterStep
        self.allowUserVerification = allowUserVerification
        self.allowResidentKey = allowResidentKey
    }
}
