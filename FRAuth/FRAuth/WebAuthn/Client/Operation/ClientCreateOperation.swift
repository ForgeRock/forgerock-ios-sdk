//
//  ClientCreateOperation.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Original work Copyright © 2018 Lyo Kato. All rights reserved.
//  Modified work Copyright © 2021-2022 ForgeRock, Inc.
//

import Foundation

class ClientCreateOperation: AuthenticatorMakeCredentialSessionDelegate {
    
    struct CreateOperationCompletionCallbacks {
        let onSuccess: CreateResponseCompletion
        let onError: ErrorCallback
    }
    
    let id = UUID().uuidString
    let type = ClientOperationType.create
    
    weak var delegate: ClientOperationDelegate?

    private let options:        PublicKeyCredentialCreationOptions
    private let rpId:           String
    private let clientData:     CollectedClientData
    private let clientDataJSON: String
    private let clientDataHash: [UInt8]
    private let lifetimeTimer:  UInt64
    
    private var session: AuthenticatorMakeCredentialSession

    private var stopped: Bool = false

    private var timer: DispatchSource?
    
    private var completion: CreateOperationCompletionCallbacks?

    internal init(
        options:        PublicKeyCredentialCreationOptions,
        rpId:           String,
        session:        AuthenticatorMakeCredentialSession,
        clientData:     CollectedClientData,
        clientDataJSON: String,
        clientDataHash: [UInt8],
        lifetimeTimer:  UInt64
    ) {
        self.options        = options
        self.rpId           = rpId
        self.session        = session
        self.clientData     = clientData
        self.clientDataJSON = clientDataJSON
        self.clientDataHash = clientDataHash
        self.lifetimeTimer  = lifetimeTimer
    }
    
    
    func start(onSuccess: @escaping CreateResponseCompletion, onError: @escaping ErrorCallback) {
        WAKLogger.debug("<CreateOperation> start")
        
        DispatchQueue.global().async {
            if self.stopped {
                let logMessage = "<CreateOperation> already stopped"
                WAKLogger.debug(logMessage)
                onError(FRWAKError.badOperation(platformError: nil, message: logMessage))
                self.delegate?.operationDidFinish(opType: self.type, opId: self.id)
                return
            }
            if self.completion != nil {
                let logMessage = "<CreateOperation> already started"
                WAKLogger.debug(logMessage)
                onError(FRWAKError.badOperation(platformError: nil, message: logMessage))
                self.delegate?.operationDidFinish(opType: self.type, opId: self.id)
                return
            }
            
            self.completion = CreateOperationCompletionCallbacks(onSuccess: onSuccess, onError: onError)
            
            self.startLifetimeTimer()

            self.session.delegate = self
            self.session.start()
        }
        
    }

    func cancel(reason: FRWAKError = FRWAKError.cancelled(platformError: nil, message: nil)) {
        WAKLogger.debug("<CreateOperation> cancel")
        if self.completion != nil && !self.stopped {
            DispatchQueue.global().async {
                if self.session.transport == .internal_ {
                    // When session is for *internal* authentciator,
                    // it may be showing UI on same process as this client.
                    // At the timing like that,
                    // it causes trouble if this operation tries to close.
                    // So, let the session to start closing
                    if case FRWAKError.timeout(let platformError, let message) = reason {
                        self.session.cancel(reason: FRWAKError.timeout(platformError: platformError, message: message ?? "<CreateOperation> timeout"))
                    } else {
                        self.session.cancel(reason: FRWAKError.cancelled(platformError: nil, message: "<CreateOperation> cancelled"))
                    }
                } else {
                    self.stop(by: reason)
                }
            }
        }
    }
    
    private func completed() {
        WAKLogger.debug("<CreateOperation> completed")
        if self.completion == nil {
            WAKLogger.debug("<CreateOperation> not started")
            return
        }
        if self.stopped {
            WAKLogger.debug("<CreateOperation> already stopped")
            return
        }
        self.stopped = true
        self.stopLifetimeTimer()
        self.delegate?.operationDidFinish(opType: self.type, opId: self.id)
    }

