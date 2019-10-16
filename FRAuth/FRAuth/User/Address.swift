//
//  Address.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation


/**
 Address class is a representation of a user's Address data according to OAuth2 and OIDC spec. Address is retrieved using /userinfo endpoint and is part of UserInfo object.
 */
@objc(FRUserInfoAddress)
public class Address: NSObject, NSSecureCoding {
    
    //  MARK: - Property
    
    /// Formatted address
    @objc public var formatted: String?
    /// Street address
    @objc public var streetAddress: String?
    /// Locality
    @objc public var locality: String?
    /// Region
    @objc public var region: String?
    /// Postal code
    @objc public var postalCode: String?
    /// Country
    @objc public var country: String?
    /// Raw JSON response of Address information
    @objc public var address: [String: Any]
    
    
    //  MARK: - Init
    
    /// Construct Address object with given raw JSON response from /userinfo endpoint
    ///
    /// - Parameter address: Raw JSON response from /userinfo
    init(_ address: [String: Any]) {
        
        self.address = address
        let addressDictionary = self.address as Dictionary
        
        self.formatted = addressDictionary.string(OIDC.formatted)
        self.streetAddress = addressDictionary.string(OIDC.streetAddress)
        self.locality = addressDictionary.string(OIDC.locality)
        self.region = addressDictionary.string(OIDC.region)
        self.postalCode = addressDictionary.string(OIDC.postalCode)
        self.country = addressDictionary.string(OIDC.country)
        
        super.init()
    }
    
    
    //  MARK: - Debug
    
    /// Prints debug description of Address object
    override public var debugDescription: String {
        var desc =  "\(String(describing: self))\n\t\t"
        
        if let formatted = self.formatted {
            desc += "\tFormatted: " + formatted
        }
        if let streetAddress = self.streetAddress {
            desc += "\tStreet Address: " + streetAddress
        }
        if let locality = self.locality {
            desc += "\tLocality: " + locality
        }
        if let region = self.region {
            desc += "\tRegion: " + region
        }
        if let postalCode = self.postalCode {
            desc += "\tPostal Code: " + postalCode
        }
        if let country = self.country {
            desc += "\tCountry: " + country
        }
        
        return desc
    }
    
    
    // MARK: NSSecureCoding
    
    /// Boolean value of whether SecureCoding is supported or not
    public class var supportsSecureCoding: Bool {
        return true
    }
    
    
    /// Initializes Address object with NSCoder
    ///
    /// - Parameter aDecoder: NSCoder
    convenience required public init?(coder aDecoder: NSCoder) {
        if let address = aDecoder.decodeObject(forKey: "address") as? [String: Any] {
            self.init(address)
        }
        return nil
    }
    
    
    /// Encodes Address object with NSCoder
    ///
    /// - Parameter aCoder: NSCoder
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.address, forKey: "address")
    }
}
