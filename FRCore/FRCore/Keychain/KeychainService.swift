//
//  KeychainService.swift
//  FRCore
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import Security

/// KeychainService class represents and is responsible internal Keychain Service operation such as storing, retrieving, and deleting String/Bool/Data/Certificate/Key/Identity data with Apple's Keychain Service
public struct KeychainService {
    
    // MARK: - Property
    
    /// Options for Keychain Service operation
    fileprivate var options: KeychainOptions
    /// SecuredKey used for encryption/decryption of data in Keychain Service
    fileprivate var securedKey: SecuredKey?
    
    /// Prints debug, human readable, and meaningful information of Keychain Service instance
    public var debugDescription: String {
        var description = "[KeychainService] - Service Name: \(self.options.service)"
        if let accessGroup = self.options.accessGroup {
            description += " | Access Group: \(accessGroup)"
        }
        description += " | Accessibility: \(self.options.accessibility.description)\n"
        
        guard let items = self.getAllItems() else {
            return description + ""
        }
        let allItems = self.stringify(items) as AnyObject
        return description + "Items: \n\(allItems)"
    }
    
    
    // MARK: - Init
    
    /// Initializes Keychain Service with Service namespace
    ///
    /// - Parameter service: Service string value which represents namespace for Keychain Storage
    /// - Parameter securedKey: SecuredKey object containing public/private keys for encryption/decryption of data
    public init(service: String, securedKey: SecuredKey? = nil) {
        Log.v("Called - service: \(service)")
        self.options = KeychainOptions(service: service)
        self.securedKey = securedKey
    }
    
    
    /// Initializes Keychain Service with given KeychainOption
    ///
    /// - Parameter options: KeychainOption that defines Keychain Operation's default settings
    /// - Parameter securedKey: SecuredKey object containing public/private keys for encryption/decryption of data
    public init(options: KeychainOptions, securedKey: SecuredKey? = nil) {
        Log.v("Called - options: \(options)")
        self.options = options
        self.securedKey = securedKey
    }
    
    
    /// Initializes Keychain Service with Service, and Access Group identifier
    ///
    /// - Parameters:
    ///   - service: Service string value which represents namespace for Keychain Storage
    ///   - accessGroup: Shared Keychain Group identifier which is defined in XCode's Keychain Sharing option under Capabilities tab. AccessGroup can be given with or without Apple's TeamID. Initialization method internally validates, and adds if Apple TeamID is missing. **Note** that this initialization method will NOT validate if AccessGroup is actually accessible or not. KeychainService.validateAccessGroup should be invoked to validate application's access to the access group.
    /// - Parameter securedKey: SecuredKey object containing public/private keys for encryption/decryption of data   
    public init(service: String, accessGroup: String, securedKey: SecuredKey? = nil) {
        Log.v("Called - service: \(service), accessGroup: \(accessGroup)")
        self.options = KeychainOptions(service: service, accessGroup: accessGroup)
        self.securedKey = securedKey
    }
    
    
    // MARK: - String
    
    /// Sets String data into Keychain Service with given Key
    ///
    /// - Parameters:
    ///   - val: String value to store
    ///   - key: Key for the value
    /// - Returns: Bool value that indicates whether operation was successful or not
    @discardableResult public func set(_ val: String?, key: String) -> Bool {
        if let value = val {
            return self.set(value, key: key, itemClass: self.options.defaultClass)
        }
        else {
            return false
        }
    }
    
    
    /// Sets String data into Keychain Service with given key, and KeychainItemClass
    ///
    /// - Parameters:
    ///   - val: String value to store
    ///   - key: Key for the value
    ///   - itemClass: KeychainItemClass enum value indicating what type of SecItemClass that this data to be stored
    /// - Returns: Bool value that indicates whether operation was successful or not
    @discardableResult func set(_ val: String, key: String, itemClass: KeychainItemClass) -> Bool {
        if let valData = val.data(using: String.Encoding.utf8) {
            return self.set(valData, key: key, itemClass: itemClass)
        }
        return false
    }
    
    
    /// Retrieves String data from Keychain Service with given key
    ///
    /// - Parameter key: Key for the value
    /// - Returns: String value for the given key; if no data is found, null is returned
    public func getString(_ key: String) -> String? {
        return self.getString(key, itemClass: self.options.defaultClass)
    }
    
    
    /// Retrieves String data from Keychain Service with given key, and KeychainItemClass
    ///
    /// - Parameters:
    ///   - key: Key for the value
    ///   - itemClass: KeychainItemClass enum value indicating what type of SecItemClass that this data to be retrieved
    /// - Returns: String value for the given key and KeychainItemClass; if no data is found, null is returned
    func getString(_ key: String, itemClass: KeychainItemClass) -> String? {
        if let data = self.getData(key, itemClass: itemClass) {
            if let str = String(data: data, encoding: .utf8) {
                return str
            }
        }
        return nil
    }
    
    
    // MARK: - Bool
    
