//
//  AccessTokenTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AccessTokenTests: FRAuthBaseTest {

    var access_token: String = "eyJhbGciOiJIUzI1NiIsImtpZCI6IndVM2lmSUlhTE9VQVJlUkIvRkc2ZU0xUDFRTT0iLCJ0eXAiOiJKV1QifQ.eyJzdWIiOiJqYW1lcy5nbyIsImN0cyI6Ik9BVVRIMl9TVEFURUxFU1NfR1JBTlQiLCJhdXRoX2xldmVsIjowLCJhdWRpdFRyYWNraW5nSWQiOiIxNjBkMzcxZi1hMTFhLTRhYWFhLWExMWEtZTVlNzA2Y2UzOGMyLTExMTEiLCJpc3MiOiJodHRwczovL3Rlc3QvYW0vb2F1dGgyIiwidG9rZW5OYW1lIjoiYWNjZXNzX3Rva2VuIiwidG9rZW5fdHlwZSI6IkJlYXJlciIsImF1dGhHcmFudElkIjoiYXNkZkNhc2ROektsZ1ZvSG1wWTFKcmtQTG44IiwiYXVkIjoiNDYzNGY0ZTQ1ZjU4MDhhNTM4YWRhMDhkZTYxNzg5MmUiLCJuYmYiOjE1NjI2OTUzOTYsImdyYW50X3R5cGUiOiJhdXRob3JpemF0aW9uX2NvZGUiLCJzY29wZSI6WyJvcGVuaWQiXSwiYXV0aF90aW1lIjoxNTYyNjk1Mzk2LCJyZWFsbSI6Ii8iLCJleHAiOjE1NjI2OTg5OTYsImlhdCI6MTU2MjY5NTM5NiwiZXhwaXJlc19pbiI6MzYwMCwianRpIjoiN3NYVjdTMVpySW9GaHlJcWc0NXBBWFh6blpvIn0.cM55pKRijubjEOA8j6uX7UZNF0NvB-V6fq-CWY3I894"
    var refresh_token: String = "eyJhbGciOiJIUzI1NiIsImtpZCI6IndVM2lmSUlhTE9VQVJlUkIvRkc2ZU0xUDFRTT0iLCJ0eXAiOiJKV1QifQ.eyJzdWIiOiJqYW1lcy5nbyIsImN0cyI6Ik9BVVRIMl9TVEFURUxFU1NfR1JBTlQiLCJhdXRoX2xldmVsIjowLCJhdWRpdFRyYWNraW5nSWQiOiIyYWZmYWRhOC04YjNiLTQyNjMtOTg5YS02MWY5Yjk4ZWI0YTAtMTQ2MTkiLCJpc3MiOiJodHRwczovL3Rlc3QvYW0vb2F1dGgyIiwidG9rZW5OYW1lIjoicmVmcmVzaF90b2tlbiIsInRva2VuX3R5cGUiOiJCZWFyZXIiLCJhdXRoR3JhbnRJZCI6IlBhT3Y5anphUDlmU0FqS2ZjLXVabUtNWVpGVSIsImF1ZCI6IjQ2MzRmNGU0NWY1ODA4YTUzOGFkYTA4ZGU2MTc4OTJlIiwiYWNyIjoiMCIsIm5iZiI6MTU2MjYyOTExNSwib3BzIjoiU0JFZHNSekVvNXJCVTY2Rm5zc1Z6aXZVZXdRIiwiZ3JhbnRfdHlwZSI6ImF1dGhvcml6YXRpb25fY29kZSIsInNjb3BlIjpbIm9wZW5pZCJdLCJhdXRoX3RpbWUiOjE1NjI2MjkxMTMsInJlYWxtIjoiLyIsImV4cCI6MTU2MzIzMzkxNSwiaWF0IjoxNTYyNjI5MTE1LCJleHBpcmVzX2luIjo2MDQ4MDAsImp0aSI6ImY5SzFzeFNGd0F3YzhRMUxMdlhoMlN6LWpfayJ9.hcEbzxAqDVv4Kou96LZBiMN07t3UmMqaRe3vKpdT1Eo"
    var id_token: String = "eyJhbGciOiJIUzI1NiIsImtpZCI6IndVM2lmSUlhTE9VQVJlUkIvRkc2ZU0xUDFRTT0iLCJ0eXAiOiJKV1QifQ.eyJhdF9oYXNoIjoiWWhCV3dWWlhaUkhJRTBWRTVOMVpHUSIsInN1YiI6ImphbWVzLmdvIiwiYXVkaXRUcmFja2luZ0lkIjoiMmFmZmFkYTgtOGIzYi00MjYzLTk4OWEtNjFmOWI5OGViNGEwLTE0NjIzIiwiaXNzIjoiaHR0cHM6Ly90ZXN0L2FtL29hdXRoMiIsInRva2VuTmFtZSI6ImlkX3Rva2VuIiwiYXVkIjoiNDYzNGY0ZTQ1ZjU4MDhhNTM4YWRhMDhkZTYxNzg5MmUiLCJjX2hhc2giOiJCLVRxQXMxN1dRS1lMTVRVUUhFaFlBIiwiYWNyIjoiMCIsIm9yZy5mb3JnZXJvY2sub3BlbmlkY29ubmVjdC5vcHMiOiJTQkVkc1J6RW81ckJVNjZGbnNzVnppdlVld1EiLCJzX2hhc2giOiJiS0U5VXNwd3lJUGc4THNRSGtKYWlRIiwiYXpwIjoiNDYzNGY0ZTQ1ZjU4MDhhNTM4YWRhMDhkZTYxNzg5MmUiLCJhdXRoX3RpbWUiOjE1NjI2MjkxMTMsInJlYWxtIjoiLyIsImV4cCI6MTU2MjYzMjcxNiwidG9rZW5UeXBlIjoiSldUVG9rZW4iLCJpYXQiOjE1NjI2MjkxMTZ9.vgp4xbVT3v41k9RjDhbgHgZyyyyFKiZL5thwWzMYYBk"
    var token_type: String = "Bearer"
    var scope: String = "opneid"
    var expires_in: Int = 3600
    
    func testAccessTokenInit() {
        
        // Given
        let tokenDict: [String: Any] = ["access_token":self.access_token, "scope":self.scope, "expires_in":self.expires_in, "token_type":self.token_type, "refresh_token": self.refresh_token, "id_token": self.id_token]
        guard let at = AccessToken(tokenResponse: tokenDict) else {
            XCTFail("Fail to create AccessToken object with given token dictionary: \(tokenDict)")
            return
        }
        
        // Then
        XCTAssertEqual(at.value, self.access_token)
        XCTAssertEqual(at.scope, self.scope)
        XCTAssertEqual(at.expiresIn, self.expires_in)
        XCTAssertEqual(at.tokenType, self.token_type)
        XCTAssertEqual(at.refreshToken, self.refresh_token)
        XCTAssertEqual(at.idToken, self.id_token)
        
        // Also should be
        XCTAssertFalse(at.isExpired)
        // Even after
        sleep(10)
        // Should be
        XCTAssertFalse(at.isExpired)
    }
    
    func testAccessTokenDebugDescription() {
        
        // Given
        var tokenDict: [String: Any] = ["access_token":self.access_token, "scope":self.scope, "expires_in":self.expires_in, "token_type":self.token_type, "refresh_token": self.refresh_token, "id_token": self.id_token]
        guard let at = AccessToken(tokenResponse: tokenDict) else {
            XCTFail("Fail to create AccessToken object with given token dictionary: \(tokenDict)")
            return
        }
        
        // Then
        XCTAssertTrue(at.debugDescription.contains(self.access_token))
        XCTAssertTrue(at.debugDescription.contains(self.scope))
        XCTAssertTrue(at.debugDescription.contains(String(describing: self.expires_in)))
        XCTAssertTrue(at.debugDescription.contains(self.token_type))
        XCTAssertTrue(at.debugDescription.contains(self.refresh_token))
        XCTAssertTrue(at.debugDescription.contains(self.id_token))
        
        tokenDict = ["access_token":self.access_token, "scope":self.scope, "expires_in":self.expires_in, "token_type":self.token_type]
        guard let at2 = AccessToken(tokenResponse: tokenDict) else {
            XCTFail("Fail to create AccessToken object with given token dictionary: \(tokenDict)")
            return
        }
        
        // Then
        XCTAssertTrue(at2.debugDescription.contains(self.access_token))
        XCTAssertTrue(at2.debugDescription.contains(self.scope))
        XCTAssertTrue(at2.debugDescription.contains(String(describing: self.expires_in)))
        XCTAssertTrue(at2.debugDescription.contains(self.token_type))
        XCTAssertFalse(at2.debugDescription.contains(self.refresh_token))
        XCTAssertFalse(at2.debugDescription.contains(self.id_token))
    }
    
    func testAccessTokenExpiration() {
        
        // Given
        let tokenDict: [String: Any] = ["access_token":self.access_token, "scope":self.scope, "expires_in":10, "token_type":self.token_type, "refresh_token": self.refresh_token, "id_token": self.id_token]
        guard let at = AccessToken(tokenResponse: tokenDict) else {
            XCTFail("Fail to create AccessToken object with given token dictionary: \(tokenDict)")
            return
        }
        
        sleep(20)
        
        // Then
        XCTAssertTrue(at.isExpired)
    }
    
    func testMissingResponseValue() {
        
        // Testing AccessToken initialization with JSON response
        
        // Given missing token_type
        var tokenDict: [String: Any] = ["access_token":self.access_token, "scope":self.scope, "expires_in":self.expires_in]
        var at = AccessToken(tokenResponse: tokenDict)
        // Then
        XCTAssertNil(at)
        
        // Given missing expires_in
        tokenDict = ["access_token":self.access_token, "scope":self.scope, "token_type":self.token_type]
        at = AccessToken(tokenResponse: tokenDict)
        // Then
        XCTAssertNil(at)
        
        // Given missing scope
        tokenDict = ["access_token":self.access_token, "token_type":self.token_type, "expires_in":self.expires_in]
        at = AccessToken(tokenResponse: tokenDict)
        // Then
        XCTAssertNil(at)
        
        // Given missing access_token
        tokenDict = ["scope":self.scope, "token_type":self.token_type, "expires_in":self.expires_in]
        at = AccessToken(tokenResponse: tokenDict)
        // Then
        XCTAssertNil(at)
        
        // Given minimal set of response values
        tokenDict = ["access_token":self.access_token, "scope":self.scope, "token_type":self.token_type, "expires_in":self.expires_in]
        at = AccessToken(tokenResponse: tokenDict)
        // Then
        XCTAssertNotNil(at)
        
        
        // Testing AccessToken initialization with parameters
        
        // Given missing token_type
        at = AccessToken(token: self.access_token, expiresIn: self.expires_in, scope: self.scope, tokenType: nil, refreshToken: nil, idToken: nil, authenticatedTimestamp: Date().timeIntervalSince1970)
        // Then
        XCTAssertNil(at)
        
        // Given missing expires_in
        at = AccessToken(token: self.access_token, expiresIn: nil, scope: self.scope, tokenType: self.token_type, refreshToken: nil, idToken: nil, authenticatedTimestamp: Date().timeIntervalSince1970)
        // Then
        XCTAssertNil(at)
        
        // Given missing scope
        at = AccessToken(token: self.access_token, expiresIn: self.expires_in, scope: nil, tokenType: self.token_type, refreshToken: nil, idToken: nil, authenticatedTimestamp: Date().timeIntervalSince1970)
        // Then
        XCTAssertNil(at)
        
        // Given missing access_token
        at = AccessToken(token: nil, expiresIn: self.expires_in, scope: self.scope, tokenType: self.token_type, refreshToken: nil, idToken: nil, authenticatedTimestamp: Date().timeIntervalSince1970)
        // Then
        XCTAssertNil(at)
        
        // Given missing authenticatedTimestamp
        at = AccessToken(token: self.access_token, expiresIn: self.expires_in, scope: self.scope, tokenType: self.token_type, refreshToken: nil, idToken: nil, authenticatedTimestamp: nil)
        // Then
        XCTAssertNil(at)
        
        // Given minimal set of response values
        at = AccessToken(token: self.access_token, expiresIn: self.expires_in, scope: self.scope, tokenType: self.token_type, refreshToken: nil, idToken: nil, authenticatedTimestamp: Date().timeIntervalSince1970)
        // Then
        XCTAssertNotNil(at)
    }
    
    
    func testTokenSecureCoding() {
    
        if #available(iOS 11.0, *) {
            // Given
            let tokenDict: [String: Any] = ["access_token":self.access_token, "scope":self.scope, "expires_in":self.expires_in, "token_type":self.token_type, "refresh_token": self.refresh_token, "id_token": self.id_token]
            guard let at = AccessToken(tokenResponse: tokenDict) else {
                XCTFail("Fail to create AccessToken object with given token dictionary: \(tokenDict)")
                return
            }
            
            // Then
            XCTAssertEqual(at.value, self.access_token)
            XCTAssertEqual(at.scope, self.scope)
            XCTAssertEqual(at.expiresIn, self.expires_in)
            XCTAssertEqual(at.tokenType, self.token_type)
            XCTAssertEqual(at.refreshToken, self.refresh_token)
            XCTAssertEqual(at.idToken, self.id_token)
            
            // Should Also
            do {
                // With given
                let tokenData = try NSKeyedArchiver.archivedData(withRootObject: at, requiringSecureCoding: true)
                
                // Then
                if let token = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [AccessToken.self, Token.self], from: tokenData) as? AccessToken {
                    // Should equal
                    XCTAssertEqual(at, token)
                    XCTAssertTrue(at == token)
                    XCTAssertEqual(token.value, self.access_token)
                    XCTAssertEqual(token.scope, self.scope)
                    XCTAssertEqual(token.expiresIn, self.expires_in)
                    XCTAssertEqual(token.tokenType, self.token_type)
                    XCTAssertEqual(token.refreshToken, self.refresh_token)
                    XCTAssertEqual(token.idToken, self.id_token)
                }
                else {
                    XCTFail("Failed to unarchive AccessToken \nToken:\(at.debugDescription)\n\nToken Data: \(tokenData)")
                }
            }
            catch {
                XCTFail("Failed to archive AccessToken \nError:\(error.localizedDescription)\n\nToken:\(at.debugDescription)")
            }
        }
    }
    
    func testAuthorizationHeader() {
        
        // Given
        let tokenDict: [String: Any] = ["access_token":self.access_token, "scope":self.scope, "expires_in":self.expires_in, "token_type":self.token_type, "refresh_token": self.refresh_token, "id_token": self.id_token]
        guard let at = AccessToken(tokenResponse: tokenDict) else {
            XCTFail("Fail to create AccessToken object with given token dictionary: \(tokenDict)")
            return
        }
        
        // Then
        XCTAssertEqual(at.buildAuthorizationHeader(), at.tokenType + " " + at.value)
    }
    
    func testAccessTokenJSONEncoding() {
        
        let tokenDict: [String: Any] = ["access_token":self.access_token, "scope":self.scope, "expires_in":self.expires_in, "token_type":self.token_type, "refresh_token": self.refresh_token, "id_token": self.id_token]
        guard let at = AccessToken(tokenResponse: tokenDict) else {
            XCTFail("Fail to create AccessToken object with given token dictionary: \(tokenDict)")
            return
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let data = try? encoder.encode(at)
        XCTAssertNotNil(data)
        
        if let atData = data, let jsonAccessToken = String(data: atData, encoding: .utf8) {
            let atDictionary = self.parseStringToDictionary(jsonAccessToken)
            XCTAssertNotNil(atDictionary)
            
            if let expires_in = atDictionary["expiresIn"] as? Int, let scope = atDictionary["scope"] as? String, let refresh_token = atDictionary["refreshToken"] as? String, let id_token = atDictionary["idToken"] as? String, let accessToken = atDictionary["value"] as? String {
                XCTAssertEqual(expires_in, self.expires_in)
                XCTAssertEqual(scope, self.scope)
                XCTAssertEqual(refresh_token, self.refresh_token)
                XCTAssertEqual(id_token, self.id_token)
                XCTAssertEqual(accessToken, self.access_token)
            } else {
                XCTFail("Fail to parse AccessToken JSON String correctly with given data \(jsonAccessToken)")
            }
        } else {
            XCTFail("Fail to create AccessToken JSON String with given data")
        }
    }
}
