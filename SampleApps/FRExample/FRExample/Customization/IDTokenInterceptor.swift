// 
//  IDTokenInterceptor.swift
//  FRExample
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import FRCore
import FRAuth

class IDTokenInterceptor: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        //  Only trigger this interceptor for START_AUTHENTICATE and AUTHENTICATE methods
        if action.type == "START_AUTHENTICATE" || action.type == "AUTHENTICATE" {
            //  Validate if current user is authenticated, and id_token exists
            if let user = FRUser.currentUser, let idToken = user.token?.idToken {
                var urlParams = request.urlParams
                urlParams["iPlanetDirectoryPro"] = idToken
                let newRequest = Request(url: request.url, method: request.method, headers: request.headers, bodyParams: request.bodyParams, urlParams: urlParams, requestType: request.requestType, responseType: request.responseType, timeoutInterval: request.timeoutInterval)
                return newRequest
            }
        }
        
        return request
    }
}