    /// Sets Bool value into Keychain Service with given key
    ///
    /// - Parameters:
    ///   - val: Bool value to store
    ///   - key: Key for the value
    /// - Returns: Bool value indicating whether operation was successful or not
    @discardableResult public func set(_ val: Bool, key: String) -> Bool {
        return self.set(val, key: key, itemClass: self.options.defaultClass)
    }
    
    
    /// Sets Bool value into Keychain Service with given key, and KeychainItemClass
    ///
    /// - Parameters:
    ///   - val: Bool value to store
    ///   - key: Key for the value
    ///   - itemClass: KeychainItemClass enum value indicating what type of SecItemClass that this data to be stored
    /// - Returns: Bool value indicating whether operation was successful or not
    @discardableResult func set(_ val: Bool, key: String, itemClass: KeychainItemClass) -> Bool {
        let bytes: [UInt8] = val ? [1] : [0]
        return self.set(Data(bytes), key: key, itemClass: itemClass)
    }
    
    
    /// Retrieves Bool data from Keychain Service with given key
    ///
    /// - Parameter key: Key for the value
    /// - Returns: Bool data for the given key; if no data is found, null is returned
    public func getBool(_ key: String) -> Bool? {
        return self.getBool(key, itemClass: self.options.defaultClass)
    }
    
    
    /// Retrieves Bool data from Keychain Service with given key, and KeychainItemClass
    ///
    /// - Parameters:
    ///   - key: Key for the value
    ///   - itemClass: KeychainItemClass enum value indicating what type of SecItemClass that this data to be retrieved
    /// - Returns: Bool data for the given key and KeychainItemClass; if no data is found, null is returned
    func getBool(_ key: String, itemClass: KeychainItemClass) -> Bool? {
        if let data = self.getData(key, itemClass: itemClass), let bit = data.first {
            return bit == 1
        }
        return nil
    }
    
    
    // MARK: - Data
    
