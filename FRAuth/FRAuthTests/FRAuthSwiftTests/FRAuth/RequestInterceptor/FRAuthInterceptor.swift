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
            RequestInterceptorTests.intercepted.append("START_AUTHENTICATE")
        }
        else if action.type == "AUTHENTICATE" {
            RequestInterceptorTests.intercepted.append("AUTHENTICATE")
        }
        else if action.type == "AUTHORIZE" {
            RequestInterceptorTests.intercepted.append("AUTHORIZE")
        }
        else if action.type == "EXCHANGE_TOKEN" {
            RequestInterceptorTests.intercepted.append("EXCHANGE_TOKEN")
        }
        else if action.type == "REFRESH_TOKEN" {
            RequestInterceptorTests.intercepted.append("REFRESH_TOKEN")
        }
        else if action.type == "REVOKE_TOKEN" {
            RequestInterceptorTests.intercepted.append("REVOKE_TOKEN")
        }
        else if action.type == "LOGOUT" {
            RequestInterceptorTests.intercepted.append("LOGOUT")
        }
        
        return request
    }
}
