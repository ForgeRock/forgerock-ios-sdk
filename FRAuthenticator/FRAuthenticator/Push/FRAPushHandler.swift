// 
//  FRAPushHandler.swift
//  FRAuthenticator
//
//  Copyright (c) 2020-2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import UIKit
import FRCore

/// FRAPushHandler is mainly responsible to handle PushNotification activities in application layer and handling incoming Device Token, and Notification from the application.
public class FRAPushHandler: NSObject {
    
    //  MARK: - Properties
    
    /// shared instance of FRAPushHandler
    public static var shared: FRAPushHandler = FRAPushHandler()
    
    /// PushDeviceTokenManager instance
    private var pushDeviceTokenManager: PushDeviceTokenManager = PushDeviceTokenManager()
    
    
    //  MARK: - Init
    
    /// Prevents init
    private override init() { }
    
    
    //  MARK: - AppDelegate methods
    
    /// Notifies FRAuthenticator SDK for successful Device Token registration; Device Token will be used for PushMechanism registration with AM. If a new Device Token is received, it will store locally and update the Device Token on AM.
    /// - Parameters:
    ///   - application: The app object that initiated the remote-notification registration process.
    ///   - deviceToken: Device Token received from AppDelegate of the application
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        FRALog.i("Received DeviceToken data (\(deviceToken)")
        if pushDeviceTokenManager.deviceToken != deviceTokenString {
            self.updateDeviceToken(deviceToken: deviceTokenString, onSuccess: {
                FRALog.i("DeviceToken is updated on the server successfully")
            }) { (error) in
                FRALog.e("Failed to update DeviceToken with following error: \(error.localizedDescription)")
            }
            FRALog.i("Parsed and stored DeviceToken (\(deviceTokenString)")
        } else {
            FRALog.i("DeviceToken (\(deviceTokenString) parsed but not stored; identical device token.")
        }
    }

    
    /// Notifies FRAuthenticator SDK for failure of Device Token registration; this nullifies existing Device Token
    /// - Parameters:
    ///   - application: The app object that initiated the remote-notification registration process.
    ///   - error: An error captured for device token registration
    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        FRALog.e("Received an error for registration of Device Token: \(error.localizedDescription)")
        self.clearDeviceToken()
    }
    
    
    /// Notifies FRAuthenticator SDK for the recipient of Notification for the current application; FRAuthenticator SDK parses received Notification into PushNotification object for application to accept or deny push authentication request if the notification was from AM Push Authentication.
    /// - Parameters:
    ///   - application: The app object that received the remote-notification.
    ///   - userInfo: Payload of remote-notification
    /// - Returns: PushNotification object if the remote-notification is format of AM's Push Authentication; otherwise returns nil
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) -> PushNotification? {
        
        guard let aps = userInfo["aps"] as? [String: Any], let jwt = aps["data"] as? String, let messageId = aps["messageId"] as? String else {
            FRALog.i("Remote-notification is received; however, not a valid format for FRAuthenticator SDK. Ignoring the notification.")
            return nil
        }
        
        FRALog.v("Received valid format of remote-notification for AM Push Authentication; starts parsing it into PushNotification object")
        do {
            // Check if notification with given messageId already exists
            if let notification = FRAClient.storage.getNotificationByMessageId(messageId: messageId) {
                FRALog.v("Received remote-notification with messageId: \(messageId) already exists in StorageClient; returning the existing PushNotification object")
                return notification
            } else {
                // Extract JWT payload
                FRALog.v("Starts extracting JWT payload: \(jwt)")
                let jwtPayload = try FRCompactJWT.extractPayload(jwt: jwt)
                FRALog.v("JWT payload is extracted: \(jwtPayload)")
                
                // Construct and save Notification object
                FRALog.v("PushNotification object created - messageId:\(messageId), payload: \(jwtPayload)")
                let notification = try PushNotification(messageId: messageId, payload: jwtPayload)
                
                if let mechanism = FRAClient.storage.getMechanismForUUID(uuid: notification.mechanismUUID) {
                    
                    // Check if the push mechanism has the user id information, otherwise set it from the notification
                    if let userId = jwtPayload["d"] as? String, mechanism.uid == nil {
                        mechanism.uid = userId
                        if !FRAClient.storage.setMechanism(mechanism: mechanism) {
                            FRALog.w("Failed to update PushMechanism object in StorageClient")
                        }
                    }
                    
                    if try FRCompactJWT.verify(jwt: jwt, secret: mechanism.secret) == false {
                        FRALog.e("Failed to verify given JWT in remote-notification payload; returning nil")
                        return nil
                    }
                    FRALog.v("Verification of JWT in remote-notification payload with PushMechanism's secret")
                }
                else {
                    FRALog.e("Failed to retrieve PushMechanism object from StorageClient; returning null")
                    return nil
                }
                
                if FRAClient.storage.setNotification(notification: notification) {
                    FRALog.v("PushNotification object is created and saved into StorageClient")
                }
                else {
                    FRALog.w("PushNotification object failed to be stored into StorageClient")
                    return nil
                }
                
                return notification
            }
        }
        catch {
            FRALog.e("An error occurred during handling incoming PushNotification: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    //  MARK: - Hanlde Notifications
    
    /// Handles PushNotification authentication process with given decision
    /// - Parameters:
    ///   - challengeResponse: the response for the Push Challenge
    ///   - approved: Boolean indicator whether or not PushNotification authentication is approved or denied
    ///   - onSuccess: successful completion callback
    ///   - onError: failure error callback
    func handleNotification(notification: PushNotification, challengeResponse: String? = nil, approved: Bool, onSuccess: @escaping SuccessCallback, onError: @escaping ErrorCallback) {
        
        if !notification.isPending {
            onError(PushNotificationError.notificationInvalidStatus)
            return
        }
        
        if let mechanism = FRAClient.storage.getMechanismForUUID(uuid: notification.mechanismUUID) as? PushMechanism {
            
            if let account = FRAClient.storage.getAccount(accountIdentifier: mechanism.accountIdentifier), let policyName = account.lockingPolicy, account.lock {
                FRALog.e("Unable to process the Push Authentication request: Account is locked.")
                onError(AccountError.accountLocked(policyName))
                return
            }
            
            do {
                let request = try buildPushAuthenticationRequest(notification: notification, challengeResponse: challengeResponse, approved: approved, mechanism: mechanism)
                RestClient.shared.invoke(request: request, action: Action(type: .PUSH_AUTHENTICATE)) { (result) in
                    switch result {
                    case .success(_, _):
                        notification.approved = approved
                        notification.pending = false
                        FRALog.i("PushNotification authentication was successful")
                        if FRAClient.storage.setNotification(notification: notification) {
                            FRALog.v("New PushNotification object is stored into StorageClient")
                        }
                        else {
                            FRALog.e("Failed to save PushNotification object into StorageClient")
                        }
                        onSuccess()
                        break
                    case .failure(let error):
                        notification.approved = false
                        notification.pending = true
                        FRALog.i("PushNotification authentication failed with following error: \(error.localizedDescription)")
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
            FRALog.e("Failed to retrieve PushMechanism object based on MechanismUUID in Push Notification's payload: \(notification.mechanismUUID)")
            onError(PushNotificationError.storageError("Failed to retrieve PushMechanism object with given UUID: \(notification.mechanismUUID)"))
        }
    }
    
    
    //  MARK: - Register
    
    /// Registers current PushMechanism object with designated AM instance using information given in QR code
    /// - Parameters:
    ///   - mechanism: PushMechanism object
    ///   - onSuccess: Success callback to notify that registration is completed and successful
    ///   - onFailure: Error callback to notify an error occurred during the push registration
    func register(mechanism: PushMechanism, onSuccess: @escaping SuccessCallback, onFailure: @escaping ErrorCallback) {
        do {
            let request = try buildPushRegistrationRequest(mechanism: mechanism)
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
            FRALog.w("Failed to prepare and make request for Push Registration with following error: \(error.localizedDescription   )")
            onFailure(error)
        }
    }
    
    
    //  MARK: - Device Token
    
    /// Get the current device token ID. If the device token has not been set, it will return n
    /// - Returns: The current Push device token ID
    public var deviceToken: String? {
        return pushDeviceTokenManager.deviceToken
    }
    
    
    /// Updates current device token with designated AM instance using information given in QR code
    ///
    /// NOTE: The device token is automatically stored within the method `application(_ application:, didRegisterForRemoteNotificationsWithDeviceToken deviceToken:)`.
    /// Use this method for manual updates. The provided device token will overwrite any previously stored token.
    /// - Parameters:
    ///   - mechanism: PushMechanism object
    ///   - deviceToken: APNS device token
    ///   - onSuccess: Success callback to notify that device token update is completed and successful
    ///   - onFailure: Error callback to notify an error occurred during the push device token update
    public func updateDeviceToken(mechanism: PushMechanism, deviceToken: String, onSuccess: @escaping SuccessCallback, onFailure: @escaping ErrorCallback) {
        FRALog.i("DeviceToken has changed; updating DeviceToken in storage")
        pushDeviceTokenManager.setDeviceToken(deviceToken)
        
        do {
            let request = try buildPushUpdateRequest(mechanism: mechanism, deviceToken: deviceToken)
            RestClient.shared.invoke(request: request, action: Action(type: .PUSH_UPDATE)) { (result) in
                switch result {
                case .success(let result, let httpResponse):
                    FRALog.v("Push device token update request was successful: \n\nResponse:\(result)\n\nHTTPResponse:\(String(describing: httpResponse))")
                    onSuccess()
                    break
                case .failure(let error):
                    FRALog.e("Push device token update request failed with following error: \(error.localizedDescription)")
                    onFailure(error)
                    break
                }
            }
        }
        catch {
            FRALog.w("Failed to prepare and make request for Push device token update with following error: \(error.localizedDescription)")
            onFailure(error)
        }
    }
    
    
    /// Updates all current device tokens with designated AM instance using information given in QR code
    ///
    /// NOTE: The device token is automatically stored within the method `application(_ application:, didRegisterForRemoteNotificationsWithDeviceToken deviceToken:)`.
    /// Use this method for manual updates. The provided device token will overwrite any previously stored token.
    /// - Parameters:
    ///  - deviceToken: APNS device token
    ///  - onSuccess: Success callback to notify that device token update is completed and successful
    ///  - onFailure: Error callback to notify an error occurred during the push device token update
    public func updateDeviceToken(deviceToken: String, onSuccess: @escaping SuccessCallback, onFailure: @escaping ErrorCallback) {
        FRALog.i("DeviceToken has changed; updating DeviceToken in storage")
        pushDeviceTokenManager.setDeviceToken(deviceToken)
        
        guard let mechanisms = getAllPushMechanisms(), !mechanisms.isEmpty else {
            FRALog.e("Failed to retrieve PushMechanism objects from StorageClient")
            onFailure(PushNotificationError.storageError("Failed to retrieve PushMechanism objects"))
            return
        }
        
        let dispatchGroup = DispatchGroup()
        var updateErrors: [Error] = []
        
        for mechanism in mechanisms {
            dispatchGroup.enter()
            do {
                let request = try buildPushUpdateRequest(mechanism: mechanism, deviceToken: deviceToken)
                RestClient.shared.invoke(request: request, action: Action(type: .PUSH_UPDATE)) { (result) in
                    switch result {
                    case .success(_, _):
                        FRALog.v("Push device token update request was successful for mechanism: \(mechanism.mechanismUUID)")
                    case .failure(let error):
                        FRALog.e("Push device token update request failed for mechanism: \(mechanism.mechanismUUID) with error: \(error.localizedDescription)")
                        updateErrors.append(error)
                    }
                    dispatchGroup.leave()
                }
            } catch {
                FRALog.e("Failed to build push update request for mechanism: \(mechanism.mechanismUUID) with error: \(error.localizedDescription)")
                updateErrors.append(error)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if updateErrors.isEmpty {
                onSuccess()
            } else {
                onFailure(PushNotificationError.updateFailed(errors: updateErrors))
            }
        }
    }
    
    
    /// Clears the current device token
   public func clearDeviceToken() {
        pushDeviceTokenManager.clearDeviceToken()
    }
    
    
    //  MARK: - Request Build
    
    /// Builds Request object for Push Registration
    /// - Parameter mechanism: PushMechanism object
    /// - Throws: CryptoError, PushNotificationError,
    /// - Returns: Request object for Push Registration request
    func buildPushRegistrationRequest(mechanism: PushMechanism) throws -> Request {
        
        guard let deviceToken = pushDeviceTokenManager.deviceToken else {
            FRALog.e("Missing DeviceToken")
            throw PushNotificationError.missingDeviceToken
        }
        
        let challengeResponse = try Crypto.generatePushChallengeResponse(challenge: mechanism.challenge, secret: mechanism.secret)
        FRALog.v("Challenge response generated: \(mechanism.challenge)")
        
        let deviceName = UIDevice.current.name
        
        var payload: [String: CodableValue] = [:]
        payload[FRAConstants.response] = CodableValue(challengeResponse)
        payload[FRAConstants.mechanismUid] = CodableValue(mechanism.mechanismUUID)
        payload[FRAConstants.deviceId] = CodableValue(deviceToken)
        payload[FRAConstants.deviceName] = CodableValue(deviceName)
        payload[FRAConstants.deviceType] = CodableValue(FRAConstants.ios)
        payload[FRAConstants.communicationType] = CodableValue(FRAConstants.apns)
        FRALog.v("Push registration JWT payload prepared: \(payload)")
                
        let jwt = try FRCompactJWT(algorithm: .hs256, secret: mechanism.secret, payload: payload).sign()
        FRALog.v("JWT generated and signed: \(jwt)")
        
        let requestPayload: [String: String] = [FRAConstants.messageId: mechanism.messageId, FRAConstants.jwt: jwt]
        
        var headers: [String: String] = [:]
        headers["Set-Cookie"] = mechanism.loadBalancer
        
        //  AM 6.5.2 - 8.x
        //
        //  Endpoint: /openam/json/push/sns/message?_action=register
        //  API Version: resource=1.0, protocol=1.0
        headers[FRAConstants.acceptAPIVersion] = FRAConstants.apiResource10 + ", " + FRAConstants.apiProtocol10
        
        let request = Request(url: mechanism.regEndpoint.absoluteString, method: .POST, headers: headers, bodyParams: requestPayload, requestType: .json, responseType: .json)
        
        return request
    }
    
    
    /// Builds Request object for Push Authentication
    /// - Parameters:
    ///  - notification: PushNotification object
    ///  - challengeResponse: Challenge response for Push Authentication
    ///  - approved: Boolean indicator whether or not Push Authentication is approved
    ///  - mechanism: PushMechanism object
    ///  - Throws: CryptoError, PushNotificationError
    func buildPushAuthenticationRequest(notification: PushNotification, challengeResponse: String? = nil, approved: Bool, mechanism: PushMechanism) throws -> Request {
        var payload: [String: CodableValue] = [:]
        payload[FRAConstants.response] = try CodableValue(Crypto.generatePushChallengeResponse(challenge: notification.challenge, secret: mechanism.secret))
        if !approved {
            payload["deny"] = CodableValue(true)
        }
        
        if notification.pushType == .challenge {
            payload["challengeResponse"] = CodableValue(challengeResponse)
        }
        
        FRALog.v("Push authentication JWT payload prepared: \(payload)")
        
        let jwt = try FRCompactJWT(algorithm: .hs256, secret: mechanism.secret, payload: payload).sign()
        FRALog.v("JWT generated and signed: \(jwt)")
        
        let requestPayload: [String: String] = [FRAConstants.messageId: notification.messageId, FRAConstants.jwt: jwt]

        var headers: [String: String] = [:]
        headers["Set-Cookie"] = notification.loadBalanceKey
        
        //  AM 6.5.2 - 8.x
        //
        //  Endpoint: /openam/json/push/sns/message?_action=authenticate
        //  API Version: resource=1.0, protocol=1.0
        headers[FRAConstants.acceptAPIVersion] = FRAConstants.apiResource10 + ", " + FRAConstants.apiProtocol10
        
        let request = Request(url: mechanism.authEndpoint.absoluteString, method: .POST, headers: headers, bodyParams: requestPayload, requestType: .json, responseType: .json)
        
        return request
    }
    
    
    /// Builds Request object for push device token update
    /// - Parameters:
    /// - mechanism: PushMechanism object
    /// - deviceToken: Device Token
    /// - Throws: CryptoError, PushNotificationError,
    /// - Returns: Request object for Push Registration request
    func buildPushUpdateRequest(mechanism: PushMechanism, deviceToken: String) throws -> Request {
        let deviceName = UIDevice.current.name
        
        var payload: [String: CodableValue] = [:]
        payload[FRAConstants.mechanismUid] = CodableValue(mechanism.mechanismUUID)
        payload[FRAConstants.deviceId] = CodableValue(deviceToken)
        payload[FRAConstants.deviceName] = CodableValue(deviceName)
        payload[FRAConstants.deviceType] = CodableValue(FRAConstants.ios)
        payload[FRAConstants.communicationType] = CodableValue(FRAConstants.apns)
        FRALog.v("Push device token update JWT payload prepared: \(payload)")
                
        let jwt = try FRCompactJWT(algorithm: .hs256, secret: mechanism.secret, payload: payload).sign()
        FRALog.v("JWT generated and signed: \(jwt)")
        
        var requestPayload: [String: String] = [FRAConstants.mechanismUid: mechanism.mechanismUUID, FRAConstants.jwt: jwt]
        
        if let username = mechanism.uid {
            requestPayload[FRAConstants.username] = username
        }
        
        var headers: [String: String] = [:]
        headers["Set-Cookie"] = mechanism.loadBalancer
        
        //  AM 8.x
        //
        //  Endpoint: /openam/json/push/sns/message?_action=refresh
        //  API Version: resource=1.0, protocol=1.0
        headers[FRAConstants.acceptAPIVersion] = FRAConstants.apiResource10 + ", " + FRAConstants.apiProtocol10
        
        let request = Request(url: mechanism.updateEndpoint.absoluteString, method: .POST, headers: headers, bodyParams: requestPayload, requestType: .json, responseType: .json)
        
        return request
    }
    
    
    //  MARK: - Private
    
    private func getAllPushMechanisms() -> [PushMechanism]? {
        var pushMechanisms: [PushMechanism] = []
        
        let accounts = FRAClient.storage.getAllAccounts()
        for account in accounts {
            let mechanisms = FRAClient.storage.getMechanismsForAccount(account: account)
            for mechanism in mechanisms {
                if let pushMechanism = mechanism as? PushMechanism {
                    pushMechanisms.append(pushMechanism)
                }
            }
        }
        
        return pushMechanisms
    }
    
}