    /// Sets Data value into Keychain Service with given key
    ///
    /// - Parameters:
    ///   - val: Data value to store
    ///   - key: Key for the value
    /// - Returns: Bool value indicating whether operation was successful or not
    @discardableResult public func set(_ val: Data, key: String) -> Bool {
        return self.set(val, key: key, itemClass: self.options.defaultClass)
    }
    
    
    /// Sets Data value into Keychain Service with given key, and KeychainItemClass
    ///
    /// - Parameters:
    ///   - val: Data value to store
    ///   - key: Key for the value
    ///   - itemClass: KeychainItemClass enum value indicating what type of SecItemClass that this data to be stored
    /// - Returns: Bool value indicating whether operation was successful or not
    @discardableResult func set(_ val: Data, key: String, itemClass: KeychainItemClass) -> Bool {
                
        // Check if item with the same key exists
        var checkQuery = self.options.buildQuery(itemClass)
        checkQuery[SecKeys.account.rawValue] = key
        let checkStatus = SecItemCopyMatching(checkQuery as CFDictionary, nil)
        
        if checkStatus == errSecSuccess || checkStatus == errSecInteractionNotAllowed {
            // If item already exists, delete the item, and save new data
            var deleteQuery = self.options.buildQuery(itemClass)
            deleteQuery[SecKeys.account.rawValue] = key
            let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)
            
            if deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound {
                // If deleting old item was successful, add the item
                var query = self.options.buildQuery(itemClass)
                query[SecKeys.account.rawValue] = key
                
                if let securedKey = self.securedKey, let encryptedData = securedKey.encrypt(data: val) {
                    query[SecKeys.valueData.rawValue] = encryptedData
                }
                else {
                    query[SecKeys.valueData.rawValue] = val
                }
                
                let status = SecItemAdd(query as CFDictionary, nil)
                return status == noErr
            }
            else {
                // If deleting old item failed, return false
                return false
            }
        }
        else if checkStatus == errSecItemNotFound {
            // If no item was found, simply create new data
            var query = self.options.buildQuery(itemClass)
            query[SecKeys.account.rawValue] = key
            
            if let securedKey = self.securedKey, let encryptedData = securedKey.encrypt(data: val) {
                query[SecKeys.valueData.rawValue] = encryptedData
            }
            else {
                query[SecKeys.valueData.rawValue] = val
            }
            
            let status = SecItemAdd(query as CFDictionary, nil)
            return status == noErr
        } else {
            // If any other error was returned, return false
            return false
        }
    }
    
    
    /// Retrieves Data data from Keychain Service with given key
    ///
    /// - Parameter key: Key for the value
    /// - Returns: Data data for the given key and KeychainItemClass; if no data is found, null is returned
    public func getData(_ key: String) -> Data? {
        return self.getData(key, itemClass: self.options.defaultClass)
    }
    
    
    /// Retrieves Data object from Keychain Service with given key and KeychainItemClass
    ///
    /// - Parameters:
    ///   - key: Key for the value
    ///   - itemClass: KeychainItemClass enum value indicating what type of SecItemClass that this data to be stored
    /// - Returns: Data data for the given key and KeychainItemClass; if no data is found, null is returned
    func getData(_ key: String, itemClass: KeychainItemClass) -> Data? {
        
        var query = self.options.buildQuery(itemClass)
        
        query[SecKeys.returnData.rawValue] = true
        query[SecKeys.matchLimit.rawValue] = self.options.matchLimit
        query[SecKeys.account.rawValue] = key
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == noErr {
            if let securedKey = self.securedKey, let returnedData = result as? Data, let decryptedData = securedKey.decrypt(data: returnedData) {
                return decryptedData
            }
            else {
                return result as? Data
            }
        }
        
        return nil
    }
    
    
    // MARK: - Certificate
    
    /// Sets SecCertificate data into Keychain Service with given 'label' (similar to Key)
    ///
    /// - Parameters:
    ///   - certificate: SecCertificate data to store
    ///   - label: Label string value for the certificate
    /// - Returns: Bool value indicating whether operation was successful or not
    @discardableResult public func setCertificate(_ certificate: SecCertificate, label: String) -> Bool {
        
        // Check if item with the same label exists
        var checkQuery = self.options.buildQuery(.certificate)
        checkQuery[SecKeys.label.rawValue] = label
        let checkStatus = SecItemCopyMatching(checkQuery as CFDictionary, nil)
        
        if checkStatus == errSecSuccess || checkStatus == errSecInteractionNotAllowed {
            // If item already exists, delete the item, and save new data
            var deleteQuery = self.options.buildQuery(.certificate)
            deleteQuery[SecKeys.label.rawValue] = label
            let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)
            
            if deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound {
                // If deleting old item was successful, add the item
                var query = self.options.buildQuery(.certificate)
                query[SecKeys.label.rawValue] = label
                query[SecKeys.valueRef.rawValue] = certificate
                
                let status = SecItemAdd(query as CFDictionary, nil)
                return status == noErr
            }
            else {
                // If deleting old item failed, return false
                return false
            }
        }
        else if checkStatus == errSecItemNotFound {
            // If no item was found, simply create new data
            var query = self.options.buildQuery(.certificate)
            query[SecKeys.label.rawValue] = label
            query[SecKeys.valueRef.rawValue] = certificate
            
            let status = SecItemAdd(query as CFDictionary, nil)
            return status == noErr
        } else {
            // If any other error was returned, return false
            return false
        }
    }
    
    
    /// Retrieves SecCertificate data from Keychain Service with given Label
    ///
    /// - Parameter label: Label value for the certificate
    /// - Returns: SecCertificate with given label value; if no certificate is found, null will be returned
    public func getCertificate(_ label: String) -> SecCertificate? {
        
        var query = self.options.buildQuery(.certificate)
        query[SecKeys.label.rawValue] = label
        query[SecKeys.returnRef.rawValue] = true
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == noErr {
            return (result as! SecCertificate)
        }
        
        return nil
    }
    
    
    // MARK: - Identity
    
    /// Retrieves SecIdentity data with given 'label' for **SecCertificate** stored in the same Keychain Service
    ///
    /// - NOTE: SecIdentity is not a data stored directly with actual Identity data; SecIdentity is a data created by Apple's Security framework with combination of SecCertificate, and associated Private Key for the Certificate.
    /// - SEEALSO: https://developer.apple.com/documentation/security/secidentity
    ///
    /// - Parameter label: Label value for the **certificate**; Note that there is no label or key for identity itself; SecIdentity is retrieved based on SecCertificate's label
    /// - Returns: SecIdentity with given SecCertificate's label; if private key associated with given certificate's label, or incorrect key is stored, SecIdentity will not be retrieved and return null
    public func getIdentities(_ label: String) -> SecIdentity? {
        
        var query = self.options.buildQuery(.identity)
        query[SecKeys.label.rawValue] = label
        query[SecKeys.returnRef.rawValue] = true
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == noErr {
            return (result as! SecIdentity)
        }
        
        return nil
    }
    
    
    // MARK: - Key
    
    /// Sets SecKey data into Keychain Service with given Application Tag
    ///
    /// - Parameters:
    ///   - rsaKey: SecKey data to store
    ///   - applicationTag: Application Tag for the SecKey
    /// - Returns: Bool value indicating whether operation was successful or not
    @discardableResult public func setRSAKey(_ rsaKey: SecKey, applicationTag: String) -> Bool {
        
        // Check if item with the same key exists
        var checkQuery = self.options.buildQuery(.key)
        checkQuery[SecKeys.applcationTag.rawValue] = applicationTag
        let checkStatus = SecItemCopyMatching(checkQuery as CFDictionary, nil)
        
        if checkStatus == errSecSuccess || checkStatus == errSecInteractionNotAllowed {
            // If item already exists, delete the item, and save new data
            var deleteQuery = self.options.buildQuery(.key)
            deleteQuery[SecKeys.applcationTag.rawValue] = applicationTag
            let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)
            
            if deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound {
                // If deleting old item was successful, add the item
                var query = self.options.buildQuery(.key)
                query[SecKeys.applcationTag.rawValue] = applicationTag
                query[SecKeys.valueRef.rawValue] = rsaKey
                
                let status = SecItemAdd(query as CFDictionary, nil)
                return status == noErr
            }
            else {
                // If deleting old item failed, return false
                return false
            }
        }
        else if checkStatus == errSecItemNotFound {
            // If no item was found, simply create new data
            var query = self.options.buildQuery(.key)
            query[SecKeys.applcationTag.rawValue] = applicationTag
            query[SecKeys.valueRef.rawValue] = rsaKey
            
            let status = SecItemAdd(query as CFDictionary, nil)
            return status == noErr
        } else {
            // If any other error was returned, return false
            return false
        }
    }

    
    /// Retrieves SecKey data from Keychain Service with given Application Tag
    ///
    /// - Parameter applicationTag: Application Tag string for the SecKey
    /// - Returns: SecKey with given application tag value; if no key is found, null will be returned
    public func getRSAKey(_ applicationTag: String) -> SecKey? {
        
        var query = self.options.buildQuery(.key)
        query[SecKeys.applcationTag.rawValue] = applicationTag
        query[SecKeys.returnRef.rawValue] = true
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == noErr {
            return (result as! SecKey)
        }
        
        return nil
    }
    
    
    // MARK: - All Items
    
    /// Retrieves all items with key/applicationTag/label:value map;
    ///
    /// - Returns: Key/Value map Dictionary for all data
    public func allItems() -> [String: Any]? {
        if let allItems = self.getAllItems() {
            return self.simplifyItems(allItems)
        }
        return nil
    }
    
    
    /// Retrieves all items with all information in Keychain Service
    ///
    /// - Returns: Array of Dictionary conatining detailed information for each data
    fileprivate func getAllItems() -> [[String: Any]]? {
        
        let secItemClasses = KeychainItemClass.allClasses
        
        var returnItems: [[String: Any]] = []
        for itemClass in secItemClasses {
            
            var query = self.options.buildQuery(itemClass)
            query[SecKeys.matchLimit.rawValue] = SecKeys.matchLimitAll.rawValue
            query[SecKeys.returnAttr.rawValue] = true
            query[SecKeys.returnData.rawValue] = true
            
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            
            if status == noErr, let items = result as? [[String: Any]] {
                returnItems = returnItems + items
            }
        }
        
        return returnItems
    }

    
    // MARK: - DELETE
    
    /// Deletes Data with given key from Keychain Service
    ///
    /// - NOTE: When deleting SecKey / SecCertificate, please use delete method with KeychainItemClass option by specifying item class.
    ///
    /// - Parameter key: Key for the data in Keychain Service
    /// - Returns: Bool value indicating whether operation was successful or not
    @discardableResult public func delete(_ key: String) -> Bool {
        return self.delete(key, itemClass: self.options.defaultClass)
    }
    
    
    /// Delets Data with given key and KeychainItemClass from Keychain Service
    ///
    /// - Parameters:
    ///   - key: Key for the data to be deleted
    ///   - itemClass: KeychainItemClass enum value indicating what type of SecItemClass that this data to be stored
    /// - Returns: Bool value indicating whether operation was successful or not
    @discardableResult func delete(_ key: String, itemClass: KeychainItemClass) -> Bool {
        var query = self.options.buildQuery(itemClass)
        
        if itemClass == .genericPassword || itemClass == .internetPassword {
            // For .genericPassword, and .internetPassword, data is stored with Account attribute as key
            query[SecKeys.account.rawValue] = key
        } else if itemClass == .key {
            // For .key, data is stored with Application Tag attribute as key
            query[SecKeys.applcationTag.rawValue] = key
        } else if itemClass == .certificate {
            // For .certificate, data is stored with Label attribute as key
            query[SecKeys.label.rawValue] = key
        }
        // For .identity, an identity is a certificate paired with its associated private key in the keychain service, and it shares attributes of .certificate, and .key
        // Therefore, there is no need to delete, or handle .identity data
        
        let result = SecItemDelete(query as CFDictionary)
        return result == errSecSuccess || result == errSecItemNotFound
    }
    
    
    /// Deletes all data regardless of KeychainItemClass in the Keychain Service
    ///
    /// - Returns: Bool value indicating whether operation was successful or not
    @discardableResult public func deleteAll() -> Bool {
        
        let allClasses = KeychainItemClass.allClasses
        
        var anyResult = true
        
        for itemClass in allClasses {
            let query = self.options.buildQuery(itemClass)
            let result = SecItemDelete(query as CFDictionary)
            
            if anyResult {
                anyResult = result == errSecSuccess || result == errSecItemNotFound
            }
        }
        
        return anyResult
    }
    
    
    // MARK: - Utils
    
    /// Generates and returns simplified Dictionary of all items in Keychain Service as key:value map
    ///
    /// - Parameter items: Dictionary of raw / details information of each data in Keychain SErvice
    /// - Returns: Returns Dictionary of key/value map of all items in Keychain Service
    fileprivate func simplifyItems(_ items: [[String: Any]]) -> [String: Any] {
        
        var returnItems: [String: Any] = [:]
        
        for attr: [String: Any] in items {
            if let key = attr[SecKeys.account.rawValue] as? String, let data = attr[SecKeys.valueData.rawValue] as? Data {

                var returnedData = data
                if let securedKey = self.securedKey, let decryptedData = securedKey.decrypt(data: returnedData) {
                    returnedData = decryptedData
                }
                
                if let str = String(data: returnedData, encoding: .utf8) {
                    returnItems[key] = str
                }
                else {
                    returnItems[key] = returnedData
                }
            }
        }
        
        return returnItems
    }
    
    
    /// Simplifies, and generates debug, human readable, and meaningful description of each item in Keychain Service
    ///
    /// - Parameter items: Dictionary of raw / details information of each data in Keychain SErvice
    /// - Returns: Dictionary of details information with human readable description of each data in Keychain SErvice
    fileprivate func stringify(_ items: [[String: Any]]) -> [[String: Any]] {
        let items = items.map{ attr -> [String: Any] in
            var item = [String: Any]()
            
            // itemClass, and itemClass specific attributes
            if let service = attr[SecKeys.service.rawValue] as? String {
                item[SecKeys.service.description] = service
            }
            if let accessGroup = attr[SecKeys.accessGroup.rawValue] as? String {
                item[SecKeys.accessGroup.description] = accessGroup
            }

            // key
            if let key = attr[SecKeys.account.rawValue] as? String {
                item[SecKeys.account.description] = key
            }

            // Data
            if let data = attr[SecKeys.valueData.rawValue] as? Data {
                if let str = String(data: data, encoding: .utf8) {
                    item[SecKeys.valueData.description] = str
                }
                else {
                    item[SecKeys.valueData.description] = data
                }
            }
            
            // Accessibility
            if let accessibility = attr[SecKeys.accessible.rawValue] as? String {
                item[SecKeys.accessible.description] = accessibility
            }
            
            // Synchronizable
            if let sync = attr[SecKeys.synchronizable.rawValue] as? Bool {
                item[SecKeys.synchronizable.description] = sync
            }
            
            // Created / Modified Dates
            if let cDate = attr[SecKeys.createdDate.rawValue] {
                item[SecKeys.createdDate.description] = cDate
            }
            if let mDate = attr[SecKeys.modifiedDate.rawValue] {
                item[SecKeys.modifiedDate.description] = mDate
            }
            
            // Key/Certificate related attributes
            if let applicationTag = attr[SecKeys.applcationTag.rawValue] {
                item[SecKeys.applcationTag.description] = applicationTag
            }
            if let keyType = attr[SecKeys.keyType.rawValue] {
                item[SecKeys.keyType.description] = keyType
            }
            if let label = attr[SecKeys.label.rawValue] {
                item[SecKeys.label.description] = label
            }

            return item
        }

        return items
    }
    
    
    // MARK: - Static Helper Methods
    
    /// Validates whether Keychain Service is accessible (read/write/delete) data for given Service and Access Group
    ///
    /// - Parameters:
    ///   - service: Service namespace for Keychain Service
    ///   - accessGroup: Access Group (Shared Keychain Group Identifier) defined in Keychain Sharing under Capabilities tab
    /// - Returns: Bool result indicating whether Keychain Service is accessible with given Service namespace and Access Group
    public static func validateAccessGroup(service: String, accessGroup: String) -> Bool {
        
        var validatedAccessGroup = accessGroup
        if let appleTeamId = KeychainService.getAppleTeamId(), !accessGroup.hasPrefix(appleTeamId) {
            // If Apple TeamId prefix is found, and accessGroup provided doesn't contain, append it
            validatedAccessGroup = appleTeamId + "." + accessGroup
        }
        
        // Validate if dummy data can be added to Keychain Service with given Access Group
        let itemKey = "_forgercok_internal_keychain_" + service + accessGroup
        let itemData = "_forgercok_internal_keychain_".data(using: .utf8)
        
        var query: [String: Any] = [:]
        query[SecKeys.secClass.rawValue] = KeychainItemClass.genericPassword.rawValue
        query[SecKeys.service.rawValue] = service
        query[SecKeys.accessGroup.rawValue] = validatedAccessGroup
        query[SecKeys.account.rawValue] = itemKey
        query[SecKeys.valueData.rawValue] = itemData
        query[SecKeys.accessible.rawValue] = KeychainAccessibility.afterFirstUnlock.rawValue
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        // If dummy data was added, make sure to delete it
        if status == noErr {
            var query: [String: Any] = [:]
            query[SecKeys.secClass.rawValue] = KeychainItemClass.genericPassword.rawValue
            query[SecKeys.service.rawValue] = service
            query[SecKeys.accessGroup.rawValue] = validatedAccessGroup
            query[SecKeys.account.rawValue] = itemKey
            query[SecKeys.accessible.rawValue] = KeychainAccessibility.afterFirstUnlock.rawValue
            SecItemDelete(query as CFDictionary)
        }
        
        return status == noErr
    }
    
    
    /// Retrieves Apple's TeamID in the current application's Developer Program
    ///
    /// - Returns: String Apple TeamID
    public static func getAppleTeamId() -> String? {
        // Get Apple TeamId by retrieving dummy data from Keychain Service
        var query: [String: Any] = [:]
        let itemKey = "_forgercok_internal_keychain_bundleSeedId"
        query[SecKeys.secClass.rawValue] = KeychainItemClass.genericPassword.rawValue
        query[SecKeys.service.rawValue] = "com.forgerock.ios"
        query[SecKeys.account.rawValue] = itemKey
        query[SecKeys.returnAttr.rawValue] = true
        
        var result: AnyObject?
        var status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            // If dummy data is not found, add it
            status = SecItemAdd(query as CFDictionary, &result)
        } else if status != noErr {
            // If an error occurs while retrieving dummy data, return nil
            return nil
        }
        
        if let resultDict = result as? [String: Any], let accessGroup = resultDict[SecKeys.accessGroup.rawValue] as? String {
            // Parse the result, and find Access Group attribute, then split String with .
            let accessGroupComponent = accessGroup.components(separatedBy: ".")
            // If Access Group somehow returns only one or less segment, ignore
            if accessGroupComponent.count > 1 {
                return accessGroupComponent[0]
            }
        }
        return nil
    }
}

