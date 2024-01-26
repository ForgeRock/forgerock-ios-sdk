//
//  PIProtectTests.swift
//  PingProtectTests
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import PingProtect
@testable import PingOneSignals

final class PIProtectTests: XCTestCase {
    
    func test_00_getData_fail() {
        
        let ex1 = self.expectation(description: "signal data recieved")
        PIProtect.getData { data, error in
            XCTAssertNil(data)
            XCTAssertNotNil(error)
            ex1.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_01_initSDK_success() {
        
        let ex = self.expectation(description: "SDK initialized")
        PIProtect.initSDK { error in
            XCTAssertNil(error)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_02_getData_success() {
        
        let ex = self.expectation(description: "SDK initialized")
        PIProtect.initSDK { error in
            XCTAssertNil(error)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        let ex1 = self.expectation(description: "signal data recieved")
        PIProtect.getData { data, error in
            XCTAssertNil(error)
            XCTAssertNotNil(data)
            ex1.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
}
