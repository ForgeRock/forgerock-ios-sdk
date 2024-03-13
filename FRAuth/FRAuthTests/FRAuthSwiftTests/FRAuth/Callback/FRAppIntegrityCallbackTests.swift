//
//  FRAppIntegrityCallbackTests.swift
//  FRAuthTests
//
//  Copyright (c) 2023- 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

final class FRAppIntegrityCallbackTests: FRAuthBaseTest {
    
    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
        self.startSDK()
    }
    
    func test_01_CallbackConstruction_Successful() throws {
        let jsonStr = """
        {"type":"AppIntegrityCallback","output":[{"name":"challenge","value":"x2AMmYOIP7CFCkp0tbXkr69NDBaP1dUypxioQTbdnfM="}, {"name":"attestToken","value":""}],"input":[{"name":"IDToken1clientError","value":""},{"name":"IDToken1attestToken","value":""},{"name":"IDToken1token","value":""},{"name":"IDToken1clientData","value":""},{"name":"IDToken1keyId","value":""}]}
        """
        
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let callback = try FRAppIntegrityCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback.challenge, "x2AMmYOIP7CFCkp0tbXkr69NDBaP1dUypxioQTbdnfM=")
            XCTAssertEqual(callback.type, "AppIntegrityCallback")
            XCTAssertEqual(callback.payload, nil)
    
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    func test_01_CallbackConstruction_Successful_Persist() throws {
        let jsonStr = """
        {"type":"AppIntegrityCallback","output":[{"name":"challenge","value":"x2AMmYOIP7CFCkp0tbXkr69NDBaP1dUypxioQTbdnfM="}, {"name":"attestToken","value":"keyid::appattest"}],"input":[{"name":"IDToken1clientError","value":""},{"name":"IDToken1attestToken","value":""},{"name":"IDToken1token","value":""},{"name":"IDToken1clientData","value":""},{"name":"IDToken1keyId","value":""}]}
        """
        
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let callback = try FRAppIntegrityCallback(json: callbackResponse)
            let appIntegrityKeys = FRAppIntegrityKeys()
            
            // Then
            XCTAssertEqual(callback.challenge, "x2AMmYOIP7CFCkp0tbXkr69NDBaP1dUypxioQTbdnfM=")
            XCTAssertEqual(callback.type, "AppIntegrityCallback")
            XCTAssertEqual(appIntegrityKeys.getKey(), "keyid::appattest")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    func test_01_Public_Methods() throws {
        let jsonStr = """
        {"type":"AppIntegrityCallback","output":[{"name":"challenge","value":"x2AMmYOIP7CFCkp0tbXkr69NDBaP1dUypxioQTbdnfM="}, {"name":"attestToken","value":""}],"input":[{"name":"IDToken1clientError","value":""},{"name":"IDToken1attestToken","value":""},{"name":"IDToken1token","value":""},{"name":"IDToken1clientData","value":""},{"name":"IDToken1keyId","value":""}]}
        """
        
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let callback = try FRAppIntegrityCallback(json: callbackResponse)
            
            callback.setClientError("test")
            callback.setkeyId("keyId")
            callback.setPayload("payload")
            callback.setAssertion("assert")
            callback.setAttestation("attest")
            callback.setClientData("clientData")
            
            // Then
            XCTAssertEqual(callback.challenge, "x2AMmYOIP7CFCkp0tbXkr69NDBaP1dUypxioQTbdnfM=")
            XCTAssertEqual(callback.type, "AppIntegrityCallback")
            
            let expectedValue = ["IDToken1keyId": "keyId", "IDToken1clientData":"clientData", "IDToken1token":"assert", "IDToken1attestToken": "attest", "IDToken1clientError": "test"]
            
            XCTAssertTrue(expectedValue == callback.inputValues)
         
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    @available(iOS 14.0, *)
    func test_02_InputConstruction_Successful() async throws {
        let jsonStr = """
        {"type":"AppIntegrityCallback","output":[{"name":"challenge","value":"x2AMmYOIP7CFCkp0tbXkr69NDBaP1dUypxioQTbdnfM="},{"name":"attestToken","value":""}],"input":[{"name":"IDToken1clientError","value":""},{"name":"IDToken1attestToken","value":""},{"name":"IDToken1token","value":""},{"name":"IDToken1clientData","value":""},{"name":"IDToken1keyId","value":""}]}
        """
        
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let callback = try FRAppIntegrityCallback(json: callbackResponse)
            FRAppAttestDomainModal.shared = {
                return MockAttestation()
            }()
            
            // Then
            XCTAssertEqual(callback.challenge, "x2AMmYOIP7CFCkp0tbXkr69NDBaP1dUypxioQTbdnfM=")
            XCTAssertEqual(callback.type, "AppIntegrityCallback")
            
           
            try await callback.requestIntegrityToken()
            
            let buildResponse = callback.buildResponse().description
            
            XCTAssertTrue(buildResponse.contains("attestation"))
            XCTAssertTrue(buildResponse.contains("assertion"))
            XCTAssertTrue(buildResponse.contains("clientData"))
            XCTAssertTrue(buildResponse.contains("keyid"))
            
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    @available(iOS 14.0, *)
    func test_03_InvalidClientData_Failure() async throws {
        let jsonStr = """
        {"type":"AppIntegrityCallback","output":[{"name":"challenge","value":"x2AMmYOIP7CFCkp0tbXkr69NDBaP1dUypxioQTbdnfM="}, {"name":"attestToken","value":""}],"input":[{"name":"IDToken1clientError","value":""},{"name":"IDToken1attestToken","value":""},{"name":"IDToken1token","value":""},{"name":"IDToken1clientData","value":""},{"name":"IDToken1keyId","value":""}]}
        """
        
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        var callback: FRAppIntegrityCallback? = nil
        // Try
        do {
            callback = try FRAppIntegrityCallback(json: callbackResponse)
            FRAppAttestDomainModal.shared = { return MockAttestation(exception: FRDeviceCheckAPIFailure.invalidClientData) }()
    
            // Then
            XCTAssertEqual(callback?.challenge, "x2AMmYOIP7CFCkp0tbXkr69NDBaP1dUypxioQTbdnfM=")
            XCTAssertEqual(callback?.type, "AppIntegrityCallback")
          
            try await callback?.requestIntegrityToken()
            
            XCTFail("Failed while expecting success")
           
            
        } catch {
            
            let buildResponse = callback?.buildResponse().description
            
            XCTAssertTrue(buildResponse!.contains("ClientDeviceErrors"))
            
        }
    }
    
    @available(iOS 14.0, *)
    func test_03_Unknown_Error() async throws {
        let jsonStr = """
        {"type":"AppIntegrityCallback","output":[{"name":"challenge","value":"x2AMmYOIP7CFCkp0tbXkr69NDBaP1dUypxioQTbdnfM="}, {"name":"attestToken","value":""}],"input":[{"name":"IDToken1clientError","value":""},{"name":"IDToken1attestToken","value":""},{"name":"IDToken1token","value":""},{"name":"IDToken1clientData","value":""},{"name":"IDToken1keyId","value":""}]}
        """
        
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        var callback: FRAppIntegrityCallback? = nil
        // Try
        do {
            callback = try FRAppIntegrityCallback(json: callbackResponse)
            FRAppAttestDomainModal.shared = { return MockAttestation(exception: .unknownError) }()
            // Then
            XCTAssertEqual(callback?.challenge, "x2AMmYOIP7CFCkp0tbXkr69NDBaP1dUypxioQTbdnfM=")
            XCTAssertEqual(callback?.type, "AppIntegrityCallback")
            
         
            try await callback?.requestIntegrityToken()
            
            XCTFail("Failed while expecting success")
           
            
        } catch {
            
            let buildResponse = callback?.buildResponse().description
            
            XCTAssertTrue(buildResponse!.contains("ClientDeviceErrors"))
            
        }
    }
    
}

@available(iOS 14.0, *)
class MockAttestation: FRAppAttestation {
    
    var exception: FRDeviceCheckAPIFailure? = nil
    init(exception: FRDeviceCheckAPIFailure? = nil) {
        self.exception = exception
    }
    
    func requestIntegrityToken(challenge: String, payload: String?) async throws -> FRAppIntegrityKeys {
        if let exp = exception {
            throw exp
        }
        return FRAppIntegrityKeys(attestKey: "attestation", assertKey: "assertion", keyIdentifier: "keyid", clientDataHash: "clientData")
    }
}
