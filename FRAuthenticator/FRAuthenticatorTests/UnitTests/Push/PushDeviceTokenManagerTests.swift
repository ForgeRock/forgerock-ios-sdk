// 
//  PushDeviceTokenManagerTests.swift
//  FRAuthenticator
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class PushDeviceTokenManagerTests: FRABaseTests {

    func test_01_init_with_token() {
        let token = "sampleToken"
        let manager = PushDeviceTokenManager(token)
        
        XCTAssertEqual(manager.deviceToken, token)
    }
    
    
    func test_02_init_without_token() {
        let manager = PushDeviceTokenManager()
        
        XCTAssertNil(manager.deviceToken)
    }
    
    
    func test_03_get_push_device_token() {
        let token = "sampleToken"
        let manager = PushDeviceTokenManager()
        
        manager.setDeviceToken(token)
        
        XCTAssertEqual(manager.getPushDeviceToken()?.tokenId, token)
    }
    
    
    func test_04_get_push_device_token_not_found() {
        let manager = PushDeviceTokenManager()
        
        XCTAssertNil(manager.getPushDeviceToken())
    }
    
    
    func test_05_set_device_token() {
        let initialToken = "initialToken"
        let newToken = "newToken"
        
        let manager = PushDeviceTokenManager(initialToken)
        XCTAssertEqual(manager.deviceToken, initialToken)
        
        manager.setDeviceToken(newToken)
        XCTAssertEqual(manager.deviceToken, newToken)
        
        let pushDeviceToken = FRAClient.storage.getPushDeviceToken()
        XCTAssertEqual(pushDeviceToken?.tokenId, newToken)
    }
    
    
    func test_06_clear_device_token() {
        let token = "sampleToken"
        let manager = PushDeviceTokenManager(token)
        
        manager.clearDeviceToken()
        
        XCTAssertNil(manager.deviceToken)
    }
    
    
    func test_07_should_update_token() {
        let token = "sampleToken"
        let newToken = "newToken"
        
        let manager = PushDeviceTokenManager(token)
        
        XCTAssertTrue(manager.shouldUpdateToken(newToken))
        XCTAssertFalse(manager.shouldUpdateToken(token))
    }
    
    
    func test_08_update_local_token() {
        let newToken = "newToken"
        
        let manager = PushDeviceTokenManager()
        manager.setDeviceToken(newToken)
        
        XCTAssertEqual(manager.deviceToken, newToken)
        
        let pushDeviceToken = FRAClient.storage.getPushDeviceToken()
        XCTAssertEqual(pushDeviceToken?.tokenId, newToken)
    }
    
}
