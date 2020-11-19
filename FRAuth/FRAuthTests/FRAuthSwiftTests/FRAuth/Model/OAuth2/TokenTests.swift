//
//  TokenTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest

class TokenTests: FRAuthBaseTest {
    
    func testBasicTokenValue() {
        
        // Given
        let token = Token("tokenValue")
        
        // Then
        XCTAssertEqual(token.value, "tokenValue")
    }
    
    func testBasicTokenDebugDescription() {
        
        // Given
        let token = Token("tokenValue")
        
        // Then
        XCTAssertTrue(token.debugDescription.contains("tokenValue"))
    }
    
    
    func testTokenSecureCoding() {
        if #available(iOS 11.0, *) {
            // Given
            let token = Token("tokenValue")
            
            // Then
            XCTAssertEqual(token.value, "tokenValue")
            
            // Should Also
            do {
                // With given
                let tokenData = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
                
                // Then
                if let token2 = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [AccessToken.self, Token.self], from: tokenData) as? Token {
                    // Should equal
                    XCTAssertEqual(token2, token)
                    XCTAssertTrue(token2 == token)
                    XCTAssertEqual(token2.value, "tokenValue")
                }
                else {
                    XCTFail("Failed to unarchive AccessToken \nToken:\(token.debugDescription)\n\nToken Data: \(tokenData)")
                }
            }
            catch {
                XCTFail("Failed to archive AccessToken \nError:\(error.localizedDescription)\n\nToken:\(token.debugDescription)")
            }
            
        }
    }
}