    private func stopInternal(reason: FRWAKError) {
        WAKLogger.debug("<CreateOperation> stop")
        if self.completion == nil {
            WAKLogger.debug("<CreateOperation> not started")
            return
        }
        if self.stopped {
            WAKLogger.debug("<CreateOperation> already stopped")
            return
        }
        self.stopped = true
        self.stopLifetimeTimer()
        self.session.cancel(reason: reason)
        self.delegate?.operationDidFinish(opType: self.type, opId: self.id)
    }

    // MARK: Private Methods

    private func stop(by error: FRWAKError) {
        WAKLogger.debug("<CreateOperation> stop by \(error)")
        self.stopInternal(reason: error)
        self.dispatchError(error)
    }

    private func dispatchError(_ error: FRWAKError) {
        WAKLogger.debug("<CreateOperation> dispatchError")
        if let completion = self.completion {
            completion.onError(error)
            self.completion = nil
        }
    }

    private func startLifetimeTimer() {
        WAKLogger.debug("<CreateOperation> startLifetimeTimer: \(self.lifetimeTimer) sec")
        if self.timer != nil {
            WAKLogger.debug("<CreateOperation> timer already started")
            return
        }
        if let timer = DispatchSource.makeTimerSource() as? DispatchSource {
            timer.schedule(deadline: .now() + TimeInterval(self.lifetimeTimer))
            timer.setEventHandler(handler: {
                [weak self] in
                self?.lifetimeTimerTimeout()
            })
            timer.resume()
            self.timer = timer
        }
    }

    private func stopLifetimeTimer() {
        WAKLogger.debug("<CreateOperation> stopLifetimeTimer")
        self.timer?.cancel()
        self.timer = nil
    }

    @objc func lifetimeTimerTimeout() {
        let logMessage = "<CreateOperation> timeout"
        WAKLogger.debug(logMessage)
        self.stopLifetimeTimer()
        self.cancel(reason: FRWAKError.timeout(platformError: nil, message: logMessage))
    }

    private func judgeUserVerificationExecution(_ session: AuthenticatorMakeCredentialSession) -> Bool {
        WAKLogger.debug("<CreateOperation> judgeUserVerificationExecution")
        let userVerificationRequest =
            self.options.authenticatorSelection?.userVerification ?? .discouraged
        switch userVerificationRequest {
        case .required:
            return true
        case .preferred:
            return session.canPerformUserVerification()
        case .discouraged:
            return false
        }
    }

    // MARK: AuthenticatorMakeCredentialSessionDelegate Methods

