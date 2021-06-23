//
//  FRTestUtils.swift
//  FRAuthTests
//
//  Copyright (c) 2019-2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import XCTest

@objc
class FRTestUtils: XCTest {
    
    @objc static func cleanUpAfterTearDown() {
        FRTestNetworkStubProtocol.mockedResponses = []
        FRTestNetworkStubProtocol.requestIndex = 0
    }
    
    
    @objc static func parseStringToDictionary(_ str: String) -> [String: Any] {
        
        var json: [String: Any]?
        
        if let data = str.data(using: .utf8) {
            do {
                json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject]
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
        if let jsonPath = Bundle(for: FRTestUtils.self).path(forResource: fileName, ofType: "json"),
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

    
    @objc static func randomString(of length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var s = ""
        for _ in 0 ..< length {
            s.append(letters.randomElement()!)
        }
        return s
    }
}
