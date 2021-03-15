//
//  FRAuthTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019-2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class FRAuthTests: FRAuthBaseTest {

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
        
        guard let frAuth = FRAuth.shared else {
            XCTFail("FRAuth shared instance is returned nil")
            return
        }
        XCTAssertTrue(frAuth.keychainManager.isSharedKeychainAccessible)
        XCTAssertNotNil(frAuth.oAuth2Client)
        XCTAssertNotNil(frAuth.tokenManager)
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
        
        guard let frAuth = FRAuth.shared else {
            XCTFail("FRAuth shared instance is returned nil")
            return
        }
        XCTAssertFalse(frAuth.keychainManager.isSharedKeychainAccessible)
        XCTAssertNotNil(frAuth.oAuth2Client)
        XCTAssertNotNil(frAuth.tokenManager)
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
        guard let frAtuh = FRAuth.shared else {
            XCTFail("FRAuth shared instance is returned nil")
            return
        }
        XCTAssertNil(frAtuh.oAuth2Client)
        XCTAssertNil(frAtuh.tokenManager)
        XCTAssertNil(initError)
        
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
        guard let frAtuhWithNoUri = FRAuth.shared else {
            XCTFail("FRAuth shared instance is returned nil")
            return
        }
        XCTAssertNil(frAtuhWithNoUri.oAuth2Client)
        XCTAssertNil(frAtuhWithNoUri.tokenManager)
        XCTAssertNil(initError)
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
        guard let frAtuhWithNoUri = FRAuth.shared else {
            XCTFail("FRAuth shared instance is returned nil")
            return
        }
        XCTAssertNil(frAtuhWithNoUri.oAuth2Client)
        XCTAssertNil(frAtuhWithNoUri.tokenManager)
        XCTAssertNil(initError)
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
        guard let frAtuhWithNoUri = FRAuth.shared else {
            XCTFail("FRAuth shared instance is returned nil")
            return
        }
        XCTAssertNil(frAtuhWithNoUri.oAuth2Client)
        XCTAssertNil(frAtuhWithNoUri.tokenManager)
        XCTAssertNil(initError)
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
    
    
    func testFRStartWithMissingCookieName() {
        
        // Given
        var config = self.readConfigFile(fileName: "FRAuthConfig")
        config.removeValue(forKey: "forgerock_cookie_name")
        
        // Then
        do {
            try FRAuth.initPrivate(config: config)
        }
        catch {
            XCTFail("SDK Initialization failed: \(error.localizedDescription)")
        }
        guard let serverConfig = FRAuth.shared?.serverConfig else {
            XCTFail("Failed to retrieve ServerConfig object")
            return
        }
        
        XCTAssertEqual(serverConfig.cookieName, OpenAM.iPlanetDirectoryPro)
        
        // It should
        XCTAssertNotNil(FRAuth.shared)
    }
    
    
    func testFRStartWithCustomCookieName() {
        
        // Given
        var config = self.readConfigFile(fileName: "FRAuthConfig")
        config["forgerock_cookie_name"] = "customCookieName"
        
        // Then
        do {
            try FRAuth.initPrivate(config: config)
        }
        catch {
            XCTFail("SDK Initialization failed: \(error.localizedDescription)")
        }
        guard let serverConfig = FRAuth.shared?.serverConfig else {
            XCTFail("Failed to retrieve ServerConfig object")
            return
        }
        
        XCTAssertEqual(serverConfig.cookieName, "customCookieName")
        
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
    
    
    func test_frstart_with_custom_endpoints() {
        // Given
        var config = self.readConfigFile(fileName: "FRAuthConfig")
        config["forgerock_authenticate_endpoint"] = "/custom/authenticate/path"
        config["forgerock_token_endpoint"] = "/custom/token/path"
        config["forgerock_authorize_endpoint"] = "/custom/authorize/path"
        config["forgerock_revoke_endpoint"] = "/custom/token/path"
        config["forgerock_userinfo_endpoint"] = "/custom/userinfo/path"
        config["forgerock_session_endpoint"] = "/custom/session/path"
        
        // Then
        do {
            try FRAuth.initPrivate(config: config)
            
            guard let serverConfig = FRAuth.shared?.serverConfig else {
                XCTFail("Failed to retrieve ServerConfig object")
                return
            }
            
            XCTAssertEqual(serverConfig.authenticateURL, "http://openam.example.com:8081/openam/custom/authenticate/path")
            XCTAssertEqual(serverConfig.tokenURL, "http://openam.example.com:8081/openam/custom/token/path")
            XCTAssertEqual(serverConfig.authorizeURL, "http://openam.example.com:8081/openam/custom/authorize/path")
            XCTAssertEqual(serverConfig.tokenRevokeURL, "http://openam.example.com:8081/openam/custom/token/path")
            XCTAssertEqual(serverConfig.userInfoURL, "http://openam.example.com:8081/openam/custom/userinfo/path")
            XCTAssertEqual(serverConfig.sessionURL, "http://openam.example.com:8081/openam/custom/session/path")
        }
        catch {
            XCTFail("SDK Initialization failed: \(error.localizedDescription)")
        }
        
        // It should
        XCTAssertNotNil(FRAuth.shared)
    }
    
    
    func test_frstart_with_some_custom_endpoints() {
        // Given
        var config = self.readConfigFile(fileName: "FRAuthConfig")
        config["forgerock_authenticate_endpoint"] = "/custom/authenticate/path"
        config["forgerock_token_endpoint"] = "/custom/token/path"
        
        // Then
        do {
            try FRAuth.initPrivate(config: config)
            
            guard let serverConfig = FRAuth.shared?.serverConfig else {
                XCTFail("Failed to retrieve ServerConfig object")
                return
            }
            
            XCTAssertEqual(serverConfig.authenticateURL, "http://openam.example.com:8081/openam/custom/authenticate/path")
            XCTAssertEqual(serverConfig.tokenURL, "http://openam.example.com:8081/openam/custom/token/path")
            XCTAssertEqual(serverConfig.authorizeURL, "http://openam.example.com:8081/openam/oauth2/realms/root/authorize")
            XCTAssertEqual(serverConfig.tokenRevokeURL, "http://openam.example.com:8081/openam/oauth2/realms/root/token/revoke")
            XCTAssertEqual(serverConfig.userInfoURL, "http://openam.example.com:8081/openam/oauth2/realms/root/userinfo")
            XCTAssertEqual(serverConfig.sessionURL, "http://openam.example.com:8081/openam/json/realms/root/sessions")
        }
        catch {
            XCTFail("SDK Initialization failed: \(error.localizedDescription)")
        }
        
        // It should
        XCTAssertNotNil(FRAuth.shared)
    }
    
    
    func test_frstart_with_custom_cookie_name() {
        // Given
        var config = self.readConfigFile(fileName: "FRAuthConfig")
        config["forgerock_cookie_name"] = "customCookieName"
        
        // Then
        do {
            try FRAuth.initPrivate(config: config)
            
            guard let serverConfig = FRAuth.shared?.serverConfig else {
                XCTFail("Failed to retrieve ServerConfig object")
                return
            }
            
            XCTAssertEqual(serverConfig.cookieName, "customCookieName")
        }
        catch {
            XCTFail("SDK Initialization failed: \(error.localizedDescription)")
        }
        
        // It should
        XCTAssertNotNil(FRAuth.shared)
    }
}
