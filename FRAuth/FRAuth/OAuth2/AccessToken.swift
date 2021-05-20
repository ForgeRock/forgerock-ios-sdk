//
//  AccessToken.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// AccessToken class represents access_token data inheriting from Token class
@objc public class AccessToken: Token {
    
    //  MARK: - Property
    
    /// Lifetime (expires_in) of access_token in seconds
    @objc public var expiresIn: Int
    /// token_type of access_token
    @objc public var tokenType: String
    /// Granted scope(s) with space separator for given access_token
    @objc public var scope: String
    /// refresh_token associated with access_token (optional)
    @objc public var refreshToken: String?
    /// id_token associated with access_token (optional)
    @objc public var idToken: String?
    /// Timestamp of given access_token's authenticated time
    var authenticatedTimestamp: Date
    /// SessionToken that granted current AccessToken
    var sessionToken: String?
    /// Expiration Date of AccessToken
    @objc public var expiration: Date {
        get {
            return Date(timeIntervalSince1970: self.authenticatedTimestamp.timeIntervalSince1970 + Double(self.expiresIn))
        }
    }
    
    /// Boolean indicator whether access_token is expired or not with given expiration and authentication timestamp
    @objc
    public var isExpired:Bool {
        return self.willExpireIn(threshold: 0)
    }
    
    
    //  MARK: - Method
    
    /// Builds Authorization header with given access_token and token_type
    ///
    /// - Returns: String value of "<token_type>: <access_token>"
    @objc public func buildAuthorizationHeader() -> String {
        return self.tokenType + " " + self.value
    }
    
    
    /// Determines whether access_token will expire in given threshold
    ///
    /// - Parameter threshold: Threshold in seconds
    /// - Returns: Boolean result whether access_token will expire in given threshold
    func willExpireIn(threshold: Int) -> Bool {
        if let expiredTimestamp = Calendar.current.date(byAdding: .second, value: (self.expiresIn - threshold), to: self.authenticatedTimestamp) {
            return Date().timeIntervalSince1970 > expiredTimestamp.timeIntervalSince1970
        }
        else {
            FRLog.w("Failed to correctly validate token lifetime; \(self.authenticatedTimestamp) | \(self.expiresIn) | \(threshold)")
            return false
        }
    }
    
    
    //  MARK: - Init
    
    /// Initializes AccessToken object with Dictionary object containing access_token, scope, expires_in, token_type, and other optional values
    ///
    /// - Parameter tokenResponse: Dictionary containing access_token related information
    /// - Parameter sessionToken: SessionToken associated with AccessToken
    init?(tokenResponse: [String: Any], sessionToken: String? = nil) {
        
        /// Make sure minimum required information is provided
        guard let accessToken = tokenResponse[OAuth2.accessToken] as? String, let scope = tokenResponse[OAuth2.scope] as? String, let lifetime = tokenResponse[OAuth2.tokenExpiresIn] as? Int, let tokenType = tokenResponse[OAuth2.tokenType] as? String else {
            FRLog.w("Invalid access_token response: \(tokenResponse)")
            return nil
        }
        
        self.expiresIn = lifetime
        self.scope = scope
        self.tokenType = tokenType
        self.refreshToken = tokenResponse[OAuth2.refreshToken] as? String
        self.idToken = tokenResponse[OAuth2.idToken] as? String
        self.authenticatedTimestamp = Date()
        self.sessionToken = sessionToken
        super.init(accessToken)
    }
    
    
    /// Initializes AccessToken object with given parameters
    ///
    /// - Parameters:
    ///   - token: String value of access_token
    ///   - expiresIn: Int value of access_token lifetime
    ///   - scope: String value of scope(s) granted to access_token with space separator
    ///   - tokenType: String value of token_type
    ///   - refreshToken: String value of refresh_token
    ///   - idToken: String value of id_token
    ///   - authenticatedTimestamp: Double value of authenticated timestamp
    ///   - sessionToken: SessionToken associated with AccessToken
    init?(token: String?, expiresIn: Int?, scope: String?, tokenType: String?, refreshToken: String?, idToken:String?, authenticatedTimestamp: Double?, sessionToken: String? = nil) {
        
        guard let token = token, let expiresIn = expiresIn, let scope = scope, let tokenType = tokenType, let authenticatedTimestamp = authenticatedTimestamp else {
            FRLog.w("Invalid access_token response: some information is missing.")
            return nil
        }
        
        self.expiresIn = expiresIn
        self.scope = scope
        self.tokenType = tokenType
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.authenticatedTimestamp = Date(timeIntervalSince1970: authenticatedTimestamp)
        self.sessionToken = sessionToken
        super.init(token)
    }
    
    
    //  MARK: - Debug
    
