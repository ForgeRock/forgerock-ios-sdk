// 
//  KeychainManagerTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
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
            keychainManager?.securedKey = SecuredKey(applicationTag: "com.forgerock.ios.test.securedKey")
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
            keychainManager?.securedKey = SecuredKey(applicationTag: "com.forgerock.ios.test.securedKey2")
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
            keychainManager?.securedKey = SecuredKey(applicationTag: "com.forgerock.ios.test.securedKey")
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
            keychainManager?.securedKey = SecuredKey(applicationTag: "com.forgerock.ios.test.securedKey2")
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
            keychainManager?.securedKey = SecuredKey(applicationTag: "com.forgerock.ios.test.securedKey2")
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
}
