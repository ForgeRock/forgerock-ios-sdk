//
//  TokenTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 - 2025 Ping Identity Corporation. All rights reserved.
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
        XCTAssertEqual(token.successUrl, "")
        XCTAssertEqual(token.realm, "")
    }
    
    func testBasicTokenValueWithoutDefaultValues() {
        
        // Given
        let token = Token("tokenValue", successUrl: "http://success.url", realm: "myRealm")
        
        // Then
        XCTAssertEqual(token.value, "tokenValue")
        XCTAssertEqual(token.successUrl, "http://success.url")
        XCTAssertEqual(token.realm, "myRealm")
    }
    
    func testBasicTokenDebugDescription() {
        
        // Given
        let token = Token("tokenValue")
        
        // Then
        XCTAssertTrue(token.debugDescription.contains("tokenValue"))
    }
    
    
    func testTokenSecureCoding() {
        
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
    
    func testTokenSecureCodingWithoutDefaultValues() {
        
        // Given
        let token = Token("tokenValue", successUrl: "http://success.url", realm: "myRealm")
        
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
                XCTAssertEqual(token2.successUrl, "http://success.url")
                XCTAssertEqual(token2.realm, "myRealm")
            }
            else {
                XCTFail("Failed to unarchive AccessToken \nToken:\(token.debugDescription)\n\nToken Data: \(tokenData)")
            }
        }
        catch {
            XCTFail("Failed to archive AccessToken \nError:\(error.localizedDescription)\n\nToken:\(token.debugDescription)")
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
    
    func testTokenJSONEncodingWithoutDefaultValues() {
        
        let token = Token("tokenValue", successUrl: "http://success.url", realm: "myRealm")
        
        // Then
        XCTAssertEqual(token.value, "tokenValue")
        XCTAssertEqual(token.successUrl, "http://success.url")
        XCTAssertEqual(token.realm, "myRealm")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let data = try? encoder.encode(token)
        XCTAssertNotNil(data)
        
        if let tokenData = data, let jsonToken = String(data: tokenData, encoding: .utf8) {
            let tokenDictionary = self.parseStringToDictionary(jsonToken)
            XCTAssertNotNil(tokenDictionary)
            
            if let token2Value = tokenDictionary["value"] as? String,
               let token2SuccessUrl = tokenDictionary["successUrl"] as? String,
               let token2Realm = tokenDictionary["realm"] as? String {
                XCTAssertEqual(token2Value, token.value)
                XCTAssertEqual(token2Value, "tokenValue")
                XCTAssertEqual(token2SuccessUrl, token.successUrl)
                XCTAssertEqual(token2SuccessUrl, "http://success.url")
                XCTAssertEqual(token2Realm, token.realm)
                XCTAssertEqual(token2Realm, "myRealm")
            } else {
                XCTFail("Fail to parse AccessToken JSON String correctly with given data \(jsonToken)")
            }
        } else {
            XCTFail("Fail to create AccessToken JSON String with given data")
        }
    }
}
