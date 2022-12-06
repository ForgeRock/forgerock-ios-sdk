// 
//  UserDeviceKeyServiceTests.swift
//  FRAuthTests
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
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
        let sharedPreferencesDeviceRepository = KeychainDeviceRepository(uuid: nil, keychainService: nil)
        do {
            let uuid = try sharedPreferencesDeviceRepository.persist(userId: userId, userName: userName, key: key, authenticationType: authenticationType)
            XCTAssertFalse(uuid.isEmpty)
            
        } catch {
            XCTFail("Failed to persist user info")
        }
        
        let userDeviceKeyService = UserDeviceKeyService(encryptedPreference: sharedPreferencesDeviceRepository)
        
        XCTAssertFalse(userDeviceKeyService.userKeys.isEmpty)
        XCTAssertEqual(userDeviceKeyService.userKeys.first!.userId, userId)
        
        let _ = sharedPreferencesDeviceRepository.delete(key: key)
    }
    
    
    func test_02_getKeyStatus_noKeysFound() {
        let userId = "Test User Id 2"
        let userName = "User Name"
        let key = "Test Key 2"
        let authenticationType = DeviceBindingAuthenticationType.none
        let sharedPreferencesDeviceRepository = KeychainDeviceRepository(uuid: nil, keychainService: nil)
        do {
            let uuid = try sharedPreferencesDeviceRepository.persist(userId: "Wrong user Id", userName: userName, key: key, authenticationType: authenticationType)
            XCTAssertFalse(uuid.isEmpty)
            
        } catch {
            XCTFail("Failed to persist user info")
        }
        
        let userDeviceKeyService = UserDeviceKeyService(encryptedPreference: sharedPreferencesDeviceRepository)
        
        XCTAssertFalse(userDeviceKeyService.userKeys.isEmpty)
        let status = userDeviceKeyService.getKeyStatus(userId: userId)
        switch status {
        case .noKeysFound:
            return
        default:
            XCTFail("Wrong Key status")
        }
        
        let _ = sharedPreferencesDeviceRepository.delete(key: key)
    }
    
    
    func test_03_getKeyStatus_singleKeyFound() {
        let userId = "Test User Id 3"
        let userName = "User Name"
        let key = "Test Key 3"
        let authenticationType = DeviceBindingAuthenticationType.none
        let sharedPreferencesDeviceRepository = KeychainDeviceRepository(uuid: nil, keychainService: nil)
        do {
            let uuid = try sharedPreferencesDeviceRepository.persist(userId: userId, userName: userName, key: key, authenticationType: authenticationType)
            XCTAssertFalse(uuid.isEmpty)
            
        } catch {
            XCTFail("Failed to persist user info")
        }
        
        let userDeviceKeyService = UserDeviceKeyService(encryptedPreference: sharedPreferencesDeviceRepository)
        
        XCTAssertFalse(userDeviceKeyService.userKeys.isEmpty)
        let status = userDeviceKeyService.getKeyStatus(userId: userId)
        switch status {
        case .singleKeyFound(let key):
            XCTAssertEqual(key.userId, userId)
        default:
            XCTFail("Wrong Key status")
        }
        
        let _ = sharedPreferencesDeviceRepository.delete(key: key)
    }
    
    
    func test_04_getKeyStatus_multipleKeysFound() {
        let userId = "Test User Id 5"
        let userName = "User Name"
        let key = "Test Key 4"
        let authenticationType = DeviceBindingAuthenticationType.none
        let sharedPreferencesDeviceRepository = KeychainDeviceRepository(uuid: nil, keychainService: nil)
        do {
            let uuid1 = try sharedPreferencesDeviceRepository.persist(userId: userId, userName: userName, key: key, authenticationType: authenticationType)
            XCTAssertFalse(uuid1.isEmpty)
            let uuid2 = try sharedPreferencesDeviceRepository.persist(userId: userId, userName: userName, key: key, authenticationType: authenticationType)
            XCTAssertFalse(uuid2.isEmpty)
            
        } catch {
            XCTFail("Failed to persist user info")
        }
        
        let userDeviceKeyService = UserDeviceKeyService(encryptedPreference: sharedPreferencesDeviceRepository)
        
        XCTAssertFalse(userDeviceKeyService.userKeys.isEmpty)
        let status = userDeviceKeyService.getKeyStatus(userId: nil)
        switch status {
        case .multipleKeysFound(let keys):
            XCTAssertTrue(keys.count > 1)
        default:
            XCTFail("Wrong Key status")
        }
        
        let _ = sharedPreferencesDeviceRepository.delete(key: key)
    }
}
