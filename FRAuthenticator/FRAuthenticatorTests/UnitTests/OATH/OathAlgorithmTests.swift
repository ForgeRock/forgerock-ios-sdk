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

    func test_00_default_to_sha1() {
        var algorithm = OathAlgorithm(algorithm: nil)
        XCTAssertEqual(algorithm, OathAlgorithm.sha1)
        XCTAssertEqual(algorithm.getAlgorithm(), kCCHmacAlgSHA1)
        XCTAssertEqual(algorithm.getDigestLength(), CC_SHA1_DIGEST_LENGTH)
        
        algorithm = OathAlgorithm(algorithm: "invalid_str")
        XCTAssertEqual(algorithm, OathAlgorithm.sha1)
        XCTAssertEqual(algorithm.getAlgorithm(), kCCHmacAlgSHA1)
        XCTAssertEqual(algorithm.getDigestLength(), CC_SHA1_DIGEST_LENGTH)
    }
    
    
    func test_01_sha1() {
        let algorithm = OathAlgorithm(algorithm: "sha1")
        XCTAssertEqual(algorithm, OathAlgorithm.sha1)
        XCTAssertEqual(algorithm.getAlgorithm(), kCCHmacAlgSHA1)
        XCTAssertEqual(algorithm.getDigestLength(), CC_SHA1_DIGEST_LENGTH)
    }
    
    
    func test_2_md5() {
        var algorithm = OathAlgorithm(algorithm: "md5")
        XCTAssertEqual(algorithm, OathAlgorithm.md5)
        XCTAssertEqual(algorithm.getAlgorithm(), kCCHmacAlgMD5)
        XCTAssertEqual(algorithm.getDigestLength(), CC_MD5_DIGEST_LENGTH)
        
        algorithm = OathAlgorithm(algorithm: "Md5")
        XCTAssertEqual(algorithm, OathAlgorithm.md5)
        XCTAssertEqual(algorithm.getAlgorithm(), kCCHmacAlgMD5)
        XCTAssertEqual(algorithm.getDigestLength(), CC_MD5_DIGEST_LENGTH)
        
        algorithm = OathAlgorithm(algorithm: "MD5")
        XCTAssertEqual(algorithm, OathAlgorithm.md5)
        XCTAssertEqual(algorithm.getAlgorithm(), kCCHmacAlgMD5)
        XCTAssertEqual(algorithm.getDigestLength(), CC_MD5_DIGEST_LENGTH)
    }
    
    
    func test_3_sha256() {
        var algorithm = OathAlgorithm(algorithm: "sha256")
        XCTAssertEqual(algorithm, OathAlgorithm.sha256)
        XCTAssertEqual(algorithm.getAlgorithm(), kCCHmacAlgSHA256)
        XCTAssertEqual(algorithm.getDigestLength(), CC_SHA256_DIGEST_LENGTH)
        
        algorithm = OathAlgorithm(algorithm: "sHa256")
        XCTAssertEqual(algorithm, OathAlgorithm.sha256)
        XCTAssertEqual(algorithm.getAlgorithm(), kCCHmacAlgSHA256)
        XCTAssertEqual(algorithm.getDigestLength(), CC_SHA256_DIGEST_LENGTH)
        
        algorithm = OathAlgorithm(algorithm: "SHA256")
        XCTAssertEqual(algorithm, OathAlgorithm.sha256)
        XCTAssertEqual(algorithm.getAlgorithm(), kCCHmacAlgSHA256)
        XCTAssertEqual(algorithm.getDigestLength(), CC_SHA256_DIGEST_LENGTH)
    }
    
    
    func test_3_sha512() {
        var algorithm = OathAlgorithm(algorithm: "sha512")
        XCTAssertEqual(algorithm, OathAlgorithm.sha512)
        XCTAssertEqual(algorithm.getAlgorithm(), kCCHmacAlgSHA512)
        XCTAssertEqual(algorithm.getDigestLength(), CC_SHA512_DIGEST_LENGTH)
        
        algorithm = OathAlgorithm(algorithm: "sHA512")
        XCTAssertEqual(algorithm, OathAlgorithm.sha512)
        XCTAssertEqual(algorithm.getAlgorithm(), kCCHmacAlgSHA512)
        XCTAssertEqual(algorithm.getDigestLength(), CC_SHA512_DIGEST_LENGTH)
        
        algorithm = OathAlgorithm(algorithm: "SHA512")
        XCTAssertEqual(algorithm, OathAlgorithm.sha512)
        XCTAssertEqual(algorithm.getAlgorithm(), kCCHmacAlgSHA512)
        XCTAssertEqual(algorithm.getDigestLength(), CC_SHA512_DIGEST_LENGTH)
    }
}
