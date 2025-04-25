// 
//  TelephonyCollectorTests.swift
//  FRAuthTests
//
//  Copyright (c) 2023 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
import CoreTelephony
@testable import FRAuth

final class TelephonyCollectorTests: XCTestCase {
    
    func test_firstElementInCustomSortedArray() {
        
        // ("Verizon", "us"), ("Telus", "ca") -> ("Telus", "ca")
        var array = [TelephonyCollector.CarrierInfo]()
        array.append((carrierName: "Verizon", isoCountryCode: "us"))
        array.append((carrierName: "Telus", isoCountryCode: "ca"))
        let result = TelephonyCollector.firstElementInCustomSortedArray(array: array)
        XCTAssertEqual(result?.carrierName, "Telus")
        
        // ("Telus", "ca"), ("Verizon", "us")  -> ("Telus", "ca")
        array.removeAll()
        array.append((carrierName: "Telus", isoCountryCode: "ca"))
        array.append((carrierName: "Verizon", isoCountryCode: "us"))
        let result1 = TelephonyCollector.firstElementInCustomSortedArray(array: array)
        XCTAssertEqual(result1?.carrierName, "Telus")
        
        // (nil, "ca"), ("Verizon", "us")  -> ("Verizon", "us")
        array.removeAll()
        array.append((carrierName: nil, isoCountryCode: "ca"))
        array.append((carrierName: "Verizon", isoCountryCode: "us"))
        let result2 = TelephonyCollector.firstElementInCustomSortedArray(array: array)
        XCTAssertEqual(result2?.carrierName, "Verizon")
        
        // ("Telus", "ca"), ("nil", "us")  -> ("Telus", "ca")
        array.removeAll()
        array.append((carrierName: "Telus", isoCountryCode: "ca"))
        array.append((carrierName: nil, isoCountryCode: "us"))
        let result3 = TelephonyCollector.firstElementInCustomSortedArray(array: array)
        XCTAssertEqual(result3?.carrierName, "Telus")
        
        // ("nil", "ca"), ("nil", "us")  -> (nil, "ca")
        array.removeAll()
        array.append((carrierName: nil, isoCountryCode: "ca"))
        array.append((carrierName: nil, isoCountryCode: "us"))
        let result4 = TelephonyCollector.firstElementInCustomSortedArray(array: array)
        XCTAssertEqual(result4?.carrierName, nil)
        XCTAssertEqual(result4?.isoCountryCode, "ca")
        
        // ("nil", "us"), ("nil", "ca")   -> (nil, "ca")
        array.removeAll()
        array.append((carrierName: nil, isoCountryCode: "us"))
        array.append((carrierName: nil, isoCountryCode: "ca"))
        let result5 = TelephonyCollector.firstElementInCustomSortedArray(array: array)
        XCTAssertEqual(result5?.carrierName, nil)
        XCTAssertEqual(result5?.isoCountryCode, "ca")
        
        // ("nil", "nil"), ("nil", "ca")   -> (nil, "ca")
        array.removeAll()
        array.append((carrierName: nil, isoCountryCode: nil))
        array.append((carrierName: nil, isoCountryCode: "ca"))
        let result6 = TelephonyCollector.firstElementInCustomSortedArray(array: array)
        XCTAssertEqual(result6?.carrierName, nil)
        XCTAssertEqual(result6?.isoCountryCode, "ca")
        
        // ("nil", "us"), ("nil", "nil")   -> (nil, "us")
        array.removeAll()
        array.append((carrierName: nil, isoCountryCode: "us"))
        array.append((carrierName: nil, isoCountryCode: nil))
        let result7 = TelephonyCollector.firstElementInCustomSortedArray(array: array)
        XCTAssertEqual(result7?.carrierName, nil)
        XCTAssertEqual(result7?.isoCountryCode, "us")
        
        // ("nil", "us"), ("nil", "nil")   -> (nil, nil)
        array.removeAll()
        array.append((carrierName: nil, isoCountryCode: nil))
        array.append((carrierName: nil, isoCountryCode: nil))
        let result8 = TelephonyCollector.firstElementInCustomSortedArray(array: array)
        XCTAssertEqual(result8?.carrierName, nil)
        XCTAssertEqual(result8?.isoCountryCode, nil)
    }
}
