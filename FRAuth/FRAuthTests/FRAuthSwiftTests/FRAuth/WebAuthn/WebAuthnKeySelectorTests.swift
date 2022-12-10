// 
//  WebAuthnKeySelectorTests.swift
//  FRAuthTests
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

final class WebAuthnKeySelectorTests: XCTestCase {
    func testWebAuthKeySelectionOrder() throws {
        let actualKey =
        ["mockjey 20240621 22:10:10", "22ba8202-6ece-4f56-9667-4eac6c265a41 20220621 20:10:10", "12ba8202-6ece-4f56-9667-4eac6c265a41 20220621 20:10:10",
         "22ba8202-6ece-4f56-9667-4eac6c265a41 20220621 19:10:10", "22ba8202-6ece-4f56-9667-4eac6c265a41 20220621 22:10:10", "12ba8202-6ece-4f56-9667-4eac6c265a41 20220621 10:10:10", "mockjey 20230621 10:10:10"]
        
        let expectedKey =
        ["mockjey 20240621 22:10:10", "mockjey 20230621 10:10:10",
         "22ba8202-6ece-4f56-9667-4eac6c265a41 20220621 22:10:10",
         "22ba8202-6ece-4f56-9667-4eac6c265a41 20220621 20:10:10",
         "22ba8202-6ece-4f56-9667-4eac6c265a41 20220621 19:10:10",
         "12ba8202-6ece-4f56-9667-4eac6c265a41 20220621 20:10:10", "12ba8202-6ece-4f56-9667-4eac6c265a41 20220621 10:10:10"]
        
        XCTAssertEqual(expectedKey, actualKey.sortedByDate())
        
    }
    
    func testKeysWithInvalidDate() throws {
        let actualKey =
        ["22ba8202-6ece-4f56-9667-4eac6c265a41 jey adfafdadaadfafdada",  "22ba8202-6ece-4f56-9667-4eac6c265a41 20220621 19:10:10", "22ba8202-6ece-4f56-9667-4eac6c265a41 20220621 20:10:10"]
        
        let expectedKey =
        ["22ba8202-6ece-4f56-9667-4eac6c265a41 jey adfafdadaadfafdada",
         "22ba8202-6ece-4f56-9667-4eac6c265a41 20220621 20:10:10",
         "22ba8202-6ece-4f56-9667-4eac6c265a41 20220621 19:10:10"]
        
        XCTAssertEqual(expectedKey, actualKey.sortedByDate())
        
    }
    
    func testKeysWithNullOrNoDate() throws {
        let actualKey =
        ["22ba8202-6ece-4f56-9667-4eac6c265a41",  "22ba8202-6ece-4f56-9667-4eac6c265a41 20220621 19:10:10", "22ba8202-6ece-4f56-9667-4eac6c265a41 20220621 20:10:10"]
        
        let expectedKey =
        ["22ba8202-6ece-4f56-9667-4eac6c265a41 20220621 20:10:10",
         "22ba8202-6ece-4f56-9667-4eac6c265a41 20220621 19:10:10", "22ba8202-6ece-4f56-9667-4eac6c265a41"]
        
        XCTAssertEqual(expectedKey, actualKey.sortedByDate())
        
    }
}
