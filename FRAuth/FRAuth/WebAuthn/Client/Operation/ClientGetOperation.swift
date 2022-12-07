//
//  ClientGetOperation.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Original work Copyright © 2018 Lyo Kato. All rights reserved.
//  Modified work Copyright © 2021-2022 ForgeRock, Inc.
//

import Foundation

class ClientGetOperation: AuthenticatorGetAssertionSessionDelegate {
    
    struct GetOperationCompletionCallbacks {
        let onSuccess: GetResponseCompletion
        let onError: ErrorCallback
    }
    
    let id = UUID().uuidString
    let type = ClientOperationType.get
    
    weak var delegate: ClientOperationDelegate?

    private let options:        PublicKeyCredentialRequestOptions
    private let rpId:           String
    private let clientData:     CollectedClientData
    private let clientDataJSON: String
    private let clientDataHash: [UInt8]
    private let lifetimeTimer:  UInt64

    private var savedCredentialId: [UInt8]?

    private var session: AuthenticatorGetAssertionSession
    private var stopped: Bool = false

    private var timer: DispatchSource?
    
    private var completion: GetOperationCompletionCallbacks?
    
    internal init(
        options:        PublicKeyCredentialRequestOptions,
        rpId:           String,
        session:        AuthenticatorGetAssertionSession,
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
    
    
    func start(onSuccess: @escaping GetResponseCompletion, onError: @escaping ErrorCallback) {
        WAKLogger.debug("<GetOperation> start")
        DispatchQueue.global().async {
            if self.stopped {
                let logMessage = "<GetOperation> already stopped"
                WAKLogger.debug(logMessage)
                onError(FRWAKError.badOperation(platformError: nil, message: logMessage))
                self.delegate?.operationDidFinish(opType: self.type, opId: self.id)
                return
            }
            
            let transports: [AuthenticatorTransport] = self.options.allowCredentials.flatMap { $0.transports }
            if !transports.isEmpty && !transports.contains(self.session.transport) {
                let logMessage = "<GetOperation> transport mismatch"
                WAKLogger.debug(logMessage)
                onError(FRWAKError.notAllowed(platformError: nil, message: logMessage))
                self.delegate?.operationDidFinish(opType: self.type, opId: self.id)
                return
            }
            
            self.completion = GetOperationCompletionCallbacks(onSuccess: onSuccess, onError: onError)
            
            // start timer
            // 5.1.4 - 17 Start lifetime timer
            self.startLifetimeTimer()
            
            self.session.delegate = self
            self.session.start()
        }
    }
    
    func cancel(reason: FRWAKError = FRWAKError.cancelled(platformError: nil, message: nil)) {
        WAKLogger.debug("<GetOperation> cancel")
        if self.completion != nil && !self.stopped {
            DispatchQueue.global().async {
                if self.session.transport == .internal_ {
                    // When session is for *internal* authentciator,
                    // it may be showing UI on same process as this client.
                    // At the timing like that,
                    // it causes trouble if this operation tries to close.
                    // So, let the session to start closing
                    WAKLogger.debug("<GetOperation> session is 'internal', send 'cancel' to session")
                    self.session.cancel(reason: reason)
                } else {
                    WAKLogger.debug("<GetOperation> session is not 'internal', close operation")
                    self.stop(by: reason)
                }
            }
        }
    }
    
    private func completed() {
        WAKLogger.debug("<GetOperation> completed")
        if self.completion == nil {
            WAKLogger.debug("<GetOperation> not started")
            return
        }
        if self.stopped {
            WAKLogger.debug("<GetOperation> already stopped")
            return
        }
        self.stopped = true
        self.stopLifetimeTimer()
        self.delegate?.operationDidFinish(opType: self.type, opId: self.id)
    }

    private func stopInternal(reason: FRWAKError) {
        WAKLogger.debug("<GetOperation> stop")
        if self.completion == nil {
            WAKLogger.debug("<GetOperation> not started")
            return
        }
        if self.stopped {
            WAKLogger.debug("<GetOperation> already stopped")
            return
        }
        self.stopped = true
        self.stopLifetimeTimer()
        self.session.cancel(reason: reason)
        self.delegate?.operationDidFinish(opType: self.type, opId: self.id)
    }
    
    private func startLifetimeTimer() {
        WAKLogger.debug("<GetOperation> startLifetimeTimer \(self.lifetimeTimer) sec")
        if self.timer != nil {
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

    private func stop(by error: FRWAKError) {
        WAKLogger.debug("<GetOperation> stop by")
        self.stopInternal(reason: error)
        self.dispatchError(error)
    }

    private func dispatchError(_ error: FRWAKError) {
        WAKLogger.debug("<GetOperation> dispatchError")
        
        if let completion = self.completion {
            completion.onError(error)
            self.completion = nil
        }
    }

    private func stopLifetimeTimer() {
        WAKLogger.debug("<GetOperation> stopLifetimeTimer")
        self.timer?.cancel()
        self.timer = nil
    }

    @objc func lifetimeTimerTimeout() {
        let logMessage = "<GetOperation> timeout"
        WAKLogger.debug(logMessage)
        self.stopLifetimeTimer()
        self.cancel(reason: FRWAKError.timeout(platformError: nil, message: logMessage))
    }

    private func judgeUserVerificationExecution(_ session: AuthenticatorGetAssertionSession) -> Bool {
        WAKLogger.debug("<GetOperation> judgeUserVerificationExecution")
        switch self.options.userVerification {
        case .required:
            return true
        case .preferred:
            return session.canPerformUserVerification()
        case .discouraged:
            return false
        }
    }

    // MARK: AuthenticatorGetAssertionSessionDelegate Methods

    func authenticatorSessionDidBecomeAvailable(session: AuthenticatorGetAssertionSession) {

        WAKLogger.debug("<GetOperation> authenticator become available")
        
        if self.stopped {
            WAKLogger.debug("<GetOperation> already stopped")
            return
        }

        if self.options.userVerification == .required
            && !session.canPerformUserVerification() {
            let logMessage = "<GetOperation> user-verification is required, but this authenticator doesn't support"
            WAKLogger.debug(logMessage)
            self.stop(by: FRWAKError.unsupported(platformError: nil, message: logMessage))
            return
        }

        let userVerification =
            self.judgeUserVerificationExecution(session)

        let userPresence = !userVerification

        if self.options.allowCredentials.isEmpty {

            session.getAssertion(
                rpId:                          self.rpId,
                hash:                          self.clientDataHash,
                allowCredentialDescriptorList: self.options.allowCredentials,
                requireUserPresence:           userPresence,
                requireUserVerification:       userVerification
            )

        } else {

            let allowCredentialDescriptorList = self.options.allowCredentials.filter {
                // TODO more check for id
                $0.transports.contains(session.transport)
            }

            if (allowCredentialDescriptorList.isEmpty) {
                let logMessage = "<GetOperation> no matched credential on this authenticator"
                WAKLogger.debug(logMessage)
                self.stop(by: FRWAKError.notAllowed(platformError: nil, message: logMessage))
                return
            }

            // need to remember the credential Id
            // because authenticator doesn't return credentialId for single descriptor
            if allowCredentialDescriptorList.count == 1 {
                self.savedCredentialId = allowCredentialDescriptorList[0].id
            }

            session.getAssertion(
                rpId:                          self.rpId,
                hash:                          self.clientDataHash,
                allowCredentialDescriptorList: allowCredentialDescriptorList,
                requireUserPresence:           userPresence,
                requireUserVerification:       userVerification
            )

        }
    }

    func authenticatorSessionDidDiscoverCredential(
        session:   AuthenticatorGetAssertionSession,
        assertion: AuthenticatorAssertionResult
    ) {
        
        WAKLogger.debug("<GetOperation> authenticator discovered credential")
        
        var credentialId: [UInt8]
        if let savedId = self.savedCredentialId {
            WAKLogger.debug("<GetOperation> use saved credentialId")
           credentialId = savedId
        } else {
            WAKLogger.debug("<GetOperation> use credentialId from authenticator")
            guard let resultId = assertion.credentailId else {
                let logMessage = "<GetOperation> credentialId not found"
                WAKLogger.debug(logMessage)
                self.dispatchError(FRWAKError.unknown(platformError: nil, message: logMessage))
                return
            }
            credentialId = resultId
        }

        // TODO support extensionResult
        let cred = PublicKeyCredential<AuthenticatorAssertionResponse>(
            rawId:    credentialId,
            id:       Base64.encodeBase64URL(credentialId),
            response: AuthenticatorAssertionResponse(
                clientDataJSON:    self.clientDataJSON,
                authenticatorData: assertion.authenticatorData,
                signature:         assertion.signature,
                userHandle:        assertion.userHandle
            )
        )

        self.completed()
        
        if let completion = self.completion {
            completion.onSuccess(cred)
            self.completion = nil
        }
    }

    func authenticatorSessionDidBecomeUnavailable(session: AuthenticatorGetAssertionSession) {
        let logMessage = "<GetOperation> authenticator become unavailable"
        WAKLogger.debug(logMessage)
        self.stop(by: FRWAKError.notAllowed(platformError: nil, message: logMessage))
    }

    func authenticatorSessionDidStopOperation(
        session: AuthenticatorGetAssertionSession,
        reason:  FRWAKError
    ) {
        WAKLogger.debug("<GetOperation> authenticator stopped operation")
        self.stop(by: reason)
    }

}

