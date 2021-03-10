//
//  JailbreakDetectorTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class JailbreakDetectorTests: FRAuthBaseTest {

    
    func testNoJailbreakDetector() {
        // Given
        FRJailbreakDetector.shared.detectors = []
        let result = FRJailbreakDetector.shared.analyze()
        
        // Then
        #if targetEnvironment(simulator)
        XCTAssertEqual(result, 0.0, "JailbreakDetector Test fail: returns result as simulator while running on device")
        #else
        XCTAssertTrue(result == -1.0, "JailbreakDetector Test fail: all detector should return false; but returned something else (score: \(result)")
        #endif
    }
    
    func testJailbreakDetector() {
        // Given
        let result = FRJailbreakDetector.shared.analyze()
        
        // Then
        #if targetEnvironment(simulator)
        XCTAssertEqual(result, 0.0, "JailbreakDetector Test fail: returns result as simulator while running on device")
        #else
        XCTAssertTrue(result == 0.0, "JailbreakDetector Test fail: all detector should return false; but returned something else (score: \(result)")
        #endif
    }
    
    func testIndividualDetector() {
        // Given
        let jbDetector = FRJailbreakDetector.shared
        
        for detector in jbDetector.detectors {
            var expectedResult: Double = 0.0
            
            #if targetEnvironment(simulator)
            if detector is SSHDetector || detector is BashDetector {
                expectedResult = 1.0
            }
            #endif
            
            #if !targetEnvironment(simulator)
            XCTAssertEqual(detector.analyze(), expectedResult, "Detector comparison failed for \(String(describing: detector))")
            #else
            if String(describing: detector) == "FRAuth.SandboxDetector" {
                print("Ignoring SandboxDetector result on Simulator as its return value keeps changing: \(String(describing: detector))")
            }
            else {
                print("expected result: \(expectedResult)")
                print("actual result: \(detector.analyze())")
                XCTAssertEqual(detector.analyze(), expectedResult, "Detector comparison failed for \(String(describing: detector))")
            }
            #endif
        }
    }
}
