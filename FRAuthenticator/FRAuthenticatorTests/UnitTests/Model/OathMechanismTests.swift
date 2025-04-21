// 
//  OathMechanismTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class OathMechanismTests: FRABaseTests {
    
    func test_01_archive_obj() {
        let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30&algorithm=SHA256")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = OathMechanism(type: parser.type, issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, digits: parser.digits)
            if let mechanismData = try? NSKeyedArchiver.archivedData(withRootObject: mechanism, requiringSecureCoding: true) {
                let mechanismFromData = NSKeyedUnarchiver.unarchiveObject(with: mechanismData) as? OathMechanism
                XCTAssertNotNil(mechanismFromData)
                XCTAssertEqual(mechanism.mechanismUUID, mechanismFromData?.mechanismUUID)
                XCTAssertEqual(mechanism.issuer, mechanismFromData?.issuer)
                XCTAssertEqual(mechanism.type, mechanismFromData?.type)
                XCTAssertEqual(mechanism.secret, mechanismFromData?.secret)
                XCTAssertEqual(mechanism.version, mechanismFromData?.version)
                XCTAssertEqual(mechanism.accountName, mechanismFromData?.accountName)
                XCTAssertEqual(mechanism.algorithm, mechanismFromData?.algorithm)
                XCTAssertEqual(mechanism.digits, mechanismFromData?.digits)
                XCTAssertEqual(mechanism.timeAdded.timeIntervalSince1970, mechanismFromData?.timeAdded.timeIntervalSince1970)
            }
            else {
                XCTFail("Failed to serialize OathMechanism object with Secure Coding")
            }
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_02_codable_serialization() {
        let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30&algorithm=SHA256")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = OathMechanism(type: parser.type, issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, digits: parser.digits)
            
            //  Encode
            let jsonData = try JSONEncoder().encode(mechanism)
            
            //  Decode
            let decodedMechanism = try JSONDecoder().decode(OathMechanism.self, from: jsonData)
            
            XCTAssertEqual(mechanism.mechanismUUID, decodedMechanism.mechanismUUID)
            XCTAssertEqual(mechanism.issuer, decodedMechanism.issuer)
            XCTAssertEqual(mechanism.type, decodedMechanism.type)
            XCTAssertEqual(mechanism.secret, decodedMechanism.secret)
            XCTAssertEqual(mechanism.version, decodedMechanism.version)
            XCTAssertEqual(mechanism.accountName, decodedMechanism.accountName)
            XCTAssertEqual(mechanism.algorithm, decodedMechanism.algorithm)
            XCTAssertEqual(mechanism.digits, decodedMechanism.digits)
            XCTAssertEqual(mechanism.timeAdded.millisecondsSince1970, decodedMechanism.timeAdded.millisecondsSince1970)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    func test_03_archive_obj_from_mfa_uri() {
        let qrCode = URL(string: "mfauth://totp/Forgerock:demo?" +
                         "a=aHR0cHM6Ly9mb3JnZXJvY2suZXhhbXBsZS5jb20vb3BlbmFtL2pzb24vcHVzaC9zbnMvbWVzc2FnZT9fYWN0aW9uPWF1dGhlbnRpY2F0ZQ&" +
                         "image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&" +
                         "b=ff00ff&" +
                         "r=aHR0cHM6Ly9mb3JnZXJvY2suZXhhbXBsZS5jb20vb3BlbmFtL2pzb24vcHVzaC9zbnMvbWVzc2FnZT9fYWN0aW9uPXJlZ2lzdGVy&" +
                         "s=ryJkqNRjXYd_nX523672AX_oKdVXrKExq-VjVeRKKTc&" +
                         "c=Daf8vrc8onKu-dcptwCRS9UHmdui5u16vAdG2HMU4w0&" +
                         "l=YW1sYmNvb2tpZT0wMQ==&" +
                         "m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&" +
                         "policies=eyJiaW9tZXRyaWNBdmFpbGFibGUiOiB7IH0sImRldmljZVRhbXBlcmluZyI6IHsic2NvcmUiOiAwLjh9fQ&" +
                         "digits=6&" +
                         "secret=R2PYFZRISXA5L25NVSSYK2RQ6E======&" +
                         "period=30&" +
                         "issuer=Rm9yZ2Vyb2Nr")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = OathMechanism(type: parser.type, issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, digits: parser.digits)
            
            
            XCTAssertNotNil(mechanism.mechanismUUID)
            XCTAssertNotNil(mechanism.issuer)
            XCTAssertNotNil(mechanism.type)
            XCTAssertNotNil(mechanism.version)
            XCTAssertNotNil(mechanism.accountName)
            XCTAssertNotNil(mechanism.algorithm)
            XCTAssertNotNil(mechanism.digits)
            XCTAssertNotNil(mechanism.secret)
            
            XCTAssertEqual(mechanism.issuer, "Forgerock")
            XCTAssertEqual(mechanism.type, "totp")
            XCTAssertEqual(mechanism.accountName, "demo")
            XCTAssertEqual(mechanism.algorithm.rawValue, "sha1")
            XCTAssertEqual(mechanism.secret, "R2PYFZRISXA5L25NVSSYK2RQ6E======")
            XCTAssertEqual(mechanism.digits, 6)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
}
