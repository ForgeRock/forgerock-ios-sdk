// 
//  AuthenticatorManager.swift
//  FRAuthenticator
//
//  Copyright (c) 2020-2023 ForgeRock. All rights reserved.
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
    
    /// FRAPolicyEvaluator instance
    let policyEvaluator: FRAPolicyEvaluator
    
    //  MARK: - Init
    
    /// Initializes AuthenticatorManager object with given StorageClient
    /// - Parameters:
    ///     - storageClient: StorageClient instance to store/retrieve/remove Account/Mechanism objects
    ///     - policyEvaluator: The PolicyEvaluator instance used to enforce  Authenticator Policy rules such as Device Tampering dectection
    init(storageClient: StorageClient, policyEvaluator: FRAPolicyEvaluator) {
        self.storageClient = storageClient
        self.policyEvaluator = policyEvaluator
    }
    
    
    //  MARK: - QR Code Parsing to Mechanism
    
    /// Creates Mechanism and Account (if does not exist) objects and stores them into StorageClient
    /// - Parameters:
    ///   - uri: URL of QR Code
    ///   - onSuccess: success completion callback with Mechanism
    ///   - onFailure: failure callback with Error
    func createMechanismFromUri(uri: URL, onSuccess: @escaping MechanismCallback, onError: @escaping ErrorCallback) {
        
        let uriType = uri.getURIType()
        let authType = uri.getAuthType()
        if uriType == .mfauth {
            FRALog.v("Validating stored Mechanisms for duplication")
            do {
                let parser = try PushQRCodeParser(url: uri)
                let account = Account(issuer: parser.issuer, accountName: parser.label, imageUrl: parser.image, backgroundColor: parser.backgroundColor, policies: parser.policies)
                if let thisMechanism = self.storageClient.getMechanismsForAccount(account: account).first {
                    FRALog.e("Found a Mechanism under the same account")
                    onError(MechanismError.alreadyExists(thisMechanism.identifier))
                    return
                }
            }
            catch {
                onError(error)
            }
            
            FRALog.v("Evaluating policies for the new Account")
            let result = self.policyEvaluator.evaluate(uri: uri)
            if let policy = result.nonCompliancePolicy, !result.comply {
                onError(AccountError.failToRegisterPolicyViolation(policy.name))
                return
            }
            
            FRALog.v("Received Combined MFA URI (\(uri.absoluteString)). Proceeding to construct Mechanism objects")
            // try to register OATH mechanism, do not return object or error
            do {
                let mechanism = try self.storeOathQRCode(uri: uri)
                FRALog.v("OATH mechanism for (\(mechanism.issuer)) in Combined MFA successfully created.")
            }
            catch {
                FRALog.v("Error creating OATH mechanism from Combined MFA URI")
            }
            // try to register push mechanism and do return object or error
            self.storePushQRcode(uri: uri, onSuccess: { (mechanism) in
                onSuccess(mechanism)
            }, onFailure: {(error) in
                onError(error)
            })
        } else {
            FRALog.v("Received URI (\(uri.absoluteString)) with authType (\(authType.rawValue)), and proceeding to construct Mechanism object")
            if authType == .hotp || authType == .totp {
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
            let account = Account(issuer: parser.issuer, accountName: parser.label, imageUrl: parser.image, backgroundColor: parser.backgroundColor,  policies: parser.policies)
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
        let account = Account(issuer: parser.issuer, accountName: parser.label, imageUrl: parser.image, backgroundColor: parser.backgroundColor, policies: parser.policies)
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
            // Evaluate policies
            evaluatePoliciesForAccount(account: account)
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
            // Evaluate policies
            evaluatePoliciesForAccount(account: account)
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
    
    
    /// Update given Account object on the StorageClient
    /// - Parameter account: Account object to be updated
    /// - Throws: AccountError
    /// - Returns: Boolean result of the operation
    @discardableResult func updateAccount(account: Account) throws -> Bool {
        if let policyName = account.lockingPolicy, account.lock {
            throw AccountError.accountLocked(policyName)
        }
        
        if (self.storageClient.getAccount(accountIdentifier: account.identifier)) != nil {
            if !self.storageClient.setAccount(account: account) {
                FRALog.w("Account object (\(account.identifier) cannot be updated; it failed on StorageClient")
                return false
            }

            FRALog.v("Account object (\(account.identifier) was updated")
            return true
        } else {
            FRALog.w("Account object (\(account.identifier) was not found on StorageClient")
            return false
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
    
    
    /// Lock the given `Account` object limiting the access to all `Mechanism` objects and any `PushNotification` objects associated with it.
    /// - Parameters:
    ///     - account: Account object to be locked
    ///     - policy: The non-compliance policy
    /// - Throws: AccountError
    /// - Returns: Boolean result of lock operation
    @discardableResult public func lockAccount(account: Account, policy: FRAPolicy) throws -> Bool {
        if account.lock {
            throw AccountError.failToLockAccountAlreadyLocked
        } else if policy.name.isEmpty {
            throw AccountError.failToLockMissingPolicyName
        } else if !policyEvaluator.isPolicyAttached(account: account, policyName: policy.name) {
            throw AccountError.failToLockInvalidPolicy
        } else {
            account.lock(policy: policy)
            return storageClient.setAccount(account: account)
        }
    }
    
    
    /// Unlock the  given `Account` object
    /// - Parameter account: Account object to be locked
    /// - Throws: AccountError
    /// - Returns: Boolean result of unlock operation
    @discardableResult public func unlockAccount(account: Account) throws -> Bool {
        if !account.lock {
            throw AccountError.failToUnlockAccountNotLocked
        } else {
            account.unlock()
            return storageClient.setAccount(account: account)
        }
    }
    
    private func evaluatePoliciesForAccount(account: Account) -> Void {
        let result = self.policyEvaluator.evaluate(account: account)
        if let policy = result.nonCompliancePolicy, !result.comply {
            FRALog.w("Locking Account ID (\(account.identifier)) due non-compliance policy: \(policy.name))")
            account.lock(policy: policy)
            storageClient.setAccount(account: account)
        } else if account.lock && result.comply {
            FRALog.w("Unlocking previously locked Account: All policies are compliance.")
            account.unlock()
            storageClient.setAccount(account: account)
        }
    }
    
    
    //  MARK: - Mechanism
    
    
    /// Retrieves Mechanism object with given Mechanism UUID
    /// - Parameter uuid: UUID of Mechanism
    /// - Returns: Mechanism object that is associated with given UUID
    func getMechanismForUUID(uuid: String) -> Mechanism? {
        return self.storageClient.getMechanismForUUID(uuid: uuid)
    }
    
    
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
    
    
    /// Retrieves PushNotification object with given PushNotification Identifier; Identifier of PushNotification object is "<mechanismUUID>-<timeAdded>"
    /// - Parameter identifier: String value of PushNotification object's identifier as in "<mechanismUUID>-<timeAdded>"
    /// - Returns: PushNotification object with given identifier
    func getNotification(identifier: String) -> PushNotification? {
        return self.storageClient.getNotification(notificationIdentifier: identifier)
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
