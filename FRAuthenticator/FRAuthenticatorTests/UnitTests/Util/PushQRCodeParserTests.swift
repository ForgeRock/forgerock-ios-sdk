// 
//  PushQRCodeParserTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class PushQRCodeParserTests: FRABaseTests {

    func test_01_parse_push_qrcode_success() {
        
        let qrCode = URL(string: "pushauth://push/Forgerock:demo?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI=&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr")!
        
        do {
            let parser = try PushQRCodeParser(url: qrCode)
            
            XCTAssertNotNil(parser.scheme)
            XCTAssertNotNil(parser.type)
            XCTAssertNotNil(parser.issuer)
            XCTAssertNotNil(parser.label)
            XCTAssertNotNil(parser.secret)
            
            XCTAssertEqual(parser.scheme, "pushauth")
            XCTAssertEqual(parser.type, "push")
            XCTAssertEqual(parser.issuer, "Forgerock")
            XCTAssertEqual(parser.label, "demo")
            XCTAssertEqual(parser.secret, "dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=")
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_02_parse_push_qrcode_with_invalid_scheme() {
        let qrCode = URL(string: "otpauth://push/forgerock:demo?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI=&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr")!

        do {
            let _ = try PushQRCodeParser(url: qrCode)
        }
        catch MechanismError.invalidQRCode {
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_03_parse_push_qrcode_with_invalid_type() {
        let qrCode = URL(string: "pushauth://totp/forgerock:demo?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI=&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr")!

        do {
            let _ = try PushQRCodeParser(url: qrCode)
        }
        catch MechanismError.invalidType {
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_04_parse_push_qrcode_without_background_color_success() {
        
        let qrCode = URL(string: "pushauth://push/forgerock:demo?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI=&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr")!
        
        do {
            let _ = try PushQRCodeParser(url: qrCode)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_05_parse_push_qrcode_without_issuer_in_path_color_success() {
        
        let qrCode = URL(string: "pushauth://push/demo?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI=&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr")!
        
        do {
            let parser = try PushQRCodeParser(url: qrCode)
            XCTAssertNotNil(parser.issuer)
            XCTAssertNotNil(parser.label)
            XCTAssertEqual(parser.label, "demo")
            XCTAssertEqual(parser.issuer, "")
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_06_parse_push_qrcode_with_invalid_url() {
        let qrCode = URL(string: "pushauth://push/demo?a=invalidurl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&r=invalidurl&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr")!
        
        do {
            let _ = try PushQRCodeParser(url: qrCode)
        }
        catch MechanismError.invalidInformation {
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_07_parse_push_qrcode_without_url() {
        let qrCode = URL(string: "pushauth://push/demo?image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr")!
        
        do {
            let _ = try PushQRCodeParser(url: qrCode)
        }
        catch MechanismError.missingInformation {
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_08_parse_push_from_mfa_qrcode_success() {
        let qrCode = URL(string: "mfauth://totp/Test:demo?" +
                         "a=aHR0cHM6Ly9mb3JnZXJvY2suZXhhbXBsZS5jb20vb3BlbmFtL2pzb24vcHVzaC9zbnMvbWVzc2FnZT9fYWN0aW9uPWF1dGhlbnRpY2F0ZQ&" +
                         "image=https://img.favpng.com/9/25/24/computer-icons-instagram-logo-sticker-png-favpng-LZmXr3KPyVbr8LkxNML458QV3.jpg&" +
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
        
        let jsonPolicies = """
        {"biometricAvailable": { },"deviceTampering": {"score": 0.8}}
        """
        
        do {
            let parser = try PushQRCodeParser(url: qrCode)
            
            XCTAssertNotNil(parser.scheme)
            XCTAssertNotNil(parser.type)
            XCTAssertNotNil(parser.issuer)
            XCTAssertNotNil(parser.label)
            XCTAssertNotNil(parser.secret)
            
            XCTAssertEqual(parser.scheme, "mfauth")
            XCTAssertEqual(parser.type, "totp")
            XCTAssertEqual(parser.issuer, "Test")
            XCTAssertEqual(parser.label, "demo")
            XCTAssertEqual(parser.loadBalancer, "amlbcookie=01")
            XCTAssertEqual(parser.challenge, "Daf8vrc8onKu+dcptwCRS9UHmdui5u16vAdG2HMU4w0")
            XCTAssertEqual(parser.secret, "ryJkqNRjXYd_nX523672AX_oKdVXrKExq-VjVeRKKTc")
            XCTAssertEqual(parser.registrationEndpoint.absoluteString, "https://forgerock.example.com/openam/json/push/sns/message?_action=register")
            XCTAssertEqual(parser.authenticationEndpoint.absoluteString, "https://forgerock.example.com/openam/json/push/sns/message?_action=authenticate")
            XCTAssertEqual(parser.policies, jsonPolicies)
            XCTAssertEqual(parser.backgroundColor, "ff00ff")
            XCTAssertEqual(parser.image, "https://img.favpng.com/9/25/24/computer-icons-instagram-logo-sticker-png-favpng-LZmXr3KPyVbr8LkxNML458QV3.jpg")
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
}
