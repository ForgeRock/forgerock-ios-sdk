// 
//  HOTPMechanismTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest

class HOTPMechanismTests: FRABaseTests {

    func test_01_hotpmechanism_init_success() {
         
         let qrCode = URL(string: "otpauth://hotp/ForgeRock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=ForgeRock&counter=0&algorithm=SHA256")!
         
         do {
             let parser = try OathQRCodeParser(url: qrCode)
             let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, counter: parser.counter, digits: parser.digits)
             
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
             XCTAssertEqual(mechanism.algorithm, "SHA256")
         }
         catch {
             XCTFail("Failed with unexpected error: \(error.localizedDescription)")
         }
     }
     
     
    func test_02_archive_obj() {
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0&algorithm=SHA256")!

        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, counter: parser.counter, digits: parser.digits)
            let mechanismData = NSKeyedArchiver.archivedData(withRootObject: mechanism)

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
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    
    func test_03_hotp_mechanism_identifier() {
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0&algorithm=SHA256")!
        
        do {
            let parser = try OathQRCodeParser(url: qrCode)
            let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, counter: parser.counter, digits: parser.digits)
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
            let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, counter: parser.counter, digits: parser.digits)
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
            let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, counter: parser.counter, digits: parser.digits)
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
            let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, counter: parser.counter, digits: parser.digits)
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
            let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, counter: parser.counter, digits: parser.digits)
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
            let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, counter: parser.counter, digits: parser.digits)
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
}