/// KeychainOptions represent available options for Keychain Service
public struct KeychainOptions {
    
    //  MARK: - Property
    
    /// Service name
    public var service: String = ""
    /// AccessGroup as defined in Capabilities tab in XCode project
    public var accessGroup: String?
    /// URL of designated storage
    public var url: URL?
    /// Boolean indicator whether the keychain data should be synchronized with iCloud
    public var synchronizable: Bool = false
    /// Default Accessibility flag
    public var accessibility: KeychainAccessibility = .afterFirstUnlock
    /// Default SecKeyItemClass
    var defaultClass: KeychainItemClass
    /// Default match limit
    public var matchLimit: String = SecKeys.matchLimitOne.rawValue
    
    
    //  MARK: - Init
    
    /// Initializes KeychainOptions with given Service namespace
    ///
    /// - Parameter service: Service namespace value as String
    public init(service: String) {
        self.service = service
        self.defaultClass = .genericPassword
    }
    
    
    /// Initializes KeychainOptions with given Service namespace and AccessGroup
    ///
    /// - Parameters:
    ///   - service: Service namespace value as String
    ///   - accessGroup: Access Group value as defined in XCode's Shared Keychain section under Capabilities tab
    public init(service: String, accessGroup: String) {
        
        var validatedAccessGroup = accessGroup
        if let appleTeamId = KeychainService.getAppleTeamId(), !accessGroup.hasPrefix(appleTeamId) {
            // If Apple TeamId prefix is found, and accessGroup provided doesn't contain, append it
            validatedAccessGroup = appleTeamId + "." + accessGroup
        }
        Log.v("Keychain Access Group: \(validatedAccessGroup)")
        
        self.service = service
        self.accessGroup = validatedAccessGroup
        self.defaultClass = .genericPassword
    }
    
    
    /// Initializes KeychainOptions with given URL; designed for KeychainItemClass Internet Password
    ///
    /// - Parameter url: URL value for the internet password
    public init(url: URL) {
        self.url = url
        self.defaultClass = .internetPassword
    }
    
    
    //  MARK: - Build
    
