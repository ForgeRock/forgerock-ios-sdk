// 
//  SSLPinningTests.swift
//  FRAuthTests
//
//  Copyright (c) 2022-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
import FRAuth
import FRCore

class SSLPinningTests: FRAuthBaseTest {
    
    override func setUp() {
        //leave empty
    }
    
    ///Test SSL Pinning with no public key hashes in the config file
    func testSSLPinningWithNoPublicKeyHashes() {
        self.config.configPlistFileName = "FRAuthConfig"
        FRAuth.configPlistFileName = "FRAuthConfig"
        
        //  Init SDK
        self.startSDK()
        
        let request = Request(url: FRTestURL.anythingURL, method: .GET)
        let ex = self.expectation(description: "Request submit")
        var requestSucceeded = false
        
        RestClient.shared.invoke(request: request, action: nil) { (result) in
            
            switch result {
            case .success(_, _):
                requestSucceeded = true
                break
            case .failure(_):
                requestSucceeded = false
                break
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertTrue(requestSucceeded, "Request failed with no public key hashes")
    }
    
    
    ///Test SSL Pinning with matching public key hash and a server
    func testSSLPinningWithCorrectPublicKeyHashAndCorrectServer() {
        self.config.configPlistFileName = "FRAuthConfigPKHash"
        FRAuth.configPlistFileName = "FRAuthConfigPKHash"
        
        //  Init SDK
        self.startSDK()
        
        let request = Request(url: FRTestURL.anythingURL, method: .GET)
        let ex = self.expectation(description: "Request submit")
        var requestSucceeded = false
        
        RestClient.shared.invoke(request: request, action: nil) { (result) in
            
            switch result {
            case .success(_, _):
                requestSucceeded = true
                break
            case .failure(_):
                requestSucceeded = false
                break
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertTrue(requestSucceeded, "Request failed with the correct server and correct public key hash")
    }
    
    
    ///Test SSL Pinning with mismatching public key hash and a server
    func testSSLPinningWithPublicKeyHashAndWrongServer() {
        self.config.configPlistFileName = "FRAuthConfigPKHash"
        FRAuth.configPlistFileName = "FRAuthConfigPKHash"
        
        //  Init SDK
        self.startSDK()
        
        let request = Request(url: "https://reqres.in/api/users", method: .GET)
        let ex = self.expectation(description: "Request submit")
        var requestSucceeded = true
        
        RestClient.shared.invoke(request: request, action: nil) { (result) in
            
            switch result {
            case .success(_, _):
                requestSucceeded = true
                break
            case .failure(_):
                requestSucceeded = false
                break
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertFalse(requestSucceeded, "Request succeeded with mismatched public key hash and a server")
    }
    
    
    ///Test SSL Pinning with empty public key hashes array in the config
    func testSSLPinningWithEmptyPublicKeyHashesArray() {
        self.config.configPlistFileName = "FRAuthConfigEmptyPKHash"
        FRAuth.configPlistFileName = "FRAuthConfigEmptyPKHash"
        
        //  Init SDK
        self.startSDK()
        
        let request = Request(url: FRTestURL.anythingURL, method: .GET)
        let ex = self.expectation(description: "Request submit")
        var requestSucceeded = false
        
        RestClient.shared.invoke(request: request, action: nil) { (result) in
            switch result {
            case .success(_, _):
                requestSucceeded = true
                break
            case .failure(_):
                requestSucceeded = false
                break
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertTrue(requestSucceeded, "Request succeeded with an empty public key hashes array")
    }
    
}
