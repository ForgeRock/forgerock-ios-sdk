// 
//  FRAuthenticatorTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class FRAuthenticatorTests: FRABaseTests {

    override func tearDown() {
        FRAClient.shared = nil
    }
    
    
    func test_01_init_success() {
        XCTAssertNil(FRAClient.shared)
        FRAClient.start()
        XCTAssertNotNil(FRAClient.shared)
    }
    
    
    func test_02_storage_client_test() {
        XCTAssertNil(FRAClient.shared)
        
        do {
            try FRAClient.setStorage(storage: KeychainServiceClient())
            FRAClient.start()
            XCTAssertNotNil(FRAClient.shared)
            try FRAClient.setStorage(storage: KeychainServiceClient())
        }
        catch FRAError.invalidStateForChangingStorage {
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
}
