// 
//  PlatformAuthenticatorGetAssertionSession.swift
//  FRAuth
//
//  Copyright (c) 2021-2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import LocalAuthentication

/**
 PlatformAuthenticatorGetAssertionSession is responsible to generate WebAuthn assertion for authentication following `6.3.3 The authenticatorGetAssertion Operation` in Web Authntication specification (https://www.w3.org/TR/webauthn/#sctn-op-get-assertion)
 */
class PlatformAuthenticatorGetAssertionSession: AuthenticatorGetAssertionSession {
    
    //  MARK: - Protocol Properties
    
    /// Authenticator's attachment
    var attachment: AuthenticatorAttachment {
        get {
            return self.config.attachment
        }
    }
    
    /// Authenticator's transport
    var transport: AuthenticatorTransport {
        get {
            return self.config.transport
        }
    }
    
    /// Delegation for internal WebAuthnClient's get assertion operations
    weak var delegate: AuthenticatorGetAssertionSessionDelegate?
    
    /// Delegation for PlatformAuthenticator process for generating authentication assertion, and handle user interaction
    weak var authenticatorDelegate: PlatformAuthenticatorAuthenticationDelegate?
    
    
    //  MARK: - Instance Properties
    
    /// PlatformAuthenticator's configuration
    private let config: PlatformAuthenticatorConfig
    /// Boolean indicator of whether or not the session is in progress
    private var inProgress: Bool = false
    /// Boolean indicator of whether or not the session did already stop
    private var didStop: Bool = false
    /// KeySupportChooser for PlatformAuthenticator
    private let keySupportChooser: KeySupportChooser
    /// CredentialStorage for PlatformAuthenticator
    private let credentialsStore: CredentialStore
    
    
    //  MARK: - Init
    
    /// Initializes PlatformAuthenticatorGetAssertionSession object with Authenticator's configurations, other utility classes to support the operation
    /// - Parameters:
    ///   - config: PlatformAuthenticator's configuration
    ///   - keySupportChooser: KeySupportChooser for PlatformAuthenticator
    ///   - credentialsStore: Credential storage for PlatformAuthenticator
    ///   - authenticatorDelegate: Delegation for PlatformAuthenticator's get assertion operation
    init(config: PlatformAuthenticatorConfig, keySupportChooser: KeySupportChooser, credentialsStore: CredentialStore, authenticatorDelegate: PlatformAuthenticatorAuthenticationDelegate? = nil) {
        self.config = config
        self.keySupportChooser = keySupportChooser
        self.credentialsStore = credentialsStore
        self.authenticatorDelegate = authenticatorDelegate
    }
    
    
    //  MARK: - AuthenticatorGetAssertionSession Protocol Methods
    
    /// Returns boolean value of whether or not the current session can support User Verification
    /// - Returns: Boolean value of whether or not User Verification is supported
    func canPerformUserVerification() -> Bool {
        return self.config.allowUserVerification
    }
    
    
    //  MARK: - AuthenticatorGetAssertionSession Protocol Methods - Lifecycle
    
    /// Starts the session' operation to generate assertion
    func start() {
        FRLog.v("getAssertion started", subModule: WebAuthn.module)
        guard !self.didStop else {
            return
        }
        
        guard !self.inProgress else {
            return
        }
        
        self.inProgress = true
        self.delegate?.authenticatorSessionDidBecomeAvailable(session: self)
    }
    
    
    /// Cancels the session's operation to generate assertion
    /// - Parameter reason: cancellation reason as in WAKError
    func cancel(reason: FRWAKError) {
        FRLog.v("getAssertion cancelled: \(reason.localizedDescription) - \(reason.message() ?? "")", subModule: WebAuthn.module)
        guard !self.didStop else {
            return
        }
        self.stop(reason: reason)
    }
    
    
    /// Stops the session's operation to generate assertion
    /// - Parameter reason: stopping reason as in WAKError
    func stop(reason: FRWAKError) {
        FRLog.v("getAssertion stopped: \(reason.localizedDescription) - \(reason.message() ?? "")", subModule: WebAuthn.module)
        guard self.inProgress else {
            return
        }
        
        guard !self.didStop else {
            return
        }
        
        self.didStop = true
        self.delegate?.authenticatorSessionDidStopOperation(session: self, reason: reason)
    }
    
    
    /// Completes the session's operation
    func completed() {
        FRLog.v("getAssertion completed", subModule: WebAuthn.module)
        self.didStop = true
    }
    
    
    //  MARK: - AuthenticatorGetAssertionSession Protocol Methods - Get Assertion
    
