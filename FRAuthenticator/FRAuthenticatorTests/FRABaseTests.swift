// 
//  FRABaseTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
import FRCore

class FRABaseTests: XCTestCase {
    
    var shouldCleanup: Bool = true
    var shouldLoadMockResponses: Bool = true
    
    override func setUp() {
        
        if shouldLoadMockResponses {
            // Register Mock URLProtocol
            URLProtocol.registerClass(FRATestNetworkStubProtocol.self)
            let config = URLSessionConfiguration.default
            config.protocolClasses = [FRATestNetworkStubProtocol.self]
            RestClient.shared.setURLSessionConfiguration(config: config)
        }
    }
    

    override func tearDown() {
        
        if shouldCleanup {
            FRATestUtils.cleanUpAfterTearDown()
        }
    }
    
    
    func loadMockResponses(_ responseFileNames: [String]) {
        FRATestUtils.loadMockResponses(responseFileNames)
    }
}
