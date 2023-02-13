// 
//  FRAuthenticator.swift
//  FRAuthenticator
//
//  Copyright (c) 2020-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// FRAuthenticator is an abstraction layer of FRAuthenticator SDK and is responsible to create, and manage Account, and Mechanism objects with StorageClient
public class FRAClient: NSObject {
    
    //  MARK: - Properties
    
    /// shared instance of FRAuthenticator after SDK started
    public static var shared: FRAClient? = nil
    /// current storage client object
    static var storage: StorageClient = KeychainServiceClient()
    /// current policy evaluator object
    static var policyEvaluator: FRAPolicyEvaluator = FRAPolicyEvaluator()
    /// AuthenticatorManager instance for FRAClient
    let authenticatorManager: AuthenticatorManager
    
    
    //  MARK: - Init
    
    /// Prevents init
    private override init() { fatalError("FRAClient() is prohibited. Use FRAClient.start() to initialize SDK, and FRAClient.share to access FRAClient") }
    
    
    /// Initializes FRAClient object with StorageClient
    /// - Parameters:
    ///     - storageClient: Dedicated StorageClient for FRAClient instance
    ///     - policyEvaluator: The PolicyEvaluator instance
    init(storageClient: StorageClient, policyEvaluator: FRAPolicyEvaluator) {
        FRALog.v("Init: \(String(describing: storageClient))")
        self.authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
    }
    
    
    //  MARK: - Lifecycle
    
    /// Starts SDK's lifecylce and internal process
    static public func start() {
        FRALog.v("FRAClient SDK started")
        FRAClient.shared = FRAClient(storageClient: FRAClient.storage, policyEvaluator: FRAClient.policyEvaluator)
    }
    
    
    //  MARK: - StorageClient
    
    /// Sets default SDK's Storage Client; any storage client that inherits 'StorageClient' can be used for SDK's storage
    /// - Parameter storage: StoreClient object
    /// - Throws: FRAError
    static public func setStorage(storage: StorageClient) throws {
        //  If SDK has already started; SDK can't handle the change of storage client. Throws an exception.
        guard FRAClient.shared == nil else {
            FRALog.e("StorageClient cannot be set; FRAClient already initialized")
            throw FRAError.invalidStateForChangingStorage
        }
        FRALog.i("StorageClient is set: \(String(describing: storage))")
        //  Update storage client
        FRAClient.storage = storage
    }
    
    //  MARK: - FRAPolicyEvaluator
    
    /// Sets default SDK's PolicyEvaluator
    /// - Parameter policyEvaluator: FRAPolicyEvaluator object
    /// - Throws: FRAError
    static public func setPolicyEvaluator(policyEvaluator: FRAPolicyEvaluator) throws {
        //  If SDK has already started; SDK can't handle the change of storage client. Throws an exception.
        guard FRAClient.shared == nil else {
            FRALog.e("FRAPolicyEvaluator cannot be set; FRAClient already initialized")
            throw FRAError.invalidStateForChangingPolicyEvaluator
        }
        FRALog.i("FRAPolicyEvaluator is set: \(String(describing: policyEvaluator))")
        //  Update storage client
        FRAClient.policyEvaluator = policyEvaluator
    }
    
    
    //  MARK: - Account methods
    
    /// Retrieves all Account objects from given StorageClient
    /// - Returns: An array of Account; **empty array is returned when there is no Account**
    public func getAllAccounts() -> [Account] {
        return self.authenticatorManager.getAllAccounts()
    }
    
    
    /// Retrieves Account object that is associated with given Mechanism object
    /// - Parameter mechanism: Mechanism object to retrieve associated Account object
    /// - Returns: Account object that the given Mechanism object belongs to
    public func getAccount(mechanism: Mechanism) -> Account? {
        return self.authenticatorManager.getAccount(identifier: mechanism.issuer + "-" + mechanism.accountName)
    }
    
    
    /// Retrieves a specific Account object with given identifier; identifier as in **"<issuer>-<accountName>"** format
    /// - Parameter identifier: identifier of Account object as in **"<issuer>-<accountName>"** format
    /// - Returns: Account object for given identifier
    public func getAccount(identifier: String) -> Account? {
        return self.authenticatorManager.getAccount(identifier: identifier)
    }
    
    
    /// Update given Account object on the StorageClient
    /// - Parameter account: Account object to be updated
    /// - Throws: AccountError
    /// - Returns: Boolean result of deleting operation
    @discardableResult public func updateAccount(account: Account) throws -> Bool {
        return try self.authenticatorManager.updateAccount(account: account)
    }
    
    
    /// Removes given Account object from given StorageClient
    /// - Parameter account: Account object to be removed
    /// - Returns: Boolean result of deleting operation
    @discardableResult public func removeAccount(account: Account) -> Bool {
        return self.authenticatorManager.removeAccount(account: account)
    }
    
