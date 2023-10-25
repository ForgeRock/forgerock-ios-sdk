// 
//  FRAppIntegrityKeys.swift
//  FRAuthTests
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth
@testable import FRCore

final class FRAppIntegrityKeysTests: FRAuthBaseTest {

    private let keychain: KeychainManager? = FRAuth.shared?.keychainManager
    private let keychainKey = "FRAppAttestKey"
    
    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
        self.startSDK()
    }
    

    func testKeys() {
       let testObject = FRAppIntegrityKeys(attestKey: "attest", assertKey: "assert", keyIdentifier: "keyid", clientDataHash: "hash")
        XCTAssertEqual(testObject.appAttestKey, "attest")
        XCTAssertEqual(testObject.assertKey, "assert")
        XCTAssertEqual(testObject.keyIdentifier, "keyid")
        XCTAssertEqual(testObject.clientDataHash, "hash")
    }
    
    func testKeyChainKeys() {
       let testObject = FRAppIntegrityKeys(attestKey: "attest", assertKey: "assert", keyIdentifier: "keyid", clientDataHash: "hash")
        
        testObject.updateKey(value: "keyid::attest")
        XCTAssertEqual(testObject.getKey(), "keyid::attest")
        XCTAssertEqual(testObject.isAttestationCompleted(), true)
        testObject.deleteKey()
        XCTAssertEqual(testObject.getKey(), nil)
        XCTAssertEqual(testObject.isAttestationCompleted(), false)
    }

}
