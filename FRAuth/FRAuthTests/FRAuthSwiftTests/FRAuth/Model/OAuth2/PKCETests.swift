//
//  PKCETests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class PKCETests: FRAuthBaseTest {

    func testThatPKCEDoesNotContainInvalidCharacters() {
        
        // Given
        let pkce = PKCE()
        
        // Code Challenge must not contain following characters
        XCTAssertFalse(pkce.codeChallenge.contains("="))
        XCTAssertFalse(pkce.codeChallenge.contains("+"))
        XCTAssertFalse(pkce.codeChallenge.contains("/"))
        
        // Code Verifier must not contain following characters
        XCTAssertFalse(pkce.codeVerifider.contains("="))
        XCTAssertFalse(pkce.codeVerifider.contains("+"))
        XCTAssertFalse(pkce.codeVerifider.contains("/"))
        
        // State must not contain following characters
        XCTAssertFalse(pkce.state.contains("="))
        XCTAssertFalse(pkce.state.contains("+"))
        XCTAssertFalse(pkce.state.contains("/"))
    }
    
    func testThatPKCEGeneratesRandomValues() {
        
        // Given
        let pkce1 = PKCE()
        let pkce2 = PKCE()
        
        // Then
        XCTAssertNotEqual(pkce1.codeChallenge, pkce2.codeChallenge)
        XCTAssertNotEqual(pkce1.codeVerifider, pkce2.codeVerifider)
        XCTAssertNotEqual(pkce1.state, pkce2.state)
    }

}
