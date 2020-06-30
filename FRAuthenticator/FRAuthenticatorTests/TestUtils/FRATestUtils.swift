// 
//  FRATestUtils.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import XCTest

class FRATestUtils: XCTest {
    
    @objc static func cleanUpAfterTearDown() {

        FRAPushHandler.shared.deviceToken = nil
        if let keychainStorageClient = FRAClient.storage as? KeychainServiceClient {
            keychainStorageClient.accountStorage.deleteAll()
            keychainStorageClient.mechanismStorage.deleteAll()
            keychainStorageClient.notificationStorage.deleteAll()
            FRAClient.storage = KeychainServiceClient()
        }
        if let keychainStorageClient = FRAClient.storage as? DummyStorageClient {
            keychainStorageClient.defaultStorageClient.accountStorage.deleteAll()
            keychainStorageClient.defaultStorageClient.mechanismStorage.deleteAll()
            keychainStorageClient.defaultStorageClient.notificationStorage.deleteAll()
            FRAClient.storage = DummyStorageClient()
        }
        FRAClient.shared = nil
        
        FRATestNetworkStubProtocol.mockedResponses = []
        FRATestNetworkStubProtocol.requestIndex = 0
    }
    
    
    static func parseStringToDictionary(_ str: String) -> [String: Any] {
        
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
            if let response = FRATestStubResponseParser(fileName) {
                FRATestNetworkStubProtocol.mockedResponses.append(response)
            }
            else {
                XCTFail("[FRAuthTest] Failed to load \(fileName) for mock response")
            }
        }
    }
}
