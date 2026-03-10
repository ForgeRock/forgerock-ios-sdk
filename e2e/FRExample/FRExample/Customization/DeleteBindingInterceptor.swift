// 
//  DeleteBindingInterceptor.swift
//  FRExample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import FRCore
import FRAuth

/// DeleteBindingInterceptor is an example RequestInterceptor that intercepts the
/// device-binding key deletion request (ActionType.DELETE_BINDING) and injects the
/// AM session cookie into the request header.
///
/// Usage:
///     FRRequestInterceptorRegistry.shared.registerInterceptors(interceptors: [DeleteBindingInterceptor()])
///
/// After registration, every call to `FRUserKeys().delete(userKey:)` will pass through
/// this interceptor, allowing you to add the session token (or any other header) before
/// the DELETE request is sent to AM's device-binding endpoint:
///     DELETE /json/realms/{realm}/users/{userId}/devices/2fa/binding/{kid}
class DeleteBindingInterceptor: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        guard action.type == ActionType.DELETE_BINDING.rawValue else {
            return request
        }

        var headers = request.headers

        // Inject the AM session cookie as a header so the request is authenticated.
        // FRUser.currentUser?.token?.sessionToken holds the SSO token when the user
        // is logged in via a Journey.
        if let sessionToken = FRSession.currentSession?.sessionToken?.value {
            headers["iPlanetDirectoryPro"] = sessionToken
        }

        return Request(
            url: request.url,
            method: request.method,
            headers: headers,
            bodyParams: request.bodyParams,
            urlParams: request.urlParams,
            requestType: request.requestType,
            responseType: request.responseType,
            timeoutInterval: request.timeoutInterval
        )
    }
}
