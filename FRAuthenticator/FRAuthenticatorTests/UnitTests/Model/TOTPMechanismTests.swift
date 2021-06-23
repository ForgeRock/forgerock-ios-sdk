// 
//  TOTPMechanismTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class TOTPMechanismTests: FRABaseTests {

    
    func test_01_totpmechanism_init_success() {
        
        let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, period: parser.period, digits: parser.digits)
            
            XCTAssertNotNil(mechanism.mechanismUUID)
            XCTAssertNotNil(mechanism.issuer)
            XCTAssertNotNil(mechanism.type)
            XCTAssertNotNil(mechanism.version)
            XCTAssertNotNil(mechanism.accountName)
            XCTAssertNotNil(mechanism.secret)
            XCTAssertNotNil(mechanism.digits)
            XCTAssertNotNil(mechanism.period)
            XCTAssertNotNil(mechanism.timeAdded)
            
            XCTAssertEqual(mechanism.issuer, "ForgeRock")
            XCTAssertEqual(mechanism.type, "totp")
            XCTAssertEqual(mechanism.accountName, "demo")
            XCTAssertEqual(mechanism.secret, "T7SIIEPTZJQQDSCB")
            XCTAssertEqual(mechanism.digits, 6)
            XCTAssertEqual(mechanism.period, 30)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_02_archive_obj() {
        let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, period: parser.period, digits: parser.digits)
            if #available(iOS 11.0, *) {
                if let mechanismData = try? NSKeyedArchiver.archivedData(withRootObject: mechanism, requiringSecureCoding: true) {
                    let mechanismFromData = NSKeyedUnarchiver.unarchiveObject(with: mechanismData) as? TOTPMechanism
                    XCTAssertNotNil(mechanismFromData)
                    XCTAssertEqual(mechanism.mechanismUUID, mechanismFromData?.mechanismUUID)
                    XCTAssertEqual(mechanism.issuer, mechanismFromData?.issuer)
                    XCTAssertEqual(mechanism.type, mechanismFromData?.type)
                    XCTAssertEqual(mechanism.secret, mechanismFromData?.secret)
                    XCTAssertEqual(mechanism.version, mechanismFromData?.version)
                    XCTAssertEqual(mechanism.accountName, mechanismFromData?.accountName)
                    XCTAssertEqual(mechanism.algorithm, mechanismFromData?.algorithm)
                    XCTAssertEqual(mechanism.digits, mechanismFromData?.digits)
                    XCTAssertEqual(mechanism.period, mechanismFromData?.period)
                    XCTAssertEqual(mechanism.timeAdded.timeIntervalSince1970, mechanismFromData?.timeAdded.timeIntervalSince1970)
                }
                else {
                    XCTFail("Failed to serialize TOTPMechanism object with Secure Coding")
                }
            } else {
                let mechanismData = NSKeyedArchiver.archivedData(withRootObject: mechanism)
                let mechanismFromData = NSKeyedUnarchiver.unarchiveObject(with: mechanismData) as? TOTPMechanism
                XCTAssertNotNil(mechanismFromData)
                XCTAssertEqual(mechanism.mechanismUUID, mechanismFromData?.mechanismUUID)
                XCTAssertEqual(mechanism.issuer, mechanismFromData?.issuer)
                XCTAssertEqual(mechanism.type, mechanismFromData?.type)
                XCTAssertEqual(mechanism.secret, mechanismFromData?.secret)
                XCTAssertEqual(mechanism.version, mechanismFromData?.version)
                XCTAssertEqual(mechanism.accountName, mechanismFromData?.accountName)
                XCTAssertEqual(mechanism.algorithm, mechanismFromData?.algorithm)
                XCTAssertEqual(mechanism.digits, mechanismFromData?.digits)
                XCTAssertEqual(mechanism.period, mechanismFromData?.period)
                XCTAssertEqual(mechanism.timeAdded.timeIntervalSince1970, mechanismFromData?.timeAdded.timeIntervalSince1970)
            }
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_03_totp_mechanism_identifier() {
        let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, period: parser.period, digits: parser.digits)
            XCTAssertNotNil(mechanism)
            XCTAssertEqual(mechanism.identifier, "ForgeRock-demo-totp")
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_04_totp_generate_code() {
        let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, period: parser.period, digits: parser.digits)
            XCTAssertNotNil(mechanism)
            XCTAssertNotNil(try mechanism.generateCode())
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_05_totp_generate_code_without_digits_and_period() {
        let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, period: parser.period, digits: parser.digits)
            XCTAssertNotNil(mechanism)
            XCTAssertNotNil(try mechanism.generateCode())
            XCTAssertEqual(mechanism.digits, 6)
            XCTAssertEqual(mechanism.period, 30)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_06_totp_custom_digits_and_period() {
        let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=8&period=60")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, period: parser.period, digits: parser.digits)
            XCTAssertNotNil(mechanism)
            XCTAssertNotNil(try mechanism.generateCode())
            XCTAssertEqual(mechanism.digits, 8)
            XCTAssertEqual(mechanism.period, 60)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_07_archive_obj_different_algorithm() {
        let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=8&period=45&algorithm=SHA256")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, period: parser.period, digits: parser.digits)
            
            if #available(iOS 11.0, *) {
                if let mechanismData = try? NSKeyedArchiver.archivedData(withRootObject: mechanism, requiringSecureCoding: true) {
                    let mechanismFromData = NSKeyedUnarchiver.unarchiveObject(with: mechanismData) as? TOTPMechanism
                    XCTAssertNotNil(mechanismFromData)
                    
                    XCTAssertEqual(mechanism.mechanismUUID, mechanismFromData?.mechanismUUID)
                    XCTAssertEqual(mechanism.issuer, mechanismFromData?.issuer)
                    XCTAssertEqual(mechanism.type, mechanismFromData?.type)
                    XCTAssertEqual(mechanism.secret, mechanismFromData?.secret)
                    XCTAssertEqual(mechanism.version, mechanismFromData?.version)
                    XCTAssertEqual(mechanism.accountName, mechanismFromData?.accountName)
                    XCTAssertEqual(mechanism.algorithm, mechanismFromData?.algorithm)
                    XCTAssertEqual(mechanism.digits, mechanismFromData?.digits)
                    XCTAssertEqual(mechanism.period, mechanismFromData?.period)
                    
                    
                    XCTAssertEqual(mechanismFromData?.issuer, "ForgeRock")
                    XCTAssertEqual(mechanismFromData?.type, "totp")
                    XCTAssertEqual(mechanismFromData?.secret, "T7SIIEPTZJQQDSCB")
                    XCTAssertEqual(mechanismFromData?.version, 1)
                    XCTAssertEqual(mechanismFromData?.accountName, "demo")
                    XCTAssertEqual(mechanismFromData?.algorithm.rawValue, "sha256")
                    XCTAssertEqual(mechanismFromData?.digits, 8)
                    XCTAssertEqual(mechanismFromData?.period, 45)
                }
                else {
                    XCTFail("Failed to serialize TOTPMechnaism with Secure Coding")
                }
            } else {
                let mechanismData = NSKeyedArchiver.archivedData(withRootObject: mechanism)
                let mechanismFromData = NSKeyedUnarchiver.unarchiveObject(with: mechanismData) as? TOTPMechanism
                XCTAssertNotNil(mechanismFromData)
                
                XCTAssertEqual(mechanism.mechanismUUID, mechanismFromData?.mechanismUUID)
                XCTAssertEqual(mechanism.issuer, mechanismFromData?.issuer)
                XCTAssertEqual(mechanism.type, mechanismFromData?.type)
                XCTAssertEqual(mechanism.secret, mechanismFromData?.secret)
                XCTAssertEqual(mechanism.version, mechanismFromData?.version)
                XCTAssertEqual(mechanism.accountName, mechanismFromData?.accountName)
                XCTAssertEqual(mechanism.algorithm, mechanismFromData?.algorithm)
                XCTAssertEqual(mechanism.digits, mechanismFromData?.digits)
                XCTAssertEqual(mechanism.period, mechanismFromData?.period)
                
                
                XCTAssertEqual(mechanismFromData?.issuer, "ForgeRock")
                XCTAssertEqual(mechanismFromData?.type, "totp")
                XCTAssertEqual(mechanismFromData?.secret, "T7SIIEPTZJQQDSCB")
                XCTAssertEqual(mechanismFromData?.version, 1)
                XCTAssertEqual(mechanismFromData?.accountName, "demo")
                XCTAssertEqual(mechanismFromData?.algorithm.rawValue, "sha256")
                XCTAssertEqual(mechanismFromData?.digits, 8)
                XCTAssertEqual(mechanismFromData?.period, 45)
            }
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_08_codable_serialization() {
        let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, period: parser.period, digits: parser.digits)
            
            //  Encode
            let jsonData = try JSONEncoder().encode(mechanism)
            
            //  Decode
            let deocdedMechanism = try JSONDecoder().decode(TOTPMechanism.self, from: jsonData)
            
            XCTAssertEqual(mechanism.mechanismUUID, deocdedMechanism.mechanismUUID)
            XCTAssertEqual(mechanism.issuer, deocdedMechanism.issuer)
            XCTAssertEqual(mechanism.type, deocdedMechanism.type)
            XCTAssertEqual(mechanism.secret, deocdedMechanism.secret)
            XCTAssertEqual(mechanism.version, deocdedMechanism.version)
            XCTAssertEqual(mechanism.accountName, deocdedMechanism.accountName)
            XCTAssertEqual(mechanism.algorithm, deocdedMechanism.algorithm)
            XCTAssertEqual(mechanism.digits, deocdedMechanism.digits)
            XCTAssertEqual(mechanism.period, deocdedMechanism.period)
            XCTAssertEqual(mechanism.timeAdded.timeIntervalSince1970, deocdedMechanism.timeAdded.timeIntervalSince1970)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_09_json_string_serialization() {
        let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, period: parser.period, digits: parser.digits)
            
            guard let jsonStr = mechanism.toJson() else {
                XCTFail("Failed to serialize the object into JSON String value")
                return
            }
            
            //  Decode
            let deocdedMechanism = try JSONDecoder().decode(TOTPMechanism.self, from: jsonStr.data(using: .utf8) ?? Data())
            
            XCTAssertEqual(mechanism.mechanismUUID, deocdedMechanism.mechanismUUID)
            XCTAssertEqual(mechanism.issuer, deocdedMechanism.issuer)
            XCTAssertEqual(mechanism.type, deocdedMechanism.type)
            XCTAssertEqual(mechanism.secret, deocdedMechanism.secret)
            XCTAssertEqual(mechanism.version, deocdedMechanism.version)
            XCTAssertEqual(mechanism.accountName, deocdedMechanism.accountName)
            XCTAssertEqual(mechanism.algorithm, deocdedMechanism.algorithm)
            XCTAssertEqual(mechanism.digits, deocdedMechanism.digits)
            XCTAssertEqual(mechanism.period, deocdedMechanism.period)
            XCTAssertEqual(mechanism.timeAdded.timeIntervalSince1970, deocdedMechanism.timeAdded.timeIntervalSince1970)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
}
