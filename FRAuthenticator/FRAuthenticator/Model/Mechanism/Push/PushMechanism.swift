// 
//  PushMechanism.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore

/// PushMechanism represents PushNotification-based OTP Auth and is responsible for its related operation
public class PushMechanism: Mechanism {
    
    //  MARK: - Properties
    
    /// Authentication URL for Push Auth
    var authEndpoint: URL
    /// Registration URL for Push Auth
    var regEndpoint: URL
    /// messageId for push registration
    var messageId: String
    /// challenge to be signed for push registration
    var challenge: String
    /// load balancer key
    var loadBalancer: String?
    
    /// Update endpoint for Push mechanism
    var updateEndpoint: URL {
        get {
            var components = URLComponents(url: self.regEndpoint, resolvingAgainstBaseURL: false)
            if let queryItems = components?.queryItems {
                components?.queryItems = queryItems.map { item in
                    if item.name == "_action" && item.value == "register" {
                        return URLQueryItem(name: item.name, value: "refresh")
                    }
                    return item
                }
            }
            
            guard let updatedURL = components?.url else {
                fatalError("Failed to construct update URL")
            }

            return updatedURL
        }
    }
    
    /// PushNotification(s) objects associated with current PushMechanism
    public var notifications: [PushNotification] = []
    
    /// An array of all current PushNotification that are pending
    public var pendingNotifications: [PushNotification] {
        get {
            var pendingNotifications: [PushNotification] = []
            for notification in self.notifications {
                if notification.isPending {
                    pendingNotifications.append(notification)
                }
            }
            return pendingNotifications
        }
    }
    
    
    // MARK: - Coding Keys

    /// CodingKeys customize the keys when this object is encoded and decoded
    enum CodingKeys: String, CodingKey {
        case authEndpoint = "authenticationEndpoint"
        case regEndpoint = "registrationEndpoint"
        case messageId
        case challenge
        case loadBalancer
    }
    
    
    //  MARK: - Init    
    
    /// Initializes PushMechanism with given data
    /// - Parameters:
    ///   - issuer: issuer of OATH
    ///   - accountName: accountName of current OATH Mechanism
    ///   - secret: shared secret in string of OATH Mechanism
    ///   - authEndpoint: authentication endpoint of AM for PushMechanism
    ///   - regEndpoint: registration endpoint of AM for PushMechanism
    ///   - messageId: messageId for push registration
    ///   - challenge: challenge to be signed for PushMechanism registration
    ///   - loadBalancer: load balancer key
    ///   - uid: unique identifier of the user associated with this mechanism
    ///   - resourceId: unique identifier of this mechanism on the server
    init(issuer: String, accountName: String, secret: String, authEndpoint: URL, regEndpoint: URL, messageId: String, challenge: String, loadBalancer: String?, uid: String?, resourceId: String?) {
        
        self.authEndpoint = authEndpoint
        self.regEndpoint = regEndpoint
        self.messageId = messageId
        self.challenge = challenge
        self.loadBalancer = loadBalancer
        
        super.init(type: FRAConstants.push, issuer: issuer, accountName: accountName, secret: secret, uid: uid, resourceId: resourceId)
    }
    
    
    /// Initializes PushMechanism with given data
    /// - Parameter mechanismUUID: Mechanism UUID
    /// - Parameter type: type of auth
    /// - Parameter version: version of PushMechanism
    /// - Parameter issuer: issuer of Push Auth
    /// - Parameter secret: shared secret of Push Auth
    /// - Parameter accountName: accountName of Push Auth
    /// - Parameter authURLStr: authentication URL for Push Auth
    /// - Parameter regURLStr: registration URL for Push Auth
    /// - Parameter messageId: messageId of Push mechanism
    /// - Parameter challenge: challenge used for Push
    /// - Parameter loadBalancer: load balancer optional value
    /// - Parameter uid: unique identifier of the user associated with this mechanism
    /// - Parameter resourceId: unique identifier of this mechanism on the server
    /// - Parameter timeAdded: Date timestamp for creation of Mechanism object
    init?(mechanismUUID: String?, type: String?, version: Int?, issuer: String?, secret: String?, accountName: String?, authURLStr: String?, regURLStr: String?, messageId: String?, challenge: String?, loadBalancer: String?, uid: String?, resourceId: String?, timeAdded: Double) {
        
        // Validate URLs
        guard let authURLStr = authURLStr, let authEndpoint = URL(string:authURLStr), let regURLStr = regURLStr, let regEndpoint = URL(string: regURLStr) else {
            return nil
        }
        
        // Validate required params
        guard let messageId = messageId, let challenge = challenge else {
            return nil
        }
        
        self.authEndpoint = authEndpoint
        self.regEndpoint = regEndpoint
        self.messageId = messageId
        self.challenge = challenge
        self.loadBalancer = loadBalancer

        super.init(mechanismUUID: mechanismUUID, type: type, version: version, issuer: issuer, secret: secret, accountName: accountName, uid: uid, resourceId: resourceId, timeAdded: timeAdded)
    }
    
    
    //  MARK: - NSCoder
    
