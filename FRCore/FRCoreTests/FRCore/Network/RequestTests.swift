//
//  RequestTest.swift
//  FRCoreTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest

class RequestTests: FRBaseTestCase {

    let testURL: String = "https://httpbin.org"
    
    /// Tests basic initialization method with valid URL string
    func testBasicConstruction() {
        //  Given
        var request = Request(url: self.testURL, method: .GET).build()
        //  Then
        XCTAssertEqual(request?.url?.absoluteString, self.testURL)
        XCTAssertEqual(request?.httpMethod, "GET")
        
        //  Given
        request = Request(url: self.testURL, method: .POST).build()
        //  Then
        XCTAssertEqual(request?.url?.absoluteString, self.testURL)
        XCTAssertEqual(request?.httpMethod, "POST")
        
        //  Given
        request = Request(url: self.testURL, method: .PUT).build()
        //  Then
        XCTAssertEqual(request?.url?.absoluteString, self.testURL)
        XCTAssertEqual(request?.httpMethod, "PUT")
        
        //  Given
        request = Request(url: self.testURL, method: .DELETE).build()
        //  Then
        XCTAssertEqual(request?.url?.absoluteString, self.testURL)
        XCTAssertEqual(request?.httpMethod, "DELETE")
    }
    
    /// Tests basic initialization method with invalid URL string
    func testInvalidRequest() {
        //  Given
        var request = Request(url: "invalid_url", method: .GET).build()
        //  Then
        XCTAssertNil(request)
        
        //  Given
        request = Request(url: "", method: .GET).build()
        //  Then
        XCTAssertNil(request)
    }
    
    /// Tests URLRequest creation with URL parameters including special characters handling in URL
    func testRequestWithURLParameters() {
        //  Given
        var request = Request(url: self.testURL, method: .POST, urlParams: ["123":"test","456":"fourfivesix"], requestType: .urlEncoded).build()
        var requestURL = request?.url
        //  Then
        XCTAssertEqual(requestURL?.valueOf("123"), "test")
        XCTAssertEqual(requestURL?.valueOf("456"), "fourfivesix")
        
        //  Given
        request = Request(url: self.testURL, method: .POST, urlParams: ["123":"*&^","456":"+-="], requestType: .urlEncoded).build()
        requestURL = request?.url
        //  Then
        XCTAssertEqual(requestURL?.valueOf("123"), "*&^")
        XCTAssertEqual(requestURL?.valueOf("456"), "+-=")
        
        //  Given
        request = Request(url: self.testURL, method: .POST, urlParams: ["special":"!@#$%^&*()_+[]{}\\|;:'\",.<>?`~"], requestType: .urlEncoded).build()
        requestURL = request?.url
        //  Then
        XCTAssertEqual(requestURL?.valueOf("special"), "!@#$%^&*()_+[]{}\\|;:'\",.<>?`~")
    }
    
    /// Tests URLRequest creation with additional HTTP headers in the request
    func testRequestWithAdditionalHeaders() {
        //  Given
        let request = Request(url: self.testURL, method: .POST, headers: ["header1":"headerone","header2":"headertwo"], requestType: .json, responseType: .json).build()
        let headerValues = request?.allHTTPHeaderFields
        
        XCTAssertEqual(headerValues!["header1"], "headerone")
        XCTAssertEqual(headerValues!["header2"], "headertwo")
    }
    
    /// Tests URLRequest creation with body parameter of Dictionary
//    func testRequestWithBodyParam() {
//        //  Given
//        let request = Request(url: self.testURL, method: .POST, bodyParams: ["body1":"bodyOne","body2":"bodyTwo"], requestType: .json, responseType: .json).build()
//        let httpBody = request?.httpBody
//        
//        let bodyJSON = ["body1":"bodyOne","body2":"bodyTwo"]
//        
//        let jsonEncoder = JSONEncoder()
//        var bodyData: Data;
//        do {
//            bodyData = try jsonEncoder.encode(bodyJSON)
//            XCTAssertEqual(bodyData, httpBody)
//        } catch {
//            XCTAssert(true, "Failed to encode Dictionary to Data")
//        }
//    }
    
    /// Tests debugDescription string to make sure all data is displayed in the description
    func testRequestDebugDescription() {
        //  Given
        let request = Request(url: self.testURL, method: .GET, headers: ["headerKey":"hValue"], bodyParams: ["bodyKey":"bValue"], urlParams: ["urlParamKey":"upValue"], requestType: .plainText, responseType: .json, timeoutInterval: 77)
        
        XCTAssertTrue(request.debugDescription.contains(self.testURL))
        XCTAssertTrue(request.debugDescription.contains("GET"))
        XCTAssertTrue(request.debugDescription.contains("headerKey"))
        XCTAssertTrue(request.debugDescription.contains("hValue"))
        XCTAssertTrue(request.debugDescription.contains("bodyKey"))
        XCTAssertTrue(request.debugDescription.contains("bValue"))
        XCTAssertTrue(request.debugDescription.contains("urlParamKey"))
        XCTAssertTrue(request.debugDescription.contains("upValue"))
        XCTAssertTrue(request.debugDescription.contains("text/plain"))
        XCTAssertTrue(request.debugDescription.contains("application/json"))
        XCTAssertTrue(request.debugDescription.contains(String(77)))
    }
    
    
    func test_body_param_get_request() {
        let request = Request(url: self.testURL, method: .GET, bodyParams: ["Test": "Test"])
        let urlRequest = request.build()
        XCTAssertNil(urlRequest?.httpBody)
    }
}