    /// Builds default query dictionary with given KeychainItemClass
    ///
    /// - Parameter itemClass: KeychainItemClass for query builder
    /// - Returns: Dictionary containing default query parameter specifically for given KeychainItemClass
    func buildQuery(_ itemClass: KeychainItemClass?) -> [String: Any] {
        
        var query = [String: Any]()
        
        if let itemClass = itemClass {
            query[SecKeys.secClass.rawValue] = itemClass.rawValue
            query[SecKeys.accessible.rawValue] = self.accessibility.rawValue
            
            switch itemClass {
            case .genericPassword:
                query[SecKeys.service.rawValue] = self.service
                if let accessGroup = self.accessGroup {
                    query[SecKeys.accessGroup.rawValue] = accessGroup
                }
                break
            case .key:
                // REMARK: for iOS only
                query[SecKeys.keyType.rawValue] = String(kSecAttrKeyTypeRSA)
                break
            case .securedKey:
                query[SecKeys.keyType.rawValue] = String(kSecAttrKeyTypeEC)
                break
            default:
                // TODO: implement internet password protocol and other class
                break
            }
        }
        
        if self.synchronizable {
            query[SecKeys.synchronizable.rawValue] = self.synchronizable
        }
        
        return query
    }
}

fileprivate enum SecKeys: String {
    case account
    case service
    case accessGroup
    
    case accessible
    case returnData
    case valueData
    case valueRef
    case returnRef
    case returnAttr
    case synchronizable
    
    case matchLimit
    case matchLimitAll
    case matchLimitOne
    
    case secClass
    case itemGenericPassword
    case itemInternetPassword
    
    case createdDate
    case modifiedDate
    
    case applcationTag
    case keyType
    case keySizeInBits
    case label
    
    case tokenId
    case privateKeyAttr
    case accessControl
    case isPermanent
    
    var description: String {
        
        switch self {
        case .account:              return "Account"
        case .service:              return "Service"
        case .accessGroup:          return "Access Group"
            
        case .accessible:           return "Accessible"
        case .returnData:           return "Return Data"
        case .valueData:            return "Data"
        case .valueRef:             return "Value Reference"
        case .returnRef:            return "Return as reference"
        case .returnAttr:           return "Return Attribute"
        case .synchronizable:       return "Synchronizable"
            
        case .matchLimit:           return "Match Limit"
        case .matchLimitAll:        return "Match All"
        case .matchLimitOne:        return "Match One"
            
        case .secClass:             return "SecClass"
        case .itemInternetPassword: return "Internet Password"
        case .itemGenericPassword:  return "Generic Password"
            
        case .createdDate:          return "Created Date"
        case .modifiedDate:         return "Modified Date"
            
        case .applcationTag:        return "Application Tag"
        case .keyType:              return "Key Type"
        case .keySizeInBits:        return "Key Size in bits"
        case .label:                return "Label"
            
        case .tokenId:              return "Token ID"
        case .privateKeyAttr:       return "Private Key Attributes"
        case .accessControl:        return "Access Control"
        case .isPermanent:          return "isPermanent"
        }
    }
    
    var rawValue: String {
        switch self {
        case .account:              return String(kSecAttrAccount)
        case .service:              return String(kSecAttrService)
        case .accessGroup:          return String(kSecAttrAccessGroup)
            
        case .accessible:           return String(kSecAttrAccessible)
        case .returnData:           return String(kSecReturnData)
        case .valueData:            return String(kSecValueData)
        case .valueRef:             return String(kSecValueRef)
        case .returnRef:            return String(kSecReturnRef)
        case .returnAttr:           return String(kSecReturnAttributes)
        case .synchronizable:       return String(kSecAttrSynchronizable)
            
        case .matchLimit:           return String(kSecMatchLimit)
        case .matchLimitAll:        return String(kSecMatchLimitAll)
        case .matchLimitOne:        return String(kSecMatchLimitOne)
            
        case .secClass:             return String(kSecClass)
        case .itemInternetPassword: return String(kSecClassGenericPassword)
        case .itemGenericPassword:  return String(kSecClassInternetPassword)
            
        case .createdDate:          return String(kSecAttrCreationDate)
        case .modifiedDate:         return String(kSecAttrModificationDate)
            
        case .applcationTag:        return String(kSecAttrApplicationTag)
        case .keyType:              return String(kSecAttrKeyType)
        case .keySizeInBits:        return String(kSecAttrKeySizeInBits)
        case .label:                return String(kSecAttrLabel)
            
        case .tokenId:              return String(kSecAttrTokenID)
        case .privateKeyAttr:       return String(kSecPrivateKeyAttrs)
        case .accessControl:        return String(kSecAttrAccessControl)
        case .isPermanent:          return String(kSecAttrIsPermanent)
        }
    }
}

