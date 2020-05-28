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

class NetworkErrorTests: FRCoreBaseTest {

    func test_01_domain() {
        XCTAssertEqual(NetworkError.errorDomain, "com.forgerock.ios.frcore.network")
    }
    
    
    func test_02_api_failed_with_error() {
        let error = NetworkError.apiFailedWithError(401, "Error Message", ["code": 401, "reason": "Unauthorized", "message": "Access Denied"])

        XCTAssertEqual(error.code, 5000000)
        XCTAssertEqual(error.errorCode, 5000000)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.errorUserInfo.keys.count, 2)
        XCTAssertNotNil(error.errorUserInfo["com.forgerock.auth.errorInfoKey"])
        XCTAssertEqual(error.localizedDescription, "Error Message")
    }
    
    
    func test_03_authentication_timeout() {
        let error = NetworkError.authenticationTimeout(401, "Error Message", ["errorCode": "110", "detail": "Invalid"])

        XCTAssertEqual(error.code, 5000001)
        XCTAssertEqual(error.errorCode, 5000001)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.errorUserInfo.keys.count, 2)
        XCTAssertNotNil(error.errorUserInfo["com.forgerock.auth.errorInfoKey"])
        XCTAssertEqual(error.localizedDescription, "Error Message")
    }
    
    
    func test_04_invalid_credentials() {
        
        let error = NetworkError.invalidCredentials(401, "Error Message", ["errorCode": "100", "detail": "Invalid"])

        XCTAssertEqual(error.code, 5000002)
        XCTAssertEqual(error.errorCode, 5000002)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.errorUserInfo.keys.count, 2)
        XCTAssertNotNil(error.errorUserInfo["com.forgerock.auth.errorInfoKey"])
        XCTAssertEqual(error.localizedDescription, "Error Message")
    }
    
    
    func test_05_invalid_response_data_type() {
        let error = NetworkError.invalidResponseDataType

        XCTAssertEqual(error.code, 5000003)
        XCTAssertEqual(error.errorCode, 5000003)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Invalid response data type")
    }
    
    
        
    func test_05_request_fail_with_error() {
        let error = NetworkError.requestFailWithError

        XCTAssertEqual(error.code, 5000004)
        XCTAssertEqual(error.errorCode, 5000004)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Request was failed with an unknown error")
    }
    
    
    func test_05_invalid_request() {
        let error = NetworkError.invalidRequest("param")

        XCTAssertEqual(error.code, 5000005)
        XCTAssertEqual(error.errorCode, 5000005)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Invalid request: param")
    }
}
