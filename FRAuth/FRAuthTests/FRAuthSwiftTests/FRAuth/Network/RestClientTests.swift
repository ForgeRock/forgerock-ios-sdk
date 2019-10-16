//
//  RestClientTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest

class RestClientTests: FRBaseTest {

    /// Tests to invoke API request with invalid URLRequest or Request object
    func testInvalidRequestObj() {
        
        let request = Request(url: "https://openam-james-go-ea.forgeblocks.com/am/json/realms/root/authenticate?authIndexType=service&authIndexValue=Usern", method: .GET)
        let expectation = self.expectation(description: "GET request should fail with invalid Request object: \(request.debugDescription)")
        
        var response:[String: Any]?, urlResponse:URLResponse?, error:AuthError?
        
        RestClient.shared.invoke(request: request) { (result) in
            switch result {
            case .success(let requestResponse, let requestUrlResponse):
                response = requestResponse
                urlResponse = requestUrlResponse
                expectation.fulfill()
                break
            case .failure(let requestError):
                
                error = requestError                
                expectation.fulfill()
                break
            }
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNil(response)
        XCTAssertNil(urlResponse)
        
        guard let _ = error else {
            XCTFail()
            return
        }
    }
}
