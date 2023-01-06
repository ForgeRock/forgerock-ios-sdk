// 
//  PlatformAuthenticator.swift
//  FRAuth
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/**
 PlatformAuthenticator class is a representation of WebAuthn Authenticator model for platform (iOS). PlatformAuthenticator is responsible for conveying WebAuthn registration/authentication configuration values and managing the operations of WebAuthn registration/authentication.
 */
class PlatformAuthenticator: Authenticator {
    
    //  MARK: - Protocol Properties
    
    /// Authenticator's attachment configuration value
    var attachment: AuthenticatorAttachment {
        get {
            return self.config.attachment
        }
    }
    
    /// Authenticator's transport configuration value
    var transport: AuthenticatorTransport {
        get {
            return self.config.transport
        }
    }
    
    /// Authenticator's counter step configuration value
    var counterStep: UInt32 {
        get {
            return self.config.counterStep
        }
        set {
            self.config.counterStep = newValue
        }
    }
    
    /// Authenticator's boolean indicator of whether or not Resident Key is supported
    var allowResidentKey: Bool {
        get {
            return self.config.allowResidentKey
        }
    }
    
    /// Authenticator's boolean indicator of whether or not User Verification is allowed
    var allowUserVerification: Bool {
        get {
            return self.config.allowUserVerification
        }
        set {
            self.config.allowUserVerification = newValue
        }
    }
    
    
    //  MARK: - Public Properties
    
    /// Delegate for WebAuthn registration protocols
    weak var registrationDelegate: PlatformAuthenticatorRegistrationDelegate?
    /// Delegate for WebAuthn authentication protocols
    weak var authenticationDelegate: PlatformAuthenticatorAuthenticationDelegate?
    
    
    //  MARK: - Instance Properties
    
    /// Authenticator's configurations
    fileprivate var config: PlatformAuthenticatorConfig
    /// Authenticator's supported key algorithms
    fileprivate let keySupportChooser = KeySupportChooser()
    /// Authenticator's credential storage
    fileprivate let credentialsStore = KeychainCredentialStore()
    
    
    //  MARK: - Init
    
    /// Initializes PlatformAuthenticator object with registration/authentication delegate, and Authenticator configuration values
    /// - Parameters:
    ///   - config: Authenticator configuration values
    ///   - registrationDelegate: Registration delegate protocols for user interaction
    ///   - authenticationDelegate: Authentication delegate protocols for user interaction
    init(config: PlatformAuthenticatorConfig? = nil, registrationDelegate: PlatformAuthenticatorRegistrationDelegate? = nil, authenticationDelegate: PlatformAuthenticatorAuthenticationDelegate? = nil) {
        self.config = config ?? PlatformAuthenticatorConfig()
        self.registrationDelegate = registrationDelegate
        self.authenticationDelegate = authenticationDelegate
    }
    
    
    //  MARK: - Authenticator Protocol Methods
    
    /// Creates WebAuthn registration attestation; following the authenticatorMakeCredential operation
    /// - Returns: AuthenticatorMakeCredentialSession object responsible for generating attestation
    func newMakeCredentialSession() -> AuthenticatorMakeCredentialSession {
        FRLog.v("Starting makeCredentialSession", subModule: WebAuthn.module)
        return PlatformAuthenticatorMakeCredentialSession(config: self.config, keySupportChooser: self.keySupportChooser, credentialsStore: self.credentialsStore, authenticatorDelegate: self.registrationDelegate)
    }
    
    
    /// Creates WebAuthn authentication assertion; following the authenticatorGetAssertion operation
    /// - Returns: AuthenticatorGetAssertionSession object responsible for generating assertion
    func newGetAssertionSession() -> AuthenticatorGetAssertionSession {
        FRLog.v("Starting getAssertionSession", subModule: WebAuthn.module)
        return PlatformAuthenticatorGetAssertionSession(config: self.config, keySupportChooser: self.keySupportChooser, credentialsStore: self.credentialsStore, authenticatorDelegate: self.authenticationDelegate)
    }
    
    func clearAllCredentialsFromCredentialStore(rpId: String) {
        let credentialSources = self.credentialsStore.loadAllCredentialSources(rpId: rpId)
        credentialSources.forEach {
            _ = self.credentialsStore.deleteCredentialSource($0)
        }
    }
    
    func loadAllCredentials(rpId: String) ->  [PublicKeyCredentialSource] {
        return self.credentialsStore.loadAllCredentialSources(rpId: rpId)
    }
    
    func deleteCredential(publicKeyCredentialSource: PublicKeyCredentialSource) {
        _ = self.credentialsStore.deleteCredentialSource(publicKeyCredentialSource)
    }
}
