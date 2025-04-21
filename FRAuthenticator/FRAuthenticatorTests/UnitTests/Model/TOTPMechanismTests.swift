// 
//  TOTPMechanismTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
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
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, period: parser.period, digits: parser.digits)
            
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
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, period: parser.period, digits: parser.digits)
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
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_03_totp_mechanism_identifier() {
        let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, period: parser.period, digits: parser.digits)
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
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, period: parser.period, digits: parser.digits)
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
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, period: parser.period, digits: parser.digits)
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
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, period: parser.period, digits: parser.digits)
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
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, period: parser.period, digits: parser.digits)
            
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
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_08_codable_serialization() {
        let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, period: parser.period, digits: parser.digits)
            
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
            XCTAssertEqual(mechanism.timeAdded.millisecondsSince1970, deocdedMechanism.timeAdded.millisecondsSince1970)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_09_json_string_serialization() {
        let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, period: parser.period, digits: parser.digits)
            
            guard let jsonStr = mechanism.toJson() else {
                XCTFail("Failed to serialize the object into JSON String value")
                return
            }
            
            //  Covert jsonString to Dictionary
            let jsonDictionary = FRJSONEncoder.jsonStringToDictionary(jsonString: jsonStr)
                
            //  Then
            
            
            XCTAssertEqual(mechanism.mechanismUUID, jsonDictionary?["mechanismUID"] as! String)
            XCTAssertEqual(mechanism.identifier, jsonDictionary?["id"] as! String)
            XCTAssertEqual(mechanism.algorithm.rawValue, jsonDictionary?["algorithm"] as! String)
            XCTAssertEqual(mechanism.issuer, jsonDictionary?["issuer"] as! String)
            XCTAssertEqual(mechanism.type, jsonDictionary?["oathType"] as! String)
            XCTAssertEqual(mechanism.secret, jsonDictionary?["secret"] as! String)
            XCTAssertEqual(FRAConstants.oathAuth, jsonDictionary?["type"] as! String)
            XCTAssertEqual(mechanism.accountName, jsonDictionary?["accountName"] as! String)
            XCTAssertEqual(mechanism.digits, jsonDictionary?["digits"] as! Int)
            XCTAssertEqual(mechanism.period, jsonDictionary?["period"] as! Int)
            XCTAssertEqual(mechanism.timeAdded.millisecondsSince1970, jsonDictionary?["timeAdded"] as! Int64)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    func test_10_totp_from_combined_mechanism() {
        
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
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, period: parser.period, digits: parser.digits)
            
            XCTAssertNotNil(mechanism.mechanismUUID)
            XCTAssertNotNil(mechanism.issuer)
            XCTAssertNotNil(mechanism.type)
            XCTAssertNotNil(mechanism.version)
            XCTAssertNotNil(mechanism.accountName)
            XCTAssertNotNil(mechanism.secret)
            XCTAssertNotNil(mechanism.digits)
            XCTAssertNotNil(mechanism.period)
            XCTAssertNotNil(mechanism.timeAdded)
            
            XCTAssertEqual(mechanism.issuer, "Forgerock")
            XCTAssertEqual(mechanism.type, "totp")
            XCTAssertEqual(mechanism.accountName, "demo")
            XCTAssertEqual(mechanism.secret, "R2PYFZRISXA5L25NVSSYK2RQ6E======")
            XCTAssertEqual(mechanism.digits, 6)
            XCTAssertEqual(mechanism.period, 30)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    func test_11_totpmechanism_init_with_new_attributes_success() {
         
         let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=ForgeRock&period=30&algorithm=SHA256&uid=ZGVtbw&oid=ZTBkZTAxMzUtZWFmOS00ZmFjLWI1ODQtMmRkYmQyYTQwN2M2MTczOTgyNDI4ODE3NQ")!
         
         do {
             let parser = try OathQRCodeParser(url: qrCode)
             let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, period: parser.period, digits: parser.digits)
             
             XCTAssertNotNil(mechanism.mechanismUUID)
             XCTAssertNotNil(mechanism.issuer)
             XCTAssertNotNil(mechanism.type)
             XCTAssertNotNil(mechanism.version)
             XCTAssertNotNil(mechanism.accountName)
             XCTAssertNotNil(mechanism.secret)
             XCTAssertNotNil(mechanism.algorithm)
             XCTAssertNotNil(mechanism.period)
             XCTAssertNotNil(mechanism.uid)
             XCTAssertNotNil(mechanism.resourceId)
             XCTAssertNotNil(mechanism.timeAdded)
             
             XCTAssertEqual(mechanism.issuer, "ForgeRock")
             XCTAssertEqual(mechanism.type, "totp")
             XCTAssertEqual(mechanism.accountName, "demo")
             XCTAssertEqual(mechanism.secret, "IJQWIZ3FOIQUEYLE")
             XCTAssertEqual(mechanism.algorithm.rawValue, "sha256")
             XCTAssertEqual(mechanism.period, 30)
             XCTAssertEqual(mechanism.uid, "demo")
             XCTAssertEqual(mechanism.resourceId, "e0de0135-eaf9-4fac-b584-2ddbd2a407c61739824288175")
         }
         catch {
             XCTFail("Failed with unexpected error: \(error.localizedDescription)")
         }
     }
}
