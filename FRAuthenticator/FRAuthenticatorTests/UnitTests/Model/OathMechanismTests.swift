// 
//  OathMechanismTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020-2021 ForgeRock. All rights reserved.
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
            if #available(iOS 11.0, *) {
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
            } else {
                let mechanismData = NSKeyedArchiver.archivedData(withRootObject: mechanism)
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
}
