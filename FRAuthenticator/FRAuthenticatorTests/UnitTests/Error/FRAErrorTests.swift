// 
//  FRAErrorTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class FRAErrorTests: FRABaseTests {

    func test_01_domain() {
        XCTAssertEqual(FRAError.errorDomain, "com.forgerock.ios.frauthenticator.fra")
    }
    
    
    func test_02_invalid_state_for_changing_storage() {
        let error = FRAError.invalidStateForChangingStorage
        
        XCTAssertEqual(error.code, 8000000)
        XCTAssertEqual(error.errorCode, 8000000)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "SDK has already started; StorageClient cannot be changed after initialization")
    }
}
