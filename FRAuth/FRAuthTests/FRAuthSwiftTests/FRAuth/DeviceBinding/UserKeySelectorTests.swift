// 
//  UserKeySelectorTests.swift
//  FRAuthTests
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

final class UserKeySelectorTests: XCTestCase {

    func testFormattedDate() throws {
        let isoTime: Double = 1675748818
        let formatted = isoTime.formattedDateString()
        XCTAssertEqual(formatted, "20230206 23:46:58")
    }
    
    func testSortedUserKeys() throws {
        
        let userKeys = [UserKey(userId: "test", userName: "test", kid: "kid", authType: .applicationPin, keyAlias: "testKeyAlias", createdAt: 1675748818), UserKey(userId: "test", userName: "test", kid: "kid", authType: .biometricOnly, keyAlias: "testKeyAlias", createdAt: 1575748818), UserKey(userId: "spetrov", userName: "spetrov", kid: "kid", authType: .biometricOnly, keyAlias: "testKeyAlias", createdAt: 1675749991), UserKey(userId: "spetrov", userName: "spetrov", kid: "kid", authType: .biometricAllowFallback, keyAlias: "testKeyAlias", createdAt: 1575748818)]
        
        let sorted = userKeys.sorted()
        
        let expected = [UserKey(userId: "spetrov", userName: "spetrov", kid: "kid", authType: .biometricAllowFallback, keyAlias: "testKeyAlias", createdAt: 1575748818), UserKey(userId: "spetrov", userName: "spetrov", kid: "kid", authType: .biometricOnly, keyAlias: "testKeyAlias", createdAt: 1675749991),  UserKey(userId: "test", userName: "test", kid: "kid", authType: .biometricOnly, keyAlias: "testKeyAlias", createdAt: 1575748818),UserKey(userId: "test", userName: "test", kid: "kid", authType: .applicationPin, keyAlias: "testKeyAlias", createdAt: 1675748818),]
        
        XCTAssertEqual(sorted, expected)
    }


}
