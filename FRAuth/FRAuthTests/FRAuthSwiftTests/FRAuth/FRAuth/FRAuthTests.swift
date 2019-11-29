//
//  FRAuthTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest

class FRAuthTests: FRBaseTest {

    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    
    func testFRStartWithEmptyOrInvalidConfigFile() {
        
        // Given
        FRAuth.configPlistFileName = "EmptyConfig"
        
        var initError: Error?
        
        // Then
        do {
            try FRAuth.start()
        }
        catch {
            initError = error
        }
        
        guard let configError: ConfigError = initError as? ConfigError else {
            XCTFail("Failed to convert initialization error: \(String(describing: initError))")
            return
        }
        
        switch configError {
        case .emptyConfiguration:
            break
        default:
            XCTFail("Received unexpected error: \(configError)")
            break
        }
    }
    
    func testFRStart() {
        
        // Given
        FRAuth.configPlistFileName = "FRAuthConfig"
        
        // Then
        do {
            try FRAuth.start()
        }
        catch {
            XCTFail("SDK Initialization failed: \(error.localizedDescription)")
        }
        
        guard let frAtuh = FRAuth.shared else {
            XCTFail("FRAuth shared instance is returned nil")
            return
        }
        XCTAssertTrue(frAtuh.keychainManager.isSharedKeychainAccessible)
    }
    
    
    func testFRStartNonSSO() {
        
        // Given
        FRAuth.configPlistFileName = "FRAuthConfigNonSSO"
        
        // Then
        do {
            try FRAuth.start()
        }
        catch {
            XCTFail("SDK Initialization failed: \(error.localizedDescription)")
        }
        
        guard let frAtuh = FRAuth.shared else {
            XCTFail("FRAuth shared instance is returned nil")
            return
        }
        XCTAssertFalse(frAtuh.keychainManager.isSharedKeychainAccessible)
    }
    
    
    func testFRStartWithInvalidAccessGroup() {
        
        // Given
        var config = self.readConfigFile(fileName: "FRAuthConfig")
        config["forgerock_keychain_access_group"] = "com.forgerock.invalid.accessGroup"
        
        var initError: Error?
        
        // Then
        do {
            try FRAuth.initPrivate(config: config)
        }
        catch {
            initError = error
        }
        
        guard let configError: ConfigError = initError as? ConfigError else {
            XCTFail("Failed to convert initialization error: \(String(describing: initError))")
            return
        }
        
        switch configError {
        case .invalidAccessGroup:
            break
        default:
            XCTFail("Received unexpected error: \(configError)")
            break
        }
    }
    
    
    func testFRStartWithMissingOrInvalidURL() {
        
        // Given
        var config = self.readConfigFile(fileName: "FRAuthConfig")
        config["forgerock_url"] = "invalid url"
        
        var initError: Error?
        
        // Then
        do {
            try FRAuth.initPrivate(config: config)
        }
        catch {
            initError = error
        }
        
        // It should
        guard let configError: ConfigError = initError as? ConfigError else {
            XCTFail("Failed to convert initialization error: \(String(describing: initError))")
            return
        }
        switch configError {
        case .invalidConfiguration:
            break
        default:
            XCTFail("Received unexpected error: \(configError)")
            break
        }
        
        // Given
        initError = nil
        config.removeValue(forKey: "forgerock_url")
        
        // Then
        do {
            try FRAuth.initPrivate(config: config)
        }
        catch {
            initError = error
        }
        
        // It should
        guard let missingConfigError: ConfigError = initError as? ConfigError else {
            XCTFail("Failed to convert initialization error: \(String(describing: initError))")
            return
        }
        switch missingConfigError {
        case .invalidConfiguration:
            break
        default:
            XCTFail("Received unexpected error: \(missingConfigError)")
        }
    }
    
    
    func testFRStartWithMissingOrInvalidRedirectURL() {
        
        // Given
        var config = self.readConfigFile(fileName: "FRAuthConfig")
        config["forgerock_oauth_redirect_uri"] = "invalid url"
        
        var initError: Error?
        
        // Then
        do {
            try FRAuth.initPrivate(config: config)
        }
        catch {
            initError = error
        }
        
        // It should
        guard let configError: ConfigError = initError as? ConfigError else {
            XCTFail("Failed to convert initialization error: \(String(describing: initError))")
            return
        }
        switch configError {
        case .invalidConfiguration:
            break
        default:
            XCTFail("Received unexpected error: \(configError)")
            break
        }
        
        // Given
        initError = nil
        config.removeValue(forKey: "forgerock_oauth_redirect_uri")
        
        // Then
        do {
            try FRAuth.initPrivate(config: config)
        }
        catch {
            initError = error
        }
        
        // It should
        guard let missingConfigError: ConfigError = initError as? ConfigError else {
            XCTFail("Failed to convert initialization error: \(String(describing: initError))")
            return
        }
        switch missingConfigError {
        case .invalidConfiguration:
            break
        default:
            XCTFail("Received unexpected error: \(missingConfigError)")
        }
    }
    
    
    func testFRStartWithMissingClientId() {
        
        // Given
        var config = self.readConfigFile(fileName: "FRAuthConfig")
        config.removeValue(forKey: "forgerock_oauth_client_id")
        
        var initError: Error?
        
        // Then
        do {
            try FRAuth.initPrivate(config: config)
        }
        catch {
            initError = error
        }
        
        // It should
        guard let configError: ConfigError = initError as? ConfigError else {
            XCTFail("Failed to convert initialization error: \(String(describing: initError))")
            return
        }
        switch configError {
        case .invalidConfiguration:
            break
        default:
            XCTFail("Received unexpected error: \(configError)")
            break
        }
    }
    
    
    func testFRStartWithMissingScope() {
        
        // Given
        var config = self.readConfigFile(fileName: "FRAuthConfig")
        config.removeValue(forKey: "forgerock_oauth_scope")
        
        var initError: Error?
        
        // Then
        do {
            try FRAuth.initPrivate(config: config)
        }
        catch {
            initError = error
        }
        
        // It should
        guard let configError: ConfigError = initError as? ConfigError else {
            XCTFail("Failed to convert initialization error: \(String(describing: initError))")
            return
        }
        switch configError {
        case .invalidConfiguration:
            break
        default:
            XCTFail("Received unexpected error: \(configError)")
            break
        }
    }
    
    
    func testFRStartWithMissingAuthServiceName() {
        
        // Given
        var config = self.readConfigFile(fileName: "FRAuthConfig")
        config.removeValue(forKey: "forgerock_auth_service_name")
        
        var initError: Error?
        
        // Then
        do {
            try FRAuth.initPrivate(config: config)
        }
        catch {
            initError = error
        }
        
        // It should
        guard let configError: ConfigError = initError as? ConfigError else {
            XCTFail("Failed to convert initialization error: \(String(describing: initError))")
            return
        }
        switch configError {
        case .invalidConfiguration:
            break
        default:
            XCTFail("Received unexpected error: \(configError)")
            break
        }
    }
    
    
    func testFRStartWithMissingRegistrationServiceName() {
        
        // Given
        var config = self.readConfigFile(fileName: "FRAuthConfig")
        config.removeValue(forKey: "forgerock_registration_service_name")
        
        var initError: Error?
        
        // Then
        do {
            try FRAuth.initPrivate(config: config)
        }
        catch {
            initError = error
        }
        
        // It should
        XCTAssertNil(initError)
    }
    
    
    func testFRStartWithMissingTimeout() {
        
        // Given
        var config = self.readConfigFile(fileName: "FRAuthConfig")
        config.removeValue(forKey: "forgerock_timeout")
        
        // Then
        do {
            try FRAuth.initPrivate(config: config)
        }
        catch {
            XCTFail("SDK Initialization failed: \(error.localizedDescription)")
        }
        
        // It should
        XCTAssertNotNil(FRAuth.shared)
    }
    
    
    func testFRStartWithMissingOAuthThreshold() {
        
        // Given
        var config = self.readConfigFile(fileName: "FRAuthConfig")
        config.removeValue(forKey: "forgerock_oauth_threshold")
        
        // Then
        do {
            try FRAuth.initPrivate(config: config)
        }
        catch {
            XCTFail("SDK Initialization failed: \(error.localizedDescription)")
        }
        
        // It should
        XCTAssertNotNil(FRAuth.shared)
    }
    
    
    func testFRStartWithMissingRealm() {
        
        // Given
        var config = self.readConfigFile(fileName: "FRAuthConfig")
        config.removeValue(forKey: "forgerock_realm")
        
        // Then
        do {
            try FRAuth.initPrivate(config: config)
        }
        catch {
            XCTFail("SDK Initialization failed: \(error.localizedDescription)")
        }
        
        // It should
        XCTAssertNotNil(FRAuth.shared)
    }
    
    
    func readConfigFile(fileName: String) -> [String: Any] {
        
        guard let path = Bundle.main.path(forResource: fileName, ofType: "plist"), let config = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            XCTFail("Failed to read \(fileName).plist file")
            return [:]
        }
        
        return config
    }
}
