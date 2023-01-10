// 
//  FRWebAuthn.swift
//  FRAuth
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore

/**
 FRWebAuthn is a utility class providing helper methods for listing and deleting WebAuthn keys stored on the device.
 The provided static methods are:
 `public static func deleteCredentials(by rpId: String)`
 `public static func loadAllCredentials(by rpId: String) ->  [PublicKeyCredentialSource]`
 `public static func deleteCredential(with publicKeyCredentialSource: PublicKeyCredentialSource)`
 */
public class FRWebAuthn: NSObject {
    /// Deletes stored credentials for a specific Relying Party Identifier
    ///
    /// - Parameters:
    ///   - rpId: Relying Party Identifier
    public static func deleteCredentials(by rpId: String) {
        let platformAuthenticator = PlatformAuthenticator()
        platformAuthenticator.clearAllCredentialsFromCredentialStore(rpId: rpId)
    }
    
    /// Returns all the stored credentials for a specific Relying Party Identifier
    ///
    /// - Parameters:
    ///   - rpId: Relying Party Identifier
    public static func loadAllCredentials(by rpId: String) ->  [PublicKeyCredentialSource] {
        let platformAuthenticator = PlatformAuthenticator()
        return platformAuthenticator.loadAllCredentials(rpId: rpId)
    }
    
    /// Deletes a stored WebAuthn Credential (PublicKeyCredentialSource)
    ///
    /// - Parameters:
    ///   - publicKeyCredentialSource: PublicKeyCredentialSource
    public static func deleteCredential(with publicKeyCredentialSource: PublicKeyCredentialSource) {
        let platformAuthenticator = PlatformAuthenticator()
        return platformAuthenticator.deleteCredential(publicKeyCredentialSource: publicKeyCredentialSource)
    }
}
