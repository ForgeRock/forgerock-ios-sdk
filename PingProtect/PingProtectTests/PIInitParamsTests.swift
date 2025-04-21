// 
//  PIInitParams.swift
//  PingProtectTests
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import PingProtect

final class PIInitParamsTests: XCTestCase {
    
    func test_01_default_values()  {
        let initParams = PIInitParams()
        
        XCTAssertEqual(initParams.behavioralDataCollection, true)
        XCTAssertEqual(initParams.customHost, nil)
        XCTAssertEqual(initParams.deviceAttributesToIgnore, nil)
        XCTAssertEqual(initParams.envId, nil)
        XCTAssertEqual(initParams.lazyMetadata, false)
        XCTAssertEqual(initParams.consoleLogEnabled, false)
    }
    
    
    func test_02_getPOInitParams()  {
        let envId = "EnvID"
        let deviceAttributesToIgnore = ["Attr1", "Atrr2"]
        let consoleLogEnabled = true
        let customHost = "custom.host"
        let lazyMetadata = true
        let behavioralDataCollection = false
        
        let initParams = PIInitParams(envId: envId, 
                                      deviceAttributesToIgnore: deviceAttributesToIgnore,
                                      consoleLogEnabled: consoleLogEnabled,
                                      customHost: customHost,
                                      lazyMetadata: lazyMetadata,
                                      behavioralDataCollection: behavioralDataCollection)
        
        let signalsInitParam = initParams.getPOInitParams()
        
        XCTAssertEqual(signalsInitParam.envId, envId)
        XCTAssertEqual(signalsInitParam.deviceAttributesToIgnore, deviceAttributesToIgnore)
        XCTAssertEqual(signalsInitParam.consoleLogEnabled, consoleLogEnabled)
        XCTAssertEqual(signalsInitParam.customHost, customHost)
        XCTAssertEqual(signalsInitParam.lazyMetadata, lazyMetadata)
        XCTAssertEqual(signalsInitParam.behavioralDataCollection, behavioralDataCollection)
    }
    
}
