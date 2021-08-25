// 
//  Notification.swift
//  FRAuthenticator
//
//  Copyright (c) 2020-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore

/// Notification class represents Push Notification message delivered to SDK (application) for registered PushMechanism
public class PushNotification: NSObject, NSSecureCoding, Codable {
    
    //  MARK: - Private Properties
    
    /// Message Identifier for Push
    var messageId: String
    /// MechanismUUID of PushMechanism that Notification belongs to
    public var mechanismUUID: String
    /// Load balance key for Push
    var loadBalanceKey: String?
    /// Time to live for push
    var ttl: Double
    /// Time added for push
    public var timeAdded: Date
    /// Challenge for push
    var challenge: String
    /// Boolean indicator of whether push notification is still pending or not
    var pending: Bool = true
    /// Boolean indicator of whether push notification is approved or not
    var approved: Bool = false
    
    
    //  MARK: - Public Properties
    
    /// Unique identifier for Notification object associated with PushMechanism
    public var identifier: String {
        get {
            return self.mechanismUUID + "-" + "\(self.timeAdded.millisecondsSince1970)"
        }
    }
    
    /// Boolean property indicating whether or not current Notification is still pending for approval
    public var isPending: Bool {
        get {
            return self.pending && !self.isExpired
        }
    }
        
    /// Boolean property indicating whether or not current Notification is expired
    public var isExpired: Bool {
        get {
            return pending && ((Date().timeIntervalSince1970 - (self.timeAdded.timeIntervalSince1970 + self.ttl)) > 0)
        }
    }
        
    /// Boolean property indicating whether or not current Notification is approved
    public var isApproved: Bool {
        get {
            return !self.pending && self.approved
        }
    }
    
    /// Boolean property indicating whether or not current Notification is denied
    public var isDenied: Bool {
        get {
            return !self.pending && !self.approved
        }
    }
    
    
    //  MARK: - Init
    
    /// Initializes Notification object with given Message Identifier, and Notification Payload from APNS
    /// - Parameter messageId: message identifier given from APNS payload
    /// - Parameter payload: 'data' attribute from APNS payload for notification
    init(messageId: String, payload: [String: Any]) throws {
        
        guard let challenge = payload["c"] as? String else {
            throw NotificationError.invalidPayload("missing challenge")
        }
        guard let loadBalanceKey = payload["l"] as? String else {
            throw NotificationError.invalidPayload("missing load balance key")
        }
        guard let ttl = payload["t"] as? String, let ttlDouble = Double(ttl) else {
            throw NotificationError.invalidPayload("missing or invalid ttl")
        }
        guard let mechanismUUID = payload["u"] as? String else {
            throw NotificationError.invalidPayload("missing Mechanism UUID")
        }
        
        self.messageId = messageId
        
        self.challenge = challenge.urlSafeDecoding()
        self.loadBalanceKey = loadBalanceKey.base64Decoded()
        self.ttl = ttlDouble
        self.mechanismUUID = mechanismUUID
        
        self.timeAdded = Date()
    }
    
    
    /// Initializes Notification with given data
    /// - Parameter messageId: message identifier from APNS payload
    /// - Parameter challenge: challenge from APNS payload
    /// - Parameter loadBalanceKey: load balance key from APNS payload
    /// - Parameter ttl: time-to-live value from APNS payload
    /// - Parameter mechanismUUID: Mechanism UUID from APNS payload
    /// - Parameter timeAdded: Date when the notification is delivered
    /// - Parameter pending: Boolean indicator of whether or not current PushNotification is still in pending
    /// - Parameter approved: Boolean indicator of whether or not current PushNotification is already approved
    init?(messageId: String?, challenge: String?, loadBalanceKey: String?, ttl: Double, mechanismUUID: String?, timeAdded: Double, pending: Bool, approved: Bool) {
        
        guard let messageId = messageId, let challenge = challenge, let mechanismUUID = mechanismUUID else {
            return nil
        }
        
        self.messageId = messageId
        self.challenge = challenge
        self.loadBalanceKey = loadBalanceKey
        self.ttl = ttl
        self.timeAdded = Date(timeIntervalSince1970: timeAdded)
        self.mechanismUUID = mechanismUUID
        self.pending = pending
        self.approved = approved
    }
    
    
    //  MARK: - NSCoder
    
    public class var supportsSecureCoding: Bool { return true }
    
    
    public func encode(with coder: NSCoder) {
        coder.encode(self.messageId, forKey: "messageId")
        coder.encode(self.challenge, forKey: "challenge")
        coder.encode(self.loadBalanceKey, forKey: "loadBalanceKey")
        coder.encode(self.ttl, forKey: "ttl")
        coder.encode(self.mechanismUUID, forKey: "mechanismUUID")
        coder.encode(self.timeAdded.timeIntervalSince1970, forKey: "timeAdded")
        coder.encode(self.pending, forKey: "pending")
        coder.encode(self.approved, forKey: "approved")
    }
    
    
    public required convenience init?(coder: NSCoder) {
        
        let messageId = coder.decodeObject(of: NSString.self, forKey: "messageId") as String?
        let challenge = coder.decodeObject(of: NSString.self, forKey: "challenge") as String?
        let loadBalanceKey = coder.decodeObject(of: NSString.self, forKey: "loadBalanceKey") as String?
        let mechanismUUID = coder.decodeObject(of: NSString.self, forKey: "mechanismUUID") as String?
        let ttl = coder.decodeDouble(forKey: "ttl") as Double
        let timeAdded = coder.decodeDouble(forKey: "timeAdded") as Double
        let pending = coder.decodeBool(forKey: "pending") as Bool
        let approved = coder.decodeBool(forKey: "approved") as Bool
        
        self.init(messageId: messageId, challenge: challenge, loadBalanceKey: loadBalanceKey, ttl: ttl, mechanismUUID: mechanismUUID, timeAdded: timeAdded, pending: pending, approved: approved)
    }
    
    
    //  MARK: - Accept / Deny
    
