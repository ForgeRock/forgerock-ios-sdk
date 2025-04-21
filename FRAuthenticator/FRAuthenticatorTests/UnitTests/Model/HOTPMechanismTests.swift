// 
//  HOTPMechanismTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class HOTPMechanismTests: FRABaseTests {

    func test_01_hotpmechanism_init_success() {
         
         let qrCode = URL(string: "otpauth://hotp/ForgeRock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=ForgeRock&counter=0&algorithm=SHA256")!
         
         do {
             let parser = try OathQRCodeParser(url: qrCode)
             let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, counter: parser.counter, digits: parser.digits)
             
             XCTAssertNotNil(mechanism.mechanismUUID)
             XCTAssertNotNil(mechanism.issuer)
             XCTAssertNotNil(mechanism.type)
             XCTAssertNotNil(mechanism.version)
             XCTAssertNotNil(mechanism.accountName)
             XCTAssertNotNil(mechanism.secret)
             XCTAssertNotNil(mechanism.algorithm)
             XCTAssertNotNil(mechanism.timeAdded)
             
             XCTAssertEqual(mechanism.issuer, "ForgeRock")
             XCTAssertEqual(mechanism.type, "hotp")
             XCTAssertEqual(mechanism.accountName, "demo")
             XCTAssertEqual(mechanism.secret, "IJQWIZ3FOIQUEYLE")
             XCTAssertEqual(mechanism.algorithm.rawValue, "sha256")
         }
         catch {
             XCTFail("Failed with unexpected error: \(error.localizedDescription)")
         }
     }
     
     
    func test_02_archive_obj() {
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0&algorithm=SHA256")!

        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, counter: parser.counter, digits: parser.digits)
            if let mechanismData = try? NSKeyedArchiver.archivedData(withRootObject: mechanism, requiringSecureCoding: true) {
                let mechanismFromData = NSKeyedUnarchiver.unarchiveObject(with: mechanismData) as? HOTPMechanism
                XCTAssertNotNil(mechanismFromData)
                XCTAssertEqual(mechanism.mechanismUUID, mechanismFromData?.mechanismUUID)
                XCTAssertEqual(mechanism.issuer, mechanismFromData?.issuer)
                XCTAssertEqual(mechanism.type, mechanismFromData?.type)
                XCTAssertEqual(mechanism.secret, mechanismFromData?.secret)
                XCTAssertEqual(mechanism.version, mechanismFromData?.version)
                XCTAssertEqual(mechanism.accountName, mechanismFromData?.accountName)
                XCTAssertEqual(mechanism.algorithm, mechanismFromData?.algorithm)
                XCTAssertEqual(mechanism.digits, mechanismFromData?.digits)
                XCTAssertEqual(mechanism.counter, mechanismFromData?.counter)
                XCTAssertEqual(mechanism.timeAdded.timeIntervalSince1970, mechanismFromData?.timeAdded.timeIntervalSince1970)
            }
            else {
                XCTFail("Failed to serialize HOTPMechnaism object with Secure Coding")
            }
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    
    func test_03_hotp_mechanism_identifier() {
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0&algorithm=SHA256")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, counter: parser.counter, digits: parser.digits)
            XCTAssertNotNil(mechanism)
            XCTAssertEqual(mechanism.identifier, "Forgerock-demo-hotp")
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    
    func test_04_hotp_mechanism_counter() {
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=4&algorithm=SHA256")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, counter: parser.counter, digits: parser.digits)
            XCTAssertNotNil(mechanism)
            XCTAssertEqual(mechanism.counter, 4)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    
    func test_05_hotp_mechanism_default_counter() {
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, counter: parser.counter, digits: parser.digits)
            XCTAssertNotNil(mechanism)
            XCTAssertEqual(mechanism.counter, 0)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    
    func test_06_hotp_mechanism_invalid_secret() {
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=invalidSecret&issuer=Forgerock&counter=4&algorithm=SHA256")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, counter: parser.counter, digits: parser.digits)
            XCTAssertNotNil(mechanism)
            XCTAssertEqual(mechanism.counter, 4)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_07_hotp_mechanism_generate_code_in_sequence() {
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0&algorithm=SHA256")!
        
        do {
            // Init SDK
            FRAClient.start()
            
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, counter: parser.counter, digits: parser.digits)
            XCTAssertNotNil(mechanism)
            
            let expected: [String] = ["185731", "773759", "684879", "952500", "430844", "344487", "866561"]
            for index in 0...6 {
                let code = try mechanism.generateCode()
                XCTAssertEqual(code.code, expected[index])
                let thisMechanism = FRAClient.storage.getMechanismForUUID(uuid: mechanism.mechanismUUID) as? HOTPMechanism
                XCTAssertEqual(thisMechanism?.counter, index + 1)
            }
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_08_hotp_mechanism_generate_code_in_sequence_and_failure() {
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0&algorithm=SHA256")!
        
        var tmpMechanism: HOTPMechanism?
        do {
            // Init SDK
            let storageClient = DummyStorageClient()
            FRAClient.storage = storageClient
            FRAClient.start()
            
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, counter: parser.counter, digits: parser.digits)
            XCTAssertNotNil(mechanism)
            tmpMechanism = mechanism
            
            let expected: [String] = ["185731", "773759", "684879", "952500", "952500", "430844", "344487", "866561"]
            for index in 0...7 {
                
                if index == 3 {
                    storageClient.setMechanismResult = false
                    let _ = try mechanism.generateCode()
                }
                else {
                    let code = try mechanism.generateCode()
                    XCTAssertEqual(code.code, expected[index])
                    let thisMechanism = FRAClient.storage.getMechanismForUUID(uuid: mechanism.mechanismUUID) as? HOTPMechanism
                    XCTAssertEqual(thisMechanism?.counter, index + 1)
                }
            }
        }
        catch MechanismError.failedToUpdateInformation {
            if let thisMechanism = tmpMechanism {
                XCTAssertEqual(thisMechanism.counter, 3)
            }
            
            if let storageClient = FRAClient.storage as? DummyStorageClient {
                storageClient.setMechanismResult = nil
            }
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_09_codable_serialization() {
        
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0&algorithm=SHA256")!
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, counter: parser.counter, digits: parser.digits)
            
            //  Encode
            let jsonData = try JSONEncoder().encode(mechanism)
            
            //  Decode
            let decodedMechanism = try JSONDecoder().decode(HOTPMechanism.self, from: jsonData)
            
            XCTAssertEqual(mechanism.mechanismUUID, decodedMechanism.mechanismUUID)
            XCTAssertEqual(mechanism.issuer, decodedMechanism.issuer)
            XCTAssertEqual(mechanism.type, decodedMechanism.type)
            XCTAssertEqual(mechanism.secret, decodedMechanism.secret)
            XCTAssertEqual(mechanism.version, decodedMechanism.version)
            XCTAssertEqual(mechanism.accountName, decodedMechanism.accountName)
            XCTAssertEqual(mechanism.algorithm, decodedMechanism.algorithm)
            XCTAssertEqual(mechanism.digits, decodedMechanism.digits)
            XCTAssertEqual(mechanism.counter, decodedMechanism.counter)
            XCTAssertEqual(mechanism.timeAdded.millisecondsSince1970, decodedMechanism.timeAdded.millisecondsSince1970)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_10_json_string_serialization() {
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0&algorithm=SHA256")!
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, counter: parser.counter, digits: parser.digits)
            
            guard let jsonString = mechanism.toJson() else {
                XCTFail("Failed to serialize the object into JSON String value")
                return
            }
            
            //  Covert jsonString to Dictionary
            let jsonDictionary = FRJSONEncoder.jsonStringToDictionary(jsonString: jsonString)
                
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
            XCTAssertEqual(mechanism.timeAdded.millisecondsSince1970, jsonDictionary?["timeAdded"] as! Int64)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    func test_11_hotp_from_combined_mechanism() {
         
        let qrCode = URL(string: "mfauth://hotp/Forgerock:demo?" +
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
                         "counter=10&" +
                         "issuer=Rm9yZ2Vyb2Nr")!
         
         do {
             let parser = try OathQRCodeParser(url: qrCode)
             let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, counter: parser.counter, digits: parser.digits)
             
             XCTAssertNotNil(mechanism.mechanismUUID)
             XCTAssertNotNil(mechanism.issuer)
             XCTAssertNotNil(mechanism.type)
             XCTAssertNotNil(mechanism.version)
             XCTAssertNotNil(mechanism.accountName)
             XCTAssertNotNil(mechanism.secret)
             XCTAssertNotNil(mechanism.algorithm)
             XCTAssertNotNil(mechanism.timeAdded)
             
             XCTAssertEqual(mechanism.issuer, "Forgerock")
             XCTAssertEqual(mechanism.type, "hotp")
             XCTAssertEqual(mechanism.accountName, "demo")
             XCTAssertEqual(mechanism.secret, "R2PYFZRISXA5L25NVSSYK2RQ6E======")
             XCTAssertEqual(mechanism.algorithm.rawValue, "sha1")
             XCTAssertEqual(mechanism.counter, 10)
         }
         catch {
             XCTFail("Failed with unexpected error: \(error.localizedDescription)")
         }
     }
    
    func test_12_hotpmechanism_init_with_new_attributes_success() {
         
         let qrCode = URL(string: "otpauth://hotp/ForgeRock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=ForgeRock&counter=0&algorithm=SHA256&uid=ZGVtbw&oid=ZTBkZTAxMzUtZWFmOS00ZmFjLWI1ODQtMmRkYmQyYTQwN2M2MTczOTgyNDI4ODE3NQ")!
         
         do {
             let parser = try OathQRCodeParser(url: qrCode)
             let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, uid: parser.uid, resourceId: parser.resourceId, counter: parser.counter, digits: parser.digits)
             
             XCTAssertNotNil(mechanism.mechanismUUID)
             XCTAssertNotNil(mechanism.issuer)
             XCTAssertNotNil(mechanism.type)
             XCTAssertNotNil(mechanism.version)
             XCTAssertNotNil(mechanism.accountName)
             XCTAssertNotNil(mechanism.secret)
             XCTAssertNotNil(mechanism.algorithm)
             XCTAssertNotNil(mechanism.uid)
             XCTAssertNotNil(mechanism.resourceId)
             XCTAssertNotNil(mechanism.timeAdded)
             
             XCTAssertEqual(mechanism.issuer, "ForgeRock")
             XCTAssertEqual(mechanism.type, "hotp")
             XCTAssertEqual(mechanism.accountName, "demo")
             XCTAssertEqual(mechanism.secret, "IJQWIZ3FOIQUEYLE")
             XCTAssertEqual(mechanism.algorithm.rawValue, "sha256")
             XCTAssertEqual(mechanism.uid, "demo")
             XCTAssertEqual(mechanism.resourceId, "e0de0135-eaf9-4fac-b584-2ddbd2a407c61739824288175")
         }
         catch {
             XCTFail("Failed with unexpected error: \(error.localizedDescription)")
         }
     }
}
