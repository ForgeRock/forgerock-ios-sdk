// 
//  AuthenticatorManager.swift
//  FRAuthenticator
//
//  Copyright (c) 2020-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation


/// AuthenticatorManager is responsible to parse given QR Code into corresponding Mechanism and Account objects, store and remove those objects within StorageClient
struct AuthenticatorManager {
    
    //  MARK: - Properties
    
    /// StorageClient instance
    let storageClient: StorageClient
    
    
    //  MARK: - Init
    
    /// Initializes AuthenticatorManager object with given StorageClient
    /// - Parameter storageClient: StorageClient instance to store/retrieve/remove Account/Mechanism objects
    init(storageClient: StorageClient) {
        self.storageClient = storageClient
    }
    
    
    //  MARK: - QR Code Parsing to Mechanism
    
    /// Creates Mechanism and Account (if does not exist) objects and stores them into StorageClient
    /// - Parameters:
    ///   - uri: URL of QR Code
    ///   - onSuccess: success completion callback with Mechanism
    ///   - onFailure: failure callback with Error
    func createMechanismFromUri(uri: URL, onSuccess: @escaping MechanismCallback, onError: @escaping ErrorCallback) {
        
        let authType = uri.getAuthType()
        FRALog.v("Received URI (\(uri.absoluteString)) with authType (\(authType.rawValue)), and proceeding to construct Mechanism object")

        if authType == .hotp {
            do {
                let mechanism = try self.storeOathQRCode(uri: uri)
                onSuccess(mechanism)
            }
            catch {
                onError(error)
            }
        }
        else if authType == .totp {
            do {
                let mechanism = try self.storeOathQRCode(uri: uri)
                onSuccess(mechanism)
            }
            catch {
                onError(error)
            }
        }
        else if authType == .push {
            self.storePushQRcode(uri: uri, onSuccess: { (mechanism) in
                onSuccess(mechanism)
            }, onFailure: {(error) in
                onError(error)
            })
        }
        else {
            FRALog.e("Unsupported auth type: \(String(describing: uri.host))")
            onError(MechanismError.invalidType)
        }
    }
    
    
    // MARK: - PushMechanism
    
