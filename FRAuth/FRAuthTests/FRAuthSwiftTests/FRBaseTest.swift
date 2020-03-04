//
//  FRAuthTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

let FRTest = true

class FRBaseTest: XCTestCase {

    var shouldCleanup: Bool = true
    var shouldLoadMockResponses: Bool = true
    var config: Config = Config()
    var configFileName: String = ""
    
    override func setUp() {
        FRLog.setLogLevel(.all)
        self.continueAfterFailure = false
        
        if self.configFileName.count > 0 {
            do {
                self.config = try Config(self.configFileName)
            }
            catch {
                XCTFail("Failed to load test configuration file: \(error)")
            }
        }
        
        if self.shouldLoadMockResponses {
            // Register FRURLProtocol
            URLProtocol.registerClass(FRTestNetworkStubProtocol.self)
            
            // Construct URLSession with FRURLProtocol
            let config = URLSessionConfiguration.default
            config.protocolClasses = [FRTestNetworkStubProtocol.self]
            FRRestClient.setURLSessionConfiguration(config: config)
        }
    }

    override func tearDown() {
        if shouldCleanup {
            FRTestUtils.cleanUpAfterTearDown()
        }
    }
    
    func startSDK() {
        FRTestUtils.startSDK(self.config)
    }
    
    func parseStringToDictionary(_ str: String) -> [String: Any] {
        return FRTestUtils.parseStringToDictionary(str)
    }
    
    func loadMockResponses(_ responseFileNames: [String]) {
        FRTestUtils.loadMockResponses(responseFileNames)
    }
    
    func readDataFromJSON(_ fileName: String) -> [String: Any]? {
        return FRTestUtils.readDataFromJSON(fileName)
    }
    
    func readConfigFile(fileName: String) -> [String: Any] {
        
        guard let path = Bundle.main.path(forResource: fileName, ofType: "plist"), let config = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            XCTFail("Failed to read \(fileName).plist file")
            return [:]
        }
        
        return config
    }
}
