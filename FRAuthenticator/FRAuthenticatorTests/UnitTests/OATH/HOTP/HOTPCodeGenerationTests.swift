// 
//  HOTPCodeGenerationTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
import FRCore

class HOTPCodeGenerationTests: FRABaseTests {

    func test_01_generate_hotp() {
        
        // Given
        let mechanism = HOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "IJQWIZ3FOIQUEYLE", algorithm: "SHA256")
        
        do {
            // When
            let code = try mechanism.generateCode()
            // Then
            XCTAssertNotNil(code)
            XCTAssertEqual(code.code, "185731")
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_02_generate_hotp_different_key() {
        // Given
        let mechanism = HOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "IJQWIZ3FOI======", algorithm: "SHA256")
        do {
            // When
            let code = try mechanism.generateCode()
            // Then
            XCTAssertNotNil(code)
            XCTAssertEqual(code.code, "919304")
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_03_generate_hotp_sequence() {
        // Given
        let mechanism = HOTPMechanism(issuer: "tester", accountName: "tester", secret: "kjr6wxe5zsiml3v47dneo6rdiuompawngagaxwdm3ykhzjjvve4ksjpi", algorithm: "SHA256", counter: 0)
        let expectedCodes: [String] = ["212759", "582291", "208342", "982745", "219752", "230137", "672139", "958477"]
        
        do {
            // When
            for expectedCode in expectedCodes {
                let code = try mechanism.generateCode()
                // Then
                XCTAssertNotNil(code)
                XCTAssertEqual(code.code, expectedCode)
            }
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_04_generate_hotp_sha1() {
        // Given
        let mechanism = HOTPMechanism(issuer: "tester", accountName: "tester", secret: "kjr6wxe5zsiml3v47dneo6rdiuompawngagaxwdm3ykhzjjvve4ksjpi", algorithm: "sha1", counter: 0)
        
        do {
            // When
            // When
            let code = try mechanism.generateCode()
            // Then
            XCTAssertNotNil(code)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_05_generate_hotp_sha224() {
        // Given
        let mechanism = HOTPMechanism(issuer: "tester", accountName: "tester", secret: "kjr6wxe5zsiml3v47dneo6rdiuompawngagaxwdm3ykhzjjvve4ksjpi", algorithm: "sha224", counter: 0)
        
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
    
    
    func test_06_generate_hotp_sha256() {
        // Given
        let mechanism = HOTPMechanism(issuer: "tester", accountName: "tester", secret: "kjr6wxe5zsiml3v47dneo6rdiuompawngagaxwdm3ykhzjjvve4ksjpi", algorithm: "sha256", counter: 0)
        
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
    
    
    func test_07_generate_hotp_sha384() {
        // Given
        let mechanism = HOTPMechanism(issuer: "tester", accountName: "tester", secret: "kjr6wxe5zsiml3v47dneo6rdiuompawngagaxwdm3ykhzjjvve4ksjpi", algorithm: "sha384", counter: 0)
        
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
    
    
    func test_08_generate_hotp_sha384() {
        // Given
        let mechanism = HOTPMechanism(issuer: "tester", accountName: "tester", secret: "kjr6wxe5zsiml3v47dneo6rdiuompawngagaxwdm3ykhzjjvve4ksjpi", algorithm: "sha512", counter: 0)
        
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
    
    
    func test_09_generate_hotp_md5() {
        // Given
        let mechanism = HOTPMechanism(issuer: "tester", accountName: "tester", secret: "kjr6wxe5zsiml3v47dneo6rdiuompawngagaxwdm3ykhzjjvve4ksjpi", algorithm: "md5", counter: 0)
        
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
