//
//  KeychainManagerTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRCore
@testable import FRAuth

class KeychainManagerTests: FRAuthBaseTest {
    
    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    
    func test_01_basic_initialization_test() {
        
        guard let serverConfig = self.config.serverConfig, let configJSON = self.config.configJSON, let accessGroup = configJSON["forgerock_keychain_access_group"] as? String else {
            XCTFail("Failed to read config object")
            return
        }
        
        do {
            let keychainManager = try KeychainManager(baseUrl: serverConfig.baseURL.absoluteString + "/" + serverConfig.realm)

            XCTAssertNotNil(keychainManager)
            XCTAssertNotNil(keychainManager?.privateStore)
            XCTAssertNotNil(keychainManager?.sharedStore)
            XCTAssertNotNil(keychainManager?.cookieStore)
            XCTAssertNotNil(keychainManager?.primaryServiceStore)
            XCTAssertNotNil(keychainManager?.deviceIdentifierStore)
            
            
            let keychainManager2 = try KeychainManager(baseUrl: serverConfig.baseURL.absoluteString + "/" + serverConfig.realm, accessGroup: accessGroup)

            XCTAssertNotNil(keychainManager2)
            XCTAssertNotNil(keychainManager2?.privateStore)
            XCTAssertNotNil(keychainManager2?.sharedStore)
            XCTAssertNotNil(keychainManager2?.cookieStore)
            XCTAssertNotNil(keychainManager2?.primaryServiceStore)
            XCTAssertNotNil(keychainManager2?.deviceIdentifierStore)
        }
        catch {
            XCTFail("Failed to construct KeychainManager: \(error.localizedDescription)")
        }
    }
    
    
    func test_02_initialization_with_invalidAccessGroup() {
        
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to read config object")
            return
        }
        
