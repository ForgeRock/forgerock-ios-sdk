// 
//  TOTPCodeGenerationTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class TOTPCodeGenerationTests: FRABaseTests {
    
    func test_01_generate_totp_sha1() {
        // Given
        let mechanism = TOTPMechanism(issuer: "tester", accountName: "tester", secret: "kjr6wxe5zsiml3v47dneo6rdiuompawngagaxwdm3ykhzjjvve4ksjpi", algorithm: "sha1", period: 30)
        
        do {
            // When
            let code = try mechanism.generateCode()
            // Then
            XCTAssertNotNil(code)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_02_generate_totp_sha224() {
        // Given
        let mechanism = TOTPMechanism(issuer: "tester", accountName: "tester", secret: "kjr6wxe5zsiml3v47dneo6rdiuompawngagaxwdm3ykhzjjvve4ksjpi", algorithm: "sha224", period: 30)
        
        do {
            // When
            let code = try mechanism.generateCode()
            // Then
            XCTAssertNotNil(code)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_03_generate_totp_sha256() {
        // Given
        let mechanism = TOTPMechanism(issuer: "tester", accountName: "tester", secret: "kjr6wxe5zsiml3v47dneo6rdiuompawngagaxwdm3ykhzjjvve4ksjpi", algorithm: "sha256", period: 30)
        
        do {
            // When
            let code = try mechanism.generateCode()
            // Then
            XCTAssertNotNil(code)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_04_generate_totp_sha384() {
        // Given
        let mechanism = TOTPMechanism(issuer: "tester", accountName: "tester", secret: "kjr6wxe5zsiml3v47dneo6rdiuompawngagaxwdm3ykhzjjvve4ksjpi", algorithm: "sha384", period: 30)
        
        do {
            // When
            let code = try mechanism.generateCode()
            // Then
            XCTAssertNotNil(code)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_05_generate_totp_sha512() {
        // Given
        let mechanism = TOTPMechanism(issuer: "tester", accountName: "tester", secret: "kjr6wxe5zsiml3v47dneo6rdiuompawngagaxwdm3ykhzjjvve4ksjpi", algorithm: "sha512", period: 30)
        
        do {
            // When
            let code = try mechanism.generateCode()
            // Then
            XCTAssertNotNil(code)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_06_generate_totp_md5() {
        // Given
        let mechanism = TOTPMechanism(issuer: "tester", accountName: "tester", secret: "kjr6wxe5zsiml3v47dneo6rdiuompawngagaxwdm3ykhzjjvve4ksjpi", algorithm: "md5", period: 30)
        
        do {
            // When
            let code = try mechanism.generateCode()
            // Then
            XCTAssertNotNil(code)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
}
