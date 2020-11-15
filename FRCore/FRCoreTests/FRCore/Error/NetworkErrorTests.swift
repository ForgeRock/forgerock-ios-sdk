// 
//  NetworkErrorTests.swift
//  FRCoreTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest

class NetworkErrorTests: FRBaseTestCase {

    func test_01_domain() {
        XCTAssertEqual(NetworkError.errorDomain, "com.forgerock.ios.frcore.network")
    }
    
    
    func test_01_invalid_response_data_type() {
        let error = NetworkError.invalidResponseDataType

        XCTAssertEqual(error.code, 5000003)
        XCTAssertEqual(error.errorCode, 5000003)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Invalid response data type")
    }
    
    
    func test_02_invalid_request() {
        let error = NetworkError.invalidRequest("param")

        XCTAssertEqual(error.code, 5000005)
        XCTAssertEqual(error.errorCode, 5000005)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Invalid request: param")
    }
    
    
    func test_03_api_request_failure() {
        let error = NetworkError.apiRequestFailure(nil, nil, nil)

        XCTAssertEqual(error.code, 5000010)
        XCTAssertEqual(error.errorCode, 5000010)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Request failed")
        
    }
}
