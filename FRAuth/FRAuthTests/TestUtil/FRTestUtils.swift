//
//  FRTestUtils.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import XCTest

@objc
class FRTestUtils: XCTest {
    
    @objc static func cleanUpAfterTearDown() {
        if let frAuth = FRAuth.shared {
            frAuth.keychainManager.sharedStore.deleteAll()
            frAuth.keychainManager.privateStore.deleteAll()
            frAuth.keychainManager.cookieStore.deleteAll()
            frAuth.keychainManager.deviceIdentifierStore.deleteAll()
        }
        
        FRTestNetworkStubProtocol.mockedResponses = []
        FRTestNetworkStubProtocol.requestIndex = 0
        FRUser._staticUser = nil
        FRDevice._staticDevice = nil
    }
    
    @objc static func startSDK(_ config: Config) {
        // Initialize SDK
        do {
            if let _ = config.configPlistFileName {
                try FRAuth.start()
                // Make sure FRAuth.shared is not nil
                guard let _ = FRAuth.shared else {
                    XCTFail("Failed to start SDK; FRAuth.shared returns nil")
                    return
                }
            }
            else if let serverConfig = config.serverConfig,
                let oAuth2Client = config.oAuth2Client,
                let sessionManager = config.sessionManager,
                let tokenManager = config.tokenManager,
                let keychainManager = config.keychainManager,
                let authServiceName = config.authServiceName,
                let registrationServiceName = config.registrationServiceName {
                
                FRAuth.shared = FRAuth(authServiceName: authServiceName, registerServiceName: registrationServiceName, serverConfig: serverConfig, oAuth2Client: oAuth2Client, tokenManager: tokenManager, keychainManager: keychainManager, sessionManager: sessionManager)
            }
            else {
                XCTFail("Failed to start SDK: invalid configuration file.")
            }
        }
        catch {
            XCTFail("Failed to start SDK: \(error)")
        }
    }
    
    @objc static func parseStringToDictionary(_ str: String) -> [String: Any] {
        
        var json: [String: Any]?
        
        if let data = str.data(using: String.Encoding.utf8) {
            do {
                json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:Any]
            } catch {
                XCTFail("Fail to parse JSON payload")
            }
        }
        
        guard let jsonDict = json else {
            XCTFail("Fail to parse JSON payload")
            return [:]
        }
        
        return jsonDict
    }
    
    @objc static func loadMockResponses(_ responseFileNames: [String]) {
        
        for fileName in responseFileNames {
            if let response = FRTestStubResponseParser(fileName) {
                FRTestNetworkStubProtocol.mockedResponses.append(response)
            }
            else {
                XCTFail("[FRAuthTest] Failed to load \(fileName) for mock response")
            }
        }
    }
    
    @objc static func readDataFromJSON(_ fileName: String) -> [String: Any]? {
        if let jsonPath = Bundle(for: FRBaseTest.self).path(forResource: fileName, ofType: "json"),
            let jsonString = try? String(contentsOfFile: jsonPath),
            let jsonData = jsonString.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [String: Any]
        {
            return json
        }
        else {
            return nil
        }
    }
}
