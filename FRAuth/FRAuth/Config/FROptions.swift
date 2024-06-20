// 
//  FROptions.swift
//  FRAuth
//
//  Copyright (c) 2022-2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// FROptions represents a configuration object for the SDK. It can be used for passing configuration options in the FRAuth.start() method.
///
@objc
open class FROptions: NSObject, Codable {
    /// String constant for FROptions storage key
    internal static let frOptionsStorageKey: String = "FROptions"
    
    public var url: String
    public var realm: String
    public var enableCookie: Bool
    public var cookieName: String
    public var timeout: String
    
    internal var authenticateEndpoint: String?
    internal var authorizeEndpoint: String?
    internal var tokenEndpoint: String?
    internal var revokeEndpoint: String?
    internal var userinfoEndpoint: String?
    internal var sessionEndpoint: String?
    internal var endSessionEndpoint: String?
    
    public var authServiceName: String
    public var registrationServiceName: String
    
    public var oauthThreshold: String?
    public var oauthClientId: String?
    public var oauthRedirectUri: String?
    public var oauthSignoutRedirectUri: String?
    public var oauthScope: String?
    public var keychainAccessGroup: String?
    public var sslPinningPublicKeyHashes: [String]?
    
    enum CodingKeys: String, CodingKey {
        case url = "forgerock_url"
        case realm = "forgerock_realm"
        case enableCookie = "forgerock_enable_cookie"
        case cookieName = "forgerock_cookie_name"
        case timeout = "forgerock_timeout"
        case authenticateEndpoint = "forgerock_authenticate_endpoint"
        case authorizeEndpoint = "forgerock_authorize_endpoint"
        case tokenEndpoint = "forgerock_token_endpoint"
        case revokeEndpoint = "forgerock_revoke_endpoint"
        case userinfoEndpoint = "forgerock_userinfo_endpoint"
        case sessionEndpoint = "forgerock_session_endpoint"
        case endSessionEndpoint = "forgerock_endsession_endpoint"
        case authServiceName = "forgerock_auth_service_name"
        case registrationServiceName = "forgerock_registration_service_name"
        case oauthThreshold = "forgerock_oauth_threshold"
        case oauthClientId = "forgerock_oauth_client_id"
        case oauthRedirectUri = "forgerock_oauth_redirect_uri"
        case oauthSignoutRedirectUri = "forgerock_oauth_sign_out_redirect_uri"
        case oauthScope = "forgerock_oauth_scope"
        case keychainAccessGroup = "forgerock_keychain_access_group"
        case sslPinningPublicKeyHashes = "forgerock_ssl_pinning_public_key_hashes"
    }
    
    //  MARK: - Init
    
