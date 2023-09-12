//
//  FRAppAttestModal.swift
//  FRAuthTests
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth
import DeviceCheck

@available(iOS 14.0, *)
final class FRAppAttestModalTests: XCTestCase {
    
    func testSuccessPath() async {
        let service = MockAppAttestService()
        let testObject = FRAppAttestDomainModal(service: service)
        do {
            let result = try await testObject.attest(challenge: "1234")
            XCTAssertNotNil(result.assertKey)
            XCTAssertNotNil(result.attestKey)
            XCTAssertNotNil(result.keyIdentifier)
            XCTAssertNotNil(result.clientDataHash)
            XCTAssertTrue(service.assertKeyCalled)
            XCTAssertTrue(service.attestKeyCalled)
            XCTAssertTrue(service.generateKeyCalled)
        } catch {
            XCTFail("AppAttestation failed")
        }
    }
    
    func testInvalidChallenge() async {
        let service: FRAppAttestService = MockAppAttestService()
        let testObject = FRAppAttestDomainModal(service: service)
        do {
            _ = try await testObject.attest(challenge: "")
            XCTFail("AppAttestation failed")
            
        } catch let error {
            XCTAssertTrue(error.localizedDescription == FRDeviceCheckAPIFailure.invalidChallenge.localizedDescription)
        }
    }
    
    func testInvalidBundleId() async {
        let service: FRAppAttestService = MockAppAttestService()
        let testObject = FRAppAttestDomainModal(service: service, bundleIdentifier: nil)
        do {
            _ = try await testObject.attest(challenge: "1234")
            XCTFail("AppAttestation failed")
            
        } catch let error {
            XCTAssertTrue(error.localizedDescription == FRDeviceCheckAPIFailure.invalidBundleIdentifier.localizedDescription)
        }
    }
    
    func testInvalidClientData() async {
        let service: FRAppAttestService = MockAppAttestService()
        let testObject = FRAppAttestDomainModal(service: service, encoder: MockJsonEncoder())
        do {
            _ = try await testObject.attest(challenge: "1234")
            XCTFail("AppAttestation failed")
            
        } catch let error {
            XCTAssertTrue(error.localizedDescription == FRDeviceCheckAPIFailure.invalidClientData.localizedDescription)
        }
    }
    
    func testUnSupported() async {
        let service = MockAppAttestService(supported: false)
        let testObject = FRAppAttestDomainModal(service: service)
        do {
            _ = try await testObject.attest(challenge: "1234")
            XCTFail("AppAttestation failed")
        } catch {
            XCTAssertTrue(error.localizedDescription == FRDeviceCheckAPIFailure.featureUnsupported.localizedDescription)
        }
    }
    
    func testDCErrorInvalidInput() async {
        let service = MockAppAttestService(supported: true, error: .invalidInput)
        let testObject = FRAppAttestDomainModal(service: service)
        do {
            _ = try await testObject.attest(challenge: "1234")
            XCTFail("AppAttestation failed")
        } catch {
            XCTAssertTrue(error.localizedDescription == FRDeviceCheckAPIFailure.invalidInput.localizedDescription)
        }
    }
    
    func testDCErrorInvalidKey() async {
        let service = MockAppAttestService(supported: true, error: .invalidKey)
        let testObject = FRAppAttestDomainModal(service: service)
        do {
            _ = try await testObject.attest(challenge: "1234")
            XCTFail("AppAttestation failed")
        } catch {
            XCTAssertTrue(error.localizedDescription == FRDeviceCheckAPIFailure.invalidKey.localizedDescription)
        }
    }
    
    func testDCErrorServerUnavailable() async {
        let service = MockAppAttestService(supported: true, error: .serverUnavailable)
        let testObject = FRAppAttestDomainModal(service: service)
        do {
            _ = try await testObject.attest(challenge: "1234")
            XCTFail("AppAttestation failed")
        } catch {
            XCTAssertTrue(error.localizedDescription == FRDeviceCheckAPIFailure.serverUnavailable.localizedDescription)
        }
    }
    
    func testDCErrorUnknownSystemFailure() async {
        let service = MockAppAttestService(supported: true, error: .unknownSystemFailure)
        let testObject = FRAppAttestDomainModal(service: service)
        do {
            _ = try await testObject.attest(challenge: "1234")
            XCTFail("AppAttestation failed")
        } catch {
            XCTAssertTrue(error.localizedDescription == FRDeviceCheckAPIFailure.unknownSystemFailure.localizedDescription)
        }
    }
    
    func testUnknownError() async {
        let service: FRAppAttestService = MockAppAttestService(supported: true, unknownError: NSError(domain: "unknown", code: 100))
        let testObject = FRAppAttestDomainModal(service: service)
        do {
            _ = try await testObject.attest(challenge: "1234")
            XCTFail("AppAttestation failed")
            
        } catch let error {
            XCTAssertNotNil(error)
        }
    }
    
    
    
}

@available(iOS 14.0, *)
class MockJsonEncoder: JSONEncoder {
    override func encode<T>(_ value: T) throws -> Data where T : Encodable {
        if value is [String: String] {
            throw FRDeviceCheckAPIFailure.invalidClientData
        }
        return Data()
    }
}

@available(iOS 14.0, *)
class MockUnkownJsonEncoder: JSONEncoder {
    override func encode<T>(_ value: T) throws -> Data where T : Encodable {
        if value is [String: String] {
            throw NSError(domain: "unknown", code: 10)
        }
        return Data()
    }
}

@available(iOS 14.0, *)
class MockAppAttestService: FRAppAttestService {
    
    var generateKeyCalled = false
    var attestKeyCalled = false
    var assertKeyCalled = false
    var supported = true
    var dcError: DCError.Code? = nil
    var unknownError: Error? = nil
    
    init(supported: Bool = true,
         error: DCError.Code? = nil,
         unknownError: Error? = nil) {
        self.supported = supported
        self.dcError = error
        self.unknownError = unknownError
    }
    
    func generateKey() async throws -> String {
        generateKeyCalled = true
        if let error: DCError.Code = self.dcError {
            throw DCError.init(error)
        }
        if let error = self.unknownError {
            throw error
        }
        return "key"
    }
    
    func attest(keyIdentifier: String, clientDataHash: Data) async throws -> Data {
        attestKeyCalled = true
        return "attestKey".data(using: .utf8)!
    }
    
    func generateAssertion(keyIdentifier: String, clientDataHash: Data) async throws -> Data {
        assertKeyCalled = true
        return "assertkey".data(using: .utf8)!
    }
    
    func isSupported() -> Bool {
        return self.supported
    }
    
}
