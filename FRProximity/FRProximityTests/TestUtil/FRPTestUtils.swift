// 
//  FRPTestUtils.swift
//  FRProximityTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import XCTest
@testable import FRAuth
@testable import FRCore

class FRPTestUtils: XCTest {
    
    
    @objc static func cleanUpAfterTearDown() {
        if let frAuth = FRAuth.shared {
            frAuth.keychainManager.sharedStore.deleteAll()
            frAuth.keychainManager.privateStore.deleteAll()
            frAuth.keychainManager.cookieStore.deleteAll()
            frAuth.keychainManager.deviceIdentifierStore.deleteAll()
        }
        
        FRTestNetworkStubProtocol.mockedResponses = []
        FRTestNetworkStubProtocol.requestIndex = 0
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
        if let jsonPath = Bundle(for: FRPTestUtils.self).path(forResource: fileName, ofType: "json"),
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
    
    
    static func getDeviceProfileFromServer(identifier: String, userName: String, ssoToken: String) -> [String: Any]? {
        
        guard let serverConfig = FRAuth.shared?.serverConfig else {
            return nil
        }
        
        let request = Request(url: serverConfig.baseURL.absoluteString + "/json/users/\(userName)/profile", method: .GET, headers: ["accept-api-version": "resource=1.0", "Set-Cookie": "iPlanetDirectoryPro=\(ssoToken)"], bodyParams: [:], urlParams: ["_queryFilter": "true"], requestType: .urlEncoded, responseType: .json, timeoutInterval: 60)
        
        let result = RestClient.shared.invokeSync(request: request)
        
        switch result {
        case .success(let response, _):
            
            if let profiles = response["result"] as? [[String: Any]] {
                for profile in profiles {
                    
                    if let _id = profile["_id"] as? String, _id == identifier {
                        return profile
                    }
                }
            }
            break
        case .failure(_):
            break
        }
        
        return nil
    }
}