    /// Generates and returns WebAuthn authentication assertion based on given credentials
    /// - Parameters:
    ///   - rpId: Relying party identifier as in String to generate the assertion
    ///   - hash: An array of bytes from challenge to generate the assertion
    ///   - allowCredentialDescriptorList: An array of allowed credential identifiers to generate the assertion
    ///   - requireUserPresence: Boolean indicator of whether or not User Presense is required to generate the assertion
    ///   - requireUserVerification: Boolean indicator of whether or not User Verification is required to generate the assertion
    func getAssertion(rpId: String, hash: [UInt8], allowCredentialDescriptorList: [PublicKeyCredentialDescriptor], requireUserPresence: Bool, requireUserVerification: Bool) {
        FRLog.v("Generating assertion operation initiated", subModule: WebAuthn.module)
        //  Get an array of credentials with allowed credentials, and relyingPartyId
        let credSources = self.getCredentialsSources(rpId: rpId, allowCredentialDescriptorList: allowCredentialDescriptorList)
        guard !credSources.isEmpty else {
            let logMessage = "Credential source is empty; stopping the operation"
            FRLog.w(logMessage, subModule: WebAuthn.module)
            self.stop(reason: FRWAKError.notAllowed(platformError: nil, message: logMessage))
            return
        }
        
        //  When credentialSource is more than one item, get user's consent to choose a specific credentials to be used to generate the assertion through delegation
        self.selectCredentialsFromSources(sources: credSources) { (keyName) in
            if let keyName = keyName, let selectedCredentials = credSources[keyName] {
                //  Perform user verification if required
                FRLog.v("Performing User Verification", subModule: WebAuthn.module)
                self.performUserVerification(requireUserVerification: requireUserVerification) { (error) in
                    guard error == nil else {
                        if let wakErr = error as? FRWAKError {
                            self.stop(reason: wakErr)
                        }
                        else {
                            self.stop(reason: FRWAKError.unknown(platformError: nil, message: nil))
                        }
                        return
                    }
                    
                    //  Adjust sign count
                    var newSignCount: UInt32 = 0
                    var copiedCred = selectedCredentials
                    copiedCred.signCount = selectedCredentials.signCount + self.config.counterStep
                    newSignCount = copiedCred.signCount
                    
                    //  Store updated credential source
                    guard self.credentialsStore.saveCredentialSource(copiedCred) else {
                        let logMessage = "Updating credential source for signing count failed"
                        FRLog.e(logMessage, subModule: WebAuthn.module)
                        self.stop(reason: FRWAKError.unknown(platformError: nil, message: logMessage))
                        return
                    }
                    FRLog.v("Signing count updated", subModule: WebAuthn.module)
                    
                    //  Generate AuthenticatorData based on the information
                    let extensions = SimpleOrderedDictionary<String>()
                    let authenticatorData = AuthenticatorData(rpIdHash: rpId.sha256!.bytes, userPresent: (requireUserPresence || requireUserVerification), userVerified: requireUserVerification, signCount: newSignCount, attestedCredentialData: nil, extensions: extensions)
                    let authenticatorDataBytes = authenticatorData.toBytes()
                    
                    var data = authenticatorDataBytes
                    data.append(contentsOf: hash)
                    
                    guard let alg = COSEAlgorithmIdentifier.fromInt(selectedCredentials.alg) else {
                        let logMessage = "Unknown key algorithm (\(selectedCredentials.alg)), stopping operation"
                        FRLog.e(logMessage, subModule: WebAuthn.module)
                        self.stop(reason: FRWAKError.unsupported(platformError: nil, message: logMessage))
                        return
                    }
                    
                    guard let keySupport = self.keySupportChooser.choose([alg]) else {
                        let logMessage = "Not supported key algorithm (\(selectedCredentials.alg)), stopping operation"
                        FRLog.e(logMessage, subModule: WebAuthn.module)
                        self.stop(reason: FRWAKError.unsupported(platformError: nil, message: logMessage))
                        return
                    }
                    
                    guard let signature = keySupport.sign(data: data, label: selectedCredentials.keyLabel) else {
                        let logMessage = "Failed to sign the data"
                        FRLog.e(logMessage, subModule: WebAuthn.module)
                        self.stop(reason: FRWAKError.unknown(platformError: nil, message: logMessage))
                        return
                    }
                    
                    //  Create AuthenticatorAssertionResult object
                    var assertion = AuthenticatorAssertionResult(authenticatorData: authenticatorDataBytes, signature: signature)
                    assertion.userHandle = selectedCredentials.userHandle
                    
                    if allowCredentialDescriptorList.count != 1 {
                        assertion.credentailId = selectedCredentials.id
                    }
                    
                    self.completed()
                    self.delegate?.authenticatorSessionDidDiscoverCredential(session: self, assertion: assertion)
                }
            }
            else {
                let logMessage = "Unknwon 'keyName' is returned; stopping the operation"
                FRLog.e(logMessage, subModule: WebAuthn.module)
                self.stop(reason: FRWAKError.notAllowed(platformError: nil, message: logMessage))
                return
            }
        }
        
    }
    
    
    //  MARK: - Internal
    
