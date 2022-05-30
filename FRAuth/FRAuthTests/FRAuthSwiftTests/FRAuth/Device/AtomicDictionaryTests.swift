//
//  AtomicStorageTest.swift
//  FRAuthTests
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

class AtomicDictionaryTests: XCTestCase {

    func testAtomicStorage() {
       let storage = AtomicDictionary()
        DispatchQueue.concurrentPerform(iterations: 2) { (index) in
            storage.set(key: "\(index)", value: ["key":  "value"])
        }
    
        XCTAssertEqual(storage.get()["0"] as! [String : String], ["key":  "value"])
        XCTAssertEqual(storage.get()["1"] as! [String : String], ["key":  "value"])
    }
    
    func testAtomicStorageWithEmptyDictinary() {
       let storage = AtomicDictionary()
        DispatchQueue.concurrentPerform(iterations: 2) { (index) in
            storage.set(key: "\(index)", value: [:])
        }
    
        XCTAssertEqual(storage.get() as! [String : String], [:])
    }


}

