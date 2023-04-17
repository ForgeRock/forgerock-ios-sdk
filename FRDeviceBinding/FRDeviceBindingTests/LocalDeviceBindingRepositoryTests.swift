// 
//  LocalDeviceBindingRepositoryTests.swift
//  FRAuthTests
//
//  Copyright (c) 2022-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth
@testable import FRDeviceBinding


class LocalDeviceBindingRepositoryTests: FRAuthBaseTest {
    
    func test_01_persist_without_accessGroup() {
        let userId = "Test User Id 1"
        let userName = "User Name"
        let key = "Test Key 1"
        let authenticationType = DeviceBindingAuthenticationType.none
        let deviceRepository = LocalDeviceBindingRepository()
        let createdAt = Date().timeIntervalSince1970
        let uuid = UUID().uuidString
        
        do {
            let userKey = UserKey(id: key, userId: userId, userName: userName, kid: uuid, authType: authenticationType, createdAt: createdAt)
            try deviceRepository.persist(userKey: userKey)
            
            let allKeys = deviceRepository.getAllKeys()
            XCTAssertNotNil(allKeys)
            
            let actualUserKey = allKeys.first { $0.id == key }
            
            XCTAssertTrue(actualUserKey == userKey)
            
            //cleanup
            let _ = deviceRepository.delete(userKey: userKey)
        } catch {
            XCTFail("Failed to persist user info")
        }
    }
    
    
    func test_02_getAllKeys_without_accessGroup() {
        let userId = "Test User Id 2"
        let userName = "User Name"
        let key = "Test Key 2"
        let authenticationType = DeviceBindingAuthenticationType.none
        let deviceRepository = LocalDeviceBindingRepository()
        let createdAt = Date().timeIntervalSince1970
        let uuid = UUID().uuidString
        
        do {
            let userKey = UserKey(id: key, userId: userId, userName: userName, kid: uuid, authType: authenticationType, createdAt: createdAt)
            try deviceRepository.persist(userKey: userKey)
            
            var allKeys = deviceRepository.getAllKeys()
            XCTAssertNotNil(allKeys)
            
            XCTAssertTrue(allKeys.count > 0)
            
            deviceRepository.delete(userKey: userKey)
            
            
            allKeys = deviceRepository.getAllKeys()
            XCTAssertNotNil(allKeys)
            XCTAssertNil(allKeys.first { $0.id == key })
            
            //cleanup
            let _ = deviceRepository.delete(userKey: userKey)
        } catch {
            XCTFail("Failed to persist user info")
        }
    }
    
    
    func test_03_persist_with_accessGroup() {
        self.config.configPlistFileName = "FRAuthConfig"
        FRAuth.configPlistFileName = "FRAuthConfig"
        
        //  Init SDK
        self.startSDK()
        
        let userId = "Test User Id 1"
        let userName = "User Name"
        let key = "Test Key 1"
        let authenticationType = DeviceBindingAuthenticationType.none
        let deviceRepository = LocalDeviceBindingRepository()
        let createdAt = Date().timeIntervalSince1970
        let uuid = UUID().uuidString
        
        do {
            
            let userKey = UserKey(id: key, userId: userId, userName: userName, kid: uuid, authType: authenticationType, createdAt: createdAt)
            try deviceRepository.persist(userKey: userKey)
            
            let allKeys = deviceRepository.getAllKeys()
            XCTAssertNotNil(allKeys)
            
            let actualUserKey = allKeys.first { $0.id == key }
            
            XCTAssertTrue(actualUserKey == userKey)
            
            //cleanup
            let _ = deviceRepository.delete(userKey: userKey)
        } catch {
            XCTFail("Failed to persist user info")
        }
    }
    
    
    func test_04_getAllKeys_with_accessGroup() {
        self.config.configPlistFileName = "FRAuthConfig"
        FRAuth.configPlistFileName = "FRAuthConfig"
        
        //  Init SDK
        self.startSDK()
        
        let userId = "Test User Id 2"
        let userName = "User Name"
        let key = "Test Key 2"
        let authenticationType = DeviceBindingAuthenticationType.none
        let deviceRepository = LocalDeviceBindingRepository()
        let createdAt = Date().timeIntervalSince1970
        let uuid = UUID().uuidString
        
        do {
            let userKey = UserKey(id: key, userId: userId, userName: userName, kid: uuid, authType: authenticationType, createdAt: createdAt)
            try deviceRepository.persist(userKey: userKey)
            
            var allKeys = deviceRepository.getAllKeys()
            XCTAssertNotNil(allKeys)
            
            XCTAssertTrue(allKeys.count > 0)
            
            deviceRepository.delete(userKey: userKey)
            
            
            allKeys = deviceRepository.getAllKeys()
            XCTAssertNotNil(allKeys)
            XCTAssertNil(allKeys.first { $0.id == key })
            
            //cleanup
            let _ = deviceRepository.delete(userKey: userKey)
        } catch {
            XCTFail("Failed to persist user info")
        }
    }
    
}
