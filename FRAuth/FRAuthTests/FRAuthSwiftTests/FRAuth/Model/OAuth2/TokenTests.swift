//
//  TokenTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

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
    
    func testTokenJSONEncoding() {
        
        let token = Token("tokenValue")
        
        // Then
        XCTAssertEqual(token.value, "tokenValue")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let data = try? encoder.encode(token)
        XCTAssertNotNil(data)
        
        if let tokenData = data, let jsonToken = String(data: tokenData, encoding: .utf8) {
            let tokenDictionary = self.parseStringToDictionary(jsonToken)
            XCTAssertNotNil(tokenDictionary)
            
            if let token2Value = tokenDictionary["value"] as? String  {
                XCTAssertEqual(token2Value, token.value)
                XCTAssertEqual(token2Value, "tokenValue")
            } else {
                XCTFail("Fail to parse AccessToken JSON String correctly with given data \(jsonToken)")
            }
        } else {
            XCTFail("Fail to create AccessToken JSON String with given data")
        }
    }
}
