// 
//  KeychainServiceStorageClient.swift
//  FRAuthenticator
//
//  Copyright (c) 2020-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore

struct KeychainServiceClient: StorageClient {

    
    /// Keychain Service types for all storages in SDK
    enum KeychainStoreType: String {
        case account = ".account"
        case mechanism = ".mechanism"
        case notification = ".notification"
    }
    
    var accountStorage: KeychainService
    var mechanismStorage: KeychainService
    var notificationStorage: KeychainService
    let keychainServiceIdentifier = "com.forgerock.ios.authenticator.keychainservice.local"
    /// SecuredKey object that is used for encrypting/decrypting data in Keychain Service
    var securedKey: SecuredKey?
    
    
    init() {
        
        // Create SecuredKey if available
        if let securedKey = SecuredKey(applicationTag: "com.forgerock.ios.authenticator.securedKey.identifier") {
            self.securedKey = securedKey
        }
        
        self.accountStorage = KeychainService(service: keychainServiceIdentifier + KeychainStoreType.account.rawValue, securedKey: self.securedKey)
        self.mechanismStorage = KeychainService(service: keychainServiceIdentifier + KeychainStoreType.mechanism.rawValue, securedKey: self.securedKey)
        self.notificationStorage = KeychainService(service: keychainServiceIdentifier + KeychainStoreType.notification.rawValue, securedKey: self.securedKey)
    }
    
    
    @discardableResult func setAccount(account: Account) -> Bool {
        if #available(iOS 11.0, *) {
            do {
                let accountData = try NSKeyedArchiver.archivedData(withRootObject: account, requiringSecureCoding: true)
                return self.accountStorage.set(accountData, key: account.identifier)
            }
            catch {
                FRALog.e("Failed to serialize Account object: \(error.localizedDescription)")
                return false
            }
        } else {
            let accountData = NSKeyedArchiver.archivedData(withRootObject: account)
            return self.accountStorage.set(accountData, key: account.identifier)
        }
    }
    
    
    @discardableResult func removeAccount(account: Account) -> Bool {
        return self.accountStorage.delete(account.identifier)
    }
    
    
    func getAccount(accountIdentifier: String) -> Account? {
        if let accountData = self.accountStorage.getData(accountIdentifier),
            let account = NSKeyedUnarchiver.unarchiveObject(with: accountData) as? Account {
            return account
        }
        else {
            return nil
        }
    }
    
    
    func getAllAccounts() -> [Account] {
        var accounts: [Account] = []
        if let items = self.accountStorage.allItems() {
            for item in items {
                if let accountData = item.value as? Data, let account = NSKeyedUnarchiver.unarchiveObject(with: accountData) as? Account {
                    accounts.append(account)
                }
            }
        }
        return accounts.sorted { (lhs, rhs) -> Bool in
            return lhs.timeAdded.timeIntervalSince1970 < rhs.timeAdded.timeIntervalSince1970
        }
    }
    
    
    @discardableResult func setMechanism(mechanism: Mechanism) -> Bool {
        if #available(iOS 11.0, *) {
            do {
                let mechanismData = try NSKeyedArchiver.archivedData(withRootObject: mechanism, requiringSecureCoding: true)
                return self.mechanismStorage.set(mechanismData, key: mechanism.identifier)
            }
            catch {
                FRALog.e("Failed to serialize Mechanism object: \(error.localizedDescription)")
                return false
            }
        } else {
            let mechanismData = NSKeyedArchiver.archivedData(withRootObject: mechanism)
            return self.mechanismStorage.set(mechanismData, key: mechanism.identifier)
        }
    }
    
    
    @discardableResult func removeMechanism(mechanism: Mechanism) -> Bool {
        return self.mechanismStorage.delete(mechanism.identifier)
    }
    

    func getMechanismsForAccount(account: Account) -> [Mechanism] {
        var mechanisms: [Mechanism] = []
        if let items = self.mechanismStorage.allItems() {
            for item in items {
                if let mechanismData = item.value as? Data,
                let mechanism = NSKeyedUnarchiver.unarchiveObject(with: mechanismData) as? Mechanism {
                    if mechanism.issuer == account.issuer && mechanism.accountName == account.accountName {
                        mechanisms.append(mechanism)
                    }
                }
            }
        }
        return mechanisms.sorted { (lhs, rhs) -> Bool in
            return lhs.timeAdded.timeIntervalSince1970 < rhs.timeAdded.timeIntervalSince1970
        }
    }
    
    
    func getMechanismForUUID(uuid: String) -> Mechanism? {
        if let items = self.mechanismStorage.allItems() {
            for item in items {
                if let mechanismData = item.value as? Data,
                let mechanism = NSKeyedUnarchiver.unarchiveObject(with: mechanismData) as? Mechanism {
                    if mechanism.mechanismUUID == uuid {
                        return mechanism
                    }
                }
            }
        }
        return nil
    }
    
    
    func getNotification(notificationIdentifier: String) -> PushNotification? {
        if let notificationData = self.notificationStorage.getData(notificationIdentifier),
            let notification = NSKeyedUnarchiver.unarchiveObject(with: notificationData) as? PushNotification {
            return notification
        }
        else {
            return nil
        }
    }
    
    
    @discardableResult func setNotification(notification: PushNotification) -> Bool {
        if #available(iOS 11.0, *) {
            do {
                let notificationData = try NSKeyedArchiver.archivedData(withRootObject: notification, requiringSecureCoding: true)
                return self.notificationStorage.set(notificationData, key: notification.identifier)
            }
            catch {
                FRALog.e("Failed to serialize PushNotification object: \(error.localizedDescription)")
                return false
            }
        } else {
            let notificationData = NSKeyedArchiver.archivedData(withRootObject: notification)
            return self.notificationStorage.set(notificationData, key: notification.identifier)
        }
    }
    
    
    @discardableResult func removeNotification(notification: PushNotification) -> Bool {
        return self.notificationStorage.delete(notification.identifier)
    }
    
    
    func getAllNotificationsForMechanism(mechanism: Mechanism) -> [PushNotification] {
        var notifications: [PushNotification] = []
        if let items = self.notificationStorage.allItems() {
           for item in items {
               if let notificationData = item.value as? Data,
                let notification = NSKeyedUnarchiver.unarchiveObject(with: notificationData) as? PushNotification,
                notification.mechanismUUID == mechanism.mechanismUUID {
                   notifications.append(notification)
               }
           }
        }
        return notifications.sorted { (lhs, rhs) -> Bool in
            return lhs.timeAdded.timeIntervalSince1970 < rhs.timeAdded.timeIntervalSince1970
        }
    }
    
    
    func getAllNotifications() -> [PushNotification] {
        var notifications: [PushNotification] = []
        if let items = self.notificationStorage.allItems() {
           for item in items {
               if let notificationData = item.value as? Data, let notification = NSKeyedUnarchiver.unarchiveObject(with: notificationData) as? PushNotification {
                   notifications.append(notification)
               }
           }
        }
        return notifications.sorted { (lhs, rhs) -> Bool in
            return lhs.timeAdded.timeIntervalSince1970 < rhs.timeAdded.timeIntervalSince1970
        }
    }
    
    
    @discardableResult func isEmpty() -> Bool {
        return self.notificationStorage.allItems()?.count == 0 && self.mechanismStorage.allItems()?.count == 0 && self.accountStorage.allItems()?.count == 0
    }
}
