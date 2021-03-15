// 
//  ConfigErrorTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class ConfigErrorTests: FRAuthBaseTest {

    
    func test_01_domain() {
        XCTAssertEqual(ConfigError.errorDomain, "com.forgerock.ios.frauth.configuration")
    }
    
    
    func test_02_empty_configuration() {
        let error = ConfigError.emptyConfiguration
        
        XCTAssertEqual(error.code, 2000000)
        XCTAssertEqual(error.errorCode, 2000000)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertTrue(error.localizedDescription.hasPrefix("Invalid configuration: configuration Dictionary is empty or 'server'/'oauth' section is missing"))
    }
    
    
    func test_03_invalid_configuration() {
        let error = ConfigError.invalidConfiguration("")
        
        XCTAssertEqual(error.code, 2000001)
        XCTAssertEqual(error.errorCode, 2000001)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertTrue(error.localizedDescription.hasPrefix("Invalid configuration: "))
    }
    
    
    func test_04_invalid_access_group() {
        let error = ConfigError.invalidAccessGroup("accessGroup")
        
        XCTAssertEqual(error.code, 2000002)
        XCTAssertEqual(error.errorCode, 2000002)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Invalid access group: accessGroup. Unable to access Keychain Service with given Access group. Validate Access Group with Keychain Group Identifier defined in XCode's Capabilities tab.")
    }
    
    
    func test_05_invalid_sdk_state() {
        let error = ConfigError.invalidSDKState
        
        XCTAssertEqual(error.code, 2000003)
        XCTAssertEqual(error.errorCode, 2000003)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertTrue(error.localizedDescription.hasPrefix("Invalid SDK State: initialize SDK using FRAuth.start() first"))
    }
}
