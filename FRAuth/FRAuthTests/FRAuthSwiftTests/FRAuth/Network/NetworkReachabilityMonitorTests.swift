//
//  NetworkReachabilityMonitorTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
import SystemConfiguration
@testable import FRAuth

class NetworkReachabilityMonitorTests: FRAuthBaseTest {

    func testGeneralReachabilityMonitoring() {
        // Given
        guard let monitor = NetworkReachabilityMonitor() else {
            XCTFail("Failed to create Reachability Monitor object without any parameter")
            return
        }
        
        // Then initial status should be unknown
        XCTAssertEqual(monitor.currentStatus, FRNetworkReachabilityStatus.unknown)
        
        // When start monitoring
        var currentStatus: FRNetworkReachabilityStatus?
        let ex = self.expectation(description: "Network Reachability Monitoring block")
        monitor.monitoringCallback = { (status) in
            currentStatus = status
            ex.fulfill()
        }
        monitor.startMonitoring()
        waitForExpectations(timeout: 60, handler: nil)
        
        // Then
        XCTAssertTrue(monitor.isReachable)
        XCTAssertTrue((currentStatus == FRNetworkReachabilityStatus.reachableWithWiFi || currentStatus == FRNetworkReachabilityStatus.reachableWithWWAN))
    }
    
    func testHostReachabilityMonitoring() {
        // Given
        let host = "https://www.forgerock.com"
        guard let monitor = NetworkReachabilityMonitor(host: host) else {
            XCTFail("Failed to create Reachability Monitor object with hostname")
            return
        }
        
        // Then initial status should be unknown
        XCTAssertEqual(monitor.currentStatus, FRNetworkReachabilityStatus.unknown)
        
        // When start monitoring
        var currentStatus: FRNetworkReachabilityStatus?
        let ex = self.expectation(description: "Network Reachability Monitoring block")
        monitor.monitoringCallback = { (status) in
            currentStatus = status
            ex.fulfill()
        }
        monitor.startMonitoring()
        waitForExpectations(timeout: 60, handler: nil)
        
        // Then
        XCTAssertTrue(monitor.isReachable)
        XCTAssertTrue((currentStatus == FRNetworkReachabilityStatus.reachableWithWiFi || currentStatus == FRNetworkReachabilityStatus.reachableWithWWAN))
    }
    
    func testReachabilityStatusWithReachableFlags() {
        // Given
        guard let monitor = NetworkReachabilityMonitor() else {
            XCTFail("Failed to create Reachability Monitor object without any parameter")
            return
        }
        let flags: SCNetworkReachabilityFlags = [.reachable]
        monitor.updateNetworkReachabilityStatus(flags: flags)
        
        // Then
        XCTAssertTrue(monitor.isReachable)
        XCTAssertEqual(monitor.currentStatus, FRNetworkReachabilityStatus.reachableWithWiFi)
    }
    
    func testReachabilityStatusWithReachableAndWWANFlags() {
        // Given
        guard let monitor = NetworkReachabilityMonitor() else {
            XCTFail("Failed to create Reachability Monitor object without any parameter")
            return
        }
        let flags: SCNetworkReachabilityFlags = [.reachable, .isWWAN]
        monitor.updateNetworkReachabilityStatus(flags: flags)
        
        // Then
        XCTAssertTrue(monitor.isReachable)
        XCTAssertEqual(monitor.currentStatus, FRNetworkReachabilityStatus.reachableWithWWAN)
    }
    
    func testReachabilityStatusWithReachableAndConnectionRequired() {
        // Given
        guard let monitor = NetworkReachabilityMonitor() else {
            XCTFail("Failed to create Reachability Monitor object without any parameter")
            return
        }
        let flags: SCNetworkReachabilityFlags = [.reachable, .connectionRequired]
        monitor.updateNetworkReachabilityStatus(flags: flags)
        
        // Then
        XCTAssertFalse(monitor.isReachable)
        XCTAssertEqual(monitor.currentStatus, FRNetworkReachabilityStatus.notReachable)
    }
    
    func testReachabilityStatusWithReachableAndConnectionRequiredAndInterventionRequired() {
        // Given
        guard let monitor = NetworkReachabilityMonitor() else {
            XCTFail("Failed to create Reachability Monitor object without any parameter")
            return
        }
        let flags: SCNetworkReachabilityFlags = [.reachable, .connectionRequired, .interventionRequired]
        monitor.updateNetworkReachabilityStatus(flags: flags)
        
        // Then
        XCTAssertFalse(monitor.isReachable)
        XCTAssertEqual(monitor.currentStatus, FRNetworkReachabilityStatus.notReachable)
    }
    
    func testReachabilityStatusWithReachableAndConnectionRequiredAndConnectionOnTraffice() {
        // Given
        guard let monitor = NetworkReachabilityMonitor() else {
            XCTFail("Failed to create Reachability Monitor object without any parameter")
            return
        }
        let flags: SCNetworkReachabilityFlags = [.reachable, .connectionRequired, .connectionOnTraffic]
        monitor.updateNetworkReachabilityStatus(flags: flags)
        
        // Then
        XCTAssertTrue(monitor.isReachable)
        XCTAssertEqual(monitor.currentStatus, FRNetworkReachabilityStatus.reachableWithWiFi)
    }
    
    func testReachabilityStatusWithoutAnyFlags() {
        // Given
        guard let monitor = NetworkReachabilityMonitor() else {
            XCTFail("Failed to create Reachability Monitor object without any parameter")
            return
        }
        let flags: SCNetworkReachabilityFlags? = nil
        monitor.updateNetworkReachabilityStatus(flags: flags)
        
        // Then
        XCTAssertFalse(monitor.isReachable)
        XCTAssertEqual(monitor.currentStatus, FRNetworkReachabilityStatus.unknown)
    }
}
