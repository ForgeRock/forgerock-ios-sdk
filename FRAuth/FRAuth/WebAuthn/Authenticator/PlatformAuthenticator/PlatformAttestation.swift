// 
//  PlatformAttestation.swift
//  FRAuth
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/**
 PlatformAttestation class is a representation of Attestation object generated from PlatformAuthenticator
 */
class PlatformAttestation {
    
    //  MARK: - Creates
    
    /// Creates AttestationObject generated from WebAuthn PlatformAuthenticator make credentials operation
    /// - Parameters:
    ///   - authData: AuthenticatorData object
    ///   - clientDataHash: Hashed client data as bytes array
    ///   - alg: Signing algorithm
    ///   - keyLabel: String label value of encryption key
    ///   - attestationPreference: `AttestationConveyancePreference` enum value representing preferred Attestation type
    /// - Returns: Signed, and constructed AttestationObject
    static func create(authData: AuthenticatorData, clientDataHash: [UInt8], alg: COSEAlgorithmIdentifier, keyLabel: String, attestationPreference: AttestationConveyancePreference) -> AttestationObject? {
        var signingData = authData.toBytes()
        signingData.append(contentsOf: clientDataHash)
        
        guard let keySupport = KeySupportChooser().choose([alg]) else {
            FRLog.e("Given key algorithm is not supported", subModule: WebAuthn.module)
            return nil
        }
        
        guard let signedData = keySupport.sign(data: signingData, label: keyLabel) else {
            FRLog.e("Failed to sign the data while generating attestation", subModule: WebAuthn.module)
            return nil
        }
        
        let stmt = SimpleOrderedDictionary<String>()
        stmt.addInt(WebAuthn.alg, Int64(alg.rawValue))
        stmt.addBytes(WebAuthn.sig, signedData)
        
        return AttestationObject(fmt: attestationPreference == .none ? WebAuthn.none : WebAuthn.packed, authData: authData, attStmt: stmt)
    }
}