        do {
            let keychainManager = try KeychainManager(baseUrl: serverConfig.baseURL.absoluteString + "/" + serverConfig.realm, accessGroup: "invalid_access_group")
            XCTFail("KeychainManager was initialized with invalid AccessGroup: \(String(describing: keychainManager))")
        }
        catch {
        }
    }
    
    
    func test_03_basic_storage_test() {
        
        var keychainManager: KeychainManager? = nil
        guard let serverConfig = self.config.serverConfig, let configJSON = self.config.configJSON, let accessGroup = configJSON["forgerock_keychain_access_group"] as? String else {
            XCTFail("Failed to read config object")
            return
        }

        do {
            keychainManager = try KeychainManager(baseUrl: serverConfig.baseURL.absoluteString + "/" + serverConfig.realm, accessGroup: accessGroup)

            XCTAssertNotNil(keychainManager)
            XCTAssertNotNil(keychainManager?.privateStore)
            XCTAssertNotNil(keychainManager?.sharedStore)
            XCTAssertNotNil(keychainManager?.cookieStore)
            XCTAssertNotNil(keychainManager?.primaryServiceStore)
            XCTAssertNotNil(keychainManager?.deviceIdentifierStore)
        }
        catch {
            XCTFail("Failed to construct KeychainManager: \(error.localizedDescription)")
        }
        
        keychainManager?.privateStore.set("test_data", key: "test_key")
        keychainManager?.sharedStore.set("test_data", key: "test_key")
        keychainManager?.cookieStore.set("test_data", key: "test_key")
        
        XCTAssertEqual(keychainManager?.privateStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager?.sharedStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager?.cookieStore.allItems()?.count, 1)
        
        XCTAssertEqual(keychainManager?.privateStore.getString("test_key"), "test_data")
        XCTAssertEqual(keychainManager?.sharedStore.getString("test_key"), "test_data")
        XCTAssertEqual(keychainManager?.cookieStore.getString("test_key"), "test_data")
        
        // Should not clean up session for next test
        self.shouldCleanup = false
    }
    
    func test_04_persisting_data_from_previous_test() {
        
        var keychainManager: KeychainManager? = nil
        guard let serverConfig = self.config.serverConfig, let configJSON = self.config.configJSON, let accessGroup = configJSON["forgerock_keychain_access_group"] as? String else {
            XCTFail("Failed to read config object")
            return
        }

        do {
            keychainManager = try KeychainManager(baseUrl: serverConfig.baseURL.absoluteString + "/" + serverConfig.realm, accessGroup: accessGroup)

            XCTAssertNotNil(keychainManager)
            XCTAssertNotNil(keychainManager?.privateStore)
            XCTAssertNotNil(keychainManager?.sharedStore)
            XCTAssertNotNil(keychainManager?.cookieStore)
            XCTAssertNotNil(keychainManager?.primaryServiceStore)
            XCTAssertNotNil(keychainManager?.deviceIdentifierStore)
        }
        catch {
            XCTFail("Failed to construct KeychainManager: \(error.localizedDescription)")
        }
        
        XCTAssertEqual(keychainManager?.privateStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager?.sharedStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager?.cookieStore.allItems()?.count, 1)
        
        XCTAssertEqual(keychainManager?.privateStore.getString("test_key"), "test_data")
        XCTAssertEqual(keychainManager?.sharedStore.getString("test_key"), "test_data")
        XCTAssertEqual(keychainManager?.cookieStore.getString("test_key"), "test_data")
    }
    
    
    func test_05_validating_base_url_changed() {
        var keychainManager: KeychainManager? = nil
        guard let serverConfig = self.config.serverConfig, let configJSON = self.config.configJSON, let accessGroup = configJSON["forgerock_keychain_access_group"] as? String else {
            XCTFail("Failed to read config object")
            return
        }

        do {
            keychainManager = try KeychainManager(baseUrl: serverConfig.baseURL.absoluteString + "/" + serverConfig.realm, accessGroup: accessGroup)

            XCTAssertNotNil(keychainManager)
            XCTAssertNotNil(keychainManager?.privateStore)
            XCTAssertNotNil(keychainManager?.sharedStore)
            XCTAssertNotNil(keychainManager?.cookieStore)
            XCTAssertNotNil(keychainManager?.primaryServiceStore)
            XCTAssertNotNil(keychainManager?.deviceIdentifierStore)
        }
        catch {
            XCTFail("Failed to construct KeychainManager: \(error.localizedDescription)")
        }
        
        keychainManager?.privateStore.set("test_data", key: "test_key")
        keychainManager?.sharedStore.set("test_data", key: "test_key")
        keychainManager?.cookieStore.set("test_data", key: "test_key")
        
        XCTAssertEqual(keychainManager?.privateStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager?.sharedStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager?.cookieStore.allItems()?.count, 1)
        
        XCTAssertEqual(keychainManager?.privateStore.getString("test_key"), "test_data")
        XCTAssertEqual(keychainManager?.sharedStore.getString("test_key"), "test_data")
        XCTAssertEqual(keychainManager?.cookieStore.getString("test_key"), "test_data")
        
        
        do {
            keychainManager = try KeychainManager(baseUrl: "http://localhost:8888/openam" + "/" + serverConfig.realm, accessGroup: accessGroup)

            XCTAssertNotNil(keychainManager)
            XCTAssertNotNil(keychainManager?.privateStore)
            XCTAssertNotNil(keychainManager?.sharedStore)
            XCTAssertNotNil(keychainManager?.cookieStore)
            XCTAssertNotNil(keychainManager?.primaryServiceStore)
            XCTAssertNotNil(keychainManager?.deviceIdentifierStore)
        }
        catch {
            XCTFail("Failed to construct KeychainManager: \(error.localizedDescription)")
        }
                
        XCTAssertEqual(keychainManager?.privateStore.allItems()?.count, 0)
        XCTAssertEqual(keychainManager?.sharedStore.allItems()?.count, 0)
        XCTAssertEqual(keychainManager?.cookieStore.allItems()?.count, 0)
        
        XCTAssertNil(keychainManager?.privateStore.getString("test_key"))
        XCTAssertNil(keychainManager?.sharedStore.getString("test_key"))
        XCTAssertNil(keychainManager?.cookieStore.getString("test_key"))
    }
    
    
    func test_06_validating_device_identifier_upon_base_url_changed() {
        
        // Given previous test of authenticating, and persisting FRUser
        self.startSDK()
        guard let keychainManagerFromConfig = self.config.keychainManager else {
            XCTFail("Failed to read KeychainManager object upon SDK initialization")
            return
        }
        var keychainManager: KeychainManager = keychainManagerFromConfig
        
        
        keychainManager.privateStore.set("test_data", key: "test_key")
        keychainManager.sharedStore.set("test_data", key: "test_key")
        keychainManager.cookieStore.set("test_data", key: "test_key")
        
        XCTAssertEqual(keychainManager.privateStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager.sharedStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager.cookieStore.allItems()?.count, 1)
        
        XCTAssertEqual(keychainManager.privateStore.getString("test_key"), "test_data")
        XCTAssertEqual(keychainManager.sharedStore.getString("test_key"), "test_data")
        XCTAssertEqual(keychainManager.cookieStore.getString("test_key"), "test_data")
        
        guard let serverConfig = self.config.serverConfig, let configJSON = self.config.configJSON, let accessGroup = configJSON["forgerock_keychain_access_group"] as? String else {
            XCTFail("Failed to read config object")
            return
        }

        do {
            keychainManager = try KeychainManager(baseUrl: serverConfig.baseURL.absoluteString + "/" + serverConfig.realm, accessGroup: accessGroup)!

            XCTAssertNotNil(keychainManager)
            XCTAssertNotNil(keychainManager.privateStore)
            XCTAssertNotNil(keychainManager.sharedStore)
            XCTAssertNotNil(keychainManager.cookieStore)
            XCTAssertNotNil(keychainManager.primaryServiceStore)
            XCTAssertNotNil(keychainManager.deviceIdentifierStore)
        }
        catch {
            XCTFail("Failed to construct KeychainManager: \(error.localizedDescription)")
        }
        
        let deviceIdentifier = FRDevice.currentDevice?.identifier.getIdentifier()
        
        XCTAssertEqual(keychainManager.privateStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager.sharedStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager.cookieStore.allItems()?.count, 1)
        
        XCTAssertEqual(keychainManager.privateStore.getString("test_key"), "test_data")
        XCTAssertEqual(keychainManager.sharedStore.getString("test_key"), "test_data")
        XCTAssertEqual(keychainManager.cookieStore.getString("test_key"), "test_data")
        XCTAssertNotNil(keychainManager.deviceIdentifierStore.getString("com.forgerock.ios.device-identifier.hash-base64-string-identifier"))
        XCTAssertEqual(deviceIdentifier, keychainManager.deviceIdentifierStore.getString("com.forgerock.ios.device-identifier.hash-base64-string-identifier"))
        
        do {
            keychainManager = try KeychainManager(baseUrl: "http://localhost:8888/openam" + "/" + serverConfig.realm, accessGroup: accessGroup)!

            XCTAssertNotNil(keychainManager)
            XCTAssertNotNil(keychainManager.privateStore)
            XCTAssertNotNil(keychainManager.sharedStore)
            XCTAssertNotNil(keychainManager.cookieStore)
            XCTAssertNotNil(keychainManager.primaryServiceStore)
            XCTAssertNotNil(keychainManager.deviceIdentifierStore)
        }
        catch {
            XCTFail("Failed to construct KeychainManager: \(error.localizedDescription)")
        }
                
        XCTAssertEqual(keychainManager.privateStore.allItems()?.count, 0)
        XCTAssertEqual(keychainManager.sharedStore.allItems()?.count, 0)
        XCTAssertEqual(keychainManager.cookieStore.allItems()?.count, 0)
        
        XCTAssertNil(keychainManager.privateStore.getString("test_key"))
        XCTAssertNil(keychainManager.sharedStore.getString("test_key"))
        XCTAssertNil(keychainManager.cookieStore.getString("test_key"))
        XCTAssertEqual(deviceIdentifier, keychainManager.deviceIdentifierStore.getString("com.forgerock.ios.device-identifier.hash-base64-string-identifier"))
    }
    
    
    func test_07_validate_KeychainManager_from_without_securedKey_to_with_securedKey() {
        
        var keychainManager: KeychainManager? = nil
        guard let serverConfig = self.config.serverConfig, let configJSON = self.config.configJSON, let accessGroup = configJSON["forgerock_keychain_access_group"] as? String else {
            XCTFail("Failed to read config object")
            return
        }

        do {
            keychainManager = try KeychainManager(baseUrl: serverConfig.baseURL.absoluteString + "/" + serverConfig.realm, accessGroup: accessGroup)
            keychainManager?.securedKey = nil
            keychainManager?.validateEncryption()
            XCTAssertNotNil(keychainManager)
            XCTAssertNotNil(keychainManager?.privateStore)
            XCTAssertNotNil(keychainManager?.sharedStore)
            XCTAssertNotNil(keychainManager?.cookieStore)
            XCTAssertNotNil(keychainManager?.primaryServiceStore)
            XCTAssertNotNil(keychainManager?.deviceIdentifierStore)
        }
        catch {
            XCTFail("Failed to construct KeychainManager: \(error.localizedDescription)")
        }
        
        keychainManager?.privateStore.set("test_data", key: "test_key")
        keychainManager?.sharedStore.set("test_data", key: "test_key")
        keychainManager?.cookieStore.set("test_data", key: "test_key")
        
        XCTAssertEqual(keychainManager?.privateStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager?.sharedStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager?.cookieStore.allItems()?.count, 1)
        
        XCTAssertEqual(keychainManager?.privateStore.getString("test_key"), "test_data")
        XCTAssertEqual(keychainManager?.sharedStore.getString("test_key"), "test_data")
        XCTAssertEqual(keychainManager?.cookieStore.getString("test_key"), "test_data")
        
        do {
            keychainManager = try KeychainManager(baseUrl: serverConfig.baseURL.absoluteString + "/" + serverConfig.realm, accessGroup: accessGroup)
            let accessibility = keychainManager?.primaryServiceStore.options.accessibility ?? .afterFirstUnlock
            keychainManager?.securedKey = SecuredKey(applicationTag: "com.forgerock.ios.test.securedKey", accessibility: accessibility)
            keychainManager?.validateEncryption()
            XCTAssertNotNil(keychainManager)
            XCTAssertNotNil(keychainManager?.privateStore)
            XCTAssertNotNil(keychainManager?.sharedStore)
            XCTAssertNotNil(keychainManager?.cookieStore)
            XCTAssertNotNil(keychainManager?.primaryServiceStore)
            XCTAssertNotNil(keychainManager?.deviceIdentifierStore)
        }
        catch {
            XCTFail("Failed to construct KeychainManager: \(error.localizedDescription)")
        }
        
        XCTAssertEqual(keychainManager?.privateStore.allItems()?.count, 0)
        XCTAssertEqual(keychainManager?.sharedStore.allItems()?.count, 0)
        XCTAssertEqual(keychainManager?.cookieStore.allItems()?.count, 0)
        
        XCTAssertNil(keychainManager?.privateStore.getString("test_key"))
        XCTAssertNil(keychainManager?.sharedStore.getString("test_key"))
        XCTAssertNil(keychainManager?.cookieStore.getString("test_key"))
        
        keychainManager?.privateStore.set("test_data", key: "test_key_2")
        keychainManager?.sharedStore.set("test_data", key: "test_key_2")
        keychainManager?.cookieStore.set("test_data", key: "test_key_2")
        
        XCTAssertEqual(keychainManager?.privateStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager?.sharedStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager?.cookieStore.allItems()?.count, 1)
        
        XCTAssertEqual(keychainManager?.privateStore.getString("test_key_2"), "test_data")
        XCTAssertEqual(keychainManager?.sharedStore.getString("test_key_2"), "test_data")
        XCTAssertEqual(keychainManager?.cookieStore.getString("test_key_2"), "test_data")
    }
    
    
    func test_08_validate_KeychainManager_from_with_securedKey_to_without_securedKey() {
        
        var keychainManager: KeychainManager? = nil
        guard let serverConfig = self.config.serverConfig, let configJSON = self.config.configJSON, let accessGroup = configJSON["forgerock_keychain_access_group"] as? String else {
            XCTFail("Failed to read config object")
            return
        }

        do {
            keychainManager = try KeychainManager(baseUrl: serverConfig.baseURL.absoluteString + "/" + serverConfig.realm, accessGroup: accessGroup)
            XCTAssertNotNil(keychainManager)
            XCTAssertNotNil(keychainManager?.privateStore)
            XCTAssertNotNil(keychainManager?.sharedStore)
            XCTAssertNotNil(keychainManager?.cookieStore)
            XCTAssertNotNil(keychainManager?.primaryServiceStore)
            XCTAssertNotNil(keychainManager?.deviceIdentifierStore)
        }
        catch {
            XCTFail("Failed to construct KeychainManager: \(error.localizedDescription)")
        }
        
        keychainManager?.privateStore.set("test_data", key: "test_key")
        keychainManager?.sharedStore.set("test_data", key: "test_key")
        keychainManager?.cookieStore.set("test_data", key: "test_key")
        
        XCTAssertEqual(keychainManager?.privateStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager?.sharedStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager?.cookieStore.allItems()?.count, 1)
        
        XCTAssertEqual(keychainManager?.privateStore.getString("test_key"), "test_data")
        XCTAssertEqual(keychainManager?.sharedStore.getString("test_key"), "test_data")
        XCTAssertEqual(keychainManager?.cookieStore.getString("test_key"), "test_data")
        
        do {
            keychainManager = try KeychainManager(baseUrl: serverConfig.baseURL.absoluteString + "/" + serverConfig.realm, accessGroup: accessGroup)
            keychainManager?.securedKey = nil
            keychainManager?.validateEncryption()
            XCTAssertNotNil(keychainManager)
            XCTAssertNotNil(keychainManager?.privateStore)
            XCTAssertNotNil(keychainManager?.sharedStore)
            XCTAssertNotNil(keychainManager?.cookieStore)
            XCTAssertNotNil(keychainManager?.primaryServiceStore)
            XCTAssertNotNil(keychainManager?.deviceIdentifierStore)
        }
        catch {
            XCTFail("Failed to construct KeychainManager: \(error.localizedDescription)")
        }
        
        XCTAssertEqual(keychainManager?.privateStore.allItems()?.count, 0)
        XCTAssertEqual(keychainManager?.sharedStore.allItems()?.count, 0)
        XCTAssertEqual(keychainManager?.cookieStore.allItems()?.count, 0)
        
        XCTAssertNil(keychainManager?.privateStore.getString("test_key"))
        XCTAssertNil(keychainManager?.sharedStore.getString("test_key"))
        XCTAssertNil(keychainManager?.cookieStore.getString("test_key"))
        
        keychainManager?.privateStore.set("test_data", key: "test_key_2")
        keychainManager?.sharedStore.set("test_data", key: "test_key_2")
        keychainManager?.cookieStore.set("test_data", key: "test_key_2")
        
        XCTAssertEqual(keychainManager?.privateStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager?.sharedStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager?.cookieStore.allItems()?.count, 1)
        
        XCTAssertEqual(keychainManager?.privateStore.getString("test_key_2"), "test_data")
        XCTAssertEqual(keychainManager?.sharedStore.getString("test_key_2"), "test_data")
        XCTAssertEqual(keychainManager?.cookieStore.getString("test_key_2"), "test_data")
    }
    
    func test_09_validate_KeychainManager_for_securedKey_changed() {
        
        var keychainManager: KeychainManager? = nil
        guard let serverConfig = self.config.serverConfig, let configJSON = self.config.configJSON, let accessGroup = configJSON["forgerock_keychain_access_group"] as? String else {
            XCTFail("Failed to read config object")
            return
        }

        do {
            keychainManager = try KeychainManager(baseUrl: serverConfig.baseURL.absoluteString + "/" + serverConfig.realm, accessGroup: accessGroup)
            let accessibility = keychainManager?.primaryServiceStore.options.accessibility ?? .afterFirstUnlock
            keychainManager?.securedKey = SecuredKey(applicationTag: "com.forgerock.ios.test.securedKey2", accessibility: accessibility)
            keychainManager?.validateEncryption()
            XCTAssertNotNil(keychainManager)
            XCTAssertNotNil(keychainManager?.privateStore)
            XCTAssertNotNil(keychainManager?.sharedStore)
            XCTAssertNotNil(keychainManager?.cookieStore)
            XCTAssertNotNil(keychainManager?.primaryServiceStore)
            XCTAssertNotNil(keychainManager?.deviceIdentifierStore)
        }
        catch {
            XCTFail("Failed to construct KeychainManager: \(error.localizedDescription)")
        }
        
        keychainManager?.privateStore.set("test_data", key: "test_key")
        keychainManager?.sharedStore.set("test_data", key: "test_key")
        keychainManager?.cookieStore.set("test_data", key: "test_key")
        
        XCTAssertEqual(keychainManager?.privateStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager?.sharedStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager?.cookieStore.allItems()?.count, 1)
        
        XCTAssertEqual(keychainManager?.privateStore.getString("test_key"), "test_data")
        XCTAssertEqual(keychainManager?.sharedStore.getString("test_key"), "test_data")
        XCTAssertEqual(keychainManager?.cookieStore.getString("test_key"), "test_data")
        
        do {
            keychainManager = try KeychainManager(baseUrl: serverConfig.baseURL.absoluteString + "/" + serverConfig.realm, accessGroup: accessGroup)
            let accessibility = keychainManager?.primaryServiceStore.options.accessibility ?? .afterFirstUnlock
            keychainManager?.securedKey = SecuredKey(applicationTag: "com.forgerock.ios.test.securedKey", accessibility: accessibility)
            keychainManager?.validateEncryption()
            XCTAssertNotNil(keychainManager)
            XCTAssertNotNil(keychainManager?.privateStore)
            XCTAssertNotNil(keychainManager?.sharedStore)
            XCTAssertNotNil(keychainManager?.cookieStore)
            XCTAssertNotNil(keychainManager?.primaryServiceStore)
            XCTAssertNotNil(keychainManager?.deviceIdentifierStore)
        }
        catch {
            XCTFail("Failed to construct KeychainManager: \(error.localizedDescription)")
        }
        
        XCTAssertEqual(keychainManager?.privateStore.allItems()?.count, 0)
        XCTAssertEqual(keychainManager?.sharedStore.allItems()?.count, 0)
        XCTAssertEqual(keychainManager?.cookieStore.allItems()?.count, 0)
        
        XCTAssertNil(keychainManager?.privateStore.getString("test_key"))
        XCTAssertNil(keychainManager?.sharedStore.getString("test_key"))
        XCTAssertNil(keychainManager?.cookieStore.getString("test_key"))
        
        keychainManager?.privateStore.set("test_data", key: "test_key_2")
        keychainManager?.sharedStore.set("test_data", key: "test_key_2")
        keychainManager?.cookieStore.set("test_data", key: "test_key_2")
        
        XCTAssertEqual(keychainManager?.privateStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager?.sharedStore.allItems()?.count, 1)
        XCTAssertEqual(keychainManager?.cookieStore.allItems()?.count, 1)
        
        XCTAssertEqual(keychainManager?.privateStore.getString("test_key_2"), "test_data")
        XCTAssertEqual(keychainManager?.sharedStore.getString("test_key_2"), "test_data")
        XCTAssertEqual(keychainManager?.cookieStore.getString("test_key_2"), "test_data")
    }
    
    
    func test_10_store_sso_token() {
        var keychainManager: KeychainManager? = nil
        guard let serverConfig = self.config.serverConfig, let configJSON = self.config.configJSON, let accessGroup = configJSON["forgerock_keychain_access_group"] as? String else {
            XCTFail("Failed to read config object")
            return
        }

        do {
            keychainManager = try KeychainManager(baseUrl: serverConfig.baseURL.absoluteString + "/" + serverConfig.realm, accessGroup: accessGroup)
            let accessibility = keychainManager?.primaryServiceStore.options.accessibility ?? .afterFirstUnlock
            keychainManager?.securedKey = SecuredKey(applicationTag: "com.forgerock.ios.test.securedKey2", accessibility: accessibility)
            keychainManager?.validateEncryption()
            XCTAssertNotNil(keychainManager)
            XCTAssertNotNil(keychainManager?.privateStore)
            XCTAssertNotNil(keychainManager?.sharedStore)
            XCTAssertNotNil(keychainManager?.cookieStore)
            XCTAssertNotNil(keychainManager?.primaryServiceStore)
            XCTAssertNotNil(keychainManager?.deviceIdentifierStore)
        }
        catch {
            XCTFail("Failed to construct KeychainManager: \(error.localizedDescription)")
        }
        
        guard let manager = keychainManager else {
            XCTFail("Failed to read KeychainManager instance")
            return
        }
        let token = Token("SBRihCHYvVVVWrpTIFt6gkm-F9g.*AAJTSQACMDEAAlNLABxmR0tKcllmYjJpOXJ1alN4WWc5RWxvSDNvT289AAR0eXBlAANDVFMAAlMxAAA.*")
        XCTAssertTrue(manager.setSSOToken(ssoToken: token))
        
        let tokenFromStorage = manager.getSSOToken()
        XCTAssertNotNil(tokenFromStorage)
        XCTAssertEqual(tokenFromStorage?.value, token.value)
    }
    
    
    func test_11_store_access_token() {
        var keychainManager: KeychainManager? = nil
        guard let serverConfig = self.config.serverConfig, let configJSON = self.config.configJSON, let accessGroup = configJSON["forgerock_keychain_access_group"] as? String else {
            XCTFail("Failed to read config object")
            return
        }

        do {
            keychainManager = try KeychainManager(baseUrl: serverConfig.baseURL.absoluteString + "/" + serverConfig.realm, accessGroup: accessGroup)
            let accessibility = keychainManager?.primaryServiceStore.options.accessibility ?? .afterFirstUnlock
            keychainManager?.securedKey = SecuredKey(applicationTag: "com.forgerock.ios.test.securedKey2", accessibility: accessibility)
            keychainManager?.validateEncryption()
            XCTAssertNotNil(keychainManager)
            XCTAssertNotNil(keychainManager?.privateStore)
            XCTAssertNotNil(keychainManager?.sharedStore)
            XCTAssertNotNil(keychainManager?.cookieStore)
            XCTAssertNotNil(keychainManager?.primaryServiceStore)
            XCTAssertNotNil(keychainManager?.deviceIdentifierStore)
        }
        catch {
            XCTFail("Failed to construct KeychainManager: \(error.localizedDescription)")
        }
        
        guard let manager = keychainManager else {
            XCTFail("Failed to read KeychainManager instance")
            return
        }
        
        guard let tokenJSON = self.readDataFromJSON("AccessToken") else {
            XCTFail("Failed to read AccessToken.json")
            return
        }
        
        do {
            let token = AccessToken(tokenResponse: tokenJSON)
            token?.sessionToken = "SBRihCHYvVVVWrpTIFt6gkm-F9g.*AAJTSQACMDEAAlNLABxmR0tKcllmYjJpOXJ1alN4WWc5RWxvSDNvT289AAR0eXBlAANDVFMAAlMxAAA.*"
            XCTAssertNotNil(token)
            XCTAssertTrue(try manager.setAccessToken(token: token))
            
            let tokenFromStorage = try manager.getAccessToken()
            XCTAssertNotNil(tokenFromStorage)
            
            XCTAssertEqual(token?.value, tokenFromStorage?.value)
            XCTAssertEqual(token?.expiresIn, tokenFromStorage?.expiresIn)
            XCTAssertEqual(token?.tokenType, tokenFromStorage?.tokenType)
            XCTAssertEqual(token?.scope, tokenFromStorage?.scope)
            XCTAssertEqual(token?.refreshToken, tokenFromStorage?.refreshToken)
            XCTAssertEqual(token?.idToken, tokenFromStorage?.idToken)
            XCTAssertEqual(token?.authenticatedTimestamp.timeIntervalSince1970, tokenFromStorage?.authenticatedTimestamp.timeIntervalSince1970)
            XCTAssertEqual(token?.sessionToken, tokenFromStorage?.sessionToken)
            XCTAssertEqual(token?.expiration.timeIntervalSince1970, tokenFromStorage?.expiration.timeIntervalSince1970)
        }
        catch {
            XCTFail("Fail with unexpected exception: \(error.localizedDescription)")
        }
    }


    // MARK: - SDKS-5451 migration-probe regression tests (AC3)

    // The KeychainManager device-identifier migration probe (KeychainManager.init, both the
    // access-group branch at lines ~137-154 and the no-access-group branch at lines ~164-181)
    // reads the device-identifier service with a kSecAttrAccessibleAlwaysThisDeviceOnly-filtered
    // lookup and, only when an item is found, calls previousService.deleteAll() and re-stores just
    // the identifier. That accessibility-as-filter behaviour is by design (decisions.md D4): the
    // device-identifier service name (KeychainStoreType.deviceIdentifier) is a constant shared
    // across all baseUrls, so a global accessibility-free buildQuery — the approach rejected in
    // SDKS-5451 — would make the probe match the freshly stored item on every launch, fire
    // deleteAll() (wiping the identifier AND the cached public/private key data) and re-set only
    // the identifier. The tests below lock in the untouched behaviour in both access-group
    // configurations: after a second KeychainManager construction, all three seeded values must
    // survive byte-identical (test_12/test_13), and a genuine legacy .alwaysThisDeviceOnly item
    // must still be migrated (test_14). Under the rejected mutation these two preservation tests
    // fail on the missing key data, which is the mutation-check evidence for Task 5.3.

    /// Key for the identifier in the device-identifier store (FRDeviceIdentifier.identifierKeychainServiceKey)
    private var deviceIdentifierKey: String { FRDeviceIdentifier.identifierKeychainServiceKey }
    /// Key for the public key data in the device-identifier store; the 'pubic' typo is real in FRDeviceIdentifier
    private var publicKeyDataKey: String { "com.forgerock.ios.device-identifier.pubic-key.data" }
    /// Key for the private key data in the device-identifier store
    private var privateKeyDataKey: String { "com.forgerock.ios.device-identifier.private-key.data" }


    /// Constructs a KeychainManager for the given baseUrl/accessGroup, failing the test if initialization throws or returns nil
    private func makeKeychainManager(baseUrl: String, accessGroup: String?) -> KeychainManager? {
        do {
            guard let manager = try KeychainManager(baseUrl: baseUrl, accessGroup: accessGroup) else {
                XCTFail("KeychainManager init returned nil")
                return nil
            }
            return manager
        }
        catch {
            XCTFail("Failed to construct KeychainManager: \(error.localizedDescription)")
            return nil
        }
    }


    /// Clears any leftover items for the three device-identifier keys, seeds all three on the given
    /// store through its public `set`, and registers a teardown block that deletes them again.
    ///
    /// The seeded items live at the store's own (current) accessibility, so the base cleanUp()
    /// could remove them; the explicit teardown keeps the test self-contained even when
    /// FRAuth.shared is nil (e.g. when this test runs alone).
    private func seedDeviceIdentifierItems(on store: KeychainService, identifier: String, publicKeyData: Data, privateKeyData: Data) {
        // The base cleanUp() deletes through the manager-held store, which cannot observe items
        // seeded under a different accessibility; delete explicitly via the seeding store
        self.addTeardownBlock {
            _ = store.delete(self.deviceIdentifierKey)
            _ = store.delete(self.publicKeyDataKey)
            _ = store.delete(self.privateKeyDataKey)
        }

        // Clear leftovers from previous tests so the assertions below observe exactly the seeded state
        _ = store.delete(self.deviceIdentifierKey)
        _ = store.delete(self.publicKeyDataKey)
        _ = store.delete(self.privateKeyDataKey)

        XCTAssertTrue(store.set(identifier, key: self.deviceIdentifierKey), "Seeding the device identifier must succeed")
        XCTAssertTrue(store.set(publicKeyData, key: self.publicKeyDataKey), "Seeding the public key data must succeed")
        XCTAssertTrue(store.set(privateKeyData, key: self.privateKeyDataKey), "Seeding the private key data must succeed")
    }


    func test_12_migrationProbe_preservesDeviceIdentifierKeyData_withAccessGroup() {

        guard let serverConfig = self.config.serverConfig, let configJSON = self.config.configJSON, let accessGroup = configJSON["forgerock_keychain_access_group"] as? String else {
            XCTFail("Failed to read config object")
            return
        }
        let baseUrl = serverConfig.baseURL.absoluteString + "/" + serverConfig.realm

        guard let firstManager = self.makeKeychainManager(baseUrl: baseUrl, accessGroup: accessGroup) else {
            return
        }
        XCTAssertNotNil(firstManager.deviceIdentifierStore.options.accessGroup, "The access-group configuration must produce a deviceIdentifierStore with an access group")

        let seededIdentifier = "SDKS-5451-migration-probe-\(UUID().uuidString)"
        let seededPublicKeyData = "SDKS-5451-seeded-public-key-data".data(using: .utf8)!
        let seededPrivateKeyData = "SDKS-5451-seeded-private-key-data".data(using: .utf8)!
        self.seedDeviceIdentifierItems(on: firstManager.deviceIdentifierStore, identifier: seededIdentifier, publicKeyData: seededPublicKeyData, privateKeyData: seededPrivateKeyData)

        // Constructing a second manager runs the migration probe. The probe's previousService
        // looks the identifier up with kSecAttrAccessibleAlwaysThisDeviceOnly and must NOT match
        // the freshly seeded items (stored with the store's own afterFirstUnlockThisDeviceOnly),
        // so deleteAll() must not fire and all three values must survive byte-identical.
        guard let secondManager = self.makeKeychainManager(baseUrl: baseUrl, accessGroup: accessGroup) else {
            return
        }

        XCTAssertEqual(secondManager.deviceIdentifierStore.getString(self.deviceIdentifierKey), seededIdentifier, "The identifier must survive a second KeychainManager construction (a global accessibility-free buildQuery would make the probe deleteAll() and re-set it)")
        XCTAssertEqual(secondManager.deviceIdentifierStore.getData(self.publicKeyDataKey), seededPublicKeyData, "The public key data must survive the probe untouched; the probe must not deleteAll() the key-data cache")
        XCTAssertEqual(secondManager.deviceIdentifierStore.getData(self.privateKeyDataKey), seededPrivateKeyData, "The private key data must survive the probe untouched; the probe must not deleteAll() the key-data cache")
    }


    func test_13_migrationProbe_preservesDeviceIdentifierKeyData_withoutAccessGroup() {

        // The migration probe also runs on every launch in the NO-access-group branch of
        // KeychainManager.init, so the preservation guarantee is asserted there too
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to read config object")
            return
        }
        let baseUrl = serverConfig.baseURL.absoluteString + "/" + serverConfig.realm

        guard let firstManager = self.makeKeychainManager(baseUrl: baseUrl, accessGroup: nil) else {
            return
        }
        XCTAssertNil(firstManager.deviceIdentifierStore.options.accessGroup, "The no-access-group configuration must produce a deviceIdentifierStore without an access group")

        let seededIdentifier = "SDKS-5451-migration-probe-\(UUID().uuidString)"
        let seededPublicKeyData = "SDKS-5451-seeded-public-key-data".data(using: .utf8)!
        let seededPrivateKeyData = "SDKS-5451-seeded-private-key-data".data(using: .utf8)!
        self.seedDeviceIdentifierItems(on: firstManager.deviceIdentifierStore, identifier: seededIdentifier, publicKeyData: seededPublicKeyData, privateKeyData: seededPrivateKeyData)

        guard let secondManager = self.makeKeychainManager(baseUrl: baseUrl, accessGroup: nil) else {
            return
        }

        XCTAssertEqual(secondManager.deviceIdentifierStore.getString(self.deviceIdentifierKey), seededIdentifier, "The identifier must survive a second KeychainManager construction without an access group")
        XCTAssertEqual(secondManager.deviceIdentifierStore.getData(self.publicKeyDataKey), seededPublicKeyData, "The public key data must survive the probe untouched in the no-access-group configuration")
        XCTAssertEqual(secondManager.deviceIdentifierStore.getData(self.privateKeyDataKey), seededPrivateKeyData, "The private key data must survive the probe untouched in the no-access-group configuration")
    }


    func test_14_migrationProbe_migratesLegacyAlwaysThisDeviceOnlyIdentifier() throws {

        guard let serverConfig = self.config.serverConfig, let configJSON = self.config.configJSON, let accessGroup = configJSON["forgerock_keychain_access_group"] as? String else {
            XCTFail("Failed to read config object")
            return
        }
        let baseUrl = serverConfig.baseURL.absoluteString + "/" + serverConfig.realm

        guard let firstManager = self.makeKeychainManager(baseUrl: baseUrl, accessGroup: accessGroup) else {
            return
        }
        let store = firstManager.deviceIdentifierStore

        // Clear any current items for the managed keys so the only pre-existing item is the
        // legacy one seeded below
        _ = store.delete(self.deviceIdentifierKey)
        _ = store.delete(self.publicKeyDataKey)
        _ = store.delete(self.privateKeyDataKey)

        // Seed a genuine legacy item exactly as pre-migration SDK versions stored it: the same
        // device-identifier service name, the same access group, and kSecAttrAccessibleAlwaysThisDeviceOnly
        var legacyOptions = KeychainOptions(service: KeychainManager.KeychainStoreType.deviceIdentifier.rawValue, accessGroup: accessGroup)
        legacyOptions.accessibility = .alwaysThisDeviceOnly
        let legacyService = KeychainService(options: legacyOptions, securedKey: firstManager.securedKey)
        let legacyIdentifier = "SDKS-5451-legacy-migration-\(UUID().uuidString)"

        // The base cleanUp() cannot remove items stored under a non-default accessibility; clean
        // through the legacy seeder itself
        self.addTeardownBlock {
            _ = legacyService.delete(self.deviceIdentifierKey)
            _ = store.delete(self.deviceIdentifierKey)
            _ = store.delete(self.publicKeyDataKey)
            _ = store.delete(self.privateKeyDataKey)
        }

        guard legacyService.set(legacyIdentifier, key: self.deviceIdentifierKey) else {
            // kSecAttrAccessibleAlwaysThisDeviceOnly is deprecated; a runtime may refuse to store it.
            // Skip rather than fail: this test is the positive-path proof that the probe's filter
            // still detects (and migrates) a genuine legacy item.
            throw XCTSkip("Seeding a kSecAttrAccessibleAlwaysThisDeviceOnly item failed on this runtime (the attribute is deprecated); the positive-path migration probe was not exercised")
        }

        // Constructing a KeychainManager runs the migration probe: the .alwaysThisDeviceOnly-filtered
        // read finds the legacy item, previousService.deleteAll() removes it, and the identifier is
        // re-stored through deviceIdentifierStore at the current accessibility
        guard let secondManager = self.makeKeychainManager(baseUrl: baseUrl, accessGroup: accessGroup) else {
            return
        }

        XCTAssertEqual(secondManager.deviceIdentifierStore.getString(self.deviceIdentifierKey), legacyIdentifier, "The legacy identifier must be migrated and readable from the device identifier store at its current accessibility")
        XCTAssertNil(legacyService.getString(self.deviceIdentifierKey), "The legacy .alwaysThisDeviceOnly item must be gone after the migration probe ran")
    }
}
