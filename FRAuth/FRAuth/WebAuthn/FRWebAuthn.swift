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

public class FRWebAuthn: NSObject {
    public static func deleteCredentials(by rpId: String) {
        let platformAuthenticator = PlatformAuthenticator()
        platformAuthenticator.clearAllCredentialsFromCredentialStore(rpId: rpId)
    }
    
    public static func loadAllCredentials(by rpId: String) ->  [PublicKeyCredentialSource] {
        let platformAuthenticator = PlatformAuthenticator()
        return platformAuthenticator.loadAllCredentials(rpId: rpId)
    }
    
    public static func deleteCredential(with publicKeyCredentialSource: PublicKeyCredentialSource) {
        let platformAuthenticator = PlatformAuthenticator()
        return platformAuthenticator.deleteCredential(publicKeyCredentialSource: publicKeyCredentialSource)
    }
}
