// 
//  WebAuthnErrorTests.swift
//  FRAuthTests
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest

class WebAuthnErrorTests: FRAuthBaseTest {

    func test_01_domain() {
        XCTAssertEqual(WebAuthnError.errorDomain, "com.forgerock.ios.frauth.webauthn")
    }
    
    
    func test_02_bad_data() {
        let error = WebAuthnError.badData
        
        XCTAssertEqual(error.code, 1600001)
        XCTAssertEqual(error.errorCode, 1600001)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.convertToAMErrorType(), "DataError")
        XCTAssertEqual(error.convertToWebAuthnOutcome(), "ERROR::DataError:")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Provided data is inadequate"))
    }
    
    
    func test_03_bad_operation() {
        let error = WebAuthnError.badOperation
        
        XCTAssertEqual(error.code, 1600002)
        XCTAssertEqual(error.errorCode, 1600002)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.convertToAMErrorType(), "UnknownError")
        XCTAssertEqual(error.convertToWebAuthnOutcome(), "ERROR::UnknownError:")
        XCTAssertTrue(error.localizedDescription.hasPrefix("The operation failed for operation-specific reason"))
    }
    
    
    func test_04_invalid_state() {
        let error = WebAuthnError.invalidState
        
        XCTAssertEqual(error.code, 1600003)
        XCTAssertEqual(error.errorCode, 1600003)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.convertToAMErrorType(), "InvalidStateError")
        XCTAssertEqual(error.convertToWebAuthnOutcome(), "ERROR::InvalidStateError:")
        XCTAssertTrue(error.localizedDescription.hasPrefix("The object is in an invalid state"))
    }
    
    
    func test_05_constraint() {
        let error = WebAuthnError.constraint
        
        XCTAssertEqual(error.code, 1600004)
        XCTAssertEqual(error.errorCode, 1600004)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.convertToAMErrorType(), "ConstraintError")
        XCTAssertEqual(error.convertToWebAuthnOutcome(), "ERROR::ConstraintError:")
        XCTAssertTrue(error.localizedDescription.hasPrefix("A mutation operation in a transaction failed because a constraint was not satisfied"))
    }
    
    
    func test_06_cancelled() {
        let error = WebAuthnError.cancelled
        
        XCTAssertEqual(error.code, 1600005)
        XCTAssertEqual(error.errorCode, 1600005)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.convertToAMErrorType(), "UnknownError")
        XCTAssertEqual(error.convertToWebAuthnOutcome(), "ERROR::UnknownError:")
        XCTAssertTrue(error.localizedDescription.hasPrefix("The operation is cancelled"))
    }
    
    
    func test_07_timeout() {
        let error = WebAuthnError.timeout
        
        XCTAssertEqual(error.code, 1600006)
        XCTAssertEqual(error.errorCode, 1600006)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.convertToAMErrorType(), "TimeoutError")
        XCTAssertEqual(error.convertToWebAuthnOutcome(), "ERROR::TimeoutError:")
        XCTAssertTrue(error.localizedDescription.hasPrefix("The operation timed out"))
    }
    
    
    func test_08_not_allowed() {
        let error = WebAuthnError.notAllowed
        
        XCTAssertEqual(error.code, 1600007)
        XCTAssertEqual(error.errorCode, 1600007)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.convertToAMErrorType(), "NotAllowedError")
        XCTAssertEqual(error.convertToWebAuthnOutcome(), "ERROR::NotAllowedError:")
        XCTAssertTrue(error.localizedDescription.hasPrefix("The request is not allowed by the user agent or the platform in the current context"))
    }
    
    
    func test_09_unsupported() {
        let error = WebAuthnError.unsupported
        
        XCTAssertEqual(error.code, 1600008)
        XCTAssertEqual(error.errorCode, 1600008)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.convertToAMErrorType(), "NotSupportedError")
        XCTAssertEqual(error.convertToWebAuthnOutcome(), "unsupported")
        XCTAssertTrue(error.localizedDescription.hasPrefix("The operation is not supported"))
    }
    
    
    func test_10_unknown() {
        let error = WebAuthnError.unknown
        
        XCTAssertEqual(error.code, 1600099)
        XCTAssertEqual(error.errorCode, 1600099)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.convertToAMErrorType(), "UnknownError")
        XCTAssertEqual(error.convertToWebAuthnOutcome(), "ERROR::UnknownError:")
        XCTAssertTrue(error.localizedDescription.hasPrefix("The operation failed for an unknown reason"))
    }
}
