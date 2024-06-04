// 
//  FRWebAuthn.swift
//  FRAuth
//
//  Copyright (c) 2023-2024 ForgeRock. All rights reserved.
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
 `public static func deleteCredential(with publicKeyCredentialSource: PublicKeyCredentialSource, forceDelete: Bool)`
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
    
    /// Deletes a locally stored WebAuthn Credential (PublicKeyCredentialSource)
    ///
    /// - Parameters:
    ///   - publicKeyCredentialSource: PublicKeyCredentialSource
    @available(*, deprecated, message: "Use deleteCredential(publicKeyCredentialSource:, forceDelete:) instead")
    public static func deleteCredential(with publicKeyCredentialSource: PublicKeyCredentialSource) {
        let platformAuthenticator = PlatformAuthenticator()
        return platformAuthenticator.deleteCredential(publicKeyCredentialSource: publicKeyCredentialSource)
    }
    
    /// Delete the provide key from local storage and also remotely from Server if the key is discoverable. By default, if failed to delete from server, local storage
    /// will not be deleted, by providing ``forceDelete`` to true, it will also delete local keys if server call is failed.
    /// - Parameter publicKeyCredentialSource: ``PublicKeyCredentialSource`` to be deleted
    /// - Parameter forceDelete: Defaults to false, true will delete local keys even if the server key removal has failed
    /// - Throws: Error during attempt to delete key from server.
    public static func deleteCredential(publicKeyCredentialSource: PublicKeyCredentialSource, forceDelete: Bool = false) throws {
        let remoteWebAuthnRepository = RemoteWebAuthnRepository()
        let platformAuthenticator = PlatformAuthenticator()
        do {
            try remoteWebAuthnRepository.deleteCredential(with: publicKeyCredentialSource)
            platformAuthenticator.deleteCredential(publicKeyCredentialSource: publicKeyCredentialSource)
        } catch let error {
            if forceDelete {
                platformAuthenticator.deleteCredential(publicKeyCredentialSource: publicKeyCredentialSource)
            }
            throw error
        }
    }
}
