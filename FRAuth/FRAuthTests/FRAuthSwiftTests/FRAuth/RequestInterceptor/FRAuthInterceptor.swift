// 
//  FRAuthInterceptor.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import FRCore

class FRAuthInterceptor: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        
        if action.type == "START_AUTHENTICATE" {
            FRRequestInterceptorTests.intercepted.append("START_AUTHENTICATE")
        }
        else if action.type == "AUTHENTICATE" {
            FRRequestInterceptorTests.intercepted.append("AUTHENTICATE")
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
        else {
            FRRequestInterceptorTests.intercepted.append(action.type)
        }
        
        return request
    }
}
