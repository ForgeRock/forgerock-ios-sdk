//
//  UserInfo.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/**
 UserInfo class is a representation of a user's UserInfo data according to OAuth2 and OIDC spec. UserInfo is retrieved using /userinfo endpoint.
 */
@objc(FRUserInfo)
public class UserInfo: NSObject, NSSecureCoding {
    
    //  MARK: - Property
    
    /// Name
    @objc public var name: String?
    /// Family name
    @objc public var familyName: String?
    /// Given name
    @objc public var givenName: String?
    /// Middle name
    @objc public var middleName: String?
    /// Nickname
    @objc public var nickName: String?
    /// Preferred Username
    @objc public var preferredUsername: String?
    /// Profile URL
    @objc public var profile: URL?
    /// Picture URL
    @objc public var picture: URL?
    /// Website URL
    @objc public var website: URL?
    /// Gender
    @objc public var gender: String?
    /// BirthDate in Date
    @objc public var birthDate: Date?
    /// Zone information
    @objc public var zoneInfo: String?
    /// Locale
    @objc public var locale: String?
    /// Subject
    @objc public var sub: String?
    /// Email address
    @objc public var email: String?
    /// Boolean indicator whether user's email address is verified
    @objc public var emailVerified: Bool = false
    /// Phone number
    @objc public var phoneNumber: String?
    /// Boolean indicator whether user's phone number is verified
    @objc public var phoneNumberVerified: Bool = false
    /// Address object which contains detailed Address information
    @objc public var address: Address?
    /// Raw JSON response of /userinfo endpoint
    @objc public var userInfo: [String: Any]
    
    
    //  MARK: - Init
    
    /// Constructs UserInfo object with given raw JSON response from /userinfo endpoint
    ///
    /// - Parameter userInfo: raw JSON response
    init(_ userInfo: [String: Any]) {
        
        self.userInfo = userInfo
        let dict = self.userInfo as Dictionary
        
        self.name = dict.string(OIDC.name)
        self.familyName = dict.string(OIDC.familyName)
        self.givenName = dict.string(OIDC.givenName)
        self.middleName = dict.string(OIDC.middleName)
        self.nickName = dict.string(OIDC.nickname)
        self.preferredUsername = dict.string(OIDC.preferredUsername)
        self.profile = dict.url(OIDC.profile)
        self.picture = dict.url(OIDC.picture)
        self.website = dict.url(OIDC.website)
        self.gender = dict.string(OIDC.gender)
        self.zoneInfo = dict.string(OIDC.zoneInfo)
        self.locale = dict.string(OIDC.locale)
        self.sub = dict.string(OIDC.sub)
        
        self.email = dict.string(OIDC.email)
        self.emailVerified = dict.bool(OIDC.emailVerified)
        
        self.phoneNumber = dict.string(OIDC.phoneNumber)
        self.phoneNumberVerified = dict.bool(OIDC.phoneNumberVerified)
        
        if let birthDate = dict.string(OIDC.birthdate) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            self.birthDate = dateFormatter.date(from: birthDate)
        }
        
        if let address = self.userInfo[OIDC.address] as? [String: Any] {
            self.address = Address(address)
        }
        
        super.init()
    }
    
    
    //  MARK: - Debug
    
    /// Prints debug description of UserInfo object
    override public var debugDescription: String {
        var desc =  "\(String(describing: self))\n\t\t"
        
        if let name = self.name {
            desc += "\tName: " + name
        }
        if let familyName = self.familyName {
            desc += "\tFamily Name: " + familyName
        }
        if let givenName = self.givenName {
            desc += "\tGiven Name: " + givenName
        }
        if let middleName = self.middleName {
            desc += "\tMiddle Name: " + middleName
        }
        if let nickName = self.nickName {
            desc += "\tNick Name: " + nickName
        }
        if let preferredUsername = self.preferredUsername {
            desc += "\tPreferred Username: " + preferredUsername
        }
        if let profile = self.profile {
            desc += "\tProfile: " + profile.absoluteString
        }
        if let picture = self.picture {
            desc += "\tPicture: " + picture.absoluteString
        }
        if let website = self.website {
            desc += "\tWebsite: " + website.absoluteString
        }
        if let gender = self.gender {
            desc += "\tGender: " + gender
        }
        if let zoneInfo = self.zoneInfo {
            desc += "\tZone Info: " + zoneInfo
        }
        if let locale = self.locale {
            desc += "\tLocale: " + locale
        }
        if let sub = self.sub {
            desc += "\tSub: " + sub
        }
        if let email = self.email {
            desc += "\tEmail: " + email
        }
        
        desc += "\tEmail Verified: " + String(describing: emailVerified)
        
        if let phoneNumber = self.phoneNumber {
            desc += "\tPhone Number: " + phoneNumber
        }
        
        desc += "\tPhone Number Verified: " + String(describing: phoneNumberVerified)
        
        if let birthDate = self.birthDate {
            desc += "\tBirth Date: " + String(describing: birthDate)
        }
        
        if let address = self.address {
            desc += "\n\t" + address.debugDescription
        }
        
        return desc
    }
    
    
    // MARK: NSSecureCoding
    
    /// Boolean value of whether SecureCoding is supported or not
    public class var supportsSecureCoding: Bool {
        return true
    }
    
    
    /// Initializes UserInfo object with NSCoder
    ///
    /// - Parameter aDecoder: NSCoder
    convenience required public init?(coder aDecoder: NSCoder) {
        guard let userInfo = aDecoder.decodeObject(forKey: "userInfo") as? [String: Any] else {
            return nil
        }
        self.init(userInfo)
    }
    
    
    /// Encodes UserInfo object with NSCoder
    ///
    /// - Parameter aCoder: NSCoder
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.userInfo, forKey: "userInfo")
    }
}

extension Dictionary {
    
    /// Extracts String value from Dictionary with given key value
    ///
    /// - Parameter key: String value of key of expected value
    /// - Returns: String value with given key
    func string(_ key: String) -> String? {
        if let dict = self as? [String: Any], let val = dict[key] as? String {
            return val
        }
        return nil
    }
    
    
    /// Extracts Boolean value from Dictionary with given key value
    ///
    /// - Parameter key: String value of key of expected value
    /// - Returns: Boolean value with given key
    func bool(_ key: String) -> Bool {
        if let dict = self as? [String: Any], let val = dict[key] as? Bool {
            return val
        }
        return false
    }
    
    
    /// Extracts URL value from Dictionary with given key value
    ///
    /// - Parameter key: String value of key of expected value
    /// - Returns: URL value with given key
    func url(_ key: String) -> URL? {
        if let dict = self as? [String: Any], let valStr = dict[key] as? String, let val = URL(string: valStr) {
            return val
        }
        return nil
    }
}
