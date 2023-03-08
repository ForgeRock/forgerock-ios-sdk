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
        let formattedDateString = isoTime.formattedDateString()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd HH:mm:ss"
        let date = dateFormatter.date(from: formattedDateString)!
        XCTAssertEqual(isoTime, date.timeIntervalSince1970)
    }
    
    func testSortedUserKeys() throws {
        
        let userKeys = [
            UserKey(id: "id", userId: "test", userName: "test", kid: "kid", authType: .applicationPin, createdAt: 1675748818),
            UserKey(id: "id", userId: "test", userName: "test", kid: "kid", authType: .biometricOnly, createdAt: 1575748818),
            UserKey(id: "id", userId: "spetrov", userName: "spetrov", kid: "kid", authType: .biometricOnly, createdAt: 1675749991),
            UserKey(id: "id", userId: "spetrov", userName: "spetrov", kid: "kid", authType: .biometricAllowFallback, createdAt: 1575748818)
        ]

        let sorted = userKeys.sorted()
        
        let expected = [
            UserKey(id: "id", userId: "spetrov", userName: "spetrov", kid: "kid", authType: .biometricAllowFallback, createdAt: 1575748818),
            UserKey(id: "id", userId: "spetrov", userName: "spetrov", kid: "kid", authType: .biometricOnly, createdAt: 1675749991),
            UserKey(id: "id", userId: "test", userName: "test", kid: "kid", authType: .biometricOnly, createdAt: 1575748818),
            UserKey(id: "id", userId: "test", userName: "test", kid: "kid", authType: .applicationPin, createdAt: 1675748818)
        ]
        
        XCTAssertEqual(sorted, expected)
    }


}
