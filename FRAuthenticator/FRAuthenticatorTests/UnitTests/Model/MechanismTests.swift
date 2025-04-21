// 
//  MechanismTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020-2025 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class MechanismTests: FRABaseTests {

    func test_01_mechanism_serialization() {
    
        let mechanism = Mechanism(type: "totp", issuer: "ForgeRock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB")
        if let mechanismData = try? NSKeyedArchiver.archivedData(withRootObject: mechanism, requiringSecureCoding: true) {
            let mechanismFromData = NSKeyedUnarchiver.unarchiveObject(with: mechanismData) as? Mechanism
            XCTAssertNotNil(mechanismFromData)
            XCTAssertEqual(mechanism.mechanismUUID, mechanismFromData?.mechanismUUID)
            XCTAssertEqual(mechanism.type, mechanismFromData?.type)
            XCTAssertEqual(mechanism.version, mechanismFromData?.version)
            XCTAssertEqual(mechanism.issuer, mechanismFromData?.issuer)
            XCTAssertEqual(mechanism.secret, mechanismFromData?.secret)
            XCTAssertEqual(mechanism.accountName, mechanismFromData?.accountName)
            XCTAssertEqual(mechanism.timeAdded.timeIntervalSince1970, mechanismFromData?.timeAdded.timeIntervalSince1970)
        }
        else {
            XCTFail("Failed to serialize Mechanism object with Secure Coding")
        }
    }
    
    
    func test_02_mechanism_order() {
        
        let thisAccount = Account(issuer: "ForgeRock", accountName: "OrderTest")
        let mechanism1 = Mechanism(type: "totp", issuer: "ForgeRock", accountName: "OrderTest", secret: "T7SIIEPTZJQQDSCB")
        sleep(1)
        let mechanism2 = Mechanism(type: "hotp", issuer: "ForgeRock", accountName: "OrderTest", secret: "T7SIIEPTZJQQDSCB")
        sleep(1)
        let mechanism3 = Mechanism(type: "push", issuer: "ForgeRock", accountName: "OrderTest", secret: "T7SIIEPTZJQQDSCB")
        
        FRAClient.start()
        FRAClient.storage.setAccount(account: thisAccount)
        FRAClient.storage.setMechanism(mechanism: mechanism3)
        FRAClient.storage.setMechanism(mechanism: mechanism1)
        FRAClient.storage.setMechanism(mechanism: mechanism2)
        
        guard let account = FRAClient.shared?.getAccount(identifier: "ForgeRock-OrderTest") else {
            XCTFail("Failed to retrieve Account, and Mechanism object")
            return
        }
        let mechanismTypes: [String] = ["totp", "hotp", "push"]
        for (index, mechanism) in account.mechanisms.enumerated() {
            XCTAssertEqual(mechanismTypes[index], mechanism.type)
        }
    }
    
    
    func test_03_codable_serialization() {
        
        let mechanism = Mechanism(type: "totp", issuer: "ForgeRock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB")
        
        do {
            //  Encode
            let jsonData = try JSONEncoder().encode(mechanism)
            
            //  Decode
            let decodedMechanism = try JSONDecoder().decode(Mechanism.self, from: jsonData)
            
            XCTAssertEqual(mechanism.mechanismUUID, decodedMechanism.mechanismUUID)
            XCTAssertEqual(mechanism.type, decodedMechanism.type)
            XCTAssertEqual(mechanism.version, decodedMechanism.version)
            XCTAssertEqual(mechanism.issuer, decodedMechanism.issuer)
            XCTAssertEqual(mechanism.secret, decodedMechanism.secret)
            XCTAssertEqual(mechanism.accountName, decodedMechanism.accountName)
            XCTAssertEqual(mechanism.timeAdded.millisecondsSince1970, decodedMechanism.timeAdded.millisecondsSince1970)
        }
        catch {
            XCTFail("Failed with an unexpected error: \(error.localizedDescription)")
        }
    }
}
