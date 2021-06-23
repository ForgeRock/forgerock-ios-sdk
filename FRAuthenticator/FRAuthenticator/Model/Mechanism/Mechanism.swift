// 
//  Mechanism.swift
//  FRAuthenticator
//
//  Copyright (c) 2020-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// Mechanism class represents generic auth type, and is base class of all Mechanism (authentication type) in FRAuthenticator SDK
public class Mechanism: NSObject, NSSecureCoding, Codable {
    
    //  MARK: - Properties
    
    /// uniquely identifiable UUID for current mechanism
    var mechanismUUID: String
    /// type of auth
    public var type: String
    /// version of auth
    var version: Int
    /// issuer of auth
    public var issuer: String
    /// shared secret of auth
    var secret: String
    /// accountName or username of auth
    public var accountName: String
    /// Time added for push
    public var timeAdded: Date
    
    /// Unique identifier for current auth associated with Account information
    public var identifier: String {
        get {
            return self.issuer + "-" + self.accountName + "-" + self.type
        }
    }
    
    //  MARK: - Init
    
    /// Prevents init
    private override init() {
        fatalError("Default init of Mechanism class is prohibited.")
    }
    
    
    /// Initializes Mechanism object with given data
    /// - Parameters:
    ///   - type: type of OATH
    ///   - issuer: issuer of OATH
    ///   - accountName: accountName of current OATH Mechanism
    ///   - secret: shared secret in string of OATH Mechanism
    init(type: String, issuer: String, accountName: String, secret: String) {
        
        self.mechanismUUID = UUID().uuidString
        self.version = 1
        
        self.type = type
        self.issuer = issuer
        self.accountName = accountName
        self.secret = secret
        self.timeAdded = Date()
    }
    
    
    /// Initializes Mechanism with given data
    /// - Parameter mechanismUUID: mechanism's UUID; generic UUID type and not same as Mechanism.identifier
    /// - Parameter type: type of Mechanism's auth
    /// - Parameter version: version of Mechanism's auth
    /// - Parameter issuer: issuer
    /// - Parameter secret: shared secret
    /// - Parameter accountName: accountName or username of auth
    /// - Parameter timeAdded: Date timestamp for creation of Mechanism object
    init?(mechanismUUID: String?, type: String?, version: Int?, issuer: String?, secret: String?, accountName: String?, timeAdded: Double) {
    
        guard let mechanismUUID = mechanismUUID, let type = type, let version = version, let issuer = issuer, let secret = secret, let accountName = accountName else {
            return nil
        }
        
        self.mechanismUUID = mechanismUUID
        self.type = type
        self.version = version
        self.issuer = issuer
        self.secret = secret
        self.accountName = accountName
        self.timeAdded = Date(timeIntervalSince1970: timeAdded)
        super.init()
    }
    
    
    //  MARK: - NSCoder
    
    public class var supportsSecureCoding: Bool {
        return true
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(self.mechanismUUID, forKey: "mechanismUUID")
        coder.encode(self.type, forKey: "type")
        coder.encode(self.version, forKey: "version")
        coder.encode(self.secret, forKey: "secret")
        coder.encode(self.issuer, forKey: "issuer")
        coder.encode(self.accountName, forKey: "accountName")
        coder.encode(self.timeAdded.timeIntervalSince1970, forKey: "timeAdded")
    }
    
    public required convenience init?(coder: NSCoder) {
        
        let mechanismUUID = coder.decodeObject(of: NSString.self, forKey: "mechanismUUID") as String?
        let type = coder.decodeObject(of: NSString.self, forKey: "type") as String?
        let version = coder.decodeInteger(forKey: "version")
        let issuer = coder.decodeObject(of: NSString.self, forKey: "issuer") as String?
        let secret = coder.decodeObject(of: NSString.self, forKey: "secret") as String?
        let accountName = coder.decodeObject(of: NSString.self, forKey: "accountName") as String?
        let timeAdded = coder.decodeDouble(forKey: "timeAdded")
        
        self.init(mechanismUUID: mechanismUUID, type: type, version: version, issuer: issuer, secret: secret, accountName: accountName, timeAdded: timeAdded)
    }
}
