// 
//  PlatformAuthenticatorMakeCredentialSession.swift
//  FRAuth
//
//  Copyright (c) 2020-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import LocalAuthentication

/**
 PlatformAuthenticatorMakeCredentialSession is responsible to generate WebAuthn attestation for registration following `6.3.2 The authenticatorMakeCredential Operation` in Web Authentication specification (https://www.w3.org/TR/webauthn/#sctn-op-make-cred)
 */
class PlatformAuthenticatorMakeCredentialSession: AuthenticatorMakeCredentialSession {
    
    //  MARK: - Properties
    
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
    
    /// Delegation for internal WebAuthnClient's get attestation operations
    weak var delegate: AuthenticatorMakeCredentialSessionDelegate?
    
    /// Delegation for PlatformAuthenticator process for generating registration attestation, and handle user interaction
    weak var authenticatorDelegate: PlatformAuthenticatorRegistrationDelegate?
    
    
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
    
    /// Initializes PlatformAuthenticatorMakeCredentialSession object with Authenticator's configuration, other utility classes to support the operation
    /// - Parameters:
    ///   - config: PlatformAuthenticator's configuration
    ///   - keySupportChooser: KeySupportChooser for PlatformAuthenticator
    ///   - credentialsStore: Credential storage for PlatformAuthenticator
    ///   - authenticatorDelegate: Delegation for PlatformAuthenticator's get assertion operation
    init(config: PlatformAuthenticatorConfig, keySupportChooser: KeySupportChooser, credentialsStore: CredentialStore, authenticatorDelegate: PlatformAuthenticatorRegistrationDelegate? = nil) {
        self.config = config
        self.keySupportChooser = keySupportChooser
        self.credentialsStore = credentialsStore
        self.authenticatorDelegate = authenticatorDelegate
    }
    
    
    //  MARK: - AuthenticatorMakeCredentialSession Protocol Methods
    
    /// Returns boolean value of whether or not the current session can support User Verification
    /// - Returns: Boolean value of whether or not User Verification is supported
    func canPerformUserVerification() -> Bool {
        return self.config.allowUserVerification
    }
    
    /// Returns boolean value of whether or not the current session can support Resident Key
    /// - Returns: Boolean value of whether or not the current session can support resident key
    func canStoreResidentKey() -> Bool {
        return true
    }
    
    
    //  MARK: - AuthenticatorMakeCredentialSession Protocol Methods - Lifecycle
    
    /// Starts the session' operation to generate attestation
    func start() {
        FRLog.v("makeCredential started", subModule: WebAuthn.module)
        guard !self.didStop else {
            return
        }
        
        guard !self.inProgress else {
            return
        }
        
        self.inProgress = true
        self.delegate?.authenticatorSessionDidBecomeAvailable(session: self)
    }
    
    
    /// Cancels the session's operation to generate attestation
    /// - Parameter reason: cancellation reason as in WAKError
    func cancel(reason: WAKError) {
        FRLog.v("makeCredential cancelled: \(reason.localizedDescription)", subModule: WebAuthn.module)
        guard !self.didStop else {
            return
        }
        self.stop(reason: reason)
    }
    
    
    /// Stops the session's operation to generate attestation
    /// - Parameter reason: stopping reason as in WAKError
    func stop(reason: WAKError) {
        FRLog.v("makeCredential stopped: \(reason.localizedDescription)", subModule: WebAuthn.module)
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
        FRLog.v("makeCredential completed", subModule: WebAuthn.module)
        self.didStop = true
    }
    
    
    //  MARK: - Internal
    