    /// Accepts PushNotification authentication
    /// - Parameters:
    ///   - onSuccess: successful completion callback
    ///   - onError: failure error callback
    public func accept(onSuccess: @escaping SuccessCallback, onError: @escaping ErrorCallback) {
        self.handleNotification(result: true, onSuccess: onSuccess, onError: onError)
    }
    
    
    /// Denies PushNotification authentication
    /// - Parameters:
    ///   - onSuccess: successful completion callback
    ///   - onError: failure error callback
    public func deny(onSuccess: @escaping SuccessCallback, onError: @escaping ErrorCallback) {
        self.handleNotification(result: false, onSuccess: onSuccess, onError: onError)
    }
    
    
    //  MARK: - Accept / Deny - Private
    
    /// Handles PushNotification authentication process with given decision
    /// - Parameters:
    ///   - result: Boolean indicator whether or not PushNotification authentication is approved or denied
    ///   - onSuccess: successful completion callback
    ///   - onError: failure error callback
    func handleNotification(result: Bool, onSuccess: @escaping SuccessCallback, onError: @escaping ErrorCallback) {
        
        if !self.isPending {
            onError(PushNotificationError.notificationInvalidStatus)
            return
        }
        
        self.approved = result
        self.pending = false
        
        if let mechanism = FRAClient.storage.getMechanismForUUID(uuid: self.mechanismUUID) as? PushMechanism {
            if FRAClient.storage.setNotification(notification: self) {
                FRALog.v("New PushNotification object is stored into StorageClient")
            }
            else {
                FRALog.e("Failed to save PushNotification object into StorageClient")
            }
            
            do {
                let request = try buildPushAuthenticationRequest(result: result, mechanism: mechanism)
                RestClient.shared.invoke(request: request) { (result) in
                          switch result {
                          case .success(_, _):
                          Log.i("PushNotification authentication was successful")
                          onSuccess()
                              break
                          case .failure(let error):
                            self.approved = false
                            self.pending = true
                            Log.i("PushNotification authentication failed with following error: \(error.localizedDescription)")
                            onError(error)
                                break
                          }
                      }
            }
            catch {
                onError(error)
            }
        }
        else {
            FRALog.e("Failed to retrieve PushMechanism object based on MechanismUUID in Push Notification's payload: \(self.mechanismUUID)")
            onError(PushNotificationError.storageError("Failed to retrieve PushMechanism object with given UUID: \(self.mechanismUUID)"))
        }
    }
    
    
    func buildPushAuthenticationRequest(result: Bool, mechanism: PushMechanism) throws -> Request {
        var payload: [String: CodableValue] = [:]
        payload[FRAConstants.response] = try CodableValue(Crypto.generatePushChallengeResponse(challenge: self.challenge, secret: mechanism.secret))
        if !result {
            payload["deny"] = CodableValue(true)
        }
        FRALog.v("Push authentication JWT payload prepared: \(payload)")
        
        let jwt = try FRCompactJWT(algorithm: .hs256, secret: mechanism.secret, payload: payload).sign()
        FRALog.v("JWT generated and signed: \(jwt)")
        
        let requestPayload: [String: String] = [FRAConstants.messageId: self.messageId, FRAConstants.jwt: jwt]

        var headers: [String: String] = [:]
        headers["Set-Cookie"] = self.loadBalanceKey
        
        //  AM 6.5.2 - 7.0.0
        //
        //  Endpoint: /openam/json/push/sns/message?_action=authenticate
        //  API Version: resource=1.0, protocol=1.0
        headers[FRAConstants.acceptAPIVersion] = FRAConstants.apiResource10 + ", " + FRAConstants.apiProtocol10
        
        let request = Request(url: mechanism.authEndpoint.absoluteString, method: .POST, headers: headers, bodyParams: requestPayload, requestType: .json, responseType: .json)
        
        return request
    }
    
    
    //  MARK: - Public
    
    /// Serializes `PushNotification` object into JSON String. Sensitive information are not exposed.
    /// - Returns: JSON String value of `PushNotification` object
    public func toJson() -> String? {
        return """
           {"id":"\(self.identifier)",
           "mechanismUID":"\(self.mechanismUUID)",
           "messageId":"\(self.messageId)",
           "challenge":"REMOVED",
           "amlbCookie":"REMOVED",
           "timeAdded":\(self.timeAdded.millisecondsSince1970),
           "timeExpired":\(self.timeAdded.millisecondsSince1970 + Int64(self.ttl * 1000)),
           "ttl":\(Int(self.ttl)),
           "approved":\(self.approved),
           "pending":\(self.pending)}
           """
    }
}
