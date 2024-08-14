//
//  CallbackConstants.swift
//  FRAuth
//
//  Copyright (c) 2019-2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation


//  MARK: - Callback enums

// Reference: https://docs.oracle.com/javase/7/docs/api/javax/security/auth/callback/ConfirmationCallback.html

/// Option Type for Callback
///
/// - unspecifiedOption: unpsecifiedOption; -1
/// - yesNoOption: YES/NO option; 0
/// - yesNoCancelOption: YES/NO/CANCEL option; 1
/// - okCancelOption: OK/CANCEL option; 2
/// - unknown: default when value is not provided
@objc(FRCallbackOptionType)
public enum OptionType: Int {
    
    case unspecifiedOption = -1
    case yesNoOption = 0
    case yesNoCancelOption = 1
    case okCancelOption = 2
    case unknown
}


/// Option for Callback
///
/// - yes: YES; 0
/// - no: NO; 1
/// - cancel: CANCEL; 2
/// - ok: OK; 3
/// - unknown: default when value is not provided
@objc(FRCallbackOption)
public enum Option: Int {
    case yes = 0
    case no = 1
    case cancel = 2
    case ok = 3
    case unknown
}


/// Message Type for Callback
///
/// - information: INFORMATION; 0
/// - warning: WARNING; 1
/// - error: ERROR; 2
/// - unknown: default when value is not provided
@objc(FRCallbackMessageType)
public enum MessageType: Int {
    case information = 0
    case warning = 1
    case error = 2
    case unknown
}


//  MARK: - Callback Constants

enum CallbackType: String {
    //  Callback types
    case ChoiceCallback = "ChoiceCallback"
    case NameCallback = "NameCallback"
    case PasswordCallback = "PasswordCallback"
    case ValidatedCreateUsernameCallback = "ValidatedCreateUsernameCallback"
    case ValidatedCreatePasswordCallback = "ValidatedCreatePasswordCallback"
    case StringAttributeInputCallback = "StringAttributeInputCallback"
    case TermsAndConditionsCallback = "TermsAndConditionsCallback"
    case KbaCreateCallback = "KbaCreateCallback"
    case PollingWaitCallback = "PollingWaitCallback"
    case ConfirmationCallback = "ConfirmationCallback"
    case TextOutputCallback = "TextOutputCallback"
    case ReCaptchaCallback = "ReCaptchaCallback"
    case HiddenValueCallback = "HiddenValueCallback"
    case DeviceProfileCallback = "DeviceProfileCallback"
    case MetadataCallback = "MetadataCallback"
    case BooleanAttributeInputCallback = "BooleanAttributeInputCallback"
    case NumberAttributeInputCallback = "NumberAttributeInputCallback"
    case SuspendedTextOutputCallback = "SuspendedTextOutputCallback"
    case WebAuthnAuthenticationCallback = "WebAuthnAuthenticationCallback"
    case WebAuthnRegistrationCallback = "WebAuthnRegistrationCallback"
    case IdPCallback = "IdPCallback"
    case SelectIdPCallback = "SelectIdPCallback"
    case DeviceBindingCallback = "DeviceBindingCallback"
    case DeviceSigningVerifierCallback = "DeviceSigningVerifierCallback"
    case FRAppIntegrityCallback = "AppIntegrityCallback"
    case TextInputCallback = "TextInputCallback"
}

/// CBConstants is mainly responsible to maintain all constant values related to Callback implementation
public struct CBConstants {
    static let type: String = "type"
    static let _type: String = "_type"
    static let _action: String = "_action"
    static let input: String = "input"
    static let output: String = "output"
    static let name: String = "name"
    static let value: String = "value"
    static let data: String = "data"
    static let _id: String = "_id"
    static let prompt: String = "prompt"
    static let messageType: String = "messageType"
    static let option: String = "option"
    static let options: String = "options"
    static let optionType: String = "optionType"
    static let defaultOption: String = "defaultOption"
    static let message: String = "message"
    static let stage: String = "stage"
}

//  MARK: - IdPCallback / SelectIdPCallback

