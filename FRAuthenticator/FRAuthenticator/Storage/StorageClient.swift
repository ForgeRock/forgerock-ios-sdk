// 
//  StorageClient.swift
//  FRAuthenticator
//
//  Copyright (c) 2020-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// StorageClient protocol represents predefined interfaces and protocols for FRAuthenticator's storage method
public protocol StorageClient {
    
    /// Stores Account object into Storage Client, and returns discardable Boolean result of operation
    /// - Parameter account: Account object to be stored
    @discardableResult func setAccount(account: Account) -> Bool
    
    /// Removes Account object from Storage Client, and returns discardable Boolean result of operation
    /// - Parameter account: Account object to be removed
    @discardableResult func removeAccount(account: Account) -> Bool
    
    /// Retrieves Account object with its unique identifier
    /// - Parameter accountIdentifier: String value of Account's unique identifier
    func getAccount(accountIdentifier: String) -> Account?
    
    /// Retrieves all Account objects stored in Storage Client
    func getAllAccounts() -> [Account]
    
    /// Stores Mechanism object into Storage Client, and returns discardable Boolean result of operation
    /// - Parameter mechanism: Mechanism object to be stored
    @discardableResult func setMechanism(mechanism: Mechanism) -> Bool
    
    /// Removes Mechanism object from Storage Client, and returns discardable Boolean result of operation
    /// - Parameter mechanism: Mechanism object to be removed
    @discardableResult func removeMechanism(mechanism: Mechanism) -> Bool
    
    /// Retrieves all Mechanism objects stored in Storage Client
    /// - Parameter account: Account object that is associated with Mechanism(s)
    func getMechanismsForAccount(account: Account) -> [Mechanism]
    
    /// Retrieves Mechanism object with given Mechanism UUID
    /// - Parameter uuid: UUID of Mechanism
    func getMechanismForUUID(uuid: String) -> Mechanism?
    
    /// Retrieves PushNotification object with its unique identifier
    /// - Parameter notificationIdentifier: String value of PushNotification's unique identifier
    func getNotification(notificationIdentifier: String) -> PushNotification?
    
    /// Stores PushNotification object into Storage Client, and returns discardable Boolean result of operation
    /// - Parameter notification: PushNotification object to be stored
    @discardableResult func setNotification(notification: PushNotification) -> Bool
    
    /// Removes PushNotification object from Storage Client, and returns discardable Boolean result of operation
    /// - Parameter notification: PushNotification object to be removed
    @discardableResult func removeNotification(notification: PushNotification) -> Bool
    
    /// Retrieves all Notification objects from Storage Client with given Mechanism object
    /// - Parameter mechanism: Mechanism object that is associated with Notification(s)
    func getAllNotificationsForMechanism(mechanism: Mechanism) -> [PushNotification]
    
    /// Retrieves all Notification objects from Storage Client
    func getAllNotifications() -> [PushNotification]
    
    /// Returns whether or not StorageClient has any data stored
    @discardableResult func isEmpty() -> Bool
}
