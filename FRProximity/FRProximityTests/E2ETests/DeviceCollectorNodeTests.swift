// 
//  DeviceCollectorNodeTests.swift
//  FRProximityTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
import CoreLocation
@testable import FRAuth

class DeviceCollectorNodeTests: FRPBaseTest {

    func test_01_device_collector_metadata_only() {
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_DeviceCollectorNodeMetadataOnly",
                                "AuthTree_SSOToken_Success"])
        
        do {
            // Init SDK
            try FRAuth.start()
            // Store Node object
            var currentNode: Node?

            var ex = self.expectation(description: "First Node submit")
            FRSession.authenticate(authIndexValue: "AuthTree") { (token, node, error) in
                // Validate result
                XCTAssertNil(token)
                XCTAssertNil(error)
                XCTAssertNotNil(node)
                currentNode = node
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            guard let firstNode = currentNode else {
                XCTFail("Failed to get Node from the first request")
                return
            }
            
            // Provide input value for callbacks
            for callback in firstNode.callbacks {
                if callback is NameCallback, let nameCallback = callback as? NameCallback {
                    nameCallback.value = "username"
                }
                else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                    passwordCallback.value = "password"
                }
                else {
                    XCTFail("Received unexpected callback \(callback)")
                }
            }
            
            ex = self.expectation(description: "Second Node submit")
            firstNode.next { (token: Token?, node, error) in
                // Validate result
                XCTAssertNil(token)
                XCTAssertNil(error)
                XCTAssertNotNil(node)
                currentNode = node
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            guard let secondNode = currentNode else {
                XCTFail("Failed to get Node from the second request")
                return
            }
            
            // Provide input value for callbacks
            var deviceCallback: DeviceProfileCallback?
            for callback in secondNode.callbacks {
                if callback is DeviceProfileCallback, let deviceProfileCallback = callback as? DeviceProfileCallback {
                    deviceCallback = deviceProfileCallback
                }
            }
            
            guard let deviceProfileCallback = deviceCallback else {
                XCTFail("While expecting DeviceProfileCallback; Node was returned without DeviceProfileCallback")
                return
            }
            
            XCTAssertTrue(deviceProfileCallback.metadataRequired)
            XCTAssertFalse(deviceProfileCallback.locationRequired)
            XCTAssertEqual(deviceProfileCallback.message.count, 0)
            
            ex = self.expectation(description: "Executing DeviceProfileCallback")
            deviceProfileCallback.execute { (response) in
                XCTAssertTrue(response.keys.contains("metadata"))
                XCTAssertTrue(response.keys.contains("identifier"))
                XCTAssertFalse(response.keys.contains("location"))
                XCTAssertNotNil(deviceProfileCallback.value)
                let requestPayload = FRPTestUtils.parseStringToDictionary(deviceProfileCallback.value as! String)
                XCTAssertEqual(response.keys, requestPayload.keys)
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            ex = self.expectation(description: "Third Node submit")
            secondNode.next { (token: Token?, node, error) in
                // Validate result
                XCTAssertNil(node)
                XCTAssertNil(error)
                XCTAssertNotNil(token)
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_02_device_collector_metadata_location_approved() {
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_DeviceCollectorNodeAll",
                                "AuthTree_SSOToken_Success"])
        
        do {
            // Init SDK
            try FRAuth.start()
            // Store Node object
            var currentNode: Node?

            var ex = self.expectation(description: "First Node submit")
            FRSession.authenticate(authIndexValue: "AuthTree") { (token, node, error) in
                // Validate result
                XCTAssertNil(token)
                XCTAssertNil(error)
                XCTAssertNotNil(node)
                currentNode = node
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            guard let firstNode = currentNode else {
                XCTFail("Failed to get Node from the first request")
                return
            }
            
            // Provide input value for callbacks
            for callback in firstNode.callbacks {
                if callback is NameCallback, let nameCallback = callback as? NameCallback {
                    nameCallback.value = "username"
                }
                else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                    passwordCallback.value = "password"
                }
                else {
                    XCTFail("Received unexpected callback \(callback)")
                }
            }
            
            ex = self.expectation(description: "Second Node submit")
            firstNode.next { (token: Token?, node, error) in
                // Validate result
                XCTAssertNil(token)
                XCTAssertNil(error)
                XCTAssertNotNil(node)
                currentNode = node
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            guard let secondNode = currentNode else {
                XCTFail("Failed to get Node from the second request")
                return
            }
            
            // Provide input value for callbacks
            var deviceCallback: DeviceProfileCallback?
            for callback in secondNode.callbacks {
                if callback is DeviceProfileCallback, let deviceProfileCallback = callback as? DeviceProfileCallback {
                    deviceCallback = deviceProfileCallback
                }
            }
            
            guard let deviceProfileCallback = deviceCallback else {
                XCTFail("While expecting DeviceProfileCallback; Node was returned without DeviceProfileCallback")
                return
            }
            
            // Fake location collector
            let fakeLocationManager = FakeLocationManager()
            fakeLocationManager.fakeLocation = [CLLocation(latitude: 49.2827, longitude: 123.1207)]
            let location = FakeLocationCollector()
            location.locationManager = fakeLocationManager
            location.changeStatus(status: .authorizedWhenInUse)

            // Assign FakeLocationCollector to callback
            for (index, collector) in deviceProfileCallback.collector.collectors.enumerated() {
                if String(describing:collector) == "FRProximity.LocationCollector" {
                    deviceProfileCallback.collector.collectors.remove(at: index)
                    deviceProfileCallback.collector.collectors.append(location)
                }
            }
            
            XCTAssertTrue(deviceProfileCallback.metadataRequired)
            XCTAssertTrue(deviceProfileCallback.locationRequired)
            XCTAssertEqual(deviceProfileCallback.message.count, 0)
            
            ex = self.expectation(description: "Executing DeviceProfileCallback")
            deviceProfileCallback.execute { (response) in
                XCTAssertTrue(response.keys.contains("metadata"))
                XCTAssertTrue(response.keys.contains("identifier"))
                XCTAssertTrue(response.keys.contains("location"))
                
                guard let locationResponse = response["location"] as? [String: Any], let lat = locationResponse["latitude"] as? Double, let long = locationResponse["longitude"] as? Double else {
                    XCTFail("Failed to parse latitude, and longitude in the response; unexpected data type was returned")
                    ex.fulfill()
                    return
                }
                XCTAssertEqual(lat, 49.2827)
                XCTAssertEqual(long, 123.1207)
                
                XCTAssertNotNil(deviceProfileCallback.value)
                let requestPayload = FRPTestUtils.parseStringToDictionary(deviceProfileCallback.value as! String)
                XCTAssertEqual(response.keys, requestPayload.keys)
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            ex = self.expectation(description: "Third Node submit")
            secondNode.next { (token: Token?, node, error) in
                // Validate result
                XCTAssertNil(node)
                XCTAssertNil(error)
                XCTAssertNotNil(token)
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_03_device_collector_metadata_location_denied() {
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_DeviceCollectorNodeAll",
                                "AuthTree_SSOToken_Success"])
        
        do {
            // Init SDK
            try FRAuth.start()
            // Store Node object
            var currentNode: Node?

            var ex = self.expectation(description: "First Node submit")
            FRSession.authenticate(authIndexValue: "AuthTree") { (token, node, error) in
                // Validate result
                XCTAssertNil(token)
                XCTAssertNil(error)
                XCTAssertNotNil(node)
                currentNode = node
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            guard let firstNode = currentNode else {
                XCTFail("Failed to get Node from the first request")
                return
            }
            
            // Provide input value for callbacks
            for callback in firstNode.callbacks {
                if callback is NameCallback, let nameCallback = callback as? NameCallback {
                    nameCallback.value = "username"
                }
                else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                    passwordCallback.value = "password"
                }
                else {
                    XCTFail("Received unexpected callback \(callback)")
                }
            }
            
            ex = self.expectation(description: "Second Node submit")
            firstNode.next { (token: Token?, node, error) in
                // Validate result
                XCTAssertNil(token)
                XCTAssertNil(error)
                XCTAssertNotNil(node)
                currentNode = node
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            guard let secondNode = currentNode else {
                XCTFail("Failed to get Node from the second request")
                return
            }
            
            // Provide input value for callbacks
            var deviceCallback: DeviceProfileCallback?
            for callback in secondNode.callbacks {
                if callback is DeviceProfileCallback, let deviceProfileCallback = callback as? DeviceProfileCallback {
                    deviceCallback = deviceProfileCallback
                }
            }
            
            guard let deviceProfileCallback = deviceCallback else {
                XCTFail("While expecting DeviceProfileCallback; Node was returned without DeviceProfileCallback")
                return
            }
            
            // Fake location collector
            let location = FakeLocationCollector()
            location.changeStatus(status: .denied)

            // Assign FakeLocationCollector to callback
            for (index, collector) in deviceProfileCallback.collector.collectors.enumerated() {
                if String(describing:collector) == "FRProximity.LocationCollector" {
                    deviceProfileCallback.collector.collectors.remove(at: index)
                    deviceProfileCallback.collector.collectors.append(location)
                }
            }
            
            XCTAssertTrue(deviceProfileCallback.metadataRequired)
            XCTAssertTrue(deviceProfileCallback.locationRequired)
            XCTAssertEqual(deviceProfileCallback.message.count, 0)
            
            ex = self.expectation(description: "Executing DeviceProfileCallback")
            deviceProfileCallback.execute { (response) in
                XCTAssertTrue(response.keys.contains("metadata"))
                XCTAssertTrue(response.keys.contains("identifier"))
                XCTAssertFalse(response.keys.contains("location"))
                XCTAssertNotNil(deviceProfileCallback.value)
                let requestPayload = FRPTestUtils.parseStringToDictionary(deviceProfileCallback.value as! String)
                XCTAssertEqual(response.keys, requestPayload.keys)
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            ex = self.expectation(description: "Third Node submit")
            secondNode.next { (token: Token?, node, error) in
                // Validate result
                XCTAssertNil(node)
                XCTAssertNil(error)
                XCTAssertNotNil(token)
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_04_device_collector_location_only_and_approved() {
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_DeviceCollectorNodeLocationOnly",
                                "AuthTree_SSOToken_Success"])
        
        do {
            // Init SDK
            try FRAuth.start()
            // Store Node object
            var currentNode: Node?

            var ex = self.expectation(description: "First Node submit")
            FRSession.authenticate(authIndexValue: "AuthTree") { (token, node, error) in
                // Validate result
                XCTAssertNil(token)
                XCTAssertNil(error)
                XCTAssertNotNil(node)
                currentNode = node
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            guard let firstNode = currentNode else {
                XCTFail("Failed to get Node from the first request")
                return
            }
            
            // Provide input value for callbacks
            for callback in firstNode.callbacks {
                if callback is NameCallback, let nameCallback = callback as? NameCallback {
                    nameCallback.value = "username"
                }
                else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                    passwordCallback.value = "password"
                }
                else {
                    XCTFail("Received unexpected callback \(callback)")
                }
            }
            
            ex = self.expectation(description: "Second Node submit")
            firstNode.next { (token: Token?, node, error) in
                // Validate result
                XCTAssertNil(token)
                XCTAssertNil(error)
                XCTAssertNotNil(node)
                currentNode = node
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            guard let secondNode = currentNode else {
                XCTFail("Failed to get Node from the second request")
                return
            }
            
            // Provide input value for callbacks
            var deviceCallback: DeviceProfileCallback?
            for callback in secondNode.callbacks {
                if callback is DeviceProfileCallback, let deviceProfileCallback = callback as? DeviceProfileCallback {
                    deviceCallback = deviceProfileCallback
                }
            }
            
            guard let deviceProfileCallback = deviceCallback else {
                XCTFail("While expecting DeviceProfileCallback; Node was returned without DeviceProfileCallback")
                return
            }
            
            // Fake location collector
            let fakeLocationManager = FakeLocationManager()
            fakeLocationManager.fakeLocation = [CLLocation(latitude: 49.2827, longitude: 123.1207)]
            let location = FakeLocationCollector()
            location.locationManager = fakeLocationManager
            location.changeStatus(status: .authorizedWhenInUse)

            // Assign FakeLocationCollector to callback
            for (index, collector) in deviceProfileCallback.collector.collectors.enumerated() {
                if String(describing:collector) == "FRProximity.LocationCollector" {
                    deviceProfileCallback.collector.collectors.remove(at: index)
                    deviceProfileCallback.collector.collectors.append(location)
                }
            }
            
            XCTAssertFalse(deviceProfileCallback.metadataRequired)
            XCTAssertTrue(deviceProfileCallback.locationRequired)
            XCTAssertEqual(deviceProfileCallback.message.count, 0)
            
            ex = self.expectation(description: "Executing DeviceProfileCallback")
            deviceProfileCallback.execute { (response) in
                XCTAssertFalse(response.keys.contains("metadata"))
                XCTAssertTrue(response.keys.contains("identifier"))
                XCTAssertTrue(response.keys.contains("location"))
                
                guard let locationResponse = response["location"] as? [String: Any], let lat = locationResponse["latitude"] as? Double, let long = locationResponse["longitude"] as? Double else {
                    XCTFail("Failed to parse latitude, and longitude in the response; unexpected data type was returned")
                    ex.fulfill()
                    return
                }
                XCTAssertEqual(lat, 49.2827)
                XCTAssertEqual(long, 123.1207)
                
                XCTAssertNotNil(deviceProfileCallback.value)
                let requestPayload = FRPTestUtils.parseStringToDictionary(deviceProfileCallback.value as! String)
                XCTAssertEqual(response.keys, requestPayload.keys)
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            ex = self.expectation(description: "Third Node submit")
            secondNode.next { (token: Token?, node, error) in
                // Validate result
                XCTAssertNil(node)
                XCTAssertNil(error)
                XCTAssertNotNil(token)
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }

    
    func test_05_device_collector_location_only_and_denied() {
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_DeviceCollectorNodeLocationOnly",
                                "AuthTree_SSOToken_Success"])
        
        do {
            // Init SDK
            try FRAuth.start()
            // Store Node object
            var currentNode: Node?

            var ex = self.expectation(description: "First Node submit")
            FRSession.authenticate(authIndexValue: "AuthTree") { (token, node, error) in
                // Validate result
                XCTAssertNil(token)
                XCTAssertNil(error)
                XCTAssertNotNil(node)
                currentNode = node
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            guard let firstNode = currentNode else {
                XCTFail("Failed to get Node from the first request")
                return
            }
            
            // Provide input value for callbacks
            for callback in firstNode.callbacks {
                if callback is NameCallback, let nameCallback = callback as? NameCallback {
                    nameCallback.value = "username"
                }
                else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                    passwordCallback.value = "password"
                }
                else {
                    XCTFail("Received unexpected callback \(callback)")
                }
            }
            
            ex = self.expectation(description: "Second Node submit")
            firstNode.next { (token: Token?, node, error) in
                // Validate result
                XCTAssertNil(token)
                XCTAssertNil(error)
                XCTAssertNotNil(node)
                currentNode = node
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            guard let secondNode = currentNode else {
                XCTFail("Failed to get Node from the second request")
                return
            }
            
            // Provide input value for callbacks
            var deviceCallback: DeviceProfileCallback?
            for callback in secondNode.callbacks {
                if callback is DeviceProfileCallback, let deviceProfileCallback = callback as? DeviceProfileCallback {
                    deviceCallback = deviceProfileCallback
                }
            }
            
            guard let deviceProfileCallback = deviceCallback else {
                XCTFail("While expecting DeviceProfileCallback; Node was returned without DeviceProfileCallback")
                return
            }
            
            // Fake location collector
            let location = FakeLocationCollector()
            location.changeStatus(status: .denied)

            // Assign FakeLocationCollector to callback
            for (index, collector) in deviceProfileCallback.collector.collectors.enumerated() {
                if String(describing:collector) == "FRProximity.LocationCollector" {
                    deviceProfileCallback.collector.collectors.remove(at: index)
                    deviceProfileCallback.collector.collectors.append(location)
                }
            }
            
            XCTAssertFalse(deviceProfileCallback.metadataRequired)
            XCTAssertTrue(deviceProfileCallback.locationRequired)
            XCTAssertEqual(deviceProfileCallback.message.count, 0)
            
            ex = self.expectation(description: "Executing DeviceProfileCallback")
            deviceProfileCallback.execute { (response) in
                XCTAssertFalse(response.keys.contains("metadata"))
                XCTAssertTrue(response.keys.contains("identifier"))
                XCTAssertFalse(response.keys.contains("location"))
                XCTAssertNotNil(deviceProfileCallback.value)
                let requestPayload = FRPTestUtils.parseStringToDictionary(deviceProfileCallback.value as! String)
                XCTAssertEqual(response.keys, requestPayload.keys)
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            ex = self.expectation(description: "Third Node submit")
            secondNode.next { (token: Token?, node, error) in
                // Validate result
                XCTAssertNil(node)
                XCTAssertNil(error)
                XCTAssertNotNil(token)
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }

    
    
    func test_06_device_collector_with_message() {
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_DeviceCollectorNodeWithMessage",
                                "AuthTree_SSOToken_Success"])
        
        do {
            // Init SDK
            try FRAuth.start()
            // Store Node object
            var currentNode: Node?

            var ex = self.expectation(description: "First Node submit")
            FRSession.authenticate(authIndexValue: "AuthTree") { (token, node, error) in
                // Validate result
                XCTAssertNil(token)
                XCTAssertNil(error)
                XCTAssertNotNil(node)
                currentNode = node
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            guard let firstNode = currentNode else {
                XCTFail("Failed to get Node from the first request")
                return
            }
            
            // Provide input value for callbacks
            for callback in firstNode.callbacks {
                if callback is NameCallback, let nameCallback = callback as? NameCallback {
                    nameCallback.value = "username"
                }
                else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                    passwordCallback.value = "password"
                }
                else {
                    XCTFail("Received unexpected callback \(callback)")
                }
            }
            
            ex = self.expectation(description: "Second Node submit")
            firstNode.next { (token: Token?, node, error) in
                // Validate result
                XCTAssertNil(token)
                XCTAssertNil(error)
                XCTAssertNotNil(node)
                currentNode = node
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            guard let secondNode = currentNode else {
                XCTFail("Failed to get Node from the second request")
                return
            }
            
            // Provide input value for callbacks
            var deviceCallback: DeviceProfileCallback?
            for callback in secondNode.callbacks {
                if callback is DeviceProfileCallback, let deviceProfileCallback = callback as? DeviceProfileCallback {
                    deviceCallback = deviceProfileCallback
                }
            }
            
            guard let deviceProfileCallback = deviceCallback else {
                XCTFail("While expecting DeviceProfileCallback; Node was returned without DeviceProfileCallback")
                return
            }
            
            // Fake location collector
            let fakeLocationManager = FakeLocationManager()
            fakeLocationManager.fakeLocation = [CLLocation(latitude: 49.2827, longitude: 123.1207)]
            let location = FakeLocationCollector()
            location.locationManager = fakeLocationManager
            location.changeStatus(status: .authorizedWhenInUse)

            // Assign FakeLocationCollector to callback
            for (index, collector) in deviceProfileCallback.collector.collectors.enumerated() {
                if String(describing:collector) == "FRProximity.LocationCollector" {
                    deviceProfileCallback.collector.collectors.remove(at: index)
                    deviceProfileCallback.collector.collectors.append(location)
                }
            }
            
            XCTAssertTrue(deviceProfileCallback.metadataRequired)
            XCTAssertTrue(deviceProfileCallback.locationRequired)
            XCTAssertTrue(deviceProfileCallback.message.count > 0)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_07_device_collector_metadata_location_approved_with_custom_metadata() {
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_DeviceCollectorNodeAll",
                                "AuthTree_SSOToken_Success"])
        
        do {
            // Init SDK
            try FRAuth.start()
            // Store Node object
            var currentNode: Node?

            var ex = self.expectation(description: "First Node submit")
            FRSession.authenticate(authIndexValue: "AuthTree") { (token, node, error) in
                // Validate result
                XCTAssertNil(token)
                XCTAssertNil(error)
                XCTAssertNotNil(node)
                currentNode = node
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            guard let firstNode = currentNode else {
                XCTFail("Failed to get Node from the first request")
                return
            }
            
            // Provide input value for callbacks
            for callback in firstNode.callbacks {
                if callback is NameCallback, let nameCallback = callback as? NameCallback {
                    nameCallback.value = "james.go@forgerock.com"
                }
                else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                    passwordCallback.value = "Password123!"
                }
                else {
                    XCTFail("Received unexpected callback \(callback)")
                }
            }
            
            ex = self.expectation(description: "Second Node submit")
            firstNode.next { (token: Token?, node, error) in
                // Validate result
                XCTAssertNil(token)
                XCTAssertNil(error)
                XCTAssertNotNil(node)
                currentNode = node
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            guard let secondNode = currentNode else {
                XCTFail("Failed to get Node from the second request")
                return
            }
            
            // Provide input value for callbacks
            var deviceCallback: DeviceProfileCallback?
            for callback in secondNode.callbacks {
                if callback is DeviceProfileCallback, let deviceProfileCallback = callback as? DeviceProfileCallback {
                    deviceCallback = deviceProfileCallback
                }
            }
            
            guard let deviceProfileCallback = deviceCallback else {
                XCTFail("While expecting DeviceProfileCallback; Node was returned without DeviceProfileCallback")
                return
            }
            
            // Fake location collector
            let fakeLocationManager = FakeLocationManager()
            fakeLocationManager.fakeLocation = [CLLocation(latitude: 49.2827, longitude: 123.1207)]
            let location = FakeLocationCollector()
            location.locationManager = fakeLocationManager
            location.changeStatus(status: .authorizedWhenInUse)

            // Assign FakeLocationCollector to callback
            deviceProfileCallback.collector.collectors.removeAll()
            deviceProfileCallback.collector.collectors.append(location)
            deviceProfileCallback.collector.collectors.append(CustomCollector())
            
            XCTAssertTrue(deviceProfileCallback.metadataRequired)
            XCTAssertTrue(deviceProfileCallback.locationRequired)
            XCTAssertEqual(deviceProfileCallback.message.count, 0)
            
            ex = self.expectation(description: "Executing DeviceProfileCallback")
            deviceProfileCallback.execute { (response) in
                XCTAssertTrue(response.keys.contains("metadata"))
                XCTAssertTrue(response.keys.contains("identifier"))
                XCTAssertTrue(response.keys.contains("location"))
                
                guard let locationResponse = response["location"] as? [String: Any], let lat = locationResponse["latitude"] as? Double, let long = locationResponse["longitude"] as? Double else {
                    XCTFail("Failed to parse latitude, and longitude in the response; unexpected data type was returned")
                    ex.fulfill()
                    return
                }
                XCTAssertEqual(lat, 49.2827)
                XCTAssertEqual(long, 123.1207)
                
                XCTAssertNotNil(deviceProfileCallback.value)
                let requestPayload = FRPTestUtils.parseStringToDictionary(deviceProfileCallback.value as! String)
                XCTAssertEqual(response.keys, requestPayload.keys)
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            ex = self.expectation(description: "Third Node submit")
            secondNode.next { (token: Token?, node, error) in
                // Validate result
                XCTAssertNil(node)
                XCTAssertNil(error)
                XCTAssertNotNil(token)
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
}
