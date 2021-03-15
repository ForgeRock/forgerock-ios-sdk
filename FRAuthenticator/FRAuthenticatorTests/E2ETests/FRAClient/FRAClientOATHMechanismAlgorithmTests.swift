// 
//  FRAClientOATHMechanismAlgorithmTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class FRAClientOATHMechanismAlgorithmTests: FRABaseTests {
    
    
    func test_01_hotp_no_algorithm() {
        //  Start SDK
        FRAClient.start()
        
        //  Given
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock")!
        FRAClient.shared?.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            if let oathMechanism = mechanism as? OathMechanism {
                XCTAssertEqual(oathMechanism.type, "hotp")
                XCTAssertEqual(oathMechanism.algorithm, .sha1)
            }
            else {
                XCTFail("Unexpected Mechanism type is returned")
            }
        }, onError: { (error) in
            XCTFail("FRAClient failed to store QR Code with given data: \(qrCode), error: \(error.localizedDescription)")
        })
    }
    
    
    func test_02_hotp_sha1_algorithm() {
        //  Start SDK
        FRAClient.start()
        
        //  Given
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&algorithm=sha1")!
        FRAClient.shared?.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            if let oathMechanism = mechanism as? OathMechanism {
                XCTAssertEqual(oathMechanism.type, "hotp")
                XCTAssertEqual(oathMechanism.algorithm, .sha1)
            }
            else {
                XCTFail("Unexpected Mechanism type is returned")
            }
        }, onError: { (error) in
            XCTFail("FRAClient failed to store QR Code with given data: \(qrCode), error: \(error.localizedDescription)")
        })
    }
    
    
    func test_03_hotp_sha224_algorithm() {
        //  Start SDK
        FRAClient.start()
        
        //  Given
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&algorithm=sha224")!
        FRAClient.shared?.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            if let oathMechanism = mechanism as? OathMechanism {
                XCTAssertEqual(oathMechanism.type, "hotp")
                XCTAssertEqual(oathMechanism.algorithm, .sha224)
            }
            else {
                XCTFail("Unexpected Mechanism type is returned")
            }
        }, onError: { (error) in
            XCTFail("FRAClient failed to store QR Code with given data: \(qrCode), error: \(error.localizedDescription)")
        })
    }
    
    
    func test_04_hotp_sha256_algorithm() {
        //  Start SDK
        FRAClient.start()
        
        //  Given
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&algorithm=sha256")!
        FRAClient.shared?.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            if let oathMechanism = mechanism as? OathMechanism {
                XCTAssertEqual(oathMechanism.type, "hotp")
                XCTAssertEqual(oathMechanism.algorithm, .sha256)
            }
            else {
                XCTFail("Unexpected Mechanism type is returned")
            }
        }, onError: { (error) in
            XCTFail("FRAClient failed to store QR Code with given data: \(qrCode), error: \(error.localizedDescription)")
        })
    }
    
    
    func test_05_hotp_sha384_algorithm() {
        //  Start SDK
        FRAClient.start()
        
        //  Given
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&algorithm=sha384")!
        FRAClient.shared?.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            if let oathMechanism = mechanism as? OathMechanism {
                XCTAssertEqual(oathMechanism.type, "hotp")
                XCTAssertEqual(oathMechanism.algorithm, .sha384)
            }
            else {
                XCTFail("Unexpected Mechanism type is returned")
            }
        }, onError: { (error) in
            XCTFail("FRAClient failed to store QR Code with given data: \(qrCode), error: \(error.localizedDescription)")
        })
    }
    
    
    func test_06_hotp_sha512_algorithm() {
        //  Start SDK
        FRAClient.start()
        
        //  Given
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&algorithm=sha512")!
        FRAClient.shared?.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            if let oathMechanism = mechanism as? OathMechanism {
                XCTAssertEqual(oathMechanism.type, "hotp")
                XCTAssertEqual(oathMechanism.algorithm, .sha512)
            }
            else {
                XCTFail("Unexpected Mechanism type is returned")
            }
        }, onError: { (error) in
            XCTFail("FRAClient failed to store QR Code with given data: \(qrCode), error: \(error.localizedDescription)")
        })
    }
    
    
    func test_07_hotp_md5_algorithm() {
        //  Start SDK
        FRAClient.start()
        
        //  Given
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&algorithm=md5")!
        FRAClient.shared?.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            if let oathMechanism = mechanism as? OathMechanism {
                XCTAssertEqual(oathMechanism.type, "hotp")
                XCTAssertEqual(oathMechanism.algorithm, .md5)
            }
            else {
                XCTFail("Unexpected Mechanism type is returned")
            }
        }, onError: { (error) in
            XCTFail("FRAClient failed to store QR Code with given data: \(qrCode), error: \(error.localizedDescription)")
        })
    }
    
    
    func test_08_hotp_invalid_algorithm() {
        //  Start SDK
        FRAClient.start()
        
        //  Given
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&algorithm=rs512")!
        FRAClient.shared?.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            XCTFail("While expecting failure to create Mechanism with invalid algorithm, it succeeded")
        }, onError: { (error) in
            if let mechanismError = error as? MechanismError {
                switch mechanismError {
                case .invalidInformation(let message):
                    XCTAssertEqual(message, "algorithm (rs512)")
                    break
                default:
                    XCTFail("Creating Mechanism with invalid algorithm returned different error than expected (error: \(error.localizedDescription)")
                }
            }
        })
    }
    
    
    func test_09_totp_no_algorithm() {
        //  Start SDK
        FRAClient.start()
        
        //  Given
        let qrCode = URL(string: "otpauth://totp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock")!
        FRAClient.shared?.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            if let oathMechanism = mechanism as? OathMechanism {
                XCTAssertEqual(oathMechanism.type, "totp")
                XCTAssertEqual(oathMechanism.algorithm, .sha1)
            }
            else {
                XCTFail("Unexpected Mechanism type is returned")
            }
        }, onError: { (error) in
            XCTFail("FRAClient failed to store QR Code with given data: \(qrCode), error: \(error.localizedDescription)")
        })
    }
    
    
    func test_10_totp_sha1_algorithm() {
        //  Start SDK
        FRAClient.start()
        
        //  Given
        let qrCode = URL(string: "otpauth://totp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&algorithm=sha1")!
        FRAClient.shared?.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            if let oathMechanism = mechanism as? OathMechanism {
                XCTAssertEqual(oathMechanism.type, "totp")
                XCTAssertEqual(oathMechanism.algorithm, .sha1)
            }
            else {
                XCTFail("Unexpected Mechanism type is returned")
            }
        }, onError: { (error) in
            XCTFail("FRAClient failed to store QR Code with given data: \(qrCode), error: \(error.localizedDescription)")
        })
    }
    
    
    func test_11_totp_sha224_algorithm() {
        //  Start SDK
        FRAClient.start()
        
        //  Given
        let qrCode = URL(string: "otpauth://totp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&algorithm=sha224")!
        FRAClient.shared?.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            if let oathMechanism = mechanism as? OathMechanism {
                XCTAssertEqual(oathMechanism.type, "totp")
                XCTAssertEqual(oathMechanism.algorithm, .sha224)
            }
            else {
                XCTFail("Unexpected Mechanism type is returned")
            }
        }, onError: { (error) in
            XCTFail("FRAClient failed to store QR Code with given data: \(qrCode), error: \(error.localizedDescription)")
        })
    }
    
    
    func test_12_totp_sha256_algorithm() {
        //  Start SDK
        FRAClient.start()
        
        //  Given
        let qrCode = URL(string: "otpauth://totp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&algorithm=sha256")!
        FRAClient.shared?.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            if let oathMechanism = mechanism as? OathMechanism {
                XCTAssertEqual(oathMechanism.type, "totp")
                XCTAssertEqual(oathMechanism.algorithm, .sha256)
            }
            else {
                XCTFail("Unexpected Mechanism type is returned")
            }
        }, onError: { (error) in
            XCTFail("FRAClient failed to store QR Code with given data: \(qrCode), error: \(error.localizedDescription)")
        })
    }
    
    
    func test_13_totp_sha384_algorithm() {
        //  Start SDK
        FRAClient.start()
        
        //  Given
        let qrCode = URL(string: "otpauth://totp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&algorithm=sha384")!
        FRAClient.shared?.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            if let oathMechanism = mechanism as? OathMechanism {
                XCTAssertEqual(oathMechanism.type, "totp")
                XCTAssertEqual(oathMechanism.algorithm, .sha384)
            }
            else {
                XCTFail("Unexpected Mechanism type is returned")
            }
        }, onError: { (error) in
            XCTFail("FRAClient failed to store QR Code with given data: \(qrCode), error: \(error.localizedDescription)")
        })
    }
    
    
    func test_14_totp_sha512_algorithm() {
        //  Start SDK
        FRAClient.start()
        
        //  Given
        let qrCode = URL(string: "otpauth://totp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&algorithm=sha512")!
        FRAClient.shared?.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            if let oathMechanism = mechanism as? OathMechanism {
                XCTAssertEqual(oathMechanism.type, "totp")
                XCTAssertEqual(oathMechanism.algorithm, .sha512)
            }
            else {
                XCTFail("Unexpected Mechanism type is returned")
            }
        }, onError: { (error) in
            XCTFail("FRAClient failed to store QR Code with given data: \(qrCode), error: \(error.localizedDescription)")
        })
    }
    
    
    func test_14_totp_md5_algorithm() {
        //  Start SDK
        FRAClient.start()
        
        //  Given
        let qrCode = URL(string: "otpauth://totp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&algorithm=md5")!
        FRAClient.shared?.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            if let oathMechanism = mechanism as? OathMechanism {
                XCTAssertEqual(oathMechanism.type, "totp")
                XCTAssertEqual(oathMechanism.algorithm, .md5)
            }
            else {
                XCTFail("Unexpected Mechanism type is returned")
            }
        }, onError: { (error) in
            XCTFail("FRAClient failed to store QR Code with given data: \(qrCode), error: \(error.localizedDescription)")
        })
    }
    
    
    func test_15_totp_invalid_algorithm() {
        //  Start SDK
        FRAClient.start()
        
        //  Given
        let qrCode = URL(string: "otpauth://totp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&algorithm=rs512")!
        FRAClient.shared?.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            XCTFail("While expecting failure to create Mechanism with invalid algorithm, it succeeded")
        }, onError: { (error) in
            if let mechanismError = error as? MechanismError {
                switch mechanismError {
                case .invalidInformation(let message):
                    XCTAssertEqual(message, "algorithm (rs512)")
                    break
                default:
                    XCTFail("Creating Mechanism with invalid algorithm returned different error than expected (error: \(error.localizedDescription)")
                }
            }
        })
    }
    
    
    func test_16_totp_invalid_digits() {
        //  Start SDK
        FRAClient.start()
        
        //  Given
        let qrCode = URL(string: "otpauth://totp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&digits=7")!
        FRAClient.shared?.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            XCTFail("While expecting failure to create Mechanism with invalid algorithm, it succeeded")
        }, onError: { (error) in
            if let mechanismError = error as? MechanismError {
                switch mechanismError {
                case .invalidInformation(let message):
                    XCTAssertEqual(message, "digits (7)")
                    break
                default:
                    XCTFail("Creating Mechanism with invalid algorithm returned different error than expected (error: \(error.localizedDescription)")
                }
            }
        })
    }
}
