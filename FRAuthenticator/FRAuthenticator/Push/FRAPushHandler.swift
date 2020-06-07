// 
//  FRAPushHandler.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import UIKit


/// FRAPushHandler is mainly responsible to handle PushNotification activities in application layer and handling incoming Device Token, and Notification from the application.
public class FRAPushHandler: NSObject {
    
    //  MARK: - Properties
    
    /// shared instance of FRAPushHandler
    public static var shared: FRAPushHandler = FRAPushHandler()
    /// Device Token
    var deviceToken: String?
    
    
    //  MARK: - Init
    
    /// Prevents init
    private override init() { }
    
    
    //  MARK: - AppDelegate methods
    
    /// Notifies FRAuthenticator SDK for successful Device Token registration; Device Token will be used for PushMechanism registration with AM
    /// - Parameters:
    ///   - application: The app object that initiated the remote-notification registration process.
    ///   - deviceToken: Device Token received from AppDelegate of the application
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        FRALog.i("Received DeviceToken data (\(deviceToken)")
        self.deviceToken = deviceTokenString
        FRALog.i("Parsed and stored DeviceToken (\(deviceTokenString)")
    }

    
    /// Notifies FRAuthenticator SDK for failure of Device Token registration; this nullifies existing Device Token
    /// - Parameters:
    ///   - application: The app object that initiated the remote-notification registration process.
    ///   - error: An error captured for device token registration
    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        FRALog.e("Received an error for registration of Device Token; nullifying current Device Token: \(error.localizedDescription)")
        self.deviceToken = nil
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
            // Extract JWT payload
            FRALog.v("Starts extracting JWT payload: \(jwt)")
            let jwtPayload = try FRCompactJWT.extractPayload(jwt: jwt)
            FRALog.v("JWT payload is extracted: \(jwtPayload)")
            
            // Construct and save Notification object
            FRALog.v("PushNotification object created - messageId:\(messageId), payload: \(jwtPayload)")
            let notification = try PushNotification(messageId: messageId, payload: jwtPayload)
            
            if let mechanism = FRAClient.storage.getMechanismForUUID(uuid: notification.mechanismUUID) {
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
            }
            
            return notification
        }
        catch {
            FRALog.e("An error occurred during handling incoming PushNotification: \(error.localizedDescription)")
            return nil
        }
    }
}
