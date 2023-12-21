// 
//  Binding.swift
//  FRDeviceBinding
//
//  Copyright (c) 2022-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation


/// Device Binding protocol to provide utility methods for ``DeviceBindingCallback`` and ``DeviceSigningVerifierCallback``
public protocol Binding {
    
    /// Create the interface for the authentication type
    /// - Parameter type: The Device Binding Authentication Type
    /// - Returns: The recommended  ``DeviceAuthenticator`` that can handle the provided ``DeviceBindingAuthenticationType``
    func getDeviceAuthenticator(type: DeviceBindingAuthenticationType) -> DeviceAuthenticator
    
    /// Get Expiration date for the signed token, claim "exp" will be set to the JWS.
    /// - Returns: The expiration date
    func getExpiration(timeout: Int?) -> Date
    
    /// Default property(method) to identify ``DeviceAuthenticator``
    var deviceAuthenticatorIdentifier: (DeviceBindingAuthenticationType) -> DeviceAuthenticator { get }
}
