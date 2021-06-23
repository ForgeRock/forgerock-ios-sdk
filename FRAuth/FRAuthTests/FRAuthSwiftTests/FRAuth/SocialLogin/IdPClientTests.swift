// 
//  IdPClientTests.swift
//  FRAuthTests
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

class IdPClientTests: FRAuthBaseTest {

    func test_01_basic_init() {
        
        let idpClient = IdPClient(provider: "providerVal", clientId: "clientIdVal", redirectUri: "redirect_uri://", scopes: nil, nonce: nil, acrValues: nil, request: nil, requestUri: nil)
        XCTAssertNotNil(idpClient)
        XCTAssertEqual(idpClient.provider, "providerVal")
        XCTAssertEqual(idpClient.clientId, "clientIdVal")
        XCTAssertEqual(idpClient.redirectUri, "redirect_uri://")
        XCTAssertEqual(idpClient.scopes, nil)
        XCTAssertEqual(idpClient.nonce, nil)
        XCTAssertEqual(idpClient.acrValues, nil)
        XCTAssertEqual(idpClient.request, nil)
        XCTAssertEqual(idpClient.requestUri, nil)
    }
    
    
    func test_02_init_additional_values() {
        
        let idpClient = IdPClient(provider: "providerVal", clientId: "clientIdVal", redirectUri: "redirect_uri://", scopes: ["scope1", "scope2", "scope3"], nonce: "i71UYQSakI8yBB1WJ0OgmU5P8", acrValues: ["acr1", "acr2"], request: "requestVal", requestUri: "request_uri://")
        XCTAssertNotNil(idpClient)
        XCTAssertEqual(idpClient.provider, "providerVal")
        XCTAssertEqual(idpClient.clientId, "clientIdVal")
        XCTAssertEqual(idpClient.redirectUri, "redirect_uri://")
        XCTAssertEqual(idpClient.scopes?.count, 3)
        XCTAssertTrue(idpClient.scopes?.contains("scope1") ?? false)
        XCTAssertTrue(idpClient.scopes?.contains("scope2") ?? false)
        XCTAssertTrue(idpClient.scopes?.contains("scope3") ?? false)
        XCTAssertEqual(idpClient.nonce, "i71UYQSakI8yBB1WJ0OgmU5P8")
        XCTAssertEqual(idpClient.acrValues?.count, 2)
        XCTAssertTrue(idpClient.acrValues?.contains("acr1") ?? false)
        XCTAssertTrue(idpClient.acrValues?.contains("acr2") ?? false)
        XCTAssertEqual(idpClient.request, "requestVal")
        XCTAssertEqual(idpClient.requestUri, "request_uri://")
    }
}
