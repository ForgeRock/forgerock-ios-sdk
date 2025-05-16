// 
//  FRCompactJWTTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class FRCompactJWTTests: FRABaseTests {

    func test_01_create_and_verify_jwt() {
        var payload: [String: CodableValue] = [:]
        payload["iss"] = CodableValue("ForgeRock")
        payload["iat"] = CodableValue(1588629070)
        payload["exp"] = CodableValue(1620165070)
        payload["aud"] = CodableValue("www.forgerock.com")
        payload["sub"] = CodableValue("james.go@forgerock.com")
        
        let secret = "cXdlcnR5dWlvcGFzZGZnaGprbHp4Y3Zibm0xMjM0NTY="
        let jwtObj = FRCompactJWT(algorithm: .hs256, secret: secret, payload: payload)
        
        do {
            let signedJwt = try jwtObj.sign()
            XCTAssertNotNil(signedJwt)
            
            let verifyResult = try FRCompactJWT.verify(jwt: signedJwt, secret: secret)
            XCTAssertTrue(verifyResult)
        }
        catch {
            XCTFail("Failed to create and verify JWT: \(error.localizedDescription)")
        }
    }
    
    
    func test_02_verify_jwt() {
        let jwt = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJGb3JnZVJvY2siLCJpYXQiOjE1ODg2MjkwNzAsImV4cCI6MTYyMDE2NTA3MCwiYXVkIjoid3d3LmZvcmdlcm9jay5jb20iLCJzdWIiOiJqYW1lcy5nb0Bmb3JnZXJvY2suY29tIn0.cjyALUH79vmz9DU6zJsUFGiZyO_qkcnfyMmUrRF2Egw"
        let secret = "cXdlcnR5dWlvcGFzZGZnaGprbHp4Y3Zibm0xMjM0NTY="
        
        do {
            let result = try FRCompactJWT.verify(jwt: jwt, secret: secret)
            XCTAssertTrue(result)
        }
        catch {
            XCTFail("Failed to validate JWT: \(error.localizedDescription)")
        }
    }
    
    
    func test_03_verify_unpadded_secret() {
        let jwt = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJGb3JnZVJvY2siLCJpYXQiOjE1ODg2MjkwNzAsImV4cCI6MTYyMDE2NTA3MCwiYXVkIjoid3d3LmZvcmdlcm9jay5jb20iLCJzdWIiOiJqYW1lcy5nb0Bmb3JnZXJvY2suY29tIn0.cjyALUH79vmz9DU6zJsUFGiZyO_qkcnfyMmUrRF2Egw"
        let secret = "cXdlcnR5dWlvcGFzZGZnaGprbHp4Y3Zibm0xMjM0NTY"
        
        do {
            let result = try FRCompactJWT.verify(jwt: jwt, secret: secret)
            XCTAssertTrue(result)
        }
        catch {
            XCTFail("Failed to validate JWT: \(error.localizedDescription)")
        }
    }
    
    
    func test_04_create_with_unpadded_secret_and_verify_with_padded() {
        var payload: [String: CodableValue] = [:]
        payload["iss"] = CodableValue("ForgeRock")
        payload["iat"] = CodableValue(1588629070)
        payload["exp"] = CodableValue(1620165070)
        payload["aud"] = CodableValue("www.forgerock.com")
        payload["sub"] = CodableValue("james.go@forgerock.com")
        
        let secret = "cXdlcnR5dWlvcGFzZGZnaGprbHp4Y3Zibm0xMjM0NTY"
        let jwtObj = FRCompactJWT(algorithm: .hs256, secret: secret, payload: payload)
        
        do {
            let signedJwt = try jwtObj.sign()
            XCTAssertNotNil(signedJwt)
            
            let verifyResult = try FRCompactJWT.verify(jwt: signedJwt, secret: secret + "=")
            XCTAssertTrue(verifyResult)
        }
        catch {
            XCTFail("Failed to create and verify JWT: \(error.localizedDescription)")
        }
    }
    
    
    func test_05_missing_component() {
        let jwt = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJGb3JnZVJvY2siLCJpYXQiOjE1ODg2MjkwNzAsImV4cCI6MTYyMDE2NTA3MCwiYXVkIjoid3d3LmZvcmdlcm9jay5jb20iLCJzdWIiOiJqYW1lcy5nb0Bmb3JnZXJvY2suY29tIn0"
        let secret = "cXdlcnR5dWlvcGFzZGZnaGprbHp4Y3Zibm0xMjM0NTY"
        
        do {
            let _ = try FRCompactJWT.verify(jwt: jwt, secret: secret)
            
            XCTFail("JWT verify is expected to fail with missing segment; however, somehow passed through the verify method")
        }
        catch CryptoError.invalidJWT {
        }
        catch {
            XCTFail("JWT verify with missing segment failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_06_unsupported_jwt_type() {
        let jwt = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJGb3JnZVJvY2siLCJpYXQiOjE1ODg2MjkwNzAsImV4cCI6MTYyMDE2NTA3MCwiYXVkIjoid3d3LmZvcmdlcm9jay5jb20iLCJzdWIiOiJqYW1lcy5nb0Bmb3JnZXJvY2suY29tIn0.P0gbM2CBSOKphtdTs7zH_XCE_rCLiTQVCsFO_SmqhTlybbWBSr8F87T73RWVJcuo"
        let secret = "cXdlcnR5dWlvcGFzZGZnaGprbHp4Y3Zibm0xMjM0NTY"
        
        do {
            let _ = try FRCompactJWT.verify(jwt: jwt, secret: secret)
            
            XCTFail("JWT verify is expected to fail with unsupported JWT type; however, somehow passed through the verify method")
        }
        catch CryptoError.unsupportedJWTType {
        }
        catch {
            XCTFail("JWT verify with missing segment failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_07_fail_to_convert_data_in_header_segment() {
        let jwt = "invalidheadersegment.eyJpc3MiOiJGb3JnZVJvY2siLCJpYXQiOjE1ODg2MjkwNzAsImV4cCI6MTYyMDE2NTA3MCwiYXVkIjoid3d3LmZvcmdlcm9jay5jb20iLCJzdWIiOiJqYW1lcy5nb0Bmb3JnZXJvY2suY29tIn0.P0gbM2CBSOKphtdTs7zH_XCE_rCLiTQVCsFO_SmqhTlybbWBSr8F87T73RWVJcuo"
        let secret = "cXdlcnR5dWlvcGFzZGZnaGprbHp4Y3Zibm0xMjM0NTY"
        
        do {
            let _ = try FRCompactJWT.verify(jwt: jwt, secret: secret)
            
            XCTFail("JWT verify is expected to fail to convert invalid header segment; however, somehow passed through the verify method")
        }
        catch CryptoError.failToConvertData {
        }
        catch {
            XCTFail("JWT verify with invalid header segment failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_08_extract_payload_segment() {
        let jwt = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJGb3JnZVJvY2siLCJpYXQiOjE1ODg2MjkwNzAsImV4cCI6MTYyMDE2NTA3MCwiYXVkIjoid3d3LmZvcmdlcm9jay5jb20iLCJzdWIiOiJqYW1lcy5nb0Bmb3JnZXJvY2suY29tIn0.cjyALUH79vmz9DU6zJsUFGiZyO_qkcnfyMmUrRF2Egw"
        
        do {
            let payload = try FRCompactJWT.extractPayload(jwt: jwt)
            
            XCTAssertEqual(payload.keys.count, 5)
            XCTAssertTrue(payload.keys.contains("iss"))
            XCTAssertTrue(payload.keys.contains("iat"))
            XCTAssertTrue(payload.keys.contains("exp"))
            XCTAssertTrue(payload.keys.contains("aud"))
            XCTAssertTrue(payload.keys.contains("sub"))
            
            XCTAssertEqual(payload["iss"] as? String, "ForgeRock")
            XCTAssertEqual(payload["iat"] as? Double, 1588629070)
            XCTAssertEqual(payload["exp"] as? Double, 1620165070)
            XCTAssertEqual(payload["aud"] as? String, "www.forgerock.com")
            XCTAssertEqual(payload["sub"] as? String, "james.go@forgerock.com")
        }
        catch {
            XCTFail("Failed to extract JWT payload: \(error.localizedDescription)")
        }
    }
    
    
    func test_09_extract_payload_with_missing_segment() {
        let jwt = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJGb3JnZVJvY2siLCJpYXQiOjE1ODg2MjkwNzAsImV4cCI6MTYyMDE2NTA3MCwiYXVkIjoid3d3LmZvcmdlcm9jay5jb20iLCJzdWIiOiJqYW1lcy5nb0Bmb3JnZXJvY2suY29tIn0"
        
        do {
            let _ = try FRCompactJWT.extractPayload(jwt: jwt)
            XCTFail("JWT extracting payload is expected to fail with missing segment; however, somehow passed through the method")
        }
        catch CryptoError.invalidJWT {
        }
        catch {
            XCTFail("JWT extracting payload with missing segment failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_09_extract_payload_with_invalid_payload_segment() {
        let jwt = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.invalidpayloadsegment.cjyALUH79vmz9DU6zJsUFGiZyO_qkcnfyMmUrRF2Egw"
        
        do {
            let _ = try FRCompactJWT.extractPayload(jwt: jwt)
            XCTFail("JWT extracting payload is expected to fail with invalid payload segment; however, somehow passed through the method")
        }
        catch CryptoError.failToConvertData {
        }
        catch {
            XCTFail("JWT extracting payload with invalid payload segment failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    func test_10_extract_payload_with_extra_data() {
        let jwt1 = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJwIjoieyAgfSIsImMiOiJ2TGhoaW9FNTIxVlcyYmNsNUM2aktERGp1bXk3Um01d2NwVkpYQllUY2ZFPSIsInQiOiIyMCIsInUiOiI0NkQ2QkUzQi02NTEyLTQ4QTQtODY4Ni1DQUIxQTkxNTZCNDQiLCJpIjoiMTY2Nzk0MDI3NDk0MiIsImsiOiJjaGFsbGVuZ2UiLCJsIjoiWVcxc1ltTnZiMnRwWlQwd01RPT0iLCJtIjoiRGlkIHlvdSB0cnkgdG8gbG9naW4_IiwibiI6IjUwLDYyLDg5In0.GXCMwE1VJTC1zVzLfBcSeiGEfPiY5i13lrtf6Fpwz6w"
        let jwt2 = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJwIjoieyAgfSIsImMiOiJqK0NBWlhrUnlRdEdxdHljYmFMc3EwTWtjcFJZbU9SSzRhUzgyQWNlTWNrPSIsInQiOiIyMCIsInUiOiI0NkQ2QkUzQi02NTEyLTQ4QTQtODY4Ni1DQUIxQTkxNTZCNDQiLCJpIjoiMTY2Nzk0MTA5MTMwNiIsImsiOiJkZWZhdWx0IiwibCI6IllXMXNZbU52YjJ0cFpUMHdNUT09IiwibSI6IkRpZCB5b3UgdHJ5IHRvIGxvZ2luPyJ9.L2WjxnumzIgA9gpNN8p7onip0As5Rytb0RuOW8_sDWI"
        
        do {
            let payload1 = try FRCompactJWT.extractPayload(jwt: jwt1)
            let payload2 = try FRCompactJWT.extractPayload(jwt: jwt2)
            
            XCTAssertEqual(payload1.keys.count, 9)
            XCTAssertEqual(payload2.keys.count, 8)

        }
        catch {
            XCTFail("Failed to extract JWT payload: \(error.localizedDescription)")
        }
    }
}