    /// Stores PushMechanism and Account (if does not exist) objects from given QR Code URL
    /// - Parameters:
    ///   - uri: URL of QR Code
    ///   - onSuccess: success completion callback with Mechanism
    ///   - onFailure: failure callback with Error
    func storePushQRcode(uri: URL, onSuccess: @escaping MechanismCallback, onFailure: @escaping ErrorCallback) {
        do {
            // Parses QRCode, and constructs Account object
            let parser = try PushQRCodeParser(url: uri)
            let account = Account(issuer: parser.issuer, accountName: parser.label, imageUrl: parser.image, backgroundColor: parser.backgroundColor)
            FRALog.v("Account object (\(account.identifier)) is created")
            
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer)
            FRALog.v("PushMechanism (\(mechanism.identifier) is created")
                        
            for thisMechanism in self.storageClient.getMechanismsForAccount(account: account) {
                FRALog.v("Validating stored Mechanism for duplication")
                if thisMechanism.type == mechanism.type {
                    FRALog.e("Found the Mechanism with same type under the same account")
                    throw MechanismError.alreadyExists(mechanism.identifier)
                }
            }
            
            FRALog.v("Start registering PushMechanism object with AM")
            mechanism.register(onSuccess: {
                FRALog.v("PushMechanism registration request was successful")
                do {
                    if !self.storageClient.setMechanism(mechanism: mechanism) {
                        FRALog.e("Failed to store Mechanism (\(mechanism.identifier)) object into StorageClient")
                        throw FRAError.failToSaveIntoStorageClient("Failed to store Mechanism (\(mechanism.identifier)) object into StorageClient")
                    }
                    try self.storeAccount(account: account)
                    FRALog.v("PushMechanism (\(mechanism.identifier) is stored into StorageClient")
                    onSuccess(mechanism)
                }
                catch {
                    onFailure(error)
                }
            }) { (error) in
                FRALog.e("PushMechanism registration request encountered an error: \(error.localizedDescription)")
                onFailure(error)
            }
        }
        catch {
            FRALog.e("An error occurred while constructing Mechanism object with given URI\nError: \(error.localizedDescription)")
            onFailure(error)
        }
    }
    
    
    //  MARK: - TOTPMechanism / HOTPMechanism
    
    /// Parses given QRCode URL, constructs, and stores Account and Mechanism objects into StorageClient
    /// - Parameter uri: QRCode URL
    /// - Throws: FRAError
    /// - Returns: Mechanism object for given QRCode
    func storeOathQRCode(uri: URL) throws -> Mechanism {

        // Parses QRCode, and constructs Account object
        let parser = try OathQRCodeParser(url: uri)
        let account = Account(issuer: parser.issuer, accountName: parser.label, imageUrl: parser.image, backgroundColor: parser.backgroundColor)
        FRALog.v("Account object (\(account.identifier)) is created")
        
        // Constructs Mechanism object, and tries to store it into StorageClient
        if uri.getAuthType() == .hotp {
            let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, counter: parser.counter, digits: parser.digits)
            FRALog.v("HOTPMechanism (\(mechanism.identifier) is created")
            
            for thisMechanism in self.storageClient.getMechanismsForAccount(account: account) {
                FRALog.v("Validating stored Mechanism for duplication")
                if thisMechanism.type == mechanism.type {
                    FRALog.e("Found the Mechanism with same type under the same account")
                    throw MechanismError.alreadyExists(mechanism.identifier)
                }
            }
            
            if !self.storageClient.setMechanism(mechanism: mechanism) {
                FRALog.e("Failed to store Mechanism (\(mechanism.identifier) object into StorageClient")
                throw FRAError.failToSaveIntoStorageClient("Failed to store Mechanism (\(mechanism.identifier) into storage")
            }
            FRALog.v("HOTPMechanism (\(mechanism.identifier) is stored into StorageClient")
            try self.storeAccount(account: account)
            return mechanism
        }
        else if uri.getAuthType() == .totp {
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, period: parser.period, digits: parser.digits)
            FRALog.v("TOTPMechanism (\(mechanism.identifier) is created")
                        
            for thisMechanism in self.storageClient.getMechanismsForAccount(account: account) {
                FRALog.v("Validating stored Mechanism for duplication")
                if thisMechanism.type == mechanism.type {
                    FRALog.e("Found the Mechanism with same type under the same account")
                    throw MechanismError.alreadyExists(mechanism.identifier)
                }
            }
            
            if !self.storageClient.setMechanism(mechanism: mechanism) {
                FRALog.e("Failed to store Mechanism (\(mechanism.identifier) object into StorageClient")
                throw FRAError.failToSaveIntoStorageClient("Failed to store Mechanism (\(mechanism.identifier) into storage")
            }
            FRALog.v("TOTPMechanism (\(mechanism.identifier) is stored into StorageClient")
            try self.storeAccount(account: account)
            return mechanism
        }
        
        FRALog.w("Invalid type is passed into internal method for parsing OATH QRCode")
        throw MechanismError.invalidType
    }
    
    
    //  MARK: - Account
    
    /// Stores Account object
    /// - Parameter account: Account object
    /// - Throws: FRAError
    func storeAccount(account: Account) throws {
        // Stores Account object if StorageClient doesn't have one yet
        if let _ = self.storageClient.getAccount(accountIdentifier: account.identifier) {
            FRALog.v("Account (\(account.identifier)) already exsits; updating Account object for newly given QRCode")
        }

        if !self.storageClient.setAccount(account: account) {
            FRALog.e("Failed to store Account (\(account.identifier) object into StorageClient")
            throw FRAError.failToSaveIntoStorageClient("Failed to store Account (\(account.identifier)) object into storage")
        }
        FRALog.v("Account (\(account.identifier)) object is stored into StorageClient")
    }
        
    
    /// Retrieves all Accounts, and associated Mechanism, and PushNotification objects (when applicable)
    /// - Returns: An array of Account object
    func getAllAccounts() -> [Account] {
        
        // Get all accounts
        let accounts = self.storageClient.getAllAccounts()
        // Loop through accounts, and retrieve Mechanism, and PushNotification
        for account in accounts {
            // Get Mechanisms
            let mechanisms = self.storageClient.getMechanismsForAccount(account: account)
            for mechanism in mechanisms {
                // If Mechanism is PushMechanism, retrieve all PushNotification
                if mechanism is PushMechanism, let pushMechanism = mechanism as? PushMechanism {
                    pushMechanism.notifications = self.storageClient.getAllNotificationsForMechanism(mechanism: pushMechanism)
                }
            }
            account.mechanisms = mechanisms
        }
        
        return accounts
    }
    
    
    /// Retrieves Account object with given Account Identifier; Identifier of Account object is "<issuer>-<accountName>"
    /// - Parameter identifier: String value of Account object's identifier as in "<issuer>-<accountName>"
    /// - Returns: Account object with given identifier
    func getAccount(identifier: String) -> Account? {
        if let account = self.storageClient.getAccount(accountIdentifier: identifier) {
            // Get Mechanisms
            let mechanisms = self.storageClient.getMechanismsForAccount(account: account)
            for mechanism in mechanisms {
                // If Mechanism is PushMechanism, retrieve all PushNotification
                if mechanism is PushMechanism, let pushMechanism = mechanism as? PushMechanism {
                    pushMechanism.notifications = self.storageClient.getAllNotificationsForMechanism(mechanism: pushMechanism)
                }
            }
            account.mechanisms = mechanisms
            
            return account
        }
        else {
            return nil
        }
    }
    
    
    /// Removes given Account object from StorageClient
    /// - Parameter account: Account object to be removed
    /// - Returns: Boolean result of the operation
    @discardableResult func removeAccount(account: Account) -> Bool {
        
        for mechanism in account.mechanisms {
            if mechanism is PushMechanism, let pushMechanism = mechanism as? PushMechanism {
                for notification in self.storageClient.getAllNotificationsForMechanism(mechanism: pushMechanism) {
                    if !self.storageClient.removeNotification(notification: notification) {
                        FRALog.e("Failed to remove PushNotification (\(notification.identifier); it failed on StorageClient")
                    }
                }
            }
            if !self.storageClient.removeMechanism(mechanism: mechanism) {
                FRALog.e("Failed to remove Mechanism (\(mechanism.identifier); it failed on StorageClient")
            }
        }
        
        if !self.storageClient.removeAccount(account: account) {
            FRALog.w("Account object (\(account.identifier) was not found from StorageClient, or cannot be removed; it failed on StorageClient")
            return false
        }

        FRALog.v("Account object (\(account.identifier) was removed")
        return true
    }
    
    
    //  MARK: - Mechanism
    
    
    /// Retrieves PushMechanism object with given PushNotification object
    /// - Parameter notification: PushNotification object to obtain associated PushMechanism
    /// - Returns: PushMechanism object that is associated with given PushNotification object
    func getMechanism(notification: PushNotification) -> PushMechanism? {
        return self.storageClient.getMechanismForUUID(uuid: notification.mechanismUUID) as? PushMechanism
    }
    
    
    /// Removes Mechanism object from StorageClient, and PushNotification objects associated with it if necessary
    /// - Parameter mechanism: Mechanism object to be removed
    /// - Returns: boolean result of operation
    @discardableResult func removeMechanism(mechanism: Mechanism) -> Bool {
        if mechanism is PushMechanism {
            for notification in self.storageClient.getAllNotificationsForMechanism(mechanism: mechanism) {
                if !self.storageClient.removeNotification(notification: notification) {
                    FRALog.e("Failed to remove PushNotification (\(notification.identifier); it failed on StorageClient")
                }
            }
        }

        if !self.storageClient.removeMechanism(mechanism: mechanism) {
            FRALog.e("Failed to remove Mechanism (\(mechanism.identifier); it failed on StorageClient")
            return false
        }
        else {
            FRALog.v("Mechanism (\(mechanism.identifier) was removed")
            return true
        }
    }
    
    
    //  MARK: - Notification
    
    /// Retrieves All PushNotification associated with given PushMechanism
    /// - Parameter mechanism: PushMechanism that the list of PushNotifications were sent
    /// - Returns: An array of PushNotification object
    func getAllNotifications(mechanism: PushMechanism) -> [PushNotification] {
        return self.storageClient.getAllNotificationsForMechanism(mechanism: mechanism)
    }
    
    
    /// Retrieves All PushNotification across all mechanisms
    /// - Returns: An array of PushNotification object
    func getAllNotifications() -> [PushNotification] {
        return self.storageClient.getAllNotifications()
    }
    
    
    /// Removes PushNotification object from StorageClient
    /// - Parameter notification: PushNotification object to be removed
    /// - Returns: boolean result of operation
    @discardableResult func removeNotification(notification: PushNotification) -> Bool {
        if !self.storageClient.removeNotification(notification: notification) {
            FRALog.e("Failed to remove PushNotification (\(notification.identifier); it failed on StorageClient")
            return false
        }
        else {
            FRALog.v("PushNotification (\(notification.identifier) was removed")
            return true
        }
    }
}
