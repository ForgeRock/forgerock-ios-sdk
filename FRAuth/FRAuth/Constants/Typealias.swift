//
//  Typealias.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
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

/// Generic typealias for completion with an error occurred
public typealias CompletionCallback = (_ error:Error?) -> Void

/// Generic typealias for completion with an JSON object
public typealias JSONCompletionCallback = (_ result: [String: Any]) -> Void


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

/// Callback definition for FRURLProtocol's refresh token policy; the callback is invoked to validate whether token refresh is required or not with given request result
@available(*, deprecated, message: "FRURLProtocol.refreshTokenPolicy is deprecated; use TokenManagementPolicy(validatingURL:delegate:) to do TokenManagement.") // Deprecated as of FRAuth: v2.0.0
public typealias FRURLProtocolResponseEvaluationCallback = (_ responseData: Data?, _ response: URLResponse?, _ error: Error?) -> Bool