    /// Selects a specific credential to be used to generate from retrieved array of credential sources
    /// - Parameters:
    ///   - sources: An array of credential sources
    ///   - callback: Completion callback to notify a string value of selected key
    func selectCredentialsFromSources(sources: [String: PublicKeyCredentialSource], callback: @escaping WebAuthnCredentialsSelectionCallback) {
        
        if sources.keys.count == 1, let keyName = sources.keys.first {
            FRLog.v("Found 1 credential source; proceed with it")
            callback(keyName)
            return
        }
        else {
            if let delegate = self.authenticatorDelegate {
                FRLog.v("Found more than 1 credential sources, proceeding with delegation to select the credential source", subModule: WebAuthn.module)
                delegate.selectCredential(keyNames: Array(sources.keys).sorted(), selectionCallback: { (keyName) in
                    FRLog.v("Selected credential source received, proceeding with getAssertion operation", subModule: WebAuthn.module)
                    callback(keyName)
                })
            }
            else {
                FRLog.e("PlatformAuthenticatorDelegate is missing", subModule: WebAuthn.module)
                callback(nil)
            }
        }
    }
    
    
    /// Retrieves an array of PublicKeyCredentialSource
    /// - Parameters:
    ///   - rpId: Relying party identifier for the getAssertion operation
    ///   - allowCredentialDescriptorList: An array of allowed credential sources from the server
    /// - Returns: A hash map of key, and public key credential source that is available for given information
    func getCredentialsSources(rpId: String, allowCredentialDescriptorList: [PublicKeyCredentialDescriptor]) -> [String: PublicKeyCredentialSource] {
        
        if allowCredentialDescriptorList.isEmpty {
            return self.credentialsStore.loadAllCredentialSources(rpId: rpId).reduce([String: PublicKeyCredentialSource]()) { (dict, source) -> [String: PublicKeyCredentialSource] in
                var dict = dict
                dict[source.otherUI] = source
                return dict
            }
        }
        else {
            return allowCredentialDescriptorList.reduce([String: PublicKeyCredentialSource]()) { (dict, descriptor) -> [String: PublicKeyCredentialSource] in
                var dict = dict
                if let source = self.credentialsStore.lookupCredentialSource(rpId: rpId, credentialId: descriptor.id) {
                    dict[source.otherUI] = source
                }
                return dict
            }
        }
    }
    
    
    /// Performs User Verification based on the UV/UP configuration value
    /// - Parameters:
    ///   - requireUserVerification: Boolean value of whether or not User Verification is required
    ///   - completion: Completion callback to notify the result of user verification
    func performUserVerification(requireUserVerification: Bool, completion: @escaping CompletionCallback) {
        if requireUserVerification {
            DispatchQueue.main.async {
                let context = LAContext()
                var evalError: NSError?
                if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &evalError) {
                    if let error = evalError {
                        completion(self.wakErrorForEvalError(evalError: error))
                        return
                    }
                    FRLog.v("Evaluation with LocalContext is available, performing biometric LocalAuthentication", subModule: WebAuthn.module)
                    context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: NSLocalizedString(WebAuthn.localAuthenticationString, comment: "Description text for local authentication reason displayed in iOS' local authentication screen.")) { [weak self] (result, error) in
                        if result && (error == nil) {
                            FRLog.v("User Verification is completed", subModule: WebAuthn.module)
                            completion(nil)
                        }
                        else if let error = error as? NSError {
                            completion(self?.wakErrorForEvalError(evalError: error))
                        }
                        else {
                            let logMessage = "LAContext - Unknown"
                            FRLog.e(logMessage, subModule: WebAuthn.module)
                            completion(FRWAKError.unknown(platformError: nil, message: logMessage))
                        }
                    }
                }
                else {
                    let reason = evalError?.localizedDescription ?? ""
                    let logMessage = "LocalAuthentication with biometric is not available (\(reason)); getAssertion operation is not allowed"
                    FRLog.e(logMessage, subModule: WebAuthn.module)
                    completion(FRWAKError.notAllowed(platformError: nil, message: logMessage))
                }
            }
        }
        else {
            FRLog.v("User Verification is not required; proceed with getAssertion operation", subModule: WebAuthn.module)
            completion(nil)
        }
    }
    
    private func wakErrorForEvalError(evalError: NSError) -> FRWAKError {
        switch LAError(_nsError: evalError) {
        case LAError.userFallback:
            FRLog.e("LAContext - User fallback", subModule: WebAuthn.module)
            return FRWAKError.notAllowed(platformError: evalError, message: "LAContext - User fallback")
        case LAError.userCancel:
            FRLog.e("LAContext - User cancelled", subModule: WebAuthn.module)
            return FRWAKError.notAllowed(platformError: evalError, message: "LAContext - User cancelled")
        case LAError.authenticationFailed:
            FRLog.e("LAContext - User authentication failed", subModule: WebAuthn.module)
            return FRWAKError.notAllowed(platformError: evalError, message: "LAContext - User authentication failed")
        case LAError.passcodeNotSet:
            FRLog.e("LAContext - Passcode is not set", subModule: WebAuthn.module)
            return FRWAKError.notAllowed(platformError: evalError, message: "LAContext - Passcode is not set")
        case LAError.systemCancel:
            FRLog.e("LAContext - System cancel", subModule: WebAuthn.module)
            return FRWAKError.notAllowed(platformError: evalError, message: "LAContext - System cancel")
        default:
            FRLog.e("LAContext - Unexpected error: \(evalError.localizedDescription)", subModule: WebAuthn.module)
            return FRWAKError.unknown(platformError: evalError, message: "LAContext - Unexpected error: \(evalError.localizedDescription)")
        }
    }
}
