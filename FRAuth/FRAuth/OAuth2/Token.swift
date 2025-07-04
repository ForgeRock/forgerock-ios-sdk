//
//  Token.swift
//  FRAuth
//
//  Copyright (c) 2019 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// Token class represents any token object type
@objc public class Token: NSObject, Encodable, NSSecureCoding {
    
    //  MARK: - Property
    
    /// Raw value of token
    @objc
    public var value: String
    public var successUrl: String
    public var realm: String
    
    
    //  MARK: - Init
    
    /// Initializes Token object with given token value
    ///
    /// - Parameter token: raw string value of token
    init(_ token: String,
        successUrl: String = "",
        realm: String = "") {
        self.value = token
        self.successUrl = successUrl
        self.realm = realm
        super.init()
    }
    
    
    //  MARK: - Debug
    
    /// Prints debug description of Token object
    override public var debugDescription: String {
        return "\(String(describing: self)) \nValue: \(self.value)"
    }
    
    
    // MARK: NSSecureCoding
    
    /// Boolean value of whether SecureCoding is supported or not
    public class var supportsSecureCoding: Bool {
        return true
    }
    
    
    /// Initializes Token object with NSCoder
    ///
    /// - Parameter aDecoder: NSCoder
    convenience required public init?(coder aDecoder: NSCoder) {
        guard let token = aDecoder.decodeObject(of: NSString.self, forKey: "value") as String?,
        let successUrl = aDecoder.decodeObject(of: NSString.self, forKey: "successUrl") as String?,
        let realm = aDecoder.decodeObject(of: NSString.self, forKey: "realm") as String? else {
            return nil
        }
        self.init(token, successUrl: successUrl, realm: realm)
    }
    
    
    /// Encodes Token object with NSCoder
    ///
    /// - Parameter aCoder: NSCoder
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.value, forKey: "value")
        aCoder.encode(self.successUrl, forKey: "successUrl")
        aCoder.encode(self.realm, forKey: "realm")
    }
    
    
    /// Evaluates whether given two Tokens are equal or not
    ///
    /// - Parameters:
    ///   - lhs: Token to be compared
    ///   - rhs: Token to be compared
    /// - Returns: Boolean result of whether given two Tokens are equal or not
    static func == (lhs: Token, rhs: Token) -> Bool {
        return lhs.value == rhs.value
    }
    
    
    /// Evaluates whether given object is equal to the self-object or not
    ///
    /// - Parameter object: An object to be compared
    /// - Returns: Boolean result of whether given Token is equal or not
    override public func isEqual(_ object: Any?) -> Bool {
        if let obj = object as? Token {
            return
                self.value == obj.value
        }
        return false
    }
}
