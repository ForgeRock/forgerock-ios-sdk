// 
//  FRPBaseTests.swift
//  FRProximityTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

class FRPBaseTest: XCTestCase {
    var shouldCleanup: Bool = true
    var shouldLoadMockResponses: Bool = true

    override func setUpWithError() throws {
        
        if self.shouldLoadMockResponses {
            // Register FRURLProtocol
            URLProtocol.registerClass(FRTestNetworkStubProtocol.self)
            
            // Construct URLSession with FRURLProtocol
            let config = URLSessionConfiguration.default
            config.protocolClasses = [FRTestNetworkStubProtocol.self]
            FRRestClient.setURLSessionConfiguration(config: config)
        }
    }

    override func tearDownWithError() throws {
        if shouldCleanup {
            FRPTestUtils.cleanUpAfterTearDown()
        }
    }
    
    
    func loadMockResponses(_ responseFileNames: [String]) {
        FRPTestUtils.loadMockResponses(responseFileNames)
    }
}