    /// 5.1.3 - 20
    func authenticatorSessionDidBecomeAvailable(session: AuthenticatorMakeCredentialSession) {
        
        WAKLogger.debug("<CreateOperation> authenticator become available")

        if self.stopped {
            WAKLogger.debug("<CreateOperation> already stopped")
            return
        }

        if let selection = self.options.authenticatorSelection {

            // XXX should be checked beforehand?
            if let attachment = selection.authenticatorAttachment {
                if attachment != session.attachment {
                    let logMessage = "<CreateOperation> authenticator's attachment doesn't match to RP's request"
                    WAKLogger.debug(logMessage)
                    self.stop(by: FRWAKError.unsupported(platformError: nil, message: logMessage))
                    return
                }
            }

            if selection.requireResidentKey
                && !session.canStoreResidentKey() {
                let logMessage = "<CreateOperation> This authenticator can't store resident-key"
                WAKLogger.debug(logMessage)
                self.stop(by: FRWAKError.unsupported(platformError: nil, message: logMessage))
                return
            }

            if selection.userVerification == .required
                && !session.canPerformUserVerification() {
                let logMessage = "<CreateOperation> This authenticator can't perform user verification"
                WAKLogger.debug(logMessage)
                self.stop(by: FRWAKError.unsupported(platformError: nil, message: logMessage))
                return
            }
        }

        let userVerification =
            self.judgeUserVerificationExecution(session)

        let userPresence = !userVerification

        let excludeCredentialDescriptorList =
            self.options.excludeCredentials.filter {descriptor in
                if descriptor.transports.contains(session.transport) {
                    return false
                } else {
                    return true
                }
        }

        let requireResidentKey =
            options.authenticatorSelection?.requireResidentKey ?? false

        let rpEntity = PublicKeyCredentialRpEntity(
            id:   self.rpId,
            name: options.rp.name,
            icon: options.rp.icon
        )

        session.makeCredential(
            hash:                            self.clientDataHash,
            rpEntity:                        rpEntity,
            userEntity:                      options.user,
            requireResidentKey:              requireResidentKey,
            requireUserPresence:             userPresence,
            requireUserVerification:         userVerification,
            attestationPreference:           options.attestation,
            credTypesAndPubKeyAlgs:          options.pubKeyCredParams,
            excludeCredentialDescriptorList: excludeCredentialDescriptorList
        )
    }

    func authenticatorSessionDidBecomeUnavailable(session: AuthenticatorMakeCredentialSession) {
        let logMessage = "<CreateOperation> authenticator become unavailable"
        WAKLogger.debug(logMessage)
        self.stop(by: FRWAKError.notAllowed(platformError: nil, message: logMessage))
    }

    func authenticatorSessionDidMakeCredential(
        session:     AuthenticatorMakeCredentialSession,
        attestation: AttestationObject
    ) {
        WAKLogger.debug("<CreateOperation> authenticator made credential")
        
        guard let attestedCred =
            attestation.authData.attestedCredentialData else {
            let logMessage = "<CreateOperation> attested credential data not found"
            WAKLogger.debug(logMessage)
            self.dispatchError(FRWAKError.unknown(platformError: nil, message: logMessage))
            return
        }

        let credentialId = attestedCred.credentialId

        var atts = attestation
        
        // XXX currently not support replacing attestation
        //     on "indirect" conveyance request
        
        var attestationObject: [UInt8]! = nil
        if self.options.attestation == .none && !attestation.isSelfAttestation() {
            WAKLogger.debug("<CreateOperation> attestation conveyance request is 'none', but this is not a self-attestation.")
            atts = attestation.toNone()
            guard let bytes = atts.toBytes() else {
                let logMessage = "<CreateOperation> failed to build attestation-object"
                WAKLogger.debug(logMessage)
                self.dispatchError(FRWAKError.unknown(platformError: nil, message: logMessage))
                return
            }
            attestationObject = bytes
            
            WAKLogger.debug("<CreateOperation> replace AAGUID with zero")
        } else {
            guard let bytes = atts.toBytes() else {
                let logMessage = "<CreateOperation> failed to build attestation-object"
                WAKLogger.debug(logMessage)
                self.dispatchError(FRWAKError.unknown(platformError: nil, message: logMessage))
                return
            }
            attestationObject = bytes
        }

        let response =
            AuthenticatorAttestationResponse(
                clientDataJSON:    self.clientDataJSON,
                attestationObject: attestationObject
            )

        // TODO support extensionResult
        let cred = PublicKeyCredential<AuthenticatorAttestationResponse>(
            rawId:    credentialId,
            id:       Base64.encodeBase64URL(credentialId),
            response: response
        )

        self.completed()

        if let completion = self.completion {
            completion.onSuccess(cred)
            self.completion = nil
        }
    }

    func authenticatorSessionDidStopOperation(
        session: AuthenticatorMakeCredentialSession,
        reason:  FRWAKError
    ) {
        WAKLogger.debug("<CreateOperation> authenticator stopped operation")
        self.stop(by: reason)
    }
}