    /// Lock the given `Account` object limiting the access to all `Mechanism` objects and any `PushNotification` objects associated with it.
    /// - Parameters:
    ///     - account: Account object to be locked
    ///     - policy: The non-compliance policy
    /// - Throws: AccountError
    /// - Returns: Boolean result of lock operation
    @discardableResult public func lockAccount(account: Account, policy: FRAPolicy) throws -> Bool {
        return try self.authenticatorManager.lockAccount(account: account, policy: policy)
    }
    
    /// Unlock the  given `Account` object
    /// - Parameters:
    ///     - account: Account object to be locked
    /// - Throws: AccountError
    /// - Returns: Boolean result of unlock operation
    @discardableResult public func unlockAccount(account: Account) throws -> Bool {
        return try self.authenticatorManager.unlockAccount(account: account)
    }
    
    //  MARK: - Mechanism
    
    /// Retrieves Mechanism object with given Mechanism UUID
    /// - Parameter uuid: UUID of Mechanism
    /// - Returns: Mechanism object that is associated with given UUID
    func getMechanismForUUID(uuid: String) -> Mechanism? {
        return self.authenticatorManager.getMechanismForUUID(uuid: uuid)
    }
    
    
    /// Retrieves a PushMechanism object with given PushNotification object
    ///
    /// **Note:** This getMechanism with PushNotification object does not retrieve all PushNotification object associated with PushMechanism. This only returns PushMechanism object without the array.
    ///
    /// - Parameter notification: PushNotification object
    /// - Returns: PushMechanism object for given PushNotification
    public func getMechanism(notification: PushNotification) -> PushMechanism? {
        return self.authenticatorManager.getMechanism(notification: notification)
    }
    
    
    /// Removes Mechanism object from StorageClient, and all associated PushNotification objects if needed
    /// - Parameter mechanism: Mechanism object to be removed
    /// - Returns: boolean result of operation
    @discardableResult public func removeMechanism(mechanism: Mechanism) -> Bool {
        return self.authenticatorManager.removeMechanism(mechanism: mechanism)
    }
    
    
    //  MARK: - Notification
    
    /// Retrieves an array of PushNotification objects that is associated with given PushMechanism
    /// - Parameter mechanism: PushMechanism object to retrieve all notifications
    /// - Returns: An array of PushNotification that given PushMechanism received
    public func getAllNotifications(mechanism: PushMechanism) -> [PushNotification] {
        return self.authenticatorManager.getAllNotifications(mechanism: mechanism)
    }
    
    
    /// Retrieves an array of PushNotification objects across all PushMechanisms
    /// - Parameter mechanism: PushMechanism object to retrieve all notifications
    /// - Returns: An array of PushNotification
    public func getAllNotifications() -> [PushNotification] {
        return self.authenticatorManager.getAllNotifications()
    }
    
    
    /// Retrieves PushNotification object with given PushNotification Identifier; Identifier of PushNotification object is **"<mechanismUUID>-<timeAdded>"**
    /// - Parameter identifier: String value of PushNotification object's identifier as in **"<mechanismUUID>-<timeAdded>"**
    /// - Returns: PushNotification object with given identifier
    public func getNotification(identifier: String) -> PushNotification? {
        return self.authenticatorManager.getNotification(identifier: identifier)
    }
    
    
    /// Removes PushNotification object from StorageClient
    /// - Parameter notification: PushNotification object to be removed
    /// - Returns: boolean result of operation
    @discardableResult public func removeNotification(notification: PushNotification) -> Bool {
        return self.authenticatorManager.removeNotification(notification: notification)
    }
    
    
    //  MARK: - QRCode parsing
    
    /// Parses given QR Code URL into Account, and Mechanism object, and stores them into StorageClient if saving both Account and Mechanism objects was successful. If Account already exists, and QR Code is storing new Mechanism object, SDK only stores Mechanism object, and ignores Account object
    /// - Parameters:
    ///   - uri: URL of QR Code
    ///   - onSuccess: success completion callback with Mechanism
    ///   - onError: failure callback with Error
    public func createMechanismFromUri(uri: URL, onSuccess: @escaping MechanismCallback, onError: @escaping ErrorCallback) {
        self.authenticatorManager.createMechanismFromUri(uri: uri, onSuccess: onSuccess, onError: onError)
    }
}
