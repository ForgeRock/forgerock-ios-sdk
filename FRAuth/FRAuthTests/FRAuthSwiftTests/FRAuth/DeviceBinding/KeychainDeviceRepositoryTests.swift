// 
//  KeychainDeviceRepositoryTests.swift
//  FRAuthTests
//
//  Copyright (c) 2022-2023 ForgeRock. All rights reserved.
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
        let deviceRepository = KeychainDeviceRepository()
        let createdAt = Date().timeIntervalSince1970
        
        do {
            
            let uuid = try deviceRepository.persist(userId: userId, userName: userName, key: key, authenticationType: authenticationType, createdAt: createdAt)
            let userKey = UserKey(userId: userId, userName: userName, kid: uuid, authType: authenticationType, keyAlias: key, createdAt: createdAt)
            XCTAssertFalse(uuid.isEmpty)
            
            let allKeys = deviceRepository.getAllKeys()
            XCTAssertNotNil(allKeys)
            
            let userKeyJson = allKeys![key]
            XCTAssertNotNil(userKeyJson)
            
            let data = (userKeyJson as? String)?.data(using: .utf8)
            let actualUserKey = try! JSONDecoder().decode(UserKey.self, from: data!)
            
            XCTAssertTrue(actualUserKey == userKey)

            //cleanup
            let _ = deviceRepository.delete(key: key)
        } catch {
            XCTFail("Failed to persist user info")
        }
    }
    
    
    func test_02_getAllKeys() {
        let userId = "Test User Id 2"
        let userName = "User Name"
        let key = "Test Key 2"
        let authenticationType = DeviceBindingAuthenticationType.none
        let deviceRepository = KeychainDeviceRepository()
        let createdAt = Date().timeIntervalSince1970
        
        do {
            let uuid = try deviceRepository.persist(userId: userId, userName: userName, key: key, authenticationType: authenticationType, createdAt: createdAt)
            XCTAssertFalse(uuid.isEmpty)
            
            var allKeys = deviceRepository.getAllKeys()
            XCTAssertNotNil(allKeys)
            XCTAssertNotNil(allKeys![key])
            
            XCTAssertTrue(allKeys!.count > 0)
            
            let deleted = deviceRepository.delete(key: key)
            XCTAssertTrue(deleted)
            
            allKeys = deviceRepository.getAllKeys()
            XCTAssertNotNil(allKeys)
            XCTAssertNil(allKeys![key])
            
            //cleanup
            let _ = deviceRepository.delete(key: key)
        } catch {
            XCTFail("Failed to persist user info")
        }
    }
}
