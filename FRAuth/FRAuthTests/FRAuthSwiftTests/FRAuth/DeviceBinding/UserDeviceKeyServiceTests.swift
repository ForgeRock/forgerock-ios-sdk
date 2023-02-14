// 
//  UserDeviceKeyServiceTests.swift
//  FRAuthTests
//
//  Copyright (c) 2022-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth


class UserDeviceKeyServiceTests: XCTestCase {
    
    func test_01_init() {
        let userId = "Test User Id 1"
        let userName = "User Name"
        let key = "Test Key 1"
        let authenticationType = DeviceBindingAuthenticationType.none
        let deviceRepository = KeychainDeviceRepository()
        let _ = deviceRepository.deleteAllKeys()
        do {
            let uuid = try deviceRepository.persist(userId: userId, userName: userName, key: key, authenticationType: authenticationType, createdAt: Date().timeIntervalSince1970)
            XCTAssertFalse(uuid.isEmpty)
            
        } catch {
            XCTFail("Failed to persist user info")
        }
        
        let userDeviceKeyService = UserDeviceKeyService(deviceRepository: deviceRepository)
        
        XCTAssertFalse(userDeviceKeyService.getAll().isEmpty)
        XCTAssertEqual(userDeviceKeyService.getAll().first!.userId, userId)
        
        let _ = deviceRepository.delete(key: key)
    }
    
    
    func test_02_getKeyStatus_noKeysFound() {
        let userId = "Test User Id 2"
        let userName = "User Name"
        let key = "Test Key 2"
        let authenticationType = DeviceBindingAuthenticationType.none
        let deviceRepository = KeychainDeviceRepository()
        do {
            let uuid = try deviceRepository.persist(userId: "Wrong user Id", userName: userName, key: key, authenticationType: authenticationType, createdAt: Date().timeIntervalSince1970)
            XCTAssertFalse(uuid.isEmpty)
            
        } catch {
            XCTFail("Failed to persist user info")
        }
        
        let userDeviceKeyService = UserDeviceKeyService(deviceRepository: deviceRepository)
        
        XCTAssertFalse(userDeviceKeyService.getAll().isEmpty)
        let status = userDeviceKeyService.getKeyStatus(userId: userId)
        switch status {
        case .noKeysFound:
            return
        default:
            XCTFail("Wrong Key status")
        }
        
        let _ = deviceRepository.delete(key: key)
    }
    
    
    func test_03_getKeyStatus_singleKeyFound() {
        let userId = "Test User Id 3"
        let userName = "User Name"
        let key = "Test Key 3"
        let authenticationType = DeviceBindingAuthenticationType.none
        let deviceRepository = KeychainDeviceRepository()
        do {
            let uuid = try deviceRepository.persist(userId: userId, userName: userName, key: key, authenticationType: authenticationType, createdAt: Date().timeIntervalSince1970)
            XCTAssertFalse(uuid.isEmpty)
            
        } catch {
            XCTFail("Failed to persist user info")
        }
        
        let userDeviceKeyService = UserDeviceKeyService(deviceRepository: deviceRepository)
        
        XCTAssertFalse(userDeviceKeyService.getAll().isEmpty)
        let status = userDeviceKeyService.getKeyStatus(userId: userId)
        switch status {
        case .singleKeyFound(let key):
            XCTAssertEqual(key.userId, userId)
        default:
            XCTFail("Wrong Key status")
        }
        
        let _ = deviceRepository.delete(key: key)
    }
    
    
    func test_04_getKeyStatus_multipleKeysFound() {
        let userId = "Test User Id 4"
        let userName = "User Name"
        let key = "Test Key 4"
        let authenticationType = DeviceBindingAuthenticationType.none
        let deviceRepository = KeychainDeviceRepository()
        do {
            let uuid1 = try deviceRepository.persist(userId: userId, userName: userName, key: key, authenticationType: authenticationType, createdAt: Date().timeIntervalSince1970)
            XCTAssertFalse(uuid1.isEmpty)
            let uuid2 = try deviceRepository.persist(userId: userId, userName: userName, key: key, authenticationType: authenticationType, createdAt: Date().timeIntervalSince1970)
            XCTAssertFalse(uuid2.isEmpty)
            
        } catch {
            XCTFail("Failed to persist user info")
        }
        
        let userDeviceKeyService = UserDeviceKeyService(deviceRepository: deviceRepository)
        
        XCTAssertFalse(userDeviceKeyService.getAll().isEmpty)
        let status = userDeviceKeyService.getKeyStatus(userId: nil)
        switch status {
        case .multipleKeysFound(let keys):
            XCTAssertTrue(keys.count > 1)
        default:
            XCTFail("Wrong Key status")
        }
        
        let _ = deviceRepository.delete(key: key)
    }
    
    
    func test_05_delete() {
        let userId = "Test User Id 5"
        let userName = "User Name"
        let key1 = "Test Key 5.1"
        let key2 = "Test Key 5.2"
        let authenticationType = DeviceBindingAuthenticationType.none
        let deviceRepository = KeychainDeviceRepository()
        let _ = deviceRepository.deleteAllKeys()
        do {
            let uuid1 = try deviceRepository.persist(userId: userId, userName: userName, key: key1, authenticationType: authenticationType, createdAt: Date().timeIntervalSince1970)
            XCTAssertFalse(uuid1.isEmpty)
            let uuid2 = try deviceRepository.persist(userId: userId, userName: userName, key: key2, authenticationType: authenticationType, createdAt: Date().timeIntervalSince1970)
            XCTAssertFalse(uuid2.isEmpty)
            
        } catch {
            XCTFail("Failed to persist user info")
        }
        
        let userDeviceKeyService = UserDeviceKeyService(deviceRepository: deviceRepository)
        
        XCTAssertTrue(userDeviceKeyService.getAll().count == 2)
        
        let userkey = userDeviceKeyService.getAll().first!
        userDeviceKeyService.delete(userKey: userkey)
        XCTAssertTrue(userDeviceKeyService.getAll().count == 1)
        
        //delete same key
        userDeviceKeyService.delete(userKey: userkey)
        XCTAssertTrue(userDeviceKeyService.getAll().count == 1)
        
        let _ = deviceRepository.deleteAllKeys()
    }
}
