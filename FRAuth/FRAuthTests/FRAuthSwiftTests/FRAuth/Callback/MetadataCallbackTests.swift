// 
//  MetadataCallbackTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class MetadataCallbackTests: FRAuthBaseTest {

    
    func test_01_metadatacallback_init_with_empty_json() {
        
        //  When
        do {
            let _ = try MetadataCallback(json: [:])
            XCTFail("Initiating MetadataCallback with empty JSON was successful while expecting failure")
        }
        catch let error as AuthError {
            // Catch AuthError
            switch error {
            // Should only fail with this error
            case .invalidCallbackResponse:
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_02_metadatacallback_init() {
        
        //  Given
        let jsonStr = """
        {
            "type" : "MetadataCallback",
            "output" : [
                {
                    "name" : "data",
                    "value" :
                    {
                        "stage" : "UsernamePassword"
                    }
                }
            ],
            "_id" : 1
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        //  When
        do {
            let callback = try MetadataCallback(json: callbackResponse)
            
            // Then
            XCTAssertEqual(callback._id, 1)
            XCTAssertEqual(callback.type, "MetadataCallback")
            var stage: String = ""
            if let outputs = callback.response["output"] as? [[String: Any]] {
                for output in outputs {
                    if let outputName = output["name"] as? String, outputName == "data", let outputValue = output["value"] as? [String: String], let stageVal = outputValue["stage"] {
                        stage = stageVal
                    }
                }
            }
            XCTAssertEqual(stage, "UsernamePassword")
            XCTAssertTrue(NSDictionary(dictionary: callbackResponse).isEqual(to: callback.response))
            XCTAssertTrue(NSDictionary(dictionary: callbackResponse).isEqual(to: callback.buildResponse()))
        }
        catch {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
}
