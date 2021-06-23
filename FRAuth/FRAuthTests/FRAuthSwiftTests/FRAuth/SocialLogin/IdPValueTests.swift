// 
//  IdPValueTests.swift
//  FRAuthTests
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class IdPValueTests: FRAuthBaseTest {

    func test_01_basic_init() {
        let idpValue = IdPValue(provider: "providerVal", uiConfig: nil)
        XCTAssertNotNil(idpValue)
        XCTAssertEqual(idpValue.provider, "providerVal")
        XCTAssertEqual(idpValue.uiConfig, nil)
    }

    func test_02_init_additional_values() {
        let idpValue = IdPValue(provider: "providerVal", uiConfig: ["logo": "logoVal", "customKey": "customVal"])
        XCTAssertNotNil(idpValue)
        XCTAssertEqual(idpValue.provider, "providerVal")
        XCTAssertNotNil(idpValue.uiConfig)
        XCTAssertEqual(idpValue.uiConfig?.keys.count, 2)
        XCTAssertTrue(idpValue.uiConfig?.keys.contains("logo") ?? false)
        XCTAssertTrue(idpValue.uiConfig?.keys.contains("customKey") ?? false)
        XCTAssertTrue(idpValue.uiConfig?.values.contains("logoVal") ?? false)
        XCTAssertTrue(idpValue.uiConfig?.values.contains("customVal") ?? false)
    }
}
