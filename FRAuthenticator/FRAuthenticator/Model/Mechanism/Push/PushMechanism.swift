// 
//  PushMechanism.swift
//  FRAuthenticator
//
//  Copyright (c) 2020-2023 ForgeRock. All rights reserved.
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
    init(issuer: String, accountName: String, secret: String, authEndpoint: URL, regEndpoint: URL, messageId: String, challenge: String, loadBalancer: String?) {
        
        self.authEndpoint = authEndpoint
        self.regEndpoint = regEndpoint
        self.messageId = messageId
        self.challenge = challenge
        self.loadBalancer = loadBalancer
        
        super.init(type: FRAConstants.push, issuer: issuer, accountName: accountName, secret: secret)
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
    /// - Parameter timeAdded: Date timestamp for creation of Mechanism object 
    init?(mechanismUUID: String?, type: String?, version: Int?, issuer: String?, secret: String?, accountName: String?, authURLStr: String?, regURLStr: String?, messageId: String?, challenge: String?, loadBalancer: String?, timeAdded: Double) {
        
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

        super.init(mechanismUUID: mechanismUUID, type: type, version: version, issuer: issuer, secret: secret, accountName: accountName, timeAdded: timeAdded)
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
        let timeAdded = coder.decodeDouble(forKey: "timeAdded")

        self.init(mechanismUUID: mechanismUUID, type: type, version: version, issuer: issuer, secret: secret, accountName: accountName, authURLStr: authEndpoint, regURLStr: regEndpoint, messageId: messageId, challenge: challenge, loadBalancer: loadBalancer, timeAdded: timeAdded)
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
    
    
    //  MARK: - Register
    
    /// Registers current PushMechanism object with designated AM instance using information given in QR code
    /// - Parameters:
    ///   - onSuccess: Success callback to notify that registration is completed and successful
    ///   - onFailure: Error callback to notify an error occurred during the push registration
    func register(onSuccess: @escaping SuccessCallback, onFailure: @escaping ErrorCallback) {
        do {
            let request = try buildPushRegistrationRequest()
            RestClient.shared.invoke(request: request, action: Action(type: .PUSH_REGISTER)) { (result) in
                switch result {
                case .success(let result, let httpResponse):
                    FRALog.v("Push registration request was successful: \n\nResponse:\(result)\n\nHTTPResponse:\(String(describing: httpResponse))")
                    onSuccess()
                    break
                case .failure(let error):
                    FRALog.e("Push registration request failed with following error: \(error.localizedDescription)")
                    onFailure(error)
                    break
                }
            }
        }
        catch {
            FRALog.w("Failed to prepare and make request for Push Registration with following error: \(error.localizedDescription)")
            onFailure(error)
        }
    }
    
        
    //  MARK: - Request Build
    
    /// Builds Request object for Push Registration
    /// - Throws: CryptoError, PushNotificationError,
    /// - Returns: Request object for Push Registration request
    func buildPushRegistrationRequest() throws -> Request {
        
        guard let deviceToken = FRAPushHandler.shared.deviceToken else {
            FRALog.e("Missing DeviceToken")
            throw PushNotificationError.missingDeviceToken
        }
        
        let challengeResponse = try Crypto.generatePushChallengeResponse(challenge: self.challenge, secret: self.secret)
        FRALog.v("Challenge response generated: \(challenge)")
        
        var payload: [String: CodableValue] = [:]
        payload[FRAConstants.response] = CodableValue(challengeResponse)
        payload[FRAConstants.mechanismUid] = CodableValue(self.mechanismUUID)
        payload[FRAConstants.deviceId] = CodableValue(deviceToken)
        payload[FRAConstants.deviceType] = CodableValue(FRAConstants.ios)
        payload[FRAConstants.communicationType] = CodableValue(FRAConstants.apns)
        FRALog.v("Push registration JWT payload prepared: \(payload)")
                
        let jwt = try FRCompactJWT(algorithm: .hs256, secret: self.secret, payload: payload).sign()
        FRALog.v("JWT generated and signed: \(jwt)")
        
        let requestPayload: [String: String] = [FRAConstants.messageId: self.messageId, FRAConstants.jwt: jwt]
        
        var headers: [String: String] = [:]
        headers["Set-Cookie"] = self.loadBalancer
        
        //  AM 6.5.2 - 7.0.0
        //
        //  Endpoint: /openam/json/push/sns/message?_action=register
        //  API Version: resource=1.0, protocol=1.0
        headers[FRAConstants.acceptAPIVersion] = FRAConstants.apiResource10 + ", " + FRAConstants.apiProtocol10
        
        let request = Request(url: self.regEndpoint.absoluteString, method: .POST, headers: headers, bodyParams: requestPayload, requestType: .json, responseType: .json)
        
        return request
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

