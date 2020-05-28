// 
//  Action.swift
//  FRCore
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation


/**
 Action is a representation of behaviour of each Request that ForgeRock SDK generates. Action is used for `RequestInterceptor` to easily identify what type of `Request` is currently being made and for developers to easily understand and take appropriate modification on the given `Request` object in `RequestInterceptor`.

 ## Notes ##
    Currently, ForgeRock SDK makes following Requests with corresponding Actions:
 
        1. START_AUTHENTICATE - Initial Request made: '/json/realms/{realm}/authenticate'
        2. AUTHENTICATE - Any subsequent Request made: '/json/realms/{realm}/authenticate'
        3. AUTHORIZE - A '/oauth2/realms/{realm}/authorize' request for exchanging SSO Token to Authorization code
        4. EXCHANGE_TOKEN - OAuth2 token exchange request with Authorization Code: '/oauth2/realms/{realm}/access_token'
        5. REFRESH_TOKEN - OAuth2 token renewal request with given 'refresh_token': '/oauth2/realms/{realm}/access_token'
        6. REVOKE_TOKEN - OAuth2 token revocation with given 'access_token' or 'refresh_token': '/oauth2/realms/{realm}/token/revoke'
        7. LOGOUT - AM Session logout request to revoke SSO Token: '/json/realms/{realm}/sessions?_action=logout'
        8. PUSH_REGISTER - AM Push registration for Authenticator SDK: '/json/push/sns/message?_action=register'
        9. PUSH_AUTHENTICATE - AM Push authentication for Authenticator SDK: '/json/push/sns/message?_action=authenticate'
        10. USER_INFO - OIDC OAuth2 userinfo request: '/oauth2/realms/{realm}/userinfo'
 */
public struct Action {
    public let type: String
    public init(type: ActionType) {
        self.type = type.rawValue
    }
}


/// ActionType in enumeration string
public enum ActionType: String {
    case START_AUTHENTICATE = "START_AUTHENTICATE"
    case AUTHENTICATE = "AUTHENTICATE"
    case AUTHORIZE = "AUTHORIZE"
    case EXCHANGE_TOKEN = "EXCHANGE_TOKEN"
    case REFRESH_TOKEN = "REFRESH_TOKEN"
    case REVOKE_TOKEN = "REVOKE_TOKEN"
    case LOGOUT = "LOGOUT"
    case PUSH_REGISTER = "PUSH_REGISTER"
    case PUSH_AUTHENTICATE = "PUSH_AUTHENTICATE"
    case USER_INFO = "USER_INFO"
}
