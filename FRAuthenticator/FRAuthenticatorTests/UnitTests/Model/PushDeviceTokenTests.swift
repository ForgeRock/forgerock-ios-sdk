// 
//  PushDeviceTokenTests.swift
//  FRAuthenticator
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuthenticator

class PushDeviceTokenTests: FRABaseTests {

    func test_01_push_device_token_init_success() {
        let tokenId = "sampleTokenId"
        let timeAdded = Date()
        
        let pushDeviceToken = PushDeviceToken(tokenId: tokenId, timeAdded: timeAdded)
        
        XCTAssertNotNil(pushDeviceToken)
        XCTAssertEqual(pushDeviceToken.tokenId, tokenId)
        XCTAssertEqual(pushDeviceToken.timeAdded, timeAdded)
    }
    
    
    func test_02_push_device_token_init_with_default_time_added() {
        let tokenId = "sampleTokenId"
        
        let pushDeviceToken = PushDeviceToken(tokenId: tokenId)
        
        XCTAssertNotNil(pushDeviceToken)
        XCTAssertEqual(pushDeviceToken.tokenId, tokenId)
        XCTAssertNotNil(pushDeviceToken.timeAdded)
    }
    
    
    func test_03_push_device_token_archive_obj() {
        let tokenId = "sampleTokenId"
        let timeAdded = Date()
        
        let pushDeviceToken = PushDeviceToken(tokenId: tokenId, timeAdded: timeAdded)
        
        if let tokenData = try? NSKeyedArchiver.archivedData(withRootObject: pushDeviceToken, requiringSecureCoding: true) {
            let tokenFromData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: PushDeviceToken.self, from: tokenData)
            XCTAssertNotNil(tokenFromData)
            XCTAssertEqual(pushDeviceToken.tokenId, tokenFromData?.tokenId)
            XCTAssertEqual(pushDeviceToken.timeAdded.timeIntervalSince1970, tokenFromData?.timeAdded.timeIntervalSince1970)
        } else {
            XCTFail("Failed to serialize PushDeviceToken object with Secure Coding")
        }
    }
    
    
    func test_04_push_device_token_codable_serialization() {
        let tokenId = "sampleTokenId"
        let timeAdded = Date()
        let pushDeviceToken = PushDeviceToken(tokenId: tokenId, timeAdded: timeAdded)
        
        do {
            // Encode
            let jsonData = try JSONEncoder().encode(pushDeviceToken)
            
            // Decode
            let decodedToken = try JSONDecoder().decode(PushDeviceToken.self, from: jsonData)

            XCTAssertEqual(pushDeviceToken.tokenId, decodedToken.tokenId)
            XCTAssertEqual(pushDeviceToken.timeAdded.timeIntervalSince1970, decodedToken.timeAdded.timeIntervalSince1970)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    
    func test_05_push_device_token_json_string_serialization() {
        let tokenId = "sampleTokenId"
        let timeAdded = Date()
        let pushDeviceToken = PushDeviceToken(tokenId: tokenId, timeAdded: timeAdded)
        
        guard let jsonString = pushDeviceToken.toJson() else {
            XCTFail("Failed to serialize the object into JSON String value")
            return
        }
        
        // Convert jsonString to Dictionary
        let jsonDictionary = FRJSONEncoder.jsonStringToDictionary(jsonString: jsonString)
        
        // Then
        XCTAssertEqual(pushDeviceToken.tokenId, jsonDictionary?["tokenId"] as! String)
        XCTAssertEqual(pushDeviceToken.timeAdded.timeIntervalSince1970, jsonDictionary?["timeAdded"] as! TimeInterval)
    }
    
}
