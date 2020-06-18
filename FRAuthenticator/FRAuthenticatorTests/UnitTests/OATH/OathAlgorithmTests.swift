// 
//  OathAlgorithmTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
import CommonCrypto

class OathAlgorithmTests: FRABaseTests {

    func test_00_invalid_algorithm() {
        let algorithm = OathAlgorithm(algorithm: "invalid_str")
        XCTAssertNil(algorithm)
    }
    
    
    func test_01_sha1() {
        guard let algorithm = OathAlgorithm(algorithm: "sha1") else {
            XCTFail("Failed to generate OathAlgorithm with 'sha1'")
            return
        }
        XCTAssertEqual(algorithm, OathAlgorithm.sha1)
        XCTAssertEqual(algorithm.getAlgorithm(), kCCHmacAlgSHA1)
        XCTAssertEqual(algorithm.getDigestLength(), CC_SHA1_DIGEST_LENGTH)
        
        guard let algorithm2 = OathAlgorithm(algorithm: "sHa1") else {
            XCTFail("Failed to generate OathAlgorithm with 'sHa1'")
            return
        }
        XCTAssertEqual(algorithm2, OathAlgorithm.sha1)
        XCTAssertEqual(algorithm2.getAlgorithm(), kCCHmacAlgSHA1)
        XCTAssertEqual(algorithm2.getDigestLength(), CC_SHA1_DIGEST_LENGTH)
        
        
        guard let algorithm3 = OathAlgorithm(algorithm: "SHA1") else {
            XCTFail("Failed to generate OathAlgorithm with 'SHA1'")
            return
        }
        XCTAssertEqual(algorithm3, OathAlgorithm.sha1)
        XCTAssertEqual(algorithm3.getAlgorithm(), kCCHmacAlgSHA1)
        XCTAssertEqual(algorithm3.getDigestLength(), CC_SHA1_DIGEST_LENGTH)
    }
    
    
    func test_2_md5() {
        guard let algorithm = OathAlgorithm(algorithm: "md5") else {
            XCTFail("Failed to generate OathAlgorithm with 'md5'")
            return
        }
        XCTAssertEqual(algorithm, OathAlgorithm.md5)
        XCTAssertEqual(algorithm.getAlgorithm(), kCCHmacAlgMD5)
        XCTAssertEqual(algorithm.getDigestLength(), CC_MD5_DIGEST_LENGTH)
        
        guard let algorithm2 = OathAlgorithm(algorithm: "Md5") else {
            XCTFail("Failed to generate OathAlgorithm with 'Md5'")
            return
        }
        XCTAssertEqual(algorithm2, OathAlgorithm.md5)
        XCTAssertEqual(algorithm2.getAlgorithm(), kCCHmacAlgMD5)
        XCTAssertEqual(algorithm2.getDigestLength(), CC_MD5_DIGEST_LENGTH)
        
        
        guard let algorithm3 = OathAlgorithm(algorithm: "MD5") else {
            XCTFail("Failed to generate OathAlgorithm with 'MD5'")
            return
        }
        XCTAssertEqual(algorithm3, OathAlgorithm.md5)
        XCTAssertEqual(algorithm3.getAlgorithm(), kCCHmacAlgMD5)
        XCTAssertEqual(algorithm3.getDigestLength(), CC_MD5_DIGEST_LENGTH)
    }
    
    
    func test_3_sha256() {
        guard let algorithm = OathAlgorithm(algorithm: "sha256") else {
            XCTFail("Failed to generate OathAlgorithm with 'sha256'")
            return
        }
        XCTAssertEqual(algorithm, OathAlgorithm.sha256)
        XCTAssertEqual(algorithm.getAlgorithm(), kCCHmacAlgSHA256)
        XCTAssertEqual(algorithm.getDigestLength(), CC_SHA256_DIGEST_LENGTH)
        
        guard let algorithm2 = OathAlgorithm(algorithm: "sHa256") else {
            XCTFail("Failed to generate OathAlgorithm with 'sHa256'")
            return
        }
        XCTAssertEqual(algorithm2, OathAlgorithm.sha256)
        XCTAssertEqual(algorithm2.getAlgorithm(), kCCHmacAlgSHA256)
        XCTAssertEqual(algorithm2.getDigestLength(), CC_SHA256_DIGEST_LENGTH)
        
        
        guard let algorithm3 = OathAlgorithm(algorithm: "SHA256") else {
            XCTFail("Failed to generate OathAlgorithm with 'SHA256'")
            return
        }
        XCTAssertEqual(algorithm3, OathAlgorithm.sha256)
        XCTAssertEqual(algorithm3.getAlgorithm(), kCCHmacAlgSHA256)
        XCTAssertEqual(algorithm3.getDigestLength(), CC_SHA256_DIGEST_LENGTH)
    }
    
    
    func test_3_sha512() {
        
        guard let algorithm = OathAlgorithm(algorithm: "sha512") else {
            XCTFail("Failed to generate OathAlgorithm with 'sha512'")
            return
        }
        XCTAssertEqual(algorithm, OathAlgorithm.sha512)
        XCTAssertEqual(algorithm.getAlgorithm(), kCCHmacAlgSHA512)
        XCTAssertEqual(algorithm.getDigestLength(), CC_SHA512_DIGEST_LENGTH)
        
        guard let algorithm2 = OathAlgorithm(algorithm: "sHA512") else {
            XCTFail("Failed to generate OathAlgorithm with 'sHA512'")
            return
        }
        XCTAssertEqual(algorithm2, OathAlgorithm.sha512)
        XCTAssertEqual(algorithm2.getAlgorithm(), kCCHmacAlgSHA512)
        XCTAssertEqual(algorithm2.getDigestLength(), CC_SHA512_DIGEST_LENGTH)
        
        
        guard let algorithm3 = OathAlgorithm(algorithm: "SHA512") else {
            XCTFail("Failed to generate OathAlgorithm with 'SHA512'")
            return
        }
        XCTAssertEqual(algorithm3, OathAlgorithm.sha512)
        XCTAssertEqual(algorithm3.getAlgorithm(), kCCHmacAlgSHA512)
        XCTAssertEqual(algorithm3.getDigestLength(), CC_SHA512_DIGEST_LENGTH)
    }
}
