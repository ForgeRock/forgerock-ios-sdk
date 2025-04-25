// 
//  FRAppAttestServiceImpl.swift
//  FRAuthTests
//
//  Copyright (c) 2023 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth
import DeviceCheck

@available(iOS 14.0, *)
final class FRAppAttestServiceImplTests: XCTestCase {

    func testIsNotSupported() async throws {
        let mock = MockDCAppAttestService(isSupported: false)
        let testObject = FRAppAttestServiceImpl(service: mock)
        XCTAssertFalse(testObject.isSupported())
    }
    
    func testIsSupported() async throws {
        let mock = MockDCAppAttestService(isSupported: true)
        let testObject = FRAppAttestServiceImpl(service: mock)
        XCTAssertTrue(testObject.isSupported())
    }
    
    func testAttestation() async throws {
        let mock = MockDCAppAttestService(isSupported: true)
        let testObject = FRAppAttestServiceImpl(service: mock)
        _ = try await testObject.attest(keyIdentifier: "attest", clientDataHash: Data())
        _ = try await testObject.generateAssertion(keyIdentifier: "assert", clientDataHash: Data())
        XCTAssertTrue(testObject.isSupported())
        XCTAssertTrue(mock.attestKeyCalled)
        XCTAssertTrue(mock.assertKeyCalled)
    }

}

@available(iOS 14.0, *)
class MockDCAppAttestService: DCAppAttestService {
    
    var mockSupported = true
    var attestKeyCalled = false
    var assertKeyCalled = false
    
    init(isSupported: Bool) {
        mockSupported = isSupported
    }
    
    override var isSupported: Bool { return mockSupported }
    
    override func generateKey() async throws -> String {
        return "generatekey"
    }
    
    override func attestKey(_ keyId: String, clientDataHash: Data) async throws -> Data {
        attestKeyCalled = true
        return Data()
    }
    
    override func generateAssertion(_ keyId: String, clientDataHash: Data) async throws -> Data {
        assertKeyCalled = true
        return Data()
    }
    
}
