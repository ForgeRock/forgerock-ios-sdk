// 
//  CallbackConstantsTests.swift
//  FRAuthTests
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

class CallbackConstantsTests: FRBaseTestCase {
    
    func test_01_test_callback_type() {
        var callbackType: CallbackType = .ChoiceCallback
        XCTAssertEqual(callbackType.rawValue, "ChoiceCallback")
        callbackType = .NameCallback
        XCTAssertEqual(callbackType.rawValue, "NameCallback")
        callbackType = .PasswordCallback
        XCTAssertEqual(callbackType.rawValue, "PasswordCallback")
        callbackType = .ValidatedCreateUsernameCallback
        XCTAssertEqual(callbackType.rawValue, "ValidatedCreateUsernameCallback")
        callbackType = .ValidatedCreatePasswordCallback
        XCTAssertEqual(callbackType.rawValue, "ValidatedCreatePasswordCallback")
        callbackType = .StringAttributeInputCallback
        XCTAssertEqual(callbackType.rawValue, "StringAttributeInputCallback")
        callbackType = .TermsAndConditionsCallback
        XCTAssertEqual(callbackType.rawValue, "TermsAndConditionsCallback")
        callbackType = .KbaCreateCallback
        XCTAssertEqual(callbackType.rawValue, "KbaCreateCallback")
        callbackType = .PollingWaitCallback
        XCTAssertEqual(callbackType.rawValue, "PollingWaitCallback")
        callbackType = .ConfirmationCallback
        XCTAssertEqual(callbackType.rawValue, "ConfirmationCallback")
        callbackType = .TextOutputCallback
        XCTAssertEqual(callbackType.rawValue, "TextOutputCallback")
        callbackType = .ReCaptchaCallback
        XCTAssertEqual(callbackType.rawValue, "ReCaptchaCallback")
        callbackType = .HiddenValueCallback
        XCTAssertEqual(callbackType.rawValue, "HiddenValueCallback")
        callbackType = .DeviceProfileCallback
        XCTAssertEqual(callbackType.rawValue, "DeviceProfileCallback")
        callbackType = .MetadataCallback
        XCTAssertEqual(callbackType.rawValue, "MetadataCallback")
        callbackType = .BooleanAttributeInputCallback
        XCTAssertEqual(callbackType.rawValue, "BooleanAttributeInputCallback")
        callbackType = .NumberAttributeInputCallback
        XCTAssertEqual(callbackType.rawValue, "NumberAttributeInputCallback")
        callbackType = .SuspendedTextOutputCallback
        XCTAssertEqual(callbackType.rawValue, "SuspendedTextOutputCallback")
        callbackType = .WebAuthnAuthenticationCallback
        XCTAssertEqual(callbackType.rawValue, "WebAuthnAuthenticationCallback")
        callbackType = .WebAuthnRegistrationCallback
        XCTAssertEqual(callbackType.rawValue, "WebAuthnRegistrationCallback")
        callbackType = .IdPCallback
        XCTAssertEqual(callbackType.rawValue, "IdPCallback")
        callbackType = .SelectIdPCallback
        XCTAssertEqual(callbackType.rawValue, "SelectIdPCallback")
    }
    
    
    func test_02_common_callback_constant_values() {
        XCTAssertEqual(CBConstants.type, "type")
        XCTAssertEqual(CBConstants._type, "_type")
        XCTAssertEqual(CBConstants._action, "_action")
        XCTAssertEqual(CBConstants.input, "input")
        XCTAssertEqual(CBConstants.output, "output")
        XCTAssertEqual(CBConstants.name, "name")
        XCTAssertEqual(CBConstants.value, "value")
        XCTAssertEqual(CBConstants.data, "data")
        XCTAssertEqual(CBConstants._id, "_id")
        XCTAssertEqual(CBConstants.prompt, "prompt")
        XCTAssertEqual(CBConstants.messageType, "messageType")
        XCTAssertEqual(CBConstants.option, "option")
        XCTAssertEqual(CBConstants.options, "options")
        XCTAssertEqual(CBConstants.optionType, "optionType")
        XCTAssertEqual(CBConstants.defaultOption, "defaultOption")
        XCTAssertEqual(CBConstants.message, "message")
        XCTAssertEqual(CBConstants.stage, "stage")
        
        //  MARK: - ReCaptchaCallback
        XCTAssertEqual(CBConstants.recaptchaSiteKey, "recaptchaSiteKey")
        
        //  MARK: - PollingWaitCallback
        XCTAssertEqual(CBConstants.waitTime, "waitTime")
    }
    
    
    func test_03_social_login_callback_constant_values() {
        XCTAssertEqual(CBConstants.providers, "providers")
        XCTAssertEqual(CBConstants.provider, "provider")
        XCTAssertEqual(CBConstants.uiConfig, "uiConfig")
        XCTAssertEqual(CBConstants.clientId, "clientId")
        XCTAssertEqual(CBConstants.redirectUri, "redirectUri")
        XCTAssertEqual(CBConstants.nonce, "nonce")
        XCTAssertEqual(CBConstants.scopes, "scopes")
        XCTAssertEqual(CBConstants.acrValues, "acrValues")
        XCTAssertEqual(CBConstants.request, "request")
        XCTAssertEqual(CBConstants.requestUri, "requestUri")
        XCTAssertEqual(CBConstants.token, "token")
        XCTAssertEqual(CBConstants.tokenType, "token_type")
        XCTAssertEqual(CBConstants.apple, "apple")
        XCTAssertEqual(CBConstants.google, "google")
        XCTAssertEqual(CBConstants.facebook, "facebook")
    }
    
    
    func test_04_kba_create_callback_constant_values() {
        XCTAssertEqual(CBConstants.predefinedQuestions, "predefinedQuestions")
        XCTAssertEqual(CBConstants.question, "question")
        XCTAssertEqual(CBConstants.answer, "answer")
    }
    
    
    func test_05_choice_callback_constant_values() {
        XCTAssertEqual(CBConstants.choices, "choices")
        XCTAssertEqual(CBConstants.defaultChoice, "defaultChoice")
    }
    
    
    func test_06_termsconditions_callback_constant_values() {
        XCTAssertEqual(CBConstants.version, "version")
        XCTAssertEqual(CBConstants.createDate, "createDate")
        XCTAssertEqual(CBConstants.terms, "terms")
    }
    
    
    func test_07_abstract_validated_callback_constant_values() {
        XCTAssertEqual(CBConstants.echoOn, "echoOn")
        XCTAssertEqual(CBConstants.policies, "policies")
        XCTAssertEqual(CBConstants.validateOnly, "validateOnly")
        XCTAssertEqual(CBConstants.failedPolicies, "failedPolicies")
        XCTAssertEqual(CBConstants.params, "params")
        XCTAssertEqual(CBConstants.policyRequirement, "policyRequirement")
        XCTAssertEqual(CBConstants.required, "required")
    }
    
    
    func test_08_webauthn_callback_constant_values() {
        XCTAssertEqual(CBConstants.webAuthnOutcome, "webAuthnOutcome")
        XCTAssertEqual(CBConstants.defaultOrigin, "com.forgerock.ios")
        XCTAssertEqual(CBConstants.originScheme, "https://")
        XCTAssertEqual(CBConstants.originPrefix, "ios:bundle-id:")
        XCTAssertEqual(CBConstants.WebAuthn, "WebAuthn")
        XCTAssertEqual(CBConstants.pubKeyCredParams, "pubKeyCredParams")
        XCTAssertEqual(CBConstants.challenge, "challenge")
        XCTAssertEqual(CBConstants.timeout, "timeout")
        XCTAssertEqual(CBConstants.userVerification, "userVerification")
        XCTAssertEqual(CBConstants.relyingPartyId, "relyingPartyId")
        XCTAssertEqual(CBConstants.allowCredentials, "allowCredentials")
        XCTAssertEqual(CBConstants.relyingPartyName, "relyingPartyName")
        XCTAssertEqual(CBConstants.attestationPreference, "attestationPreference")
        XCTAssertEqual(CBConstants.displayName, "displayName")
        XCTAssertEqual(CBConstants.userName, "userName")
        XCTAssertEqual(CBConstants.userId, "userId")
        XCTAssertEqual(CBConstants.requireResidentKey, "requireResidentKey")
        XCTAssertEqual(CBConstants.authenticatorAttachment, "authenticatorAttachment")
        XCTAssertEqual(CBConstants.authenticatorSelection, "authenticatorSelection")
        XCTAssertEqual(CBConstants.excludeCredentials, "excludeCredentials")
        XCTAssertEqual(CBConstants.webauthn_authentication, "webauthn_authentication")
        XCTAssertEqual(CBConstants.webauthn_registration, "webauthn_registration")
        XCTAssertEqual(CBConstants._relyingPartyId, "_relyingPartyId")
        XCTAssertEqual(CBConstants._allowCredentials, "_allowCredentials")
        XCTAssertEqual(CBConstants.id, "id")
        XCTAssertEqual(CBConstants._authenticatorSelection, "_authenticatorSelection")
        XCTAssertEqual(CBConstants._excludeCredentials, "_excludeCredentials")
        XCTAssertEqual(CBConstants._pubKeyCredParams, "_pubKeyCredParams")
        XCTAssertEqual(CBConstants.public_key, "public-key")
        XCTAssertEqual(CBConstants.alg, "alg")
    }
}
