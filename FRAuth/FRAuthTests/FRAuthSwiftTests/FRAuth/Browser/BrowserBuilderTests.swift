// 
//  BrowserBuilderTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class BrowserBuilderTests: FRAuthBaseTest {

    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    
    func test_01_basic_construction() {
        
        //  Start SDK
        self.startSDK()
        
        guard let oAuth2Client = self.config.oAuth2Client, let keychainManager = self.config.keychainManager else {
            XCTFail("Failed to retrieve OAuth2Client, and/or KeychainManager instance after SDK init")
            return
        }
        
        let builder = BrowserBuilder(oAuth2Client, keychainManager)
        XCTAssertNotNil(builder)
    }
    
    
    func test_02_progressive_construction() {
        
        //  Start SDK
        self.startSDK()
        
        guard let oAuth2Client = self.config.oAuth2Client, let keychainManager = self.config.keychainManager else {
            XCTFail("Failed to retrieve OAuth2Client, and/or KeychainManager instance after SDK init")
            return
        }
        
        let builder = BrowserBuilder(oAuth2Client, keychainManager)
        XCTAssertNotNil(builder)
        
        //  Given
        let vc = UIViewController()
        builder.set(browserType: .nativeBrowserApp)
        builder.set(presentingViewController: vc)
        builder.setCustomParam(key: "key1", value: "val1")
        let browser = builder.build()
        
        //  Then
        XCTAssertEqual(browser.presentingViewController, vc)
        XCTAssertEqual(browser.browserType, .nativeBrowserApp)
        XCTAssertTrue(browser.customParam.keys.contains("key1"))
        XCTAssertEqual(browser.customParam["key1"], "val1")
        XCTAssertNotNil(Browser.currentBrowser)
    }
}