/// KeychainAccessibility represents Accessibility value for Keychain Service
public enum KeychainAccessibility: String {
    case afterFirstUnlock
    case afterFirstUnlockThisDeviceOnly
    case whenUnlocked
    case whenUnlockedThisDeviceOnly
    case whenPasscodeSetThisDeviceOnly
    case alwaysThisDeviceOnly
    
    public var description: String {
        switch self {
        case .afterFirstUnlock:
            return "kSecAttrAccessibleAfterFirstUnlock"
        case .afterFirstUnlockThisDeviceOnly:
            return "kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly"
        case .whenUnlocked:
            return "kSecAttrAccessibleWhenUnlocked"
        case .whenUnlockedThisDeviceOnly:
            return "kSecAttrAccessibleWhenUnlockedThisDeviceOnly"
        case .whenPasscodeSetThisDeviceOnly:
            return "kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly"
        case .alwaysThisDeviceOnly:
            return "kSecAttrAccessibleAlwaysThisDeviceOnly"
        }
    }
    
    public var rawValue: String {
        switch self {
        case .afterFirstUnlock:
            return String(kSecAttrAccessibleAfterFirstUnlock)
        case .afterFirstUnlockThisDeviceOnly:
            return String(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
        case .whenUnlocked:
            return String(kSecAttrAccessibleWhenUnlocked)
        case .whenUnlockedThisDeviceOnly:
            return String(kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
        case .whenPasscodeSetThisDeviceOnly:
            return String(kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly)
        case .alwaysThisDeviceOnly:
            return String(kSecAttrAccessibleAlwaysThisDeviceOnly)
        }
    }
}

/// KeychainItemClass represents SecClass value
enum KeychainItemClass: String {
    case genericPassword
    case internetPassword
    case certificate
    case key
    case securedKey
    case identity
    case all
    
    var rawValue: String {
        switch self {
        case .genericPassword:
            return String(kSecClassGenericPassword)
        case .internetPassword:
            return String(kSecClassInternetPassword)
        case .certificate:
            return String(kSecClassCertificate)
        case .key:
            return String(kSecClassKey)
        case .securedKey:
            return String(kSecClassKey)
        case .identity:
            return String(kSecClassIdentity)
        default:
            return "";
        }
    }
    
    static var allClasses: [KeychainItemClass] {
        return [.genericPassword, .internetPassword, .certificate, .key, .identity]
    }
}
