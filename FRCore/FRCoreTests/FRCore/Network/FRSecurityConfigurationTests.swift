// 
//  FRSecurityConfigurationTests.swift
//  FRCoreTests
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRCore

class FRSecurityConfigurationTests: FRBaseTestCase  {
    
    override func setUp() {
        super.setUp()
    }
    
    
    /// Test validate method to make sure public key hash matches the certificate
    func testValidateWithCorrectHash() throws {
        
        let certificateData = NSData(contentsOf: Bundle(for: FRSecurityConfigurationTests.self).url(forResource: "httpbin_cert", withExtension: "der")!)
        
        let certificate = SecCertificateCreateWithData(nil, certificateData!)
        
        var optionalTrust: SecTrust?
        
        let policy = SecPolicyCreateBasicX509()
        let status = SecTrustCreateWithCertificates(certificate!, policy, &optionalTrust)
        
        guard status == errSecSuccess else {
            XCTAssert(false, "Unable to create certificate")
            return }
        let trust = optionalTrust!
        
        
        //Validate with the correct public key hash
        let frSecurityConfiguration1 = FRSecurityConfiguration(hashes: ["+KSzREQbAh9gqYLLGpfCG+cAy7Px3/Qmk/e8Egwyd7o="])
        
        let validated1 = frSecurityConfiguration1.validate(serverTrust: trust, domain: "https://httpbin.org/")
        
        XCTAssertTrue(validated1, "Certificate failed to validate with the correct public key hash")
    
    }
    
    /// Test validate method to make sure public key hash doesn't macth the certificate
    func testValidateWithWrongHash() throws {
        
        let certificateData = NSData(contentsOf: Bundle(for: FRSecurityConfigurationTests.self).url(forResource: "httpbin_cert", withExtension: "der")!)
        
        let certificate = SecCertificateCreateWithData(nil, certificateData!)
        
        var optionalTrust: SecTrust?
        
        let policy = SecPolicyCreateBasicX509()
        let status = SecTrustCreateWithCertificates(certificate!, policy, &optionalTrust)
        
        guard status == errSecSuccess else {
            XCTAssert(false, "Unable to create certificate")
            return }
        let trust = optionalTrust!
        
        //Validate with a wrong public key hash
        let frSecurityConfiguration2 = FRSecurityConfiguration(hashes: ["GSHJImFNL2AkwaL7xE1K+LVGj/V4Dgl7QYrNHKF5g0U="])
        
        let validated2 = frSecurityConfiguration2.validate(serverTrust: trust, domain: "https://httpbin.org/")
        
        XCTAssertFalse(validated2, "Certificate successfully validated with a wrong public key hash")
    }
    
}
