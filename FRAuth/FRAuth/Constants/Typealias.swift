//
//  Typealias.swift
//  FRAuth
//
//  Copyright (c) 2019-2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

//  MARK: - Node Processing

/**
 Typealias for completion callback for Node submit. Upon completion, the callback returns any one of following:
 * Expected result object; currently Node can only process following generic types:
    1. Token: SSOToken as Token object
    2. AccessToken: access_token, and other OAuth2 token, and values associated with the access_token
    3. FRUser: Abstract layer of currently authenticated user session
 * Node object to process; Node object is a representation of a step in authentication process which requires user interaction to provide input value(s) to each Callback object within Node instance.
 * Error if occurred during authentication process
 */
public typealias NodeCompletion<T> = (_ result: T?, _ node: Node?, _ error: Error?) -> Void


//  MARK: - Generic

/// Generic typealias for completion with an optional error occurred
public typealias CompletionCallback = (_ error:Error?) -> Void

/// Generic typealias for completion with an error object
public typealias ErrorCallback = (_ error:Error) -> Void

/// Generic typealias for completion with an JSON object
public typealias JSONCompletionCallback = (_ result: [String: Any]) -> Void

/// Generic typealias for completion with a String value
public typealias StringCompletionCallback = (_ result: String) -> Void


//  MARK: - WebAuthn

/// Completion Callback for user consent result for WebAuthn registration/authentication operations
public typealias WebAuthnUserConsentCallback = (_ result: WebAuthnUserConsentResult) -> Void

/// Completion Callback for key selection for WebAuthn registration/authentication operations
public typealias WebAuthnCredentialsSelectionCallback = (_ selectedKeyName: String?) -> Void


//  MARK: - Social Login

/// Callback definition for completion of Social Login authorization flow against provider
public typealias SocialLoginCompletionCallback = (_ token: String?, _ tokenType: String?, _ error: Error?) -> Void


//  MARK: - OAuth2Client

/// Callback definition for completion of exchanging access_token request
public typealias TokenCompletionCallback = (_ token: AccessToken?, _ error:Error?) -> Void


//  MARK: - OAuth2 / OIDC

/// Callback definition for completion of retrieving UserInfo from /userinfo endpoint
public typealias UserInfoCallback = (_ result: UserInfo?, _ error:Error?) -> Void


//  MARK: - FRUser

/// Callback definition for completion of retrieving or getting currently authenticated FRUser instance
public typealias UserCallback = (_ user: FRUser?, _ error:Error?) -> Void


//  MARK: - DeviceCollector

/// DeviceCollector Callback definition
public typealias DeviceCollectorCallback = (_ result: [String: Any]) -> Void


//  MARK: - FRURLProtocol

/// Callback definition for completion result
public typealias FRCompletionResultCallback = (_ result: Bool) -> Void

