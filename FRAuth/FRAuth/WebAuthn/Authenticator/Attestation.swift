//
//  Attestation.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Original work Copyright © 2018 Lyo Kato. All rights reserved.
//  Modified work Copyright © 2021 ForgeRock, Inc.
//

import Foundation
import FRCore

class AttestationObject {

    let fmt: String
    let authData: AuthenticatorData
    let attStmt: SimpleOrderedDictionary<String>

    init(fmt:      String,
         authData: AuthenticatorData,
         attStmt:  SimpleOrderedDictionary<String>) {

        self.fmt      = fmt
        self.authData = authData
        self.attStmt  = attStmt
    }

    func toNone() -> AttestationObject {
        return AttestationObject(
            fmt: WebAuthn.none,
            authData: self.authData,
            attStmt: SimpleOrderedDictionary<String>()
        )
    }

    func isSelfAttestation() -> Bool {
        if self.fmt != "packed" {
            return false
        }
        if let _ = self.attStmt.get("x5c") {
            return false
        }
        if let _ = self.attStmt.get("ecdaaKeyId") {
            return false
        }
        guard let attestedCred = self.authData.attestedCredentialData else {
            return false
        }
        if attestedCred.aaguid.contains(where: { $0 != 0x00 }) {
            return false
        }
        return true
    }

    func toBytes() -> Optional<[UInt8]> {

        let dict = SimpleOrderedDictionary<String>()
        dict.addBytes("authData", self.authData.toBytes())
        dict.addString("fmt", self.fmt)
        dict.addStringKeyMap("attStmt", self.attStmt)

        return CBORWriter()
            .putStringKeyMap(dict)
            .getResult()
    }
    
}
