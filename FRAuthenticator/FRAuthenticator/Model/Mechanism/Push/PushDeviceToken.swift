// 
//  PushDeviceToken.swift
//  FRAuthenticator
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// Represents an APNS device token with its associated ID and last update timestamp.
public class PushDeviceToken: NSObject, NSSecureCoding, Codable {
    
    // MARK: - Properties
    
    /// Token ID of the push device token
    public internal(set) var tokenId: String
    /// Time added for the push device token
    public internal(set) var timeAdded: Date
    
    
    // MARK: - Coding Keys
    
    /// CodingKeys customize the keys when this object is encoded and decoded
    enum CodingKeys: String, CodingKey {
        case tokenId
        case timeAdded
    }
    
    
    // MARK: - Init
    
    /// Prevents init
    private override init() {
        fatalError("Default init of PushDeviceToken class is prohibited.")
    }
    
    /// Initializes PushDeviceToken object with given information
    /// - Parameter tokenId: The ID of the device token (cannot be null or empty).
    /// - Parameter timeAdded: The date the device token was received.
    init(tokenId: String, timeAdded: Date = Date()) {
        self.tokenId = tokenId
        self.timeAdded = timeAdded
    }
    
    // MARK: - NSCoder
    
    public class var supportsSecureCoding: Bool { return true }
    
    public func encode(with coder: NSCoder) {
        coder.encode(self.tokenId, forKey: "tokenId")
        coder.encode(self.timeAdded.timeIntervalSince1970, forKey: "timeAdded")
    }
    
    public required convenience init?(coder: NSCoder) {
        let tokenId = coder.decodeObject(of: NSString.self, forKey: "tokenId") as String?
        let timeAdded = coder.decodeDouble(forKey: "timeAdded")
        
        guard let tokenId = tokenId else {
            return nil
        }
        
        self.init(tokenId: tokenId, timeAdded: Date(timeIntervalSince1970: timeAdded))
    }
    
    // MARK: - Codable
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.tokenId, forKey: .tokenId)
        try container.encode(self.timeAdded.timeIntervalSince1970, forKey: .timeAdded)
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let tokenId = try values.decode(String.self, forKey: .tokenId)
        let milliseconds = try values.decode(Double.self, forKey: .timeAdded)
        let timeAdded = Date(timeIntervalSince1970: milliseconds)
        
        self.init(tokenId: tokenId, timeAdded: timeAdded)
    }
    
    // MARK: - Public
    
    /// Serializes `PushDeviceToken` object into JSON String.
    /// - Returns: JSON String value of `PushDeviceToken` object
    public func toJson() -> String? {
        if let objData = try? JSONEncoder().encode(self), let serializedStr = String(data: objData, encoding: .utf8) {
            return serializedStr
        } else {
            return nil
        }
    }
}