    /// Initializes the FROptions object
    /// - Parameters:
    ///   - url: The AM URL
    ///   - realm: The AM realm used for authentication
    ///   - enableCookie: Boolean value to enable cookie usage
    ///   - timeout: Timeout value in String format
    ///   - authenticateEndpoint: AM /authenticate endpoint. Optionaly used for custom endpoints.
    ///   - authorizeEndpoint: AM /authorize endpoint. Optionaly used for custom endpoints.
    ///   - tokenEndpoint: AM /token endpoint. Optionaly used for custom endpoints.
    ///   - revokeEndpoint: AM /revoke endpoint. Optionaly used for custom endpoints.
    ///   - userinfoEndpoint: AM /userinfo endpoint. Optionaly used for custom endpoints.
    ///   - sessionEndpoint: AM /session endpoint. Optionaly used for custom endpoints.
    ///   - endSessionEndpoint: AM /endSession endpoint. Optionaly used for custom endpoints.
    ///   - authServiceName: AM Tree/Journey used for authentication. Default tree to be used with FRUser.login
    ///   - registrationServiceName: AM Tree/Journey used for registration. Default tree to be used with FRUser.register
    ///   - oauthThreshold: OAuth Client timeout threshold
    ///   - oauthClientId: OAuth Client name
    ///   - oauthRedirectUri: OAuth Client redirectURI
    ///   - oauthSignoutRedirectUri: OAuth Client signout redirectURI
    ///   - oauthScope: OAuth Client scopes
    ///   - keychainAccessGroup: Keychain access group for shared keychain
    ///   - sslPinningPublicKeyHashes: SSL Pinning hashes
    ///
    public init(url: String,
                realm: String,
                enableCookie: Bool = true,
                cookieName: String? = nil,
                timeout: String = "60",
                authenticateEndpoint: String? = nil,
                authorizeEndpoint: String? = nil,
                tokenEndpoint: String? = nil,
                revokeEndpoint: String? = nil,
                userinfoEndpoint: String? = nil,
                sessionEndpoint: String? = nil,
                endSessionEndpoint: String? = nil,
                authServiceName: String = "Login",
                registrationServiceName: String = "Registration",
                oauthThreshold: String? = nil,
                oauthClientId: String? = nil,
                oauthRedirectUri: String? = nil,
                oauthSignoutRedirectUri: String? = nil,
                oauthScope: String? = nil,
                keychainAccessGroup: String? = nil,
                sslPinningPublicKeyHashes: [String]? = nil) {
        self.url = url
        self.realm = realm
        self.enableCookie = enableCookie
        self.cookieName = cookieName ?? "iPlanetDirectoryPro"
        self.timeout = timeout
        self.authenticateEndpoint = authenticateEndpoint
        self.authorizeEndpoint = authorizeEndpoint
        self.tokenEndpoint = tokenEndpoint
        self.revokeEndpoint = revokeEndpoint
        self.userinfoEndpoint = userinfoEndpoint
        self.sessionEndpoint = sessionEndpoint
        self.endSessionEndpoint = endSessionEndpoint
        self.authServiceName = authServiceName
        self.registrationServiceName = registrationServiceName
        self.oauthClientId = oauthClientId
        self.oauthThreshold = oauthThreshold
        self.oauthRedirectUri = oauthRedirectUri
        self.oauthSignoutRedirectUri = oauthSignoutRedirectUri
        self.oauthScope = oauthScope
        self.keychainAccessGroup = keychainAccessGroup
        self.sslPinningPublicKeyHashes = sslPinningPublicKeyHashes
        
        super.init()
    }
    
    /// Initializes the FROptions object
    /// - Parameters:
    ///   - config: Configuration dictionary [String: Any], providing properties either from a Serialized FROption object or a configuration plist
    ///
    public init(config: [String: Any]) {
        self.url = config[FROptions.CodingKeys.url.rawValue] as? String ?? ""
        self.realm = config[FROptions.CodingKeys.realm.rawValue] as? String ?? ""
        self.enableCookie = config[FROptions.CodingKeys.enableCookie.rawValue] as? Bool ?? true
        self.cookieName = config[FROptions.CodingKeys.cookieName.rawValue] as? String ?? "iPlanetDirectoryPro"
        self.timeout = config[FROptions.CodingKeys.timeout.rawValue] as? String ?? "60"
        self.authenticateEndpoint = config[FROptions.CodingKeys.authenticateEndpoint.rawValue] as? String
        self.authorizeEndpoint = config[FROptions.CodingKeys.authorizeEndpoint.rawValue] as? String
        self.tokenEndpoint = config[FROptions.CodingKeys.tokenEndpoint.rawValue] as? String
        self.revokeEndpoint = config[FROptions.CodingKeys.revokeEndpoint.rawValue] as? String
        self.userinfoEndpoint = config[FROptions.CodingKeys.userinfoEndpoint.rawValue] as? String
        self.sessionEndpoint = config[FROptions.CodingKeys.sessionEndpoint.rawValue] as? String
        self.endSessionEndpoint = config[FROptions.CodingKeys.endSessionEndpoint.rawValue] as? String
        self.authServiceName = config[FROptions.CodingKeys.authServiceName.rawValue] as? String ?? "Login"
        self.registrationServiceName = config[FROptions.CodingKeys.registrationServiceName.rawValue] as? String ?? "Registration"
        self.oauthClientId = config[FROptions.CodingKeys.oauthClientId.rawValue] as? String
        self.oauthThreshold = config[FROptions.CodingKeys.oauthThreshold.rawValue] as? String
        self.oauthRedirectUri = config[FROptions.CodingKeys.oauthRedirectUri.rawValue] as? String
        self.oauthSignoutRedirectUri = config[FROptions.CodingKeys.oauthSignoutRedirectUri.rawValue] as? String
        self.oauthScope = config[FROptions.CodingKeys.oauthScope.rawValue] as? String
        self.keychainAccessGroup = config[FROptions.CodingKeys.keychainAccessGroup.rawValue] as? String
        self.sslPinningPublicKeyHashes = config[FROptions.CodingKeys.sslPinningPublicKeyHashes.rawValue] as? [String]
        
        super.init()
    }
    