    override public class var supportsSecureCoding: Bool { return true }
    
    
    override public func encode(with coder: NSCoder) {
        coder.encode(self.authEndpoint.absoluteString, forKey: "authEndpoint")
        coder.encode(self.regEndpoint.absoluteString, forKey: "regEndpoint")
        coder.encode(self.messageId, forKey: "messageId")
        coder.encode(self.challenge, forKey: "challenge")
        coder.encode(self.loadBalancer, forKey: "loadBalancer")
        super.encode(with: coder)
    }

    
    public required convenience init?(coder: NSCoder) {

        let mechanismUUID = coder.decodeObject(of: NSString.self, forKey: "mechanismUUID") as String?
        let type = coder.decodeObject(of: NSString.self, forKey: "type") as String?
        let version = coder.decodeInteger(forKey: "version")
        let issuer = coder.decodeObject(of: NSString.self, forKey: "issuer") as String?
        let secret = coder.decodeObject(of: NSString.self, forKey: "secret") as String?
        let accountName = coder.decodeObject(of: NSString.self, forKey: "accountName") as String?
        let authEndpoint = coder.decodeObject(of: NSString.self, forKey: "authEndpoint") as String?
        let regEndpoint = coder.decodeObject(of: NSString.self, forKey: "regEndpoint") as String?
        let messageId = coder.decodeObject(of: NSString.self, forKey: "messageId") as String?
        let challenge = coder.decodeObject(of: NSString.self, forKey: "challenge") as String?
        let loadBalancer = coder.decodeObject(of: NSString.self, forKey: "loadBalancer") as String?
        let uid = coder.decodeObject(of: NSString.self, forKey: "uid") as String?
        let resourceId = coder.decodeObject(of: NSString.self, forKey: "resourceId") as String?
        let timeAdded = coder.decodeDouble(forKey: "timeAdded")

        self.init(mechanismUUID: mechanismUUID, type: type, version: version, issuer: issuer, secret: secret, accountName: accountName, authURLStr: authEndpoint, regURLStr: regEndpoint, messageId: messageId, challenge: challenge, loadBalancer: loadBalancer, uid: uid, resourceId: resourceId, timeAdded: timeAdded)
    }
    
    
    //  MARK: - Codable

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(authEndpoint, forKey: .authEndpoint)
        try container.encode(regEndpoint, forKey: .regEndpoint)
        try container.encode(messageId, forKey: .messageId)
        try container.encode(challenge, forKey: .challenge)
        try container.encode(loadBalancer, forKey: .loadBalancer)
        try super.encode(to: encoder)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        authEndpoint = try container.decode(URL.self, forKey: .authEndpoint)
        regEndpoint = try container.decode(URL.self, forKey: .regEndpoint)
        messageId = try container.decode(String.self, forKey: .messageId)
        challenge = try container.decode(String.self, forKey: .challenge)
        loadBalancer = try container.decode(String.self, forKey: .loadBalancer)
        try super.init(from: decoder)
    }
    

    //  MARK: - Public
    
    /// Serializes `PushMechanism` object into JSON String.
    /// - Returns: JSON String value of `PushMechanism` object
    public func toJson() -> String? {
        if let objData = try? JSONEncoder().encode(self), let serializedStr = String(data: objData, encoding: .utf8) {
            return serializedStr
        }
        else {
            return nil
        }
    }
}