    /// Determines whether or not the makeCredential operation is allowed with given excluded credential descriptor list
    /// - Parameters:
    ///   - excludeCredentialDescriptorList: An array of credential desciptors not allowed for registration
    ///   - rpEntity: Relying party identifier as in String to generate the assertion
    ///   - completion: Completion callback to notify the result of the operation
    func performExcludeCredentialsConsent(excludeCredentialDescriptorList: [PublicKeyCredentialDescriptor], rpEntity: PublicKeyCredentialRpEntity, completion: @escaping CompletionCallback) {
        FRLog.v("\(excludeCredentialDescriptorList.count) credentials provided to be excluded")
        //  https://www.w3.org/TR/webauthn/#op-make-cred 6.3.2 - The authenticatorMakeCredential Operation
        let hasSourceToBeExcluded = excludeCredentialDescriptorList.contains {
            self.credentialsStore.lookupCredentialSource(
                rpId:         rpEntity.id!,
                credentialId: $0.id
            ) != nil
        }
        
        if hasSourceToBeExcluded {
            FRLog.v("Found matching credential from the excluded list; delegating the operation for the user consent", subModule: WebAuthn.module)
            if let delegate = self.authenticatorDelegate {
                delegate.excludeCredentialDescriptorConsent { (result) in
                    switch result {
                    case .allow:
                        FRLog.w("User allowed the operation; invalid state for excluded credentials", subModule: WebAuthn.module)
                        completion(WAKError.invalidState)
                        break
                    case .reject:
                        FRLog.w("User rejected the operation; not allowed for excluded credentials", subModule: WebAuthn.module)
                        completion(WAKError.notAllowed)
                        break
                    }
                }
            }
            else {
                FRLog.e("PlatformAuthenticatorDelegate is missing", subModule: WebAuthn.module)
                completion(WAKError.unknown)
            }
        }
        else {
            FRLog.v("No matching credential found from the excluded list; proceeding with the operation", subModule: WebAuthn.module)
            completion(nil)
        }
    }
    
    
    /// Performs User Consent operation to create new credentials during the registration
    /// - Parameters:
    ///   - keyName: String value of human readable key name being generated
    ///   - rpEntity: Relying party identifier for generating the attestation
    ///   - userEntity: User entity information object
    ///   - completion: Completion callback to notify the result of the operation
    func performCreateNewCredentialsConsent(keyName: String, rpEntity: PublicKeyCredentialRpEntity, userEntity: PublicKeyCredentialUserEntity, completion: @escaping CompletionCallback) {
        
        if let delegate = self.authenticatorDelegate {
            delegate.createNewCredentialConsent(keyName: keyName, rpName: rpEntity.name, rpId: rpEntity.id, userName: userEntity.name, userDisplayName: userEntity.displayName) { (result) in
                switch result {
                case .allow:
                    FRLog.v("User allowed to generate new credential", subModule: WebAuthn.module)
                    completion(nil)
                    break
                case .reject:
                    FRLog.e("User rejected to generate new credential", subModule: WebAuthn.module)
                    completion(WAKError.cancelled)
                    break
                }
            }
        }
        else {
            FRLog.e("PlatformAuthenticatorDelegate is missing", subModule: WebAuthn.module)
            completion(WAKError.unknown)
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
                    context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: NSLocalizedString(WebAuthn.localAuthenticationString, comment: "Description text for local authentication reason displayed in iOS' local authentication screen.")) { (result, error) in
                        
                        if result {
                            completion(nil)
                        }
                        else if let error = error {
                            switch LAError(_nsError: error as NSError) {
                            case LAError.userFallback:
                                WAKLogger.debug("<UserConsentUI> user fallback")
                                completion(WAKError.notAllowed)
                            case LAError.userCancel:
                                WAKLogger.debug("<UserConsentUI> user cancel")
                                completion(WAKError.notAllowed)
                            case LAError.authenticationFailed:
                                WAKLogger.debug("<UserConsentUI> authentication failed")
                                completion(WAKError.notAllowed)
                            case LAError.passcodeNotSet:
                                WAKLogger.debug("<UserConsentUI> passcode not set")
                                completion(WAKError.notAllowed)
                            case LAError.systemCancel:
                                WAKLogger.debug("<UserConsentUI> system cancel")
                                completion(WAKError.notAllowed)
                            default:
                                WAKLogger.debug("<UserConsentUI> must not come here")
                                completion(WAKError.unknown)
                            }
                        }
                        else {
                            WAKLogger.debug("<UserConsentUI> must not come here")
                            completion(WAKError.unknown)
                        }
                    }
                }
                else {
                    let reason = evalError?.localizedDescription ?? ""
                    WAKLogger.debug("<UserConsentUI> device not supported: \(reason)")
                    completion(WAKError.notAllowed)
                }
            }
        }
        else {
            completion(nil)
        }
    }
    
    
    /// Creates new UUID for credential
    /// - Returns: An array of bytes (UInt8) for the new credential identifier
    private func createNewCredentialId() -> [UInt8] {
        return UUIDHelper.toBytes(UUID())
    }
    
    
    //  MARK: - AuthenticatorMakeCredentialSession Protocol Methods - Make Credential
    
    /// Generates and returns WebAuthn registration attestation based on given credentials
    /// - Parameters:
    ///   - hash: An array of bytes from challenge to generate the attestation
    ///   - rpEntity: Relying party identifier as in String to generate the attestation
    ///   - userEntity: User entity object for the attestation being generated
    ///   - requireResidentKey: Boolean value of whether or not the operation would require resident key
    ///   - requireUserPresence: Boolean value of whether or not the operation would require user presence
    ///   - requireUserVerification: Boolean value of whether or not the operation would require user verification
    ///   - attestationPreference: `AttestationConveyancePreference` enum value of preferred Attestation type
    ///   - credTypesAndPubKeyAlgs: An array of allowed public key credentials algorithm/types
    ///   - excludeCredentialDescriptorList: An array of public key credential source descriptors not allowed for the registration
    func makeCredential(hash: [UInt8], rpEntity: PublicKeyCredentialRpEntity, userEntity: PublicKeyCredentialUserEntity, requireResidentKey: Bool, requireUserPresence: Bool, requireUserVerification: Bool, attestationPreference: AttestationConveyancePreference, credTypesAndPubKeyAlgs: [PublicKeyCredentialParameters], excludeCredentialDescriptorList: [PublicKeyCredentialDescriptor]) {
        
        FRLog.v("Generating attestation operation initiated", subModule: WebAuthn.module)
        let requestedAlgs = credTypesAndPubKeyAlgs.map { $0.alg }
        guard let keySupport = self.keySupportChooser.choose(requestedAlgs) else {
            FRLog.e("Requested key algorithm(s) not supported; stopping the operation", subModule: WebAuthn.module)
            self.stop(reason: .unsupported)
            return
        }
        
        self.performExcludeCredentialsConsent(excludeCredentialDescriptorList: excludeCredentialDescriptorList, rpEntity: rpEntity) { (error) in
            
            guard error == nil else {
                if let wakErr = error as? WAKError {
                    self.stop(reason: wakErr)
                }
                else {
                    self.stop(reason: .unknown)
                }
                return
            }
            
            
            if requireUserVerification && !self.config.allowUserVerification {
                FRLog.e("User Verification is required, but not supported", subModule: WebAuthn.module)
                self.stop(reason: .constraint)
                return
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd HH:mm:ss"
            let dateString = formatter.string(from: Date())
            let keyName = "\(userEntity.displayName) (\(dateString))"
            FRLog.v("Created new key name, delegating user consent for generating new key", subModule: WebAuthn.module)
            self.performCreateNewCredentialsConsent(keyName: keyName, rpEntity: rpEntity, userEntity: userEntity) { (error) in
                
                guard error == nil else {
                    if let wakErr = error as? WAKError {
                        self.stop(reason: wakErr)
                    }
                    else {
                        self.stop(reason: .unknown)
                    }
                    return
                }
                
                self.performUserVerification(requireUserVerification: requireUserVerification) { (error) in
                    guard error == nil else {
                        if let wakErr = error as? WAKError {
                            self.stop(reason: wakErr)
                        }
                        else {
                            self.stop(reason: .unknown)
                        }
                        return
                    }
                    
                    let credentialId = self.createNewCredentialId()
                    
                    //  Only store userHandle within PublicKeyCredentialSource when requireResidentKey is true
                    //  the client-side discoverable Public Key Credential Source should adhere requireResidentKey
                    var userHandle: [UInt8]? = nil
                    if requireResidentKey {
                        FRLog.v("Resident key is required; creating client-side discoverable credential source", subModule: WebAuthn.module)
                        userHandle = userEntity.id
                    }
                    let credSource = PublicKeyCredentialSource(id: credentialId, rpId: rpEntity.id ?? "", userHandle: userHandle, signCount: 0, alg: keySupport.selectedAlg.rawValue, otherUI: keyName)
                                        
                    guard let publicKeyCOSE = keySupport.createKeyPair(label: credSource.keyLabel) else {
                        FRLog.e("Failed to generate new key", subModule: WebAuthn.module)
                        self.stop(reason: .unknown)
                        return
                    }
                    
                    guard self.credentialsStore.saveCredentialSource(credSource) else {
                        FRLog.e("Failed to store new credential", subModule: WebAuthn.module)
                        self.stop(reason: .unknown)
                        return
                    }
                    
                    // TODO Extension Processing
                    let extensions = SimpleOrderedDictionary<String>()
                    
                    let attestedCredData = AttestedCredentialData(aaguid: UUIDHelper.zeroBytes, credentialId: credentialId, credentialPublicKey: publicKeyCOSE)
                    let authenticatorData = AuthenticatorData(rpIdHash: rpEntity.id!.sha256!.bytes, userPresent: (requireUserPresence || requireUserVerification), userVerified: requireUserVerification, signCount: 0, attestedCredentialData: attestedCredData, extensions: extensions)
                    
                    guard let attestation = PlatformAttestation.create(authData: authenticatorData, clientDataHash: hash, alg: keySupport.selectedAlg, keyLabel: credSource.keyLabel, attestationPreference: attestationPreference) else {
                        FRLog.e("Failed to create Attestation object", subModule: WebAuthn.module)
                        self.stop(reason: .unknown)
                        return
                    }
                    
                    self.completed()
                    self.delegate?.authenticatorSessionDidMakeCredential(session: self, attestation: attestation)
                }
            }
        }
    }
}
