//
//  OAuth2.swift
//  FRAuth
//
//  Copyright (c) 2019-2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

/// Internal constant values related to OAuth2
struct OAuth2 {
    static let clientId = "client_id"
    static let scope = "scope"
    static let redirecUri = "redirect_uri"
    static let postLogoutRedirectUri = "post_logout_redirect_uri"

    static let csrf = "csrf"
    static let decision = "decision"
    
    static let responseType = "response_type"
    static let grantType = "grant_type"
    static let grantTypeAuthCode = "authorization_code"
    static let token = "token"
    static let idTokenHint = "id_token_hint"
    static let code = "code"
    static let authorization = "Authorization"
    
    static let state = "state"
    static let codeVerifier = "code_verifier"
    static let codeChallenge = "code_challenge"
    static let codeChallengeMethod = "code_challenge_method"
    
    static let accessToken = "access_token"
    static let refreshToken = "refresh_token"
    static let idToken = "id_token"
    static let tokenType = "token_type"
    static let tokenExpiresIn = "expires_in"
}