    /// Prints debug description of AccessToken
    override public var debugDescription: String {
        return "\(String(describing: self)) isExpired?: \(self.isExpired)\n\naccess_token: \(self.value) | token_type: \(self.tokenType) | scope: \(self.scope) | expires_in: \(String(describing: self.expiresIn)) | refresh_token: \(self.refreshToken ?? "nil") | id_token: \(self.idToken ?? "nil") | expiration: \(self.expiration)"
    }
    
    
    // MARK: NSSecureCoding
    
    /// Boolean value of whether SecureCoding is supported or not
    override public class var supportsSecureCoding: Bool { return true }
    
    
    /// Initializes AccessToken object with NSCoder
    ///
    /// - Parameter aDecoder: NSCoder
    required public convenience init?(coder aDecoder: NSCoder) {

        let token = aDecoder.decodeObject(of: NSString.self, forKey: "value") as String?
        let expiresIn = aDecoder.decodeInteger(forKey: "expires_in")
        let scope = aDecoder.decodeObject(of: NSString.self, forKey: "scope") as String?
        let tokenType = aDecoder.decodeObject(of: NSString.self, forKey: "token_type") as String?
        let refreshToken = aDecoder.decodeObject(of: NSString.self, forKey: "refresh_token") as String?
        let idToken = aDecoder.decodeObject(of: NSString.self, forKey: "id_token") as String?
        let authenticatedTimestamp = aDecoder.decodeDouble(forKey: "authenticatedTimestamp")
        let sessionToken = aDecoder.decodeObject(of: NSString.self, forKey: "session_token") as String?
        
        self.init(token: token, expiresIn: expiresIn, scope: scope, tokenType: tokenType, refreshToken: refreshToken, idToken: idToken, authenticatedTimestamp: authenticatedTimestamp, sessionToken: sessionToken)
    }
    
    
    /// Encodes AccessToken object with NSCoder
    ///
    /// - Parameter aCoder: NSCoder
    override public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.value, forKey: "value")
        aCoder.encode(self.expiresIn, forKey: "expires_in")
        aCoder.encode(self.scope, forKey: "scope")
        aCoder.encode(self.tokenType, forKey: "token_type")
        aCoder.encode(self.refreshToken, forKey: "refresh_token")
        aCoder.encode(self.idToken, forKey: "id_token")
        aCoder.encode(self.authenticatedTimestamp.timeIntervalSince1970, forKey: "authenticatedTimestamp")
        aCoder.encode(self.sessionToken, forKey: "session_token")
    }
    
    private enum CodingKeys: String, CodingKey {
            case expiresIn, scope, tokenType, refreshToken, idToken, authenticatedTimestamp, sessionToken
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.expiresIn, forKey: .expiresIn)
        try container.encode(self.scope, forKey: .scope)
        try container.encode(self.tokenType, forKey: .tokenType)
        try container.encode(self.refreshToken, forKey: .refreshToken)
        try container.encode(self.idToken, forKey: .idToken)
        try container.encode(self.authenticatedTimestamp, forKey: .authenticatedTimestamp)
        try container.encode(self.sessionToken, forKey: .sessionToken)
    }
    
    
    /// Evaluates whether given two AccessTokens are equal or not
    ///
    /// - Parameters:
    ///   - lhs: AccessToken to be compared
    ///   - rhs: AccessToken to be compared
    /// - Returns: Boolean result of whether given two AccessTokens are equal or not
    static func == (lhs: AccessToken, rhs: AccessToken) -> Bool {
        return
            lhs.value == rhs.value &&
                lhs.expiresIn == rhs.expiresIn &&
                lhs.tokenType == rhs.tokenType &&
                lhs.scope == rhs.scope &&
                lhs.refreshToken == rhs.refreshToken &&
                lhs.idToken == rhs.idToken &&
                lhs.authenticatedTimestamp.timeIntervalSince1970 == rhs.authenticatedTimestamp.timeIntervalSince1970 &&
                lhs.sessionToken == rhs.sessionToken
    }
    
    
    /// Evaluates whether given object is equal to the self-object or not
    ///
    /// - Parameter object: An object to be compared
    /// - Returns: Boolean result of whether given AccessToken is equal or not
    override public func isEqual(_ object: Any?) -> Bool {
        if let obj = object as? AccessToken {
            return
                self.value == obj.value &&
                    self.expiresIn == obj.expiresIn &&
                    self.tokenType == obj.tokenType &&
                    self.scope == obj.scope &&
                    self.refreshToken == obj.refreshToken &&
                    self.idToken == obj.idToken &&
                    self.authenticatedTimestamp.timeIntervalSince1970 == obj.authenticatedTimestamp.timeIntervalSince1970 &&
                    self.sessionToken == obj.sessionToken
        }
        return false
    }
}
