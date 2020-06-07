// 
//  OathQRCodeParserTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest

class OathQRCodeParserTests: FRABaseTests {
    
    func test_01_parse_hotp_qr_code_success() {
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=2&algorithm=SHA%20256")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            
            XCTAssertNotNil(parser.scheme)
            XCTAssertNotNil(parser.type)
            XCTAssertNotNil(parser.issuer)
            XCTAssertNotNil(parser.label)
            XCTAssertNotNil(parser.secret)
            XCTAssertNotNil(parser.counter)
            XCTAssertNotNil(parser.algorithm)
            
            XCTAssertEqual(parser.scheme, "otpauth")
            XCTAssertEqual(parser.type, "hotp")
            XCTAssertEqual(parser.issuer, "Forgerock")
            XCTAssertEqual(parser.label, "demo")
            XCTAssertEqual(parser.secret, "IJQWIZ3FOIQUEYLE")
            XCTAssertEqual(parser.counter, 2)
            XCTAssertEqual(parser.algorithm, "SHA 256")
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_02_parse_topt_qr_code_success() {
        
        let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            
            XCTAssertNotNil(parser.scheme)
            XCTAssertNotNil(parser.type)
            XCTAssertNotNil(parser.issuer)
            XCTAssertNotNil(parser.label)
            XCTAssertNotNil(parser.secret)
            XCTAssertNotNil(parser.digits)
            XCTAssertNotNil(parser.period)
            
            XCTAssertEqual(parser.scheme, "otpauth")
            XCTAssertEqual(parser.type, "totp")
            XCTAssertEqual(parser.issuer, "ForgeRock")
            XCTAssertEqual(parser.label, "demo")
            XCTAssertEqual(parser.secret, "T7SIIEPTZJQQDSCB")
            XCTAssertEqual(parser.digits!, 6)
            XCTAssertEqual(parser.period!, 30)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_03_invalid_scheme() {
        let qrCode = URL(string: "invalidscheme://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        do {
            let _ = try OathQRCodeParser(url: qrCode)
            XCTFail("Parsing success while expecting failure for invalid scheme")
        }
        catch MechanismError.invalidQRCode {
            
        }
        catch {
            XCTFail("Failed to parse with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_03_invalid_type() {
        let qrCode = URL(string: "otpauth://invalidtype/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        do {
            let _ = try OathQRCodeParser(url: qrCode)
            XCTFail("Parsing success while expecting failure for invalid scheme")
        }
        catch MechanismError.invalidType {
            
        }
        catch {
            XCTFail("Failed to parse with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_04_parse_topt_qr_code_without_username_success() {
        
        let qrCode = URL(string: "otpauth://totp/ForgeRock?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            
            XCTAssertNotNil(parser.scheme)
            XCTAssertNotNil(parser.type)
            XCTAssertNotNil(parser.issuer)
            XCTAssertNotNil(parser.label)
            XCTAssertNotNil(parser.secret)
            XCTAssertNotNil(parser.digits)
            XCTAssertNotNil(parser.period)
            
            XCTAssertEqual(parser.scheme, "otpauth")
            XCTAssertEqual(parser.type, "totp")
            XCTAssertEqual(parser.issuer, "ForgeRock")
            XCTAssertEqual(parser.label, "ForgeRock")
            XCTAssertEqual(parser.secret, "T7SIIEPTZJQQDSCB")
            XCTAssertEqual(parser.digits!, 6)
            XCTAssertEqual(parser.period!, 30)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_05_parse_topt_qr_code_without_period_username_success() {
        
        let qrCode = URL(string: "otpauth://totp/ForgeRock?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            XCTAssertNotNil(parser.label)
            XCTAssertEqual(parser.label, "ForgeRock")
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
}
