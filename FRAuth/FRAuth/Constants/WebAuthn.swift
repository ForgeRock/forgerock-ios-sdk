// 
//  WebAuthn.swift
//  FRAuth
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

//  MARK: - WebAuthn Constants
public struct WebAuthn {
    static let module: String = "[WebAuthn]"
    static let alg: String = "alg"
    static let sig: String = "sig"
    static let packed: String = "packed"
    static let none: String = "none"
    public static var localAuthenticationString = "Local authentication is required."
}

//  MARK: - Internal WebAuthn enumerations

/// WebAuthn type enumeration
enum WAType: String {
    /// WebAuthn registration
    case registration = "registration"
    /// WebAuthn authentication
    case authentication = "authentication"
}


/// WebAuthn Callback type enumeration
enum WebAuthnCallbackType: String {
    /// registration
    case registration = "WebAuthnRegistrationCallback"
    /// authentication
    case authentication = "WebAuthnAuthenticationCallback"
    /// invalid WebAuthn Callback type
    case invalid = ""
}


//  MARK: - Public WebAuthn enumerations

/// User consent result for WebAuthn registration/authentication operation
public enum WebAuthnUserConsentResult {
    /// allow the operation by user consent
    case allow
    /// reject the operation by user consent
    case reject
}


/// WebAuthn Attestation Conveyance Preference Option enumeration
public enum WAAttestationPreference: String {
    /// none attestation preference option
    case none = "none"
    /// direct attestation preference option
    case direct = "direct"
    /// indirect attestation preference option
    case indirect = "indirect"
    
    /// Converts public WAAttestationPreference enum to internal AttestationConveyancePreference
    /// - Returns: AttestationConveyancePreference value of matching type
    func convert() -> AttestationConveyancePreference {
        switch self {
        case .none:
            return AttestationConveyancePreference.none
        case .direct:
            return AttestationConveyancePreference.direct
        case .indirect:
            return AttestationConveyancePreference.indirect
        }
    }
}


/// WebAuthn User Verification enumeration
public enum WAUserVerification: String {
    /// preferred User Verification
    case preferred = "preferred"
    /// required User Verification
    case required = "required"
    /// discouraged User Verification
    case discouraged = "discouraged"
    
    /// Converts public WAUserVerification enum to internal UserVerificationRequirement
    /// - Returns: UserVerificationRequirement value of matching type
    func convert() -> UserVerificationRequirement {
        switch self {
        case .preferred:
            return UserVerificationRequirement.preferred
        case .required:
            return UserVerificationRequirement.required
        case .discouraged:
            return UserVerificationRequirement.discouraged
        }
    }
}


/// WebAuthn Authenticator Attachment option enumeration
public enum WAAuthenticatorAttachment: String {
    /// platform authenticator
    case platform = "platform"
    /// cross-platform authenticator
    case crossPlatform = "cross-platform"
    /// unspecified authenticator attachment
    case unspecified = "unspecified"
}


//  MARK: - WebAuthn registration/authentication protocols
public protocol PlatformAuthenticatorRegistrationDelegate: AnyObject {
    func excludeCredentialDescriptorConsent(consentCallback: @escaping WebAuthnUserConsentCallback)
    func createNewCredentialConsent(keyName: String, rpName: String, rpId: String?, userName: String, userDisplayName: String, consentCallback: @escaping WebAuthnUserConsentCallback)
}


public protocol PlatformAuthenticatorAuthenticationDelegate: AnyObject {
    func selectCredential(keyNames: [String], selectionCallback: @escaping WebAuthnCredentialsSelectionCallback)
}
