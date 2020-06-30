// 
//  ForceAuthInterceptor.swift
//  FRExample
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import FRCore

//  ForceAuthInterceptor is an example RequestInterceptor implementation that intercepts FRAuth SDK's Authentication Tree request, and add 'ForceAuth' attribute
class ForceAuthInterceptor: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        if action.type == "START_AUTHENTICATE" || action.type == "AUTHENTICATE" {
            var urlParams = request.urlParams
            urlParams["ForceAuth"] = "true"
            let newRequest = Request(url: request.url, method: request.method, headers: request.headers, bodyParams: request.bodyParams, urlParams: urlParams, requestType: request.requestType, responseType: request.responseType, timeoutInterval: request.timeoutInterval)
            return newRequest
        }
        else {
            return request
        }
    }
}
