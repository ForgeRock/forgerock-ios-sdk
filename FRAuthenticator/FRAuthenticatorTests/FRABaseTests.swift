// 
//  FRABaseTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class FRABaseTests: FRBaseTestCase {
    
    override func setUp() {
        super.setUp()
    }
    

    override func tearDown() {
        super.tearDown()
        
        if shouldCleanup {
            FRAPushHandler.shared.clearDeviceToken()
            if let keychainStorageClient = FRAClient.storage as? KeychainServiceClient {
                keychainStorageClient.accountStorage.deleteAll()
                keychainStorageClient.mechanismStorage.deleteAll()
                keychainStorageClient.notificationStorage.deleteAll()
                keychainStorageClient.pushDeviceTokenStorage.deleteAll()
                FRAClient.storage = KeychainServiceClient()
            }
            if let keychainStorageClient = FRAClient.storage as? DummyStorageClient {
                keychainStorageClient.defaultStorageClient.accountStorage.deleteAll()
                keychainStorageClient.defaultStorageClient.mechanismStorage.deleteAll()
                keychainStorageClient.defaultStorageClient.notificationStorage.deleteAll()
                keychainStorageClient.defaultStorageClient.pushDeviceTokenStorage.deleteAll()
                FRAClient.storage = DummyStorageClient()
            }
            FRAClient.shared = nil
        }
    }
}
