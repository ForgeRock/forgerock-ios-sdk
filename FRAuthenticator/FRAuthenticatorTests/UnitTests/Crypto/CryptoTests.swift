// 
//  CryptoTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest

class CryptoTests: FRABaseTests {

    func test_01_test_sign_given_challenge() {
        let c = "1H7p3KSlvLliUxuJiEq0vRhAdbihL2pigWdFIa-pmgw".urlSafeDecoding()
        let s = "MTNi6Sv-gnFI5M7zU1H8qZWamLQoxnKXdQlHNOCsAGs"
        
        let signedChallenge = try? Crypto.generatePushChallengeResponse(challenge: c, secret: s)
        XCTAssertNotNil(signedChallenge)
        XCTAssertEqual(signedChallenge, "UWRDpPOLnRmvlOL35wrOo/FOWn/yQQbdDQRk6pSdyeg=")
    }
    
    
    func test_02_test_sign_with_url_unsafe_challenge() {
        let c = "1H7p3KSlvLliUxuJiEq0vRhAdbihL2pigWdFIa-pmgw"
        let s = "MTNi6Sv-gnFI5M7zU1H8qZWamLQoxnKXdQlHNOCsAGs"
        
        do {
            let signedChallenge = try Crypto.generatePushChallengeResponse(challenge: c, secret: s)
            XCTAssertNil(signedChallenge)
            XCTFail("Crypto.generatePushChallengeResponse should fail with unsafe URL string of challenge, but passed somehow")
        }
        catch CryptoError.invalidParam {
        }
        catch {
            XCTFail("Crypto.generatePushChallengeResponse failed with unexpected error")
        }
    }
    
    
    func test_03_test_parse_secret_successful() {
        let s = "MTNi6Sv-gnFI5M7zU1H8qZWamLQoxnKXdQlHNOCsAGs"
        let parsedSecret = Crypto.parseSecret(secret: s)
        XCTAssertNotNil(parsedSecret)
    }
    
    
    func test_04_test_parse_invalid_secret() {
        let s = "invalid_secret"
        let parsedSecret = Crypto.parseSecret(secret: s)
        XCTAssertNil(parsedSecret)
    }
}
