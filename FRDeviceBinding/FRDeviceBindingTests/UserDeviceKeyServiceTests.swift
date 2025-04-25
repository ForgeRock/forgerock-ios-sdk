// 
//  UserDeviceKeyServiceTests.swift
//  FRDeviceBindingTests
//
//  Copyright (c) 2022 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth
@testable import FRDeviceBinding


class UserDeviceKeyServiceTests: XCTestCase {
    
    func test_01_init() {
        let userId = "Test User Id 1"
        let userName = "User Name"
        let key = "Test Key 1"
        let authenticationType = DeviceBindingAuthenticationType.none
        let deviceRepository = LocalDeviceBindingRepository()
        let _ = deviceRepository.deleteAllKeys()
        let uuid = UUID().uuidString
        let userKey = UserKey(id: key, userId: userId, userName: userName, kid: uuid, authType: authenticationType, createdAt: Date().timeIntervalSince1970)
        do {
            try deviceRepository.persist(userKey: userKey)
            
        } catch {
            XCTFail("Failed to persist user info")
        }
        
        let userDeviceKeyService = UserDeviceKeyService(localDeviceBindingRepository: deviceRepository)
        
        XCTAssertFalse(userDeviceKeyService.getAll().isEmpty)
        XCTAssertEqual(userDeviceKeyService.getAll().first!.userId, userId)
        
        let _ = deviceRepository.delete(userKey: userKey)
    }
    
    
    func test_02_getKeyStatus_noKeysFound() {
        let userId = "Test User Id 2"
        let userName = "User Name"
        let key = "Test Key 2"
        let authenticationType = DeviceBindingAuthenticationType.none
        let deviceRepository = LocalDeviceBindingRepository()
        let uuid = UUID().uuidString
        let userKey = UserKey(id: key, userId: "Wrong user Id", userName: userName, kid: uuid, authType: authenticationType, createdAt: Date().timeIntervalSince1970)
        do {
            try deviceRepository.persist(userKey: userKey)
            
        } catch {
            XCTFail("Failed to persist user info")
        }
        
        let userDeviceKeyService = UserDeviceKeyService(localDeviceBindingRepository: deviceRepository)
        
        XCTAssertFalse(userDeviceKeyService.getAll().isEmpty)
        let status = userDeviceKeyService.getKeyStatus(userId: userId)
        switch status {
        case .noKeysFound:
            return
        default:
            XCTFail("Wrong Key status")
        }
        
        let _ = deviceRepository.delete(userKey: userKey)
    }
    
    
    func test_03_getKeyStatus_singleKeyFound() {
        let userId = "Test User Id 3"
        let userName = "User Name"
        let key = "Test Key 3"
        let authenticationType = DeviceBindingAuthenticationType.none
        let deviceRepository = LocalDeviceBindingRepository()
        let uuid = UUID().uuidString
        let userKey = UserKey(id: key, userId: userId, userName: userName, kid: uuid, authType: authenticationType, createdAt: Date().timeIntervalSince1970)
        do {
            try deviceRepository.persist(userKey: userKey)
            
        } catch {
            XCTFail("Failed to persist user info")
        }
        
        let userDeviceKeyService = UserDeviceKeyService(localDeviceBindingRepository: deviceRepository)
        
        XCTAssertFalse(userDeviceKeyService.getAll().isEmpty)
        let status = userDeviceKeyService.getKeyStatus(userId: userId)
        switch status {
        case .singleKeyFound(let key):
            XCTAssertEqual(key.userId, userId)
        default:
            XCTFail("Wrong Key status")
        }
        
        let _ = deviceRepository.delete(userKey: userKey)
    }
    
    
    func test_04_getKeyStatus_multipleKeysFound() {
        let userId = "Test User Id 4"
        let userName = "User Name"
        let key = "Test Key 4"
        let authenticationType = DeviceBindingAuthenticationType.none
        let deviceRepository = LocalDeviceBindingRepository()
        let uuid1 = UUID().uuidString
        let userKey1 = UserKey(id: key, userId: userId, userName: userName, kid: uuid1, authType: authenticationType, createdAt: Date().timeIntervalSince1970)
        let uuid2 = UUID().uuidString
        let userKey2 = UserKey(id: key, userId: userId, userName: userName, kid: uuid2, authType: authenticationType, createdAt: Date().timeIntervalSince1970)
        do {
            try deviceRepository.persist(userKey: userKey1)
            try deviceRepository.persist(userKey: userKey2)
            
        } catch {
            XCTFail("Failed to persist user info")
        }
        
        let userDeviceKeyService = UserDeviceKeyService(localDeviceBindingRepository: deviceRepository)
        
        XCTAssertFalse(userDeviceKeyService.getAll().isEmpty)
        let status = userDeviceKeyService.getKeyStatus(userId: nil)
        switch status {
        case .multipleKeysFound(let keys):
            XCTAssertTrue(keys.count > 1)
        default:
            XCTFail("Wrong Key status")
        }
        
        let _ = deviceRepository.delete(userKey: userKey1)
        let _ = deviceRepository.delete(userKey: userKey2)
    }
    
    
    func test_05_delete() {
        let userId = "Test User Id 5"
        let userName = "User Name"
        let key1 = "Test Key 5.1"
        let key2 = "Test Key 5.2"
        let authenticationType = DeviceBindingAuthenticationType.none
        let deviceRepository = LocalDeviceBindingRepository()
        let _ = deviceRepository.deleteAllKeys()
        let uuid1 = UUID().uuidString
        let userKey1 = UserKey(id: key1, userId: userId, userName: userName, kid: uuid1, authType: authenticationType, createdAt: Date().timeIntervalSince1970)
        let uuid2 = UUID().uuidString
        let userKey2 = UserKey(id: key2, userId: userId, userName: userName, kid: uuid2, authType: authenticationType, createdAt: Date().timeIntervalSince1970)
        do {
            try deviceRepository.persist(userKey: userKey1)
            try deviceRepository.persist(userKey: userKey2)
            
        } catch {
            XCTFail("Failed to persist user info")
        }
        
        let userDeviceKeyService = UserDeviceKeyService(localDeviceBindingRepository: deviceRepository)
        
        XCTAssertTrue(userDeviceKeyService.getAll().count == 2)
        
        let userkey = userDeviceKeyService.getAll().first!
        try? userDeviceKeyService.delete(userKey: userkey, forceDelete: true)
        XCTAssertTrue(userDeviceKeyService.getAll().count == 1)
        
        //delete same key
        try? userDeviceKeyService.delete(userKey: userkey, forceDelete: true)
        XCTAssertTrue(userDeviceKeyService.getAll().count == 1)
        
        let _ = deviceRepository.deleteAllKeys()
    }
}
