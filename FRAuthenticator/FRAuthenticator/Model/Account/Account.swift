//
//  Account.swift
//  FRAuthenticator
//
//  Copyright (c) 2020-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// Account represents an account information of authentication methods
public class Account: NSObject, NSSecureCoding, Codable {
    
    //  MARK: - Properties
    
    /// Issuer of the account
    public internal(set) var issuer: String
    /// AccountName, or Username of the account for the issuer
    public internal(set) var accountName: String
    /// URL of Account's logo image
    public internal(set) var imageUrl: String?
    /// HEX Color code in String for Account
    public internal(set) var backgroundColor: String?
    /// Time added for Account
    public internal(set) var timeAdded: Date
    /// Authenticator Policies in a JSON String format
    public internal(set) var policies: String?
    /// Name of the Policy locking the Account
    public internal(set) var lockingPolicy: String?
    /// Account lock indicator
    public internal(set) var lock: Bool
    /// An array of Mechanism associated with current Account
    public internal(set) var mechanisms: [Mechanism]
    
    /// Unique identifier of Account
    public var identifier: String {
        get {
            return self.issuer + "-" + self.accountName
        }
    }
    
    internal var _displayIssuer: String? = nil
    
    /// Alternative Issuer of the account. Returns original issuer if displayIssuer is not set.
    public var displayIssuer: String? {
        get {
            return self._displayIssuer ?? self.issuer
        }
        set {
            self._displayIssuer = newValue
        }
    }
    
    internal var _displayAccountName: String? = nil
    
    /// Alternative AccountName of the account. Returns original accountName if displayAccountName is not set.
    public var displayAccountName: String? {
        get {
            return self._displayAccountName ?? self.accountName
        }
        set {
            self._displayAccountName = newValue
        }
    }
    
    // MARK: - Coding Keys
    
