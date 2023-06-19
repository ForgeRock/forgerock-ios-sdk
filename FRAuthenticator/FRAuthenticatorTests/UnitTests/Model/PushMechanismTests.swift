// 
//  PushMechanismTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class PushMechanismTests: FRABaseTests {

    func test_01_push_mechanism_init_success() {
        
        let qrCode = URL(string: "pushauth://push/Forgerock:demo?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI=&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr")!

        do {
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer)
            
            XCTAssertNotNil(mechanism.mechanismUUID)
            XCTAssertNotNil(mechanism.issuer)
            XCTAssertNotNil(mechanism.type)
            XCTAssertNotNil(mechanism.version)
            XCTAssertNotNil(mechanism.accountName)
            XCTAssertNotNil(mechanism.secret)
            XCTAssertNotNil(mechanism.regEndpoint)
            XCTAssertNotNil(mechanism.authEndpoint)
            XCTAssertNotNil(mechanism.timeAdded)
            
            XCTAssertEqual(mechanism.issuer, "Forgerock")
            XCTAssertEqual(mechanism.type, "push")
            XCTAssertEqual(mechanism.accountName, "demo")
            XCTAssertEqual(mechanism.secret, "dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=")
            XCTAssertEqual(mechanism.regEndpoint.absoluteString, "http://amqa-clone69.test.forgerock.com:8080/openam/json/push/sns/message?_action=register")
            XCTAssertEqual(mechanism.authEndpoint.absoluteString, "http://amqa-clone69.test.forgerock.com:8080/openam/json/push/sns/message?_action=authenticate")
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_02_archive_obj() {
        let qrCode = URL(string: "pushauth://push/forgerock:demo?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI=&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr")!
        
        do {
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer)
            if #available(iOS 11.0, *) {
                if let mechanismData = try? NSKeyedArchiver.archivedData(withRootObject: mechanism, requiringSecureCoding: true) {
                    let mechanismFromData = NSKeyedUnarchiver.unarchiveObject(with: mechanismData) as? PushMechanism
                    XCTAssertEqual(mechanism.mechanismUUID, mechanismFromData?.mechanismUUID)
                    XCTAssertEqual(mechanism.issuer, mechanismFromData?.issuer)
                    XCTAssertEqual(mechanism.type, mechanismFromData?.type)
                    XCTAssertEqual(mechanism.secret, mechanismFromData?.secret)
                    XCTAssertEqual(mechanism.version, mechanismFromData?.version)
                    XCTAssertEqual(mechanism.accountName, mechanismFromData?.accountName)
                    XCTAssertEqual(mechanism.regEndpoint, mechanismFromData?.regEndpoint)
                    XCTAssertEqual(mechanism.authEndpoint, mechanismFromData?.authEndpoint)
                    XCTAssertEqual(mechanism.timeAdded.timeIntervalSince1970, mechanismFromData?.timeAdded.timeIntervalSince1970)
                }
                else {
                    XCTFail("Failed to serialize PushMechanism object with Secure Coding")
                }
            } else {
                let mechanismData = NSKeyedArchiver.archivedData(withRootObject: mechanism)
                let mechanismFromData = NSKeyedUnarchiver.unarchiveObject(with: mechanismData) as? PushMechanism
                XCTAssertEqual(mechanism.mechanismUUID, mechanismFromData?.mechanismUUID)
                XCTAssertEqual(mechanism.issuer, mechanismFromData?.issuer)
                XCTAssertEqual(mechanism.type, mechanismFromData?.type)
                XCTAssertEqual(mechanism.secret, mechanismFromData?.secret)
                XCTAssertEqual(mechanism.version, mechanismFromData?.version)
                XCTAssertEqual(mechanism.accountName, mechanismFromData?.accountName)
                XCTAssertEqual(mechanism.regEndpoint, mechanismFromData?.regEndpoint)
                XCTAssertEqual(mechanism.authEndpoint, mechanismFromData?.authEndpoint)
                XCTAssertEqual(mechanism.timeAdded.timeIntervalSince1970, mechanismFromData?.timeAdded.timeIntervalSince1970)
            }
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_03_push_mechanism_identifier() {
        let qrCode = URL(string: "pushauth://push/Forgerock:demo?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI=&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472")!
        
        do {
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer)
            XCTAssertNotNil(mechanism)
            XCTAssertEqual(mechanism.identifier, "Forgerock-demo-push")
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_04_codable_serialization() {
        let qrCode = URL(string: "pushauth://push/forgerock:demo?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI=&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr")!
        
        do {
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer)

            //  Encode
            let jsonData = try JSONEncoder().encode(mechanism)
            
            //  Decode
            let decodedMechanism = try JSONDecoder().decode(PushMechanism.self, from: jsonData)
            
            XCTAssertEqual(mechanism.mechanismUUID, decodedMechanism.mechanismUUID)
            XCTAssertEqual(mechanism.issuer, decodedMechanism.issuer)
            XCTAssertEqual(mechanism.type, decodedMechanism.type)
            XCTAssertEqual(mechanism.secret, decodedMechanism.secret)
            XCTAssertEqual(mechanism.version, decodedMechanism.version)
            XCTAssertEqual(mechanism.accountName, decodedMechanism.accountName)
            XCTAssertEqual(mechanism.regEndpoint, decodedMechanism.regEndpoint)
            XCTAssertEqual(mechanism.authEndpoint, decodedMechanism.authEndpoint)
            XCTAssertEqual(mechanism.timeAdded.millisecondsSince1970, decodedMechanism.timeAdded.millisecondsSince1970)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_05_json_string_serialization() {
        let qrCode = URL(string: "pushauth://push/forgerock:demo?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI=&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr")!
        
        do {
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer)

            guard let jsonStr = mechanism.toJson() else {
                XCTFail("Failed to serialize the object into JSON String value")
                return
            }
            
            //  Covert jsonString to Dictionary
            let jsonDictionary = FRJSONEncoder.jsonStringToDictionary(jsonString: jsonStr)
                
            //  Then
            XCTAssertEqual(mechanism.mechanismUUID, jsonDictionary?["mechanismUID"] as! String)
            XCTAssertEqual(mechanism.issuer, jsonDictionary?["issuer"] as! String)
            XCTAssertEqual(mechanism.secret, jsonDictionary?["secret"] as! String)
            XCTAssertEqual(FRAConstants.pushAuth, jsonDictionary?["type"] as! String)
            XCTAssertEqual(mechanism.accountName, jsonDictionary?["accountName"] as! String)
            XCTAssertEqual(mechanism.regEndpoint.absoluteString, jsonDictionary?["registrationEndpoint"] as! String)
            XCTAssertEqual(mechanism.authEndpoint.absoluteString, jsonDictionary?["authenticationEndpoint"] as! String)
            XCTAssertEqual(mechanism.timeAdded.millisecondsSince1970, jsonDictionary?["timeAdded"] as! Int64)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    func test_06_push_combined_mechanism() {
        
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
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer)
            
            XCTAssertNotNil(mechanism.mechanismUUID)
            XCTAssertNotNil(mechanism.issuer)
            XCTAssertNotNil(mechanism.type)
            XCTAssertNotNil(mechanism.version)
            XCTAssertNotNil(mechanism.accountName)
            XCTAssertNotNil(mechanism.secret)
            XCTAssertNotNil(mechanism.regEndpoint)
            XCTAssertNotNil(mechanism.authEndpoint)
            XCTAssertNotNil(mechanism.timeAdded)
            
            XCTAssertEqual(mechanism.issuer, "Forgerock")
            XCTAssertEqual(mechanism.type, "push")
            XCTAssertEqual(mechanism.accountName, "demo")
            XCTAssertEqual(mechanism.secret, "ryJkqNRjXYd_nX523672AX_oKdVXrKExq-VjVeRKKTc")
            XCTAssertEqual(mechanism.regEndpoint.absoluteString, "https://forgerock.example.com/openam/json/push/sns/message?_action=register")
            XCTAssertEqual(mechanism.authEndpoint.absoluteString, "https://forgerock.example.com/openam/json/push/sns/message?_action=authenticate")
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
}
