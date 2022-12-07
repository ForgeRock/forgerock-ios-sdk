//
//  Client.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Original work Copyright © 2018 Lyo Kato. All rights reserved.
//  Modified work Copyright © 2021-2022 ForgeRock, Inc.
//

import Foundation
import FRCore

enum ClientOperationType {
   case get
   case create
}

protocol ClientOperationDelegate: class {
    func operationDidFinish(opType: ClientOperationType, opId: String)
}

typealias CreateResponseCompletion = (_ response: PublicKeyCredential<AuthenticatorAttestationResponse>) -> Void
typealias GetResponseCompletion = (_ response: PublicKeyCredential<AuthenticatorAssertionResponse>) -> Void

class WebAuthnClient: ClientOperationDelegate {
    
    
    typealias CreateResponse = PublicKeyCredential<AuthenticatorAttestationResponse>
    typealias GetResponse = PublicKeyCredential<AuthenticatorAssertionResponse>

    let origin: String

    var defaultTimeout: UInt64 = 60
    var minTimeout: UInt64 = 5
    var maxTimeout: UInt64 = 300

    private let authenticator: Authenticator

    private var getOperations = [String: ClientGetOperation]()
    private var createOperations = [String: ClientCreateOperation]()

    init(
        origin:        String,
        authenticator: Authenticator
    ) {
        self.origin        = origin
        self.authenticator = authenticator
    }

    
    func create(_ options: PublicKeyCredentialCreationOptions, onSuccess: @escaping CreateResponseCompletion, onError: @escaping ErrorCallback) {
        WAKLogger.debug("<WebAuthnClient> create")
        
        let op = self.newCreateOperation(options)
        op.delegate = self
        self.createOperations[op.id] = op
        
        op.start(onSuccess: onSuccess, onError: onError)
    }
    
    func get(_ options: PublicKeyCredentialRequestOptions, onSuccess: @escaping GetResponseCompletion, onError: @escaping ErrorCallback) {
        WAKLogger.debug("<WebAuthnClient> get")
        
        let op = self.newGetOperation(options)
        op.delegate = self
        self.getOperations[op.id] = op
        
        op.start(onSuccess: onSuccess, onError: onError)
    }

    func cancel() {
        WAKLogger.debug("<WebAuthnClient> cancel")
        self.getOperations.forEach { $0.value.cancel() }
        self.createOperations.forEach { $0.value.cancel() }
    }

    /// this function comforms to https://www.w3.org/TR/webauthn/#createCredential
    func newCreateOperation(_ options: PublicKeyCredentialCreationOptions)
        -> ClientCreateOperation {

            WAKLogger.debug("<WebAuthnClient> newCreateOperation")

            let lifetimeTimer = self.adjustLifetimeTimer(options.timeout)
            let rpId = self.pickRelyingPartyID(options.rp.id)

            // 5.1.3 - 9,10
            // check options.pubKeyCredParmas
            // currently 'public-key' is only in specification.
            // do nothing

            // TODO Extension handling
            // 5.1.3 - 11
            // 5.1.3 - 12

            // 5.1.3 - 13,14,15 Prepare ClientData, JSON, Hash
            let (clientData, clientDataJSON, clientDataHash) =
                self.generateClientData(
                    type:      .webAuthnCreate,
                    challenge: String(data: Data(options.challenge), encoding: .utf8)!
                )
        
        
            let session = self.authenticator.newMakeCredentialSession()

            return ClientCreateOperation(
                options:        options,
                rpId:           rpId,
                session:        session,
                clientData:     clientData,
                clientDataJSON: clientDataJSON,
                clientDataHash: clientDataHash,
                lifetimeTimer:  lifetimeTimer
            )

    }

    func newGetOperation(_ options: PublicKeyCredentialRequestOptions)
        -> ClientGetOperation {

        WAKLogger.debug("<WebAuthnClient> newGetOperation")

        let lifetimeTimer = self.adjustLifetimeTimer(options.timeout)
        let rpId = self.pickRelyingPartyID(options.rpId)

        // TODO Extension handling
        // 5.1.4 - 8,9

        // 5.1.4 - 10, 11, 12
        let (clientData, clientDataJSON, clientDataHash) =
            self.generateClientData(
                type:      .webAuthnGet,
                challenge: String(data: Data(options.challenge), encoding: .utf8)!
        )

        let session = self.authenticator.newGetAssertionSession()

        return ClientGetOperation(
            options:        options,
            rpId:           rpId,
            session:        session,
            clientData:     clientData,
            clientDataJSON: clientDataJSON,
            clientDataHash: clientDataHash,
            lifetimeTimer:  lifetimeTimer
        )
    }

    func operationDidFinish(opType: ClientOperationType, opId: String) {
        WAKLogger.debug("<WebAuthnClient> operationDidFinish")
        switch opType {
        case .get:
            self.getOperations.removeValue(forKey: opId)
        case .create:
            self.createOperations.removeValue(forKey: opId)
        }
    }

    /// this function comforms to https://www.w3.org/TR/webauthn/#createCredential
    /// 5.1.3 - 4
    /// If the timeout member of options is present, check if its value lies within a reasonable
    /// range as defined by the client and if not, correct it to the closest value lying within that range.
    /// Set a timer lifetimeTimer to this adjusted value. If the timeout member of options is not present,
    /// then set lifetimeTimer to a client-specific default.
    private func adjustLifetimeTimer(_ timeout: UInt64?) -> UInt64 {
        WAKLogger.debug("<WebAuthnClient> adjustLifetimeTimer")
        // TODO assert self.maxTimeout > self.minTimeout
        if let t = timeout {
            if (t < self.minTimeout) {
                return self.minTimeout
            }
            if (t > self.maxTimeout) {
                return self.maxTimeout
            }
            return t
        } else {
            return self.defaultTimeout
        }
    }

    /// this function comforms to https://www.w3.org/TR/webauthn/#createCredential
    /// 5.1.3 - 7 If options.rpId is not present, then set rpId to effectiveDomain.
    private func pickRelyingPartyID(_ rpId: String?) -> String {

        WAKLogger.debug("<WebAuthnClient> pickRelyingPartyID")

        if let _rpId = rpId {
            return _rpId
        } else {
            // TODO take EffectiveDomain from origin, properly.
            return self.origin
        }
    }

    // 5.1.3 - 13,14,15 Prepare ClientData, JSON, Hash
    private func generateClientData(
        type:      CollectedClientDataType,
        challenge: String
        ) -> (CollectedClientData, String, [UInt8]) {

        WAKLogger.debug("<WebAuthnClient> generateClientData")

        // TODO TokenBinding
        let clientData = CollectedClientData(
            type:         type,
            challenge:    challenge,
            origin:       self.origin,
            tokenBinding: nil
        )

        let clientDataJSONData = try! JSONEncoder().encode(clientData)
        let clientDataJSON = String(data: clientDataJSONData, encoding: .utf8)!
        let clientDataHash = clientDataJSONData.sha256.bytes

        return (clientData, clientDataJSON, clientDataHash)
    }

}

