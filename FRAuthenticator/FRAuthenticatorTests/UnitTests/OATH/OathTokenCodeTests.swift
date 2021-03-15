// 
//  OathTokenCodeTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class OathTokenCodeTests: FRABaseTests {
    
    func test_01_success_init() {
        let startTime =  Date().timeIntervalSince1970
        let code = OathTokenCode(tokenType: FRAConstants.totp, code: "123123", start: startTime, until: startTime + 10000)
        XCTAssertNotNil(code)
        XCTAssertEqual(code.tokenType, "totp")
        XCTAssertEqual(code.code, "123123")
        XCTAssertEqual(code.start, startTime)
        XCTAssertEqual(code.until, startTime + 10000)
        XCTAssertTrue(code.isValid)
    }
    
    
    func test_02_is_valid_for_future_start() {
        let startTime =  Date().timeIntervalSince1970
        let code = OathTokenCode(tokenType: FRAConstants.totp, code: "123123", start: startTime + 100, until: startTime + 101)
        XCTAssertNotNil(code)
        XCTAssertEqual(code.tokenType, "totp")
        XCTAssertEqual(code.code, "123123")
        XCTAssertEqual(code.start, startTime + 100)
        XCTAssertEqual(code.until, startTime + 101)
        XCTAssertFalse(code.isValid)
    }
    
    
    func test_03_is_valid_for_expired() {
        let startTime =  Date().timeIntervalSince1970
        let code = OathTokenCode(tokenType: FRAConstants.totp, code: "123123", start: startTime - 10, until: startTime - 9)
        XCTAssertNotNil(code)
        XCTAssertEqual(code.tokenType, "totp")
        XCTAssertEqual(code.code, "123123")
        XCTAssertEqual(code.start, startTime - 10)
        XCTAssertEqual(code.until, startTime - 9)
        XCTAssertFalse(code.isValid)
    }
       
    
    func test_04_is_valid_for_actual_expired() {
        let startTime =  Date().timeIntervalSince1970
        let code = OathTokenCode(tokenType: FRAConstants.totp, code: "123123", start: startTime, until: startTime + 10)
        XCTAssertNotNil(code)
        XCTAssertEqual(code.tokenType, "totp")
        XCTAssertEqual(code.code, "123123")
        XCTAssertEqual(code.start, startTime)
        XCTAssertEqual(code.until, startTime + 10)
        XCTAssertTrue(code.isValid)
        sleep(3)
        XCTAssertTrue(code.isValid)
        sleep(8)
        XCTAssertFalse(code.isValid)
    }

    
    func test_05_hotp() {
        let startTime =  Date().timeIntervalSince1970
        let code = OathTokenCode(tokenType: FRAConstants.hotp, code: "123123", start: startTime, until: startTime + 5)
        XCTAssertNotNil(code)
        XCTAssertEqual(code.tokenType, "hotp")
        XCTAssertEqual(code.code, "123123")
        XCTAssertEqual(code.start, startTime)
        XCTAssertEqual(code.until, startTime + 5)
        XCTAssertTrue(code.isValid)
        sleep(10)
        XCTAssertTrue(code.isValid)
    }

    
    func test_06_hotp_is_valid_for_future() {
        let startTime =  Date().timeIntervalSince1970
        let code = OathTokenCode(tokenType: FRAConstants.hotp, code: "123123", start: startTime + 10, until: startTime + 11)
        XCTAssertNotNil(code)
        XCTAssertEqual(code.tokenType, "hotp")
        XCTAssertEqual(code.code, "123123")
        XCTAssertEqual(code.start, startTime + 10)
        XCTAssertEqual(code.until, startTime + 11)
        XCTAssertTrue(code.isValid)
    }
    
    
    func test_07_hotp_progress_returns_0() {
        let startTime =  Date().timeIntervalSince1970
        let code = OathTokenCode(tokenType: FRAConstants.hotp, code: "123123", start: startTime + 10, until: startTime + 11)
        XCTAssertNotNil(code)
        XCTAssertEqual(code.progress, 0.0)
        sleep(3)
        XCTAssertEqual(code.progress, 0.0)
    }
    
    
    func test_08_totp_progress_changes() {
        let startTime = Date().timeIntervalSince1970
        let code = OathTokenCode(tokenType: FRAConstants.totp, code: "123123", start: startTime, until: startTime + 10)
        XCTAssertNotNil(code)
        
        if code.isValid {
            var list: [Float] = []
            let ex = self.expectation(description: "OathTokenCode.progress test")
            Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { (timer) in
                
                if !code.isValid {
                    timer.invalidate()
                    ex.fulfill()
                }
                let progress = code.progress
                if list.contains(progress) {
                    XCTFail("OathTokenCode.progress contains same value")
                }
                else {
                    list.append(progress)
                }
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
    }
}
