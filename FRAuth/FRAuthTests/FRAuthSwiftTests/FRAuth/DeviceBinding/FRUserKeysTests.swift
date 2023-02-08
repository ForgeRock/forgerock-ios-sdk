// 
//  FRUserKeysTests.swift
//  FRAuthTests
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

final class FRUserKeysTests: XCTestCase {

    func test_01_loadAll() {
        let deviceRepository = KeychainDeviceRepository()
        let userKeyService = UserDeviceKeyService(deviceRepository: deviceRepository)
        let frUserKeys = FRUserKeys(userKeyService: userKeyService)
        
        let _ = deviceRepository.deleteAllKeys()
        
        let userId1 = "Test User Id 1"
        let userName1 = "User Name 1"
        let key1 = "Test Key 1"
        let type1 = DeviceBindingAuthenticationType.applicationPin
        let createdAt1 = Date().timeIntervalSince1970
        
        let uuid1 = try! deviceRepository.persist(userId: userId1, userName: userName1, key: key1, authenticationType: type1, createdAt: createdAt1)
        let userKey1 = UserKey(userId: userId1, userName: userName1, kid: uuid1, authType: type1, keyAlias: key1, createdAt: createdAt1)
        
        var userKeys = frUserKeys.loadAll()
        XCTAssertEqual(userKeys.count, 1)
        XCTAssertEqual(userKeys.first, userKey1)
        
        let userId2 = "Test User Id 2"
        let userName2 = "User Name 2"
        let key2 = "Test Key 2"
        let type2 = DeviceBindingAuthenticationType.biometricOnly
        let createdAt2 = Date().timeIntervalSince1970
        
        let uuid2 = try! deviceRepository.persist(userId: userId2, userName: userName2, key: key2, authenticationType: type2, createdAt: createdAt2)
        let userKey2 = UserKey(userId: userId2, userName: userName2, kid: uuid2, authType: type2, keyAlias: key2, createdAt: createdAt2)
        
        userKeys = frUserKeys.loadAll()
        XCTAssertEqual(userKeys.count, 2)
        XCTAssertTrue(userKeys.contains(userKey1))
        XCTAssertTrue(userKeys.contains(userKey2))
    }
    
    
    func test_02_delete_userKey() {
        let deviceRepository = KeychainDeviceRepository()
        let userKeyService = UserDeviceKeyService(deviceRepository: deviceRepository)
        let frUserKeys = FRUserKeys(userKeyService: userKeyService)
        
        let _ = deviceRepository.deleteAllKeys()

        let userId1 = "Test User Id 1"
        let userName1 = "User Name 1"
        let key1 = "Test Key 1"
        let type1 = DeviceBindingAuthenticationType.applicationPin
        let createdAt1 = Date().timeIntervalSince1970
        
        let uuid1 = try! deviceRepository.persist(userId: userId1, userName: userName1, key: key1, authenticationType: type1, createdAt: createdAt1)
        let userKey1 = UserKey(userId: userId1, userName: userName1, kid: uuid1, authType: type1, keyAlias: key1, createdAt: createdAt1)
        
        
        let userId2 = "Test User Id 2"
        let userName2 = "User Name 2"
        let key2 = "Test Key 2"
        let type2 = DeviceBindingAuthenticationType.biometricOnly
        let createdAt2 = Date().timeIntervalSince1970
        
        let uuid2 = try! deviceRepository.persist(userId: userId2, userName: userName2, key: key2, authenticationType: type2, createdAt: createdAt2)
        let userKey2 = UserKey(userId: userId2, userName: userName2, kid: uuid2, authType: type2, keyAlias: key2, createdAt: createdAt2)
        
        var userKeys = frUserKeys.loadAll()
        XCTAssertEqual(userKeys.count, 2)
        XCTAssertTrue(userKeys.contains(userKey1))
        XCTAssertTrue(userKeys.contains(userKey2))
        
        frUserKeys.delete(userkey: userKey1)
        userKeys = frUserKeys.loadAll()
        XCTAssertEqual(userKeys.count, 1)
        XCTAssertTrue(userKeys.contains(userKey2))
        
        frUserKeys.delete(userkey: userKey2)
        userKeys = frUserKeys.loadAll()
        XCTAssertEqual(userKeys.count, 0)
    }
}

