//
//  Account.swift
//  FRAuthenticator
//
//  Copyright (c) 2020-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// Account represents an account information of authentication methods
public class Account: NSObject, NSSecureCoding, Codable {
    
    //  MARK: - Properties
    
    /// Issuer of the account
    public var issuer: String
    /// AccountName, or Username of the account for the issuer
    public var accountName: String
    /// URL of Account's logo image
    public var imageUrl: String?
    /// HEX Color code in String for Account
    public var backgroundColor: String?
    /// Time added for Account
    public var timeAdded: Date
    /// An array of Mechanism associated with current Account
    public var mechanisms: [Mechanism]
    /// Unique identifier of Account
    public var identifier: String {
        get {
            return self.issuer + "-" + self.accountName
        }
    }
    
    
    //  MARK: - Init
    
    /// Prevents init
    private override init() {
        fatalError("Default init of Account class is prohibited.")
    }
    
    
    /// Initializes Account object with given information
    /// - Parameter issuer: String value of issuer
    /// - Parameter accountName: String value of accountName or username
    /// - Parameter imageUrl: String of account's logo image (optional)
    /// - Parameter backgroundColor: String HEX code of account's background color (optional)
    init(issuer: String, accountName: String, imageUrl: String? = nil, backgroundColor: String? = nil) {

        self.issuer = issuer
        self.accountName = accountName
        self.imageUrl = imageUrl
        self.backgroundColor = backgroundColor
        self.mechanisms = []
        self.timeAdded = Date()
    }
    
    
    /// Initializes Account object with given information (used for serialization/deserialization of object)
    /// - Parameter issuer: String value of issuer
    /// - Parameter accountName: String value of accountName or username
    /// - Parameter imageUrl: URL of account's logo image (optional)
    /// - Parameter backgroundColor: String HEX code of account's background color (optional)
    /// - Parameter timeAdded: Date timestamp for creation of Account object
    init?(issuer: String?, accountName: String?, imageUrl: String?, backgroundColor: String?, timeAdded: Double) {
        
        guard let issuer = issuer, let accountName = accountName else {
            return nil
        }
        
        self.issuer = issuer
        self.accountName = accountName
        self.imageUrl = imageUrl
        self.backgroundColor = backgroundColor
        self.mechanisms = []
        self.timeAdded = Date(timeIntervalSince1970: timeAdded)
    }
    
    
    //  MARK: - NSCoder
    
    public class var supportsSecureCoding: Bool { return true }
    
    
    public func encode(with coder: NSCoder) {
        coder.encode(self.issuer, forKey: "issuer")
        coder.encode(self.accountName, forKey: "accountName")
        coder.encode(self.imageUrl, forKey: "imageUrl")
        coder.encode(self.backgroundColor, forKey: "backgroundColor")
        coder.encode(self.timeAdded.timeIntervalSince1970, forKey: "timeAdded")
    }
    
    
    public required convenience init?(coder: NSCoder) {
        
        let issuer = coder.decodeObject(of: NSString.self, forKey: "issuer") as String?
        let accountName = coder.decodeObject(of: NSString.self, forKey: "accountName") as String?
        let imageUrl = coder.decodeObject(of: NSString.self, forKey: "imageUrl") as String?
        let backgroundColor = coder.decodeObject(of: NSString.self, forKey: "backgroundColor") as String?
        let timeAdded = coder.decodeDouble(forKey: "timeAdded")
        
        self.init(issuer: issuer, accountName: accountName, imageUrl: imageUrl, backgroundColor: backgroundColor, timeAdded: timeAdded)
    }
    
    
    //  MARK: - Public
    
    /// Serializes `Account` object into JSON String. Sensitive information are not exposed.
    /// - Returns: JSON String value of `Account` object
    public func toJson() -> String? {
        return """
           {"id":"\(self.identifier)",
           "issuer":"\(self.issuer)",
           "accountName":"\(self.accountName)",
           "imageURL":"\(self.imageUrl ?? "")",
           "backgroundColor":"\(self.backgroundColor ?? "")",
           "timeAdded":\(self.timeAdded.millisecondsSince1970)}
           """
    }
}

