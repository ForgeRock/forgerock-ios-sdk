//
//  FRAppAttestModal.swift
//  FRAuthTests
//
//  Copyright (c) 2023- 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth
@testable import FRCore
import DeviceCheck

@available(iOS 14.0, *)
final class FRAppAttestModalTests: FRAuthBaseTest {
    
    private let keychain: KeychainManager? = FRAuth.shared?.keychainManager
    private let keychainKey = "FRAppAttestKey"
    
    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
        self.startSDK()
    }
    
    func testSuccessPath() async {
        let service = MockAppAttestService()
        let testObject = FRAppAttestDomainModal(service: service)
        do {
            let result = try await testObject.requestIntegrityToken(challenge: "1234")
            XCTAssertNil(result.assertKey)
            XCTAssertNotNil(result.appAttestKey)
            XCTAssertNotNil(result.keyIdentifier)
            XCTAssertNotNil(result.clientDataHash)
            XCTAssertFalse(service.assertKeyCalled)
            XCTAssertTrue(service.attestKeyCalled)
            XCTAssertTrue(service.generateKeyCalled)
            XCTAssertEqual(service.assertKeyCalledTimes, 0)
            XCTAssertEqual(service.attestKeyCalledTimes, 1)
            XCTAssertEqual(service.geenrateKeyCalledTimes,1)
        } catch {
            XCTFail("AppAttestation failed")
        }
    }
    
    func testSuccessPathAssertion() async {
        let service = MockAppAttestService()
        let testObject = FRAppAttestDomainModal(service: service)
        FRAppIntegrityKeys().updateKey(value: "keyid::attest")
        do {
            let result = try await testObject.requestIntegrityToken(challenge: "1234", payload: "payloadValue")
            XCTAssertNotNil(result.assertKey)
            XCTAssertNotNil(result.appAttestKey)
            XCTAssertNotNil(result.keyIdentifier)
            XCTAssertNotNil(result.clientDataHash)
            XCTAssertTrue(service.assertKeyCalled)
            XCTAssertFalse(service.attestKeyCalled)
            XCTAssertFalse(service.generateKeyCalled)
            XCTAssertTrue(result.clientDataHash.base64Decoded()!.contains("com.forgerock.FRTestHost"))
            XCTAssertTrue(result.clientDataHash.base64Decoded()!.contains("payloadValue"))
            XCTAssertTrue(result.clientDataHash.base64Decoded()!.contains("1234"))
            XCTAssertEqual(service.assertKeyCalledTimes, 1)
            XCTAssertEqual(service.attestKeyCalledTimes, 0)
            XCTAssertEqual(service.geenrateKeyCalledTimes,0)
        } catch {
            XCTFail("AppAttestation failed")
        }
    }
    
    
    func testInvalidAssertionRetryTwiceOnError() async {
        FRAppIntegrityKeys().updateKey(value: "keyid::attest")
        
        let service = MockAppAttestService(supported: true, error: .invalidKey, assertKeyError: true)
        let testObject = FRAppAttestDomainModal(service: service)
        do {
            let result = try await testObject.requestIntegrityToken(challenge: "1234")
            XCTAssertNil(result.assertKey)
            XCTAssertNotNil(result.appAttestKey)
            XCTAssertNotNil(result.keyIdentifier)
            XCTAssertNotNil(result.clientDataHash)
            XCTAssertTrue(service.assertKeyCalled)
            XCTAssertEqual(service.assertKeyCalledTimes, 2)
            XCTAssertEqual(service.attestKeyCalledTimes, 1)
            XCTAssertEqual(service.geenrateKeyCalledTimes, 1)
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
            _ = try await testObject.requestIntegrityToken(challenge: "")
            XCTFail("AppAttestation failed")
            
        } catch let error {
            XCTAssertTrue(error.localizedDescription == FRDeviceCheckAPIFailure.invalidChallenge.localizedDescription)
        }
    }
    
    func testInvalidBundleId() async {
        let service: FRAppAttestService = MockAppAttestService()
        let testObject = FRAppAttestDomainModal(service: service, bundleIdentifier: nil)
        do {
            _ = try await testObject.requestIntegrityToken(challenge: "1234")
            XCTFail("AppAttestation failed")
            
        } catch let error {
            XCTAssertTrue(error.localizedDescription == FRDeviceCheckAPIFailure.invalidBundleIdentifier.localizedDescription)
        }
    }
    
    func testInvalidClientData() async {
        let service: FRAppAttestService = MockAppAttestService()
        let testObject = FRAppAttestDomainModal(service: service, encoder: MockJsonEncoder())
        do {
            _ = try await testObject.requestIntegrityToken(challenge: "1234")
            XCTFail("AppAttestation failed")
            
        } catch let error {
            XCTAssertTrue(error.localizedDescription == FRDeviceCheckAPIFailure.invalidClientData.localizedDescription)
        }
    }
    
    func testUnSupported() async {
        let service = MockAppAttestService(supported: false)
        let testObject = FRAppAttestDomainModal(service: service)
        do {
            _ = try await testObject.requestIntegrityToken(challenge: "1234")
            XCTFail("AppAttestation failed")
        } catch {
            XCTAssertTrue(error.localizedDescription == FRDeviceCheckAPIFailure.featureUnsupported.localizedDescription)
        }
    }
    
    func testDCErrorInvalidInput() async {
        let service = MockAppAttestService(supported: true, error: .invalidInput, generateKeyError: true)
        let testObject = FRAppAttestDomainModal(service: service)
        do {
            _ = try await testObject.requestIntegrityToken(challenge: "1234")
            XCTFail("AppAttestation failed")
        } catch {
            XCTAssertTrue(error.localizedDescription == FRDeviceCheckAPIFailure.invalidInput.localizedDescription)
        }
    }
    
    func testDCErrorInvalidKey() async {
        let service = MockAppAttestService(supported: true, error: .invalidKey, generateKeyError: true)
        let testObject = FRAppAttestDomainModal(service: service)
        do {
            _ = try await testObject.requestIntegrityToken(challenge: "1234")
            XCTFail("AppAttestation failed")
        } catch {
            XCTAssertTrue(error.localizedDescription == FRDeviceCheckAPIFailure.invalidKey.localizedDescription)
        }
    }
    
    func testDCErrorServerUnavailable() async {
        let service = MockAppAttestService(supported: true, error: .serverUnavailable, generateKeyError: true)
        let testObject = FRAppAttestDomainModal(service: service)
        do {
            _ = try await testObject.requestIntegrityToken(challenge: "1234")
            XCTFail("AppAttestation failed")
        } catch {
            XCTAssertTrue(error.localizedDescription == FRDeviceCheckAPIFailure.serverUnavailable.localizedDescription)
        }
    }
    
    func testDCErrorServerUnavailableAttestation() async {
        let service = MockAppAttestService(supported: true, error: .serverUnavailable, attestKeyError: true)
        let testObject = FRAppAttestDomainModal(service: service)
        do {
            _ = try await testObject.requestIntegrityToken(challenge: "1234")
            XCTFail("AppAttestation failed")
        } catch {
            XCTAssertTrue(error.localizedDescription == FRDeviceCheckAPIFailure.serverUnavailable.localizedDescription)
        }
    }
    
    
    func testDCErrorUnknownSystemFailure() async {
        let service = MockAppAttestService(supported: true, error: .unknownSystemFailure, generateKeyError: true)
        let testObject = FRAppAttestDomainModal(service: service)
        do {
            _ = try await testObject.requestIntegrityToken(challenge: "1234")
            XCTFail("AppAttestation failed")
        } catch {
            XCTAssertTrue(error.localizedDescription == FRDeviceCheckAPIFailure.unknownSystemFailure.localizedDescription)
        }
    }
    
    func testUnknownError() async {
        let service: FRAppAttestService = MockAppAttestService(supported: true, unknownError: NSError(domain: "unknown", code: 100), generateKeyError: true)
        let testObject = FRAppAttestDomainModal(service: service)
        do {
            _ = try await testObject.requestIntegrityToken(challenge: "1234")
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
    var assertKeyCalledTimes = 0
    var geenrateKeyCalledTimes = 0
    var attestKeyCalledTimes = 0
    
    var generateKeyError = false
    var attestKeyError = false
    var assertKeyError = false
    
    init(supported: Bool = true,
         error: DCError.Code? = nil,
         unknownError: Error? = nil, 
         generateKeyError: Bool = false,
         attestKeyError: Bool = false,
         assertKeyError: Bool = false) {
        self.supported = supported
        self.dcError = error
        self.unknownError = unknownError
        self.generateKeyError = generateKeyError
        self.attestKeyError = attestKeyError
        self.assertKeyError = assertKeyError
    }
    
    func generateKey() async throws -> String {
        generateKeyCalled = true
        geenrateKeyCalledTimes += 1
        if self.generateKeyError {
            if let error: DCError.Code = self.dcError {
                throw DCError.init(error)
            }
            if let error = self.unknownError {
                throw error
            }
        }
        return "key"
    }
    
    func attest(keyIdentifier: String, clientDataHash: Data) async throws -> Data {
        attestKeyCalled = true
        attestKeyCalledTimes += 1
        if self.attestKeyError {
            if let error: DCError.Code = self.dcError {
                throw DCError.init(error)
            }
            if let error = self.unknownError {
                throw error
            }
        }
        return "attestKey".data(using: .utf8)!
    }
    
    func generateAssertion(keyIdentifier: String, clientDataHash: Data) async throws -> Data {
        assertKeyCalledTimes += 1
        assertKeyCalled = true
        if self.assertKeyError {
            if let error: DCError.Code = self.dcError {
                throw DCError.init(error)
            }
            if let error = self.unknownError {
                throw error
            }
        }
        return "assertkey".data(using: .utf8)!
    }
    
    func isSupported() -> Bool {
        return self.supported
    }
    
}
