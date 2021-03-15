// 
//  FRAuthInterceptor.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

@testable import FRCore
@testable import FRAuth

class FRAuthInterceptor: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        if let payload = action.payload {
            FRRequestInterceptorTests.payload.append(payload)
        }
        if action.type == "START_AUTHENTICATE" {
            FRRequestInterceptorTests.intercepted.append("START_AUTHENTICATE")
        }
        else if action.type == "AUTHENTICATE" {
            FRRequestInterceptorTests.intercepted.append("AUTHENTICATE")
        }
        else if action.type == "RESUME_AUTHENTICATE" {
            FRRequestInterceptorTests.intercepted.append("RESUME_AUTHENTICATE")
        }
        else if action.type == "AUTHORIZE" {
            FRRequestInterceptorTests.intercepted.append("AUTHORIZE")
        }
        else if action.type == "EXCHANGE_TOKEN" {
            FRRequestInterceptorTests.intercepted.append("EXCHANGE_TOKEN")
        }
        else if action.type == "REFRESH_TOKEN" {
            FRRequestInterceptorTests.intercepted.append("REFRESH_TOKEN")
        }
        else if action.type == "REVOKE_TOKEN" {
            FRRequestInterceptorTests.intercepted.append("REVOKE_TOKEN")
        }
        else if action.type == "LOGOUT" {
            FRRequestInterceptorTests.intercepted.append("LOGOUT")
        }
        else if action.type == "USER_INFO" {
            FRRequestInterceptorTests.intercepted.append("USER_INFO")
        }
        else {
            FRRequestInterceptorTests.intercepted.append(action.type)
        }
        
        return request
    }
}