    // - MARK: Public
    
    /// Returns the FROptions oject in a [String: Any]? Dictionary format
    public func optionsDictionary() -> [String: Any]? {
        return try? self.asDictionary()
    }
    
    public func getAuthenticateEndpoint() -> String {
        return self.authenticateEndpoint ?? "/json/realms/\(self.realm)/authenticate"
    }
    
    public func getAuthorizeEndpoint() -> String {
        return self.authorizeEndpoint ?? "/oauth2/realms/\(self.realm)/authorize"
    }
    
    public func getTokenEndpoint() -> String {
        return self.tokenEndpoint ?? "/oauth2/realms/\(self.realm)/access_token"
    }
    
    public func getRevokeEndpoint() -> String {
        return self.revokeEndpoint ?? "/oauth2/realms/\(self.realm)/token/revoke"
    }
    
    public func getUserinfoEndpoint() -> String {
        return self.userinfoEndpoint ?? "/oauth2/realms/\(self.realm)/userinfo"
    }
    
    public func getSessionEndpoint() -> String {
        return self.sessionEndpoint ?? "/json/realms/\(self.realm)/sessions"
    }
    
    public func getEndSessionEndpoint() -> String {
        return self.endSessionEndpoint ?? "/oauth2/realms/\(self.realm)/connect/endSession"
    }

  /// Asynchronously discovers configuration options based on a provided discovery URL.
  ///
  /// - Parameter discoveryURL: The URL string from which to discover configuration options. This URL should point to a well-known configuration endpoint that returns the necessary configuration settings in a JSON format.
  /// - Returns: An instance of `FROptions` populated with the configuration settings fetched from the discovery URL.
  @available(iOS 13.0.0, *)
  open func discover(discoveryURL: String) async throws -> FROptions {
    guard let discoveryURL = URL(string: discoveryURL) else {
      throw OAuth2Error.other("Invalid discovery URL")
    }
    let data = try await URLSession.shared.data(from: discoveryURL)
    let config = try JSONDecoder().decode(OpenIdConfiguration.self, from: data.0)

    guard let baseUrl = self.url.isEmpty ? config.issuer : self.url else {
      throw OAuth2Error.other("Missing base URL")
    }
    self.url = baseUrl
    self.authorizeEndpoint = config.authorizationEndpoint
    self.tokenEndpoint = config.tokenEndpoint
    self.userinfoEndpoint = config.userinfoEndpoint
    self.endSessionEndpoint = config.endSessionEndpoint
    self.revokeEndpoint = config.revocationEndpoint

    return self
  }

    // - MARK: Private
    
    /// Equatable comparison method. Comparing the realm, cookie and oauthClientId values
    static func == (lhs: FROptions, rhs: FROptions) -> Bool {
        return (lhs.url == rhs.url &&
                lhs.realm == rhs.realm &&
                lhs.cookieName == rhs.cookieName &&
                lhs.oauthClientId == rhs.oauthClientId &&
                lhs.oauthScope == rhs.oauthScope &&
                lhs.oauthRedirectUri == rhs.oauthRedirectUri &&
                lhs.oauthSignoutRedirectUri == rhs.oauthSignoutRedirectUri &&
                lhs.keychainAccessGroup == rhs.keychainAccessGroup)
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

private struct OpenIdConfiguration: Codable {
    public let issuer: String?
    public let authorizationEndpoint: String?
    public let tokenEndpoint: String?
    public let userinfoEndpoint: String?
    public let endSessionEndpoint: String?
    public let revocationEndpoint: String?


    private enum CodingKeys: String, CodingKey {
        case issuer = "issuer"
        case authorizationEndpoint = "authorization_endpoint"
        case tokenEndpoint = "token_endpoint"
        case userinfoEndpoint = "userinfo_endpoint"
        case endSessionEndpoint = "end_session_endpoint"
        case revocationEndpoint = "revocation_endpoint"
    }
}

