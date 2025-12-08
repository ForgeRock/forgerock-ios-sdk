//
//  AA_04_DeviceProfileCallbackTest.swift
//  FRAuthTests
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AA_04_DeviceProfileCallbackTest: CallbackBaseTest {
    
    override func setUp() {
        super.setUp()
        self.config.authServiceName = "DeviceProfileCallbackTest"
    }
    
    func test_01_device_profile_callback() {
        var currentNode: Node
        
        do {
            try currentNode = fulfillUsernamePasswordNodes()
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected at least one node after username/password nodes, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        // The first callback is a ChoiceCallback (choose to collect location or not...)
        guard let choiceCallback = currentNode.callbacks.first as? ChoiceCallback else {
            XCTFail("Expected ChoiceCallback")
            return
        }
        
        // Select "Yes" - collect location data...
        choiceCallback.setValue(0)
        
        var ex = self.expectation(description: "Submit choice callback")
        currentNode.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node!
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // We expect DeviceProfileCallback here. Assert its properties. . .
        for callback in currentNode.callbacks {
            if callback is DeviceProfileCallback, let dCallback = callback as? DeviceProfileCallback {
                XCTAssertTrue(dCallback.locationRequired)
                XCTAssertTrue(dCallback.metadataRequired)
                XCTAssertEqual(dCallback.message, "Collecting profile ...")
            
                dCallback.prepareCollectors()
                var deviceInfo: [String: Any] = [:]
                let ex = self.expectation(description: "Device Profile Collection")
                dCallback.execute { (deviceProfile) in
                    // print(deviceProfile)
                    deviceInfo = deviceProfile
                    ex.fulfill()
                }
                waitForExpectations(timeout: 60, handler: nil)
                
                XCTAssertNotNil(deviceInfo)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Submit device collector callback and continue...")
        currentNode.next { (token: AccessToken?, node, error) in
            
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
}
