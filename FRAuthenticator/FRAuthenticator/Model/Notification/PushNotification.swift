// 
//  Notification.swift
//  FRAuthenticator
//
//  Copyright (c) 2020-2023 ForgeRock. All rights reserved.
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
    public internal(set) var messageId: String
    /// MechanismUUID of PushMechanism that Notification belongs to
    public internal(set) var mechanismUUID: String
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
    /// The JSON String containing the custom attributes added to this notification */
    public internal(set) var customPayload: String?
    /// Message that was received with this notification */
    public internal(set) var message: String?
    /// The type of push notification **/
    public internal(set) var pushType: PushType
    /// The numbers used in the push challenge **/
    public internal(set) var numbersChallenge: String?
    ///The context information to this notification. */
    public internal(set) var contextInfo: String?
    
    
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
            return self.pending
        }
    }
        
    /// Boolean property indicating whether or not current Notification is expired
    public var isExpired: Bool {
        get {
            return ((Date().timeIntervalSince1970 - (self.timeAdded.timeIntervalSince1970 + self.ttl)) > 0)
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
    
    ///numbers used for push challenge as int array
    public var numbersChallengeArray: [Int]? {
        guard numbersChallenge != nil else {
            return nil
        }
        return numbersChallenge!.components(separatedBy: ",").compactMap { Int($0) }
    }
    
    
    // MARK: - Coding Keys
    
    /// CodingKeys customize the keys when this object is encoded and decoded
    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case messageId
        case mechanismUUID = "mechanismUID"
        case loadBalanceKey = "amlbCookie"
        case ttl
        case timeAdded
        case timeExpired
        case challenge
        case pending
        case approved
        case customPayload
        case message
        case pushType
        case numbersChallenge
        case contextInfo
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
        
        if let intervalString = payload["i"] as? String, let interval = Int64(intervalString) {
            self.timeAdded = Date(milliseconds: interval)
        } else {
            self.timeAdded = Date()
        }
        
        self.customPayload = payload["p"] as? String
        self.message = payload["m"] as? String
        if let pushTypeString = payload["k"] as? String {
            self.pushType = PushType(rawValue: pushTypeString) ?? PushType.default
        } else {
            self.pushType = PushType.default
        }
        if self.pushType == .challenge {
            self.numbersChallenge = payload["n"] as? String
        }
        self.contextInfo = payload["x"] as? String
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
    /// - Parameter customPayload: JSON String containing the custom attributes
    /// - Parameter message: message from  from APNS payload
    /// - Parameter pushType: the type of push notification
    /// - Parameter numbersChallenge: numbers used in the push challenge
    /// - Parameter contextInfo: contextual information, such as location
    init?(messageId: String?, challenge: String?, loadBalanceKey: String?, ttl: Double, mechanismUUID: String?, timeAdded: Double, pending: Bool, approved: Bool, customPayload: String?, message: String?, pushType: PushType, numbersChallenge: String?, contextInfo: String?) {
        
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
        self.customPayload = customPayload
        self.message = message
        self.pushType = pushType
        self.numbersChallenge = numbersChallenge
        self.contextInfo = contextInfo
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
        coder.encode(self.customPayload, forKey: "customPayload")
        coder.encode(self.message, forKey: "message")
        coder.encode(self.pushType.rawValue, forKey: "pushType")
        coder.encode(self.numbersChallenge, forKey: "numbersChallenge")
        coder.encode(self.contextInfo, forKey: "contextInfo")
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
        let customPayload = coder.decodeObject(of: NSString.self, forKey: "customPayload") as String?
        let message = coder.decodeObject(of: NSString.self, forKey: "message") as String?
        var pushType = PushType.default
        if let pushTypeString = coder.decodeObject(of: NSString.self, forKey: "pushType") as? String {
            pushType = PushType(rawValue: pushTypeString) ?? PushType.default
        }
        let numbersChallenge = coder.decodeObject(of: NSString.self, forKey: "numbersChallenge") as String?
        let contextInfo = coder.decodeObject(of: NSString.self, forKey: "contextInfo") as String?
        
        self.init(messageId: messageId, challenge: challenge, loadBalanceKey: loadBalanceKey, ttl: ttl, mechanismUUID: mechanismUUID, timeAdded: timeAdded, pending: pending, approved: approved, customPayload: customPayload, message: message, pushType: pushType, numbersChallenge: numbersChallenge, contextInfo: contextInfo)
    }
    
    
    //  MARK: - Codable
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.messageId, forKey: .messageId)
        try container.encode(self.challenge, forKey: .challenge)
        try container.encode(self.loadBalanceKey, forKey: .loadBalanceKey)
        try container.encode(self.ttl, forKey: .ttl)
        try container.encode(self.mechanismUUID, forKey: .mechanismUUID)
        try container.encode(self.timeAdded.millisecondsSince1970, forKey: .timeAdded)
        try container.encode(self.timeAdded.millisecondsSince1970 + Int64(self.ttl * 1000), forKey: .timeExpired)
        try container.encode(self.pending, forKey: .pending)
        try container.encode(self.approved, forKey: .approved)
        try container.encode(self.identifier, forKey: .identifier)
        try container.encode(self.customPayload, forKey: .customPayload)
        try container.encode(self.message, forKey: .message)
        try container.encode(self.pushType, forKey: .pushType)
        try container.encode(self.numbersChallenge, forKey: .numbersChallenge)
        try container.encode(self.contextInfo, forKey: .contextInfo)
    }

    
    public required convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let messageId = try values.decode(String.self, forKey: .messageId)
        let challenge = try values.decode(String.self, forKey: .challenge)
        let loadBalanceKey = try values.decode(String.self, forKey: .loadBalanceKey)
        let mechanismUUID = try values.decode(String.self, forKey: .mechanismUUID)
        let ttl = try values.decode(Double.self, forKey: .ttl)
        let pending = try values.decode(Bool.self, forKey: .pending)
        let approved = try values.decode(Bool.self, forKey: .approved)
        let milliseconds = try values.decode(Double.self, forKey: .timeAdded)
        let timeAdded = milliseconds / 1000
        let customPayload = try? values.decode(String.self, forKey: .customPayload)
        let message = try? values.decode(String.self, forKey: .message)
        let pushType = (try? values.decode(PushType.self, forKey: .pushType)) ?? .default
        let numbersChallenge = try? values.decode(String.self, forKey: .numbersChallenge)
        let contextInfo = try? values.decode(String.self, forKey: .contextInfo)

        self.init(messageId: messageId, challenge: challenge, loadBalanceKey: loadBalanceKey, ttl: ttl, mechanismUUID: mechanismUUID, timeAdded: timeAdded, pending: pending, approved: approved, customPayload: customPayload, message: message, pushType: pushType, numbersChallenge: numbersChallenge, contextInfo: contextInfo)!
    }
    
    
    //  MARK: - Accept / Deny
    
    /// Accepts PushNotification authentication
    /// - Parameters:
    ///   - onSuccess: successful completion callback
    ///   - onError: failure error callback
    public func accept(onSuccess: @escaping SuccessCallback, onError: @escaping ErrorCallback) {
        if self.pushType == .default {
             self.handleNotification(approved: true, onSuccess: onSuccess, onError: onError)
         } else {
             onError(MechanismError.invalidInformation("Error processing the Push  Authentication request. This method cannot be used to process notification of type: \(self.pushType)"))
         }
     }
     
     
     /// Accepts the push notification request with the challenge response. Use this method to handle
     ///  notification of type PushType.challenge
     /// - Parameters:
     ///   - challengeResponse: the response for the Push Challenge
     ///   - onSuccess: successful completion callback
     ///   - onError: failure error callback
     public func accept(challengeResponse: String, onSuccess: @escaping SuccessCallback, onError: @escaping ErrorCallback) {
         if self.pushType == .challenge {
             self.handleNotification(challengeResponse: challengeResponse, approved: true, onSuccess: onSuccess, onError: onError)
         } else {
             onError(MechanismError.invalidInformation("Error processing the Push  Authentication request. This method cannot be used to process notification of type: \(self.pushType)"))
         }
    }
    
    
    /// Accepts the push notification request with the Biometric Authentication. Use this method to handle
    /// notification of type PushType.biometric
    /// - Parameters:
    ///   - title: the title to be displayed on the prompt.
    ///   - allowDeviceCredentials:  if true, accepts device PIN, pattern, or password to process notification.
    ///   - onSuccess: successful completion callback
    ///   - onError: failure error callback
    public func accept(title: String, allowDeviceCredentials: Bool, onSuccess: @escaping SuccessCallback, onError: @escaping ErrorCallback) {
        if self.pushType == .biometric {
            BiometricAuthentication.authenticate(title: title, allowDeviceCredentials: allowDeviceCredentials) {
                self.handleNotification(approved: true, onSuccess: onSuccess, onError: onError)
            } onError: { error in
                onError(MechanismError.invalidInformation(error.localizedDescription))
            }
        } else {
            onError(MechanismError.invalidInformation("Error processing the Push  Authentication request. This method cannot be used to process notification of type: \(self.pushType)"))
        }
    }
    
    
    /// Denies PushNotification authentication
    /// - Parameters:
    ///   - onSuccess: successful completion callback
    ///   - onError: failure error callback
    public func deny(onSuccess: @escaping SuccessCallback, onError: @escaping ErrorCallback) {
        self.handleNotification(approved: false, onSuccess: onSuccess, onError: onError)
    }
    
    
    //  MARK: - Accept / Deny - Private
    
    /// Handles PushNotification authentication process with given decision
    /// - Parameters:
    ///   - challengeResponse: the response for the Push Challenge
    ///   - approved: Boolean indicator whether or not PushNotification authentication is approved or denied
    ///   - onSuccess: successful completion callback
    ///   - onError: failure error callback
    func handleNotification(challengeResponse: String? = nil, approved: Bool, onSuccess: @escaping SuccessCallback, onError: @escaping ErrorCallback) {
        
        if !self.isPending {
            onError(PushNotificationError.notificationInvalidStatus)
            return
        }
        
        if let mechanism = FRAClient.storage.getMechanismForUUID(uuid: self.mechanismUUID) as? PushMechanism {
            
            if let account = FRAClient.storage.getAccount(accountIdentifier: mechanism.accountIdentifier), let policyName = account.lockingPolicy, account.lock {
                FRALog.e("Unable to process the Push Authentication request: Account is locked.")
                onError(AccountError.accountLocked(policyName))
                return
            }
            
            do {
                let request = try buildPushAuthenticationRequest(challengeResponse: challengeResponse, approved: approved, mechanism: mechanism)
                RestClient.shared.invoke(request: request, action: Action(type: .PUSH_AUTHENTICATE)) { (result) in
                    switch result {
                    case .success(_, _):
                        self.approved = approved
                        self.pending = false
                        Log.i("PushNotification authentication was successful")
                        if FRAClient.storage.setNotification(notification: self) {
                            FRALog.v("New PushNotification object is stored into StorageClient")
                        }
                        else {
                            FRALog.e("Failed to save PushNotification object into StorageClient")
                        }
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
    
    
    func buildPushAuthenticationRequest(challengeResponse: String? = nil, approved: Bool, mechanism: PushMechanism) throws -> Request {
        var payload: [String: CodableValue] = [:]
        payload[FRAConstants.response] = try CodableValue(Crypto.generatePushChallengeResponse(challenge: self.challenge, secret: mechanism.secret))
        if !approved {
            payload["deny"] = CodableValue(true)
        }
        
        if self.pushType == .challenge {
            payload["challengeResponse"] = CodableValue(challengeResponse)
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
    
    /// Serializes `PushNotification` object into JSON String.
    /// - Returns: JSON String value of `PushNotification` object
    public func toJson() -> String? {
        if let objData = try? JSONEncoder().encode(self), let serializedStr = String(data: objData, encoding: .utf8) {
            return serializedStr
        }
        else {
            return nil
        }
    }
}
                  
public enum PushType: String, Codable {
    case `default`
    case challenge
    case biometric
}
