// 
//  FROptions.swift
//  FRAuth
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

@objc
public class FROptions: NSObject, Codable {
    public var forgerock_url: String
    public var forgerock_realm: String
    public var forgerock_enable_cookie: Bool
    public var forgerock_cookie_name: String
    public var forgerock_timeout: Int
    
    public var forgerock_authenticate_endpoint: String?
    public var forgerock_authorize_endpoint: String?
    public var forgerock_token_endpoint: String?
    public var forgerock_revoke_endpoint: String?
    public var forgerock_userinfo_endpoint: String?
    public var forgerock_session_endpoint: String?
    
    public var forgerock_auth_service_name: String
    public var forgerock_registration_service_name: String
    
    public var forgerock_oauth_threshold: Int?
    public var forgerock_oauth_client_id: String?
    public var forgerock_oauth_redirect_uri: String?
    public var forgerock_oauth_scope: String?
    public var forgerock_keychain_access_group: String?
    public var forgerock_ssl_pinning_public_key_hashes: [String]?
    
    enum CodingKeys: String, CodingKey {
        case forgerock_url
        case forgerock_realm
        case forgerock_enable_cookie
        case forgerock_cookie_name
        case forgerock_timeout
        case forgerock_authenticate_endpoint
        case forgerock_authorize_endpoint
        case forgerock_token_endpoint
        case forgerock_revoke_endpoint
        case forgerock_userinfo_endpoint
        case forgerock_session_endpoint
        case forgerock_auth_service_name
        case forgerock_registration_service_name
        case forgerock_oauth_threshold
        case forgerock_oauth_client_id
        case forgerock_oauth_redirect_uri
        case forgerock_oauth_scope
        case forgerock_keychain_access_group
        case forgerock_ssl_pinning_public_key_hashes
    }
    
    public init(forgerock_url: String,
                forgerock_realm: String,
                forgerock_enable_cookie: Bool,
                forgerock_cookie_name: String?,
                forgerock_timeout: Int,
                forgerock_authenticate_endpoint: String?,
                forgerock_authorize_endpoint: String?,
                forgerock_token_endpoint: String?,
                forgerock_revoke_endpoint: String?,
                forgerock_userinfo_endpoint: String?,
                forgerock_session_endpoint: String?,
                forgerock_auth_service_name: String,
                forgerock_registration_service_name: String,
                forgerock_oauth_client_id: String?,
                forgerock_oauth_threshold: Int?,
                forgerock_oauth_redirect_uri: String?,
                forgerock_oauth_scope: String?,
                forgerock_keychain_access_group: String?,
                forgerock_ssl_pinning_public_key_hashes: [String]?) {
        self.forgerock_url = forgerock_url
        self.forgerock_realm = forgerock_realm
        self.forgerock_enable_cookie = forgerock_enable_cookie
        self.forgerock_cookie_name = forgerock_cookie_name ?? "iPlanetDirectoryPro"
        self.forgerock_timeout = forgerock_timeout
        self.forgerock_authenticate_endpoint = forgerock_authenticate_endpoint
        self.forgerock_authorize_endpoint = forgerock_authorize_endpoint
        self.forgerock_token_endpoint = forgerock_token_endpoint
        self.forgerock_revoke_endpoint = forgerock_revoke_endpoint
        self.forgerock_userinfo_endpoint = forgerock_userinfo_endpoint
        self.forgerock_session_endpoint = forgerock_session_endpoint
        self.forgerock_auth_service_name = forgerock_auth_service_name
        self.forgerock_registration_service_name = forgerock_registration_service_name
        self.forgerock_oauth_threshold = forgerock_oauth_threshold
        self.forgerock_oauth_client_id = forgerock_oauth_client_id
        self.forgerock_oauth_redirect_uri = forgerock_oauth_redirect_uri
        self.forgerock_oauth_scope = forgerock_oauth_scope
        self.forgerock_keychain_access_group = forgerock_keychain_access_group
        self.forgerock_ssl_pinning_public_key_hashes = forgerock_ssl_pinning_public_key_hashes
        
        super.init()
    }
}

extension Encodable {
  func asDictionary() throws -> [String: Any] {
    let data = try JSONEncoder().encode(self)
    guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
      throw NSError()
    }
    return dictionary
  }
}
