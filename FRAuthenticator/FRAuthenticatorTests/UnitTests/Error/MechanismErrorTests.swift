// 
//  MechanismErrorTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class MechanismErrorTests: FRABaseTests {

    func test_01_domain() {
        XCTAssertEqual(MechanismError.errorDomain, "com.forgerock.ios.frauthenticator.mechanism")
    }
    
    
    func test_02_invalidQRCode() {
        let error = MechanismError.invalidQRCode
        
        XCTAssertEqual(error.code, 6000000)
        XCTAssertEqual(error.errorCode, 6000000)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Invalid QR Code given for Mechanism initialization")
    }
    
    
    func test_03_invalidType() {
        let error = MechanismError.invalidType
        
        XCTAssertEqual(error.code, 6000001)
        XCTAssertEqual(error.errorCode, 6000001)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Invalid or missing auth type from given QR Code")
    }
    
    
    func test_04_missingInformation() {
        let error = MechanismError.missingInformation("something")
        
        XCTAssertEqual(error.code, 6000002)
        XCTAssertEqual(error.errorCode, 6000002)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Missing information: something")
    }
    
    
    func test_05_invalidInformation() {
        let error = MechanismError.invalidInformation("something")
        
        XCTAssertEqual(error.code, 6000003)
        XCTAssertEqual(error.errorCode, 6000003)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Invalid information: something")
    }
    
    
    func test_06_already_exists() {
        let error = MechanismError.alreadyExists("something")
        
        XCTAssertEqual(error.code, 6000004)
        XCTAssertEqual(error.errorCode, 6000004)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Given Mechanism already exsists: Mechanism.identifier (something)")
    }
    
    
    func test_07_failed_to_update_information() {
        let error = MechanismError.failedToUpdateInformation("something")
        
        XCTAssertEqual(error.code, 6000005)
        XCTAssertEqual(error.errorCode, 6000005)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Failed to update current Mechanism object in StorageClient: (something)")
    }
}