extension CBConstants {
    static let providers: String = "providers"
    static let provider: String = "provider"
    static let uiConfig: String = "uiConfig"
    static let clientId: String = "clientId"
    static let redirectUri: String = "redirectUri"
    static let nonce: String = "nonce"
    static let scopes: String = "scopes"
    static let acrValues: String = "acrValues"
    static let request: String = "request"
    static let requestUri: String = "requestUri"
    static let acceptsJSON: String = "acceptsJSON"
    static let token: String = "token"
    static let tokenType: String = "token_type"
    static let apple: String = "apple"
    static let google: String = "google"
    static let facebook: String = "facebook"
}

//  MARK: - DeviceProfileCallback

extension CBConstants {
    static let location: String = "location"
    static let metadata: String = "metadata"
}

//  MARK: - KbaCreateCallback

extension CBConstants {
    static let predefinedQuestions: String = "predefinedQuestions"
    static let question: String = "question"
    static let answer: String = "answer"
}

//  MARK: - ChoiceCallback

extension CBConstants {
    static let choices: String = "choices"
    static let defaultChoice: String = "defaultChoice"
}

//  MARK: - ReCaptchaCallback

extension CBConstants {
    static let recaptchaSiteKey: String = "recaptchaSiteKey"
}

//  MARK: - TermsAndConditionsCallback

extension CBConstants {
    static let version: String = "version"
    static let createDate: String = "createDate"
    static let terms: String = "terms"
}

//  MARK: - AbstractValidatedCallback

extension CBConstants {
    static let echoOn: String = "echoOn"
    static let policies: String = "policies"
    static let validateOnly: String = "validateOnly"
    static let failedPolicies: String = "failedPolicies"
    static let params: String = "params"
    static let policyRequirement: String = "policyRequirement"
    static let required: String = "required"
}

//  MARK: - PollingWaitCallback

extension CBConstants {
    static let waitTime: String = "waitTime"
}

//  MARK: - WebAuthn Callback Constants

extension CBConstants {
    
    static let webAuthnOutcome: String = "webAuthnOutcome"
    
    static let originScheme: String = "https://"
    static let originPrefix: String = "ios:bundle-id:"
    
    //  AM 7.0.0 or below
    static let WebAuthn: String = "WebAuthn"
    static let pubKeyCredParams: String = "pubKeyCredParams"
    static let challenge: String = "challenge"
    static let timeout: String = "timeout"
    static let userVerification: String = "userVerification"
    static let relyingPartyId: String = "relyingPartyId"
    static let allowCredentials: String = "allowCredentials"
    static let relyingPartyName: String = "relyingPartyName"
    static let attestationPreference: String = "attestationPreference"
    static let displayName: String = "displayName"
    static let userName: String = "userName"
    static let userId: String = "userId"
    static let requireResidentKey: String = "requireResidentKey"
    static let authenticatorAttachment: String = "authenticatorAttachment"
    static let authenticatorSelection: String = "authenticatorSelection"
    static let excludeCredentials: String = "excludeCredentials"
    
    //  AM 7.1.0
    static let webauthn_authentication: String = "webauthn_authentication"
    static let webauthn_registration: String = "webauthn_registration"
    static let _relyingPartyId: String = "_relyingPartyId"
    static let _allowCredentials: String = "_allowCredentials"
    static let id: String = "id"
    static let _authenticatorSelection: String = "_authenticatorSelection"
    static let _excludeCredentials: String = "_excludeCredentials"
    static let _pubKeyCredParams: String = "_pubKeyCredParams"
    static let public_key: String = "public-key"
    static let alg: String = "alg"
}

//  MARK: - DeviceBindingCallback

extension CBConstants {
    static let username: String = "username"
    static let authenticationType: String = "authenticationType"
    static let title: String = "title"
    static let subtitle: String = "subtitle"
    static let description: String = "description"
    static let jws: String = "jws"
    static let deviceName: String = "deviceName"
    static let deviceId: String = "deviceId"
    static let clientError: String = "clientError"
}

//  MARK: - AppIntegrity
extension CBConstants {
    static let attest = "attestToken"
    static let keyId = "keyId"
    static let clientData = "clientData"
}

//  MARK: - TextInputCallback
extension CBConstants {
    static let defaultText: String = "defaultText"
}

//  MARK: - AbstractProtectCallback

extension CBConstants {
    static let pingOneProtect: String = "PingOneProtect"
    static let protectInitialize: String = "protect_initialize"
    static let protectRiskEvaluation: String = "protect_risk_evaluation"
}
