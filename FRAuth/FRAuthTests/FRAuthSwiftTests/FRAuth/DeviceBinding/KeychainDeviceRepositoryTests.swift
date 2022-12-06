// 
//  KeychainDeviceRepositoryTests.swift
//  FRAuthTests
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth


class KeychainDeviceRepositoryTests: XCTestCase {
    
    func test_01_persist() {
        let userId = "Test User Id 1"
        let userName = "User Name"
        let key = "Test Key 1"
        let authenticationType = DeviceBindingAuthenticationType.none
        let sharedPreferencesDeviceRepository = KeychainDeviceRepository(uuid: nil, keychainService: nil)
        
        do {
            let uuid = try sharedPreferencesDeviceRepository.persist(userId: userId, userName: userName, key: key, authenticationType: authenticationType)
            XCTAssertFalse(uuid.isEmpty)
            
            let allKeys = sharedPreferencesDeviceRepository.getAllKeys()
            XCTAssertNotNil(allKeys)
            
            let userKeyJson = allKeys![key] as? String
            XCTAssertNotNil(userKeyJson)
            
            XCTAssertTrue(userKeyJson!.contains(userId))
            XCTAssertTrue(userKeyJson!.contains(userName))
            XCTAssertTrue(userKeyJson!.contains(uuid))
            XCTAssertTrue(userKeyJson!.contains(authenticationType.rawValue))
        } catch {
            XCTFail("Failed to persist user info")
        }
    }
    
    
    func test_02_getAllKeys() {
        let userId = "Test User Id 2"
        let userName = "User Name"
        let key = "Test Key 2"
        let authenticationType = DeviceBindingAuthenticationType.none
        let sharedPreferencesDeviceRepository = KeychainDeviceRepository(uuid: nil, keychainService: nil)
        
        do {
            let uuid = try sharedPreferencesDeviceRepository.persist(userId: userId, userName: userName, key: key, authenticationType: authenticationType)
            XCTAssertFalse(uuid.isEmpty)
            
            var allKeys = sharedPreferencesDeviceRepository.getAllKeys()
            XCTAssertNotNil(allKeys)
            XCTAssertNotNil(allKeys![key])
            
            XCTAssertTrue(allKeys!.count > 0)
            
            let deleted = sharedPreferencesDeviceRepository.delete(key: key)
            XCTAssertTrue(deleted)
            
            allKeys = sharedPreferencesDeviceRepository.getAllKeys()
            XCTAssertNotNil(allKeys)
            XCTAssertNil(allKeys![key])
            
        } catch {
            XCTFail("Failed to persist user info")
        }
    }
}
