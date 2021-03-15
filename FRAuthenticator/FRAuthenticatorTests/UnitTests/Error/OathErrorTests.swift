// 
//  OathErrorTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class OathErrorTests: FRABaseTests {

    func test_01_domain() {
        XCTAssertEqual(OathError.errorDomain, "com.forgerock.ios.frauthenticator.oath")
    }
    
    
    func test_02_invalid_secret() {
        let error = OathError.invalidSecret
        
        XCTAssertEqual(error.code, 9000000)
        XCTAssertEqual(error.errorCode, 9000000)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Invalid secret value; failed to parse secret")
    }
}
