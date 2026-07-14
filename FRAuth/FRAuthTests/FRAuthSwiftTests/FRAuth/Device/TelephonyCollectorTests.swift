//
//  TelephonyCollectorTests.swift
//  FRAuthTests
//
//  Copyright (c) 2023 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

final class TelephonyCollectorTests: XCTestCase {

    func test_collect_returnsUnknownCarrierInfo() {
        // CTCarrier APIs were deprecated in iOS 16 with no replacement.
        // TelephonyCollector always returns "Unknown" for both fields.
        let collector = TelephonyCollector()
        let ex = expectation(description: "collect")
        collector.collect { result in
            XCTAssertEqual(result["carrierName"] as? String, "Unknown")
            XCTAssertEqual(result["networkCountryIso"] as? String, "Unknown")
            ex.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
}