    /// CodingKeys customize the keys when this object is encoded and decoded
    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case issuer
        case displayIssuer
        case accountName
        case displayAccountName
        case imageUrl = "imageURL"
        case backgroundColor
        case timeAdded
        case policies
        case lockingPolicy
        case lock
    }

    
    //  MARK: - Init
    
    /// Prevents init
    private override init() {
        fatalError("Default init of Account class is prohibited.")
    }
    
    
    /// Initializes Account object with given information
    /// - Parameter issuer: String value of issuer
    /// - Parameter displayIssuer: String value of the alternative issuer
    /// - Parameter accountName: String value of accountName or username
    /// - Parameter displayAccountName: String value of the alternative accountName
    /// - Parameter imageUrl: String of account's logo image (optional)
    /// - Parameter backgroundColor: String HEX code of account's background color (optional)
    /// - Parameter policies: Authenticator Policies in a JSON String format
    init(issuer: String, displayIssuer: String? = nil, accountName: String, displayAccountName: String? = nil, imageUrl: String? = nil, backgroundColor: String? = nil, policies: String? = nil) {

        self.issuer = issuer
        self._displayIssuer = displayIssuer
        self.accountName = accountName
        self._displayAccountName = displayAccountName
        self.imageUrl = imageUrl
        self.backgroundColor = backgroundColor
        self.policies = policies
        self.mechanisms = []
        self.timeAdded = Date()
        self.lock = false
    }
    
    
    /// Initializes Account object with given information (used for serialization/deserialization of object)
    /// - Parameter issuer: String value of issuer
    /// - Parameter displayIssuer: String value of the alternative issuer
    /// - Parameter accountName: String value of accountName or username
    /// - Parameter displayAccountName: String value of the alternative accountName
    /// - Parameter imageUrl: URL of account's logo image (optional)
    /// - Parameter backgroundColor: String HEX code of account's background color (optional)
    /// - Parameter timeAdded: Date timestamp for creation of Account object
    /// - Parameter policies: Authenticator Policies in a JSON String format
    /// - Parameter lockingPolicy: Name of the Policy locking the Account
    /// - Parameter lock: Bool value indicating Account lock
    init?(issuer: String?, displayIssuer: String?, accountName: String?, displayAccountName: String?, imageUrl: String?, backgroundColor: String?, timeAdded: Double, policies: String?, lockingPolicy: String?, lock: Bool?) {
        
        guard let issuer = issuer, let accountName = accountName else {
            return nil
        }
        
        self.issuer = issuer
        self._displayIssuer = displayIssuer
        self.accountName = accountName
        self._displayAccountName = displayAccountName
        self.imageUrl = imageUrl
        self.backgroundColor = backgroundColor
        self.mechanisms = []
        self.timeAdded = Date(timeIntervalSince1970: timeAdded)
        self.policies = policies
        self.lockingPolicy = lockingPolicy
        self.lock = lock ?? false
    }
    
    
    //  MARK: - NSCoder
    
    public class var supportsSecureCoding: Bool { return true }
    
    public func encode(with coder: NSCoder) {
        coder.encode(self.issuer, forKey: "issuer")
        coder.encode(self._displayIssuer, forKey: "displayIssuer")
        coder.encode(self.accountName, forKey: "accountName")
        coder.encode(self._displayAccountName, forKey: "displayAccountName")
        coder.encode(self.imageUrl, forKey: "imageUrl")
        coder.encode(self.backgroundColor, forKey: "backgroundColor")
        coder.encode(self.timeAdded.timeIntervalSince1970, forKey: "timeAdded")
        coder.encode(self.policies, forKey: "policies")
        coder.encode(self.lockingPolicy, forKey: "lockingPolicy")
        coder.encode(self.lock, forKey: "lock")
    }
    
    
    public required convenience init?(coder: NSCoder) {
        
        let issuer = coder.decodeObject(of: NSString.self, forKey: "issuer") as String?
        let alternativeIssuer = coder.decodeObject(of: NSString.self, forKey: "displayIssuer") as String?
        let accountName = coder.decodeObject(of: NSString.self, forKey: "accountName") as String?
        let alternativeAccountName = coder.decodeObject(of: NSString.self, forKey: "displayAccountName") as String?
        let imageUrl = coder.decodeObject(of: NSString.self, forKey: "imageUrl") as String?
        let backgroundColor = coder.decodeObject(of: NSString.self, forKey: "backgroundColor") as String?
        let timeAdded = coder.decodeDouble(forKey: "timeAdded")
        let policies = coder.decodeObject(of: NSString.self, forKey: "policies") as String?
        let lockingPolicy = coder.decodeObject(of: NSString.self, forKey: "lockingPolicy") as String?
        let lock = coder.decodeBool(forKey: "lock") as Bool?
        
        self.init(issuer: issuer, displayIssuer: alternativeIssuer, accountName: accountName, displayAccountName: alternativeAccountName, imageUrl: imageUrl, backgroundColor: backgroundColor, timeAdded: timeAdded, policies: policies, lockingPolicy: lockingPolicy, lock: lock)
    }
    
    
    //  MARK: - Codable
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.identifier, forKey: .identifier)
        try container.encode(self.issuer, forKey: .issuer)
        try container.encode(self._displayIssuer, forKey: .displayIssuer)
        try container.encode(self.accountName, forKey: .accountName)
        try container.encode(self._displayAccountName, forKey: .displayAccountName)
        try container.encode(self.imageUrl, forKey: .imageUrl)
        try container.encode(self.backgroundColor, forKey: .backgroundColor)
        try container.encode(self.timeAdded.millisecondsSince1970, forKey: .timeAdded)
        try container.encode(self.policies, forKey: .policies)
        try container.encode(self.lockingPolicy, forKey: .lockingPolicy)
        try container.encode(self.lock, forKey: .lock)
    }

    
    public required convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let issuer = try values.decode(String.self, forKey: .issuer)
        let displayIssuer = try values.decodeIfPresent(String.self, forKey: .displayIssuer)
        let accountName = try values.decode(String.self, forKey: .accountName)
        let displayAccountName = try values.decodeIfPresent(String.self, forKey: .displayAccountName)
        let imageUrl = try values.decodeIfPresent(String.self, forKey: .imageUrl)
        let backgroundColor = try values.decodeIfPresent(String.self, forKey: .backgroundColor)
        let milliseconds = try values.decode(Double.self, forKey: .timeAdded)
        let timeAdded = milliseconds / 1000
        let policies = try values.decodeIfPresent(String.self, forKey: .policies)
        let lockingPolicy = try values.decodeIfPresent(String.self, forKey: .lockingPolicy)
        let lock = try values.decodeIfPresent(Bool.self, forKey: .lock)
        
        self.init(issuer: issuer, displayIssuer: displayIssuer, accountName: accountName, displayAccountName: displayAccountName, imageUrl: imageUrl, backgroundColor: backgroundColor, timeAdded: timeAdded, policies: policies, lockingPolicy: lockingPolicy, lock: lock)!
    }
    
    
    //  MARK: - Public
    
    /// Lock this Account
    /// - Parameters:
    ///   - policy: the non-compliance policy
    public func lock(policy: FRAPolicy) -> Void {        
        self.lockingPolicy = policy.name
        self.lock = true
    }
    
    /// Unlock this Account.
    public func unlock() -> Void {
        self.lockingPolicy = nil
        self.lock = false
    }
    
    /// Serializes `Account` object into JSON String.
    /// - Returns: JSON String value of `Account` object
    public func toJson() -> String? {
        if let objData = try? JSONEncoder().encode(self), let serializedStr = String(data: objData, encoding: .utf8) {
            return serializedStr
        }
        else {
            return nil
        }
    }
    
    
}

