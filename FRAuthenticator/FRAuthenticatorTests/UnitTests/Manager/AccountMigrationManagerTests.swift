//
//  AccountMigrationManagerTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuthenticator

final class AccountMigrationManagerTests: XCTestCase {
    
    //  MARK: - AccountMigrationManager.decodeToURLs(url:) tests
    
    func test_01_01_test_decodeToURLs_single_url() {
        do {
            let urls = try AccountMigrationManager.decodeToURLs(url: URL(string: "otpauth-migration://offline?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgE")!)
            
            XCTAssertEqual(urls.count, 1)
            
            let url = urls.first!
            
            XCTAssertEqual(url.scheme, "otpauth")
            XCTAssertEqual(url.host, "hotp")
            XCTAssertEqual(url.valueOf("secret"), "IJQWIZ3FOIQUEYLE")
            XCTAssertEqual(url.valueOf("issuer"), "Forgerock")
            XCTAssertEqual(url.valueOf("counter"), "4")
            XCTAssertEqual(url.valueOf("algorithm"), "sha256")
        } catch {
            XCTFail("AccountMigrationManager.decodeToURLs(url:) failed with unexpected reason")
        }
    }
    
    
    func test_01_02_test_decodeToURLs_two_different_types() {
        do {
            let urls = try AccountMigrationManager.decodeToURLs(url: URL(string: "otpauth-migration://offline?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgECiMKCp/khBHzymEByEESBGRlbW8aCUZvcmdlUm9jayABKAEwAg%3D%3D")!)
            
            XCTAssertEqual(urls.count, 2)
            
            let hotpUrl = urls[0]
            let totpUrl = urls[1]
            
            XCTAssertEqual(hotpUrl.scheme, "otpauth")
            XCTAssertEqual(hotpUrl.host, "hotp")
            XCTAssertEqual(hotpUrl.valueOf("secret"), "IJQWIZ3FOIQUEYLE")
            XCTAssertEqual(hotpUrl.valueOf("issuer"), "Forgerock")
            XCTAssertEqual(hotpUrl.valueOf("counter"), "4")
            XCTAssertEqual(hotpUrl.valueOf("algorithm"), "sha256")
            
            XCTAssertEqual(totpUrl.scheme, "otpauth")
            XCTAssertEqual(totpUrl.host, "totp")
            XCTAssertEqual(totpUrl.valueOf("secret"), "T7SIIEPTZJQQDSCB")
            XCTAssertEqual(totpUrl.valueOf("issuer"), "ForgeRock")
            XCTAssertEqual(totpUrl.valueOf("digits"), "6")
            XCTAssertEqual(totpUrl.valueOf("period"), "30")
            
        } catch {
            XCTFail("AccountMigrationManager.decodeToURLs(url:) failed with unexpected reason")
        }
    }
    
    
    func test_01_03_test_decodeToURLs_ten_urls() {
        do {
            let urls = try AccountMigrationManager.decodeToURLs(url: URL(string: "otpauth-migration://offline?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgECiUKCp/khBHzymEByEESBWRlbW8xGgpGb3JnZVJvY2sxIAEoATACCicKCkJhZGdlciFCYWQSBWRlbW8yGgpGb3JnZXJvY2syIAIoATABOAQKJQoKQmFkZ2VyIUJhZBIFZGVtbzMaCkZvcmdlcm9jazMgAigBMAEKJQoKQmFkZ2VyIUJhZBIFZGVtbzQaCkZvcmdlcm9jazQgBCgBMAEKJQoKQmFkZ2VyIUJhZBIEZGVtbxoJRm9yZ2Vyb2NrIAIoATABOAQKJQoKn+SEEfPKYQHIQRIFZGVtbzEaCkZvcmdlUm9jazEgASgBMAIKJwoKQmFkZ2VyIUJhZBIFZGVtbzIaCkZvcmdlcm9jazIgAigBMAE4BAolCgpCYWRnZXIhQmFkEgVkZW1vMxoKRm9yZ2Vyb2NrMyACKAEwAQolCgpCYWRnZXIhQmFkEgVkZW1vNBoKRm9yZ2Vyb2NrNCAEKAEwAQ%3D%3D")!)
            
            XCTAssertEqual(urls.count, 10)
            
        } catch {
            XCTFail("AccountMigrationManager.decodeToURLs(url:) failed with unexpected reason")
        }
    }
    
    
    func test_01_04_test_decodeToURLs_wrong_scheme() {
        do {
            let _ = try AccountMigrationManager.decodeToURLs(url: URL(string: "otpauth-migrationxxx://offline?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgE")!)
            
            XCTFail("Decoding should have failed due to wrong scheme")
        } catch AccountMigrationError.invalidScheme {
            //all good
        } catch {
            XCTFail("Decoding should have failed due to wrong scheme")
        }
    }
    
    
    func test_01_05_test_decodeToURLs_wrong_host() {
        do {
            let _ = try AccountMigrationManager.decodeToURLs(url: URL(string: "otpauth-migration://offlinexxx?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgE")!)
            
            XCTFail("Decoding should have failed due to wrong host")
        } catch AccountMigrationError.invalidHost {
            //all good
        } catch {
            XCTFail("Decoding should have failed due to wrong host")
        }
    }
    
    
    func test_01_06_test_decodeToURLs_missing_data() {
        do {
            let _ = try AccountMigrationManager.decodeToURLs(url: URL(string: "otpauth-migration://offline?Missingdata=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgE")!)
            
            XCTFail("Decoding should have failed due to missing data")
        } catch AccountMigrationError.missingData {
            //all good
        } catch {
            XCTFail("Decoding should have failed due to missing data")
        }
    }
    
    
    func test_01_07_test_decodeToURLs_invalid_data() {
        do {
            let _ = try AccountMigrationManager.decodeToURLs(url: URL(string: "otpauth-migration://offline?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcm\\dlcm9jayACKAEwATgE")!)
            
            XCTFail("Decoding should have failed due to invalid data")
        } catch AccountMigrationError.failToDecodeData {
            //all good
        } catch {
            XCTFail("Decoding should have failed due to invalid data")
        }
    }
    
    
    //  MARK: - AccountMigrationManager.decodeToMechanisms(url:) tests
    
    func test_02_01_test_decodeToMechanisms_single_mechanism() {
        do {
            let mechanisms = try AccountMigrationManager.decodeToMechanisms(url: URL(string: "otpauth-migration://offline?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgE")!)
            
            XCTAssertEqual(mechanisms.count, 1)
            
            let mechanism = mechanisms.first!
            
            XCTAssertEqual(mechanism.type, AuthType.hotp.rawValue)
            XCTAssertEqual(mechanism.secret, "IJQWIZ3FOIQUEYLE")
            XCTAssertEqual(mechanism.issuer, "Forgerock")
            XCTAssertEqual(mechanism.algorithm, OathAlgorithm.sha256)
        } catch {
            XCTFail("AccountMigrationManager.decodeToURLs(url:) failed with unexpected reason")
        }
    }
    
    
    func test_02_02_test_decodeToMechanisms_ten_mechanisms() {
        do {
            let mechanisms = try AccountMigrationManager.decodeToMechanisms(url: URL(string: "otpauth-migration://offline?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgECiUKCp/khBHzymEByEESBWRlbW8xGgpGb3JnZVJvY2sxIAEoATACCicKCkJhZGdlciFCYWQSBWRlbW8yGgpGb3JnZXJvY2syIAIoATABOAQKJQoKQmFkZ2VyIUJhZBIFZGVtbzMaCkZvcmdlcm9jazMgAigBMAEKJQoKQmFkZ2VyIUJhZBIFZGVtbzQaCkZvcmdlcm9jazQgBCgBMAEKJQoKQmFkZ2VyIUJhZBIEZGVtbxoJRm9yZ2Vyb2NrIAIoATABOAQKJQoKn+SEEfPKYQHIQRIFZGVtbzEaCkZvcmdlUm9jazEgASgBMAIKJwoKQmFkZ2VyIUJhZBIFZGVtbzIaCkZvcmdlcm9jazIgAigBMAE4BAolCgpCYWRnZXIhQmFkEgVkZW1vMxoKRm9yZ2Vyb2NrMyACKAEwAQolCgpCYWRnZXIhQmFkEgVkZW1vNBoKRm9yZ2Vyb2NrNCAEKAEwAQ%3D%3D")!)
            
            XCTAssertEqual(mechanisms.count, 10)
            
        } catch {
            XCTFail("AccountMigrationManager.decodeToURLs(url:) failed with unexpected reason")
        }
    }
    
    
    func test_02_03_test_decodeToMechanisms_wrong_scheme() {
        do {
            let _ = try AccountMigrationManager.decodeToMechanisms(url: URL(string: "otpauth-migrationxxx://offline?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgE")!)
            
            XCTFail("Decoding should have failed due to wrong scheme")
        } catch AccountMigrationError.invalidScheme {
            //all good
        } catch {
            XCTFail("Decoding should have failed due to wrong scheme")
        }
    }
    
    
    func test_02_04_test_decodeToMechanisms_wrong_host() {
        do {
            let _ = try AccountMigrationManager.decodeToMechanisms(url: URL(string: "otpauth-migration://offlinexxx?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgE")!)
            
            XCTFail("Decoding should have failed due to wrong host")
        } catch AccountMigrationError.invalidHost {
            //all good
        } catch {
            XCTFail("Decoding should have failed due to wrong host")
        }
    }
    
    
    func test_02_05_test_decodeToMechanisms_missing_data() {
        do {
            let _ = try AccountMigrationManager.decodeToMechanisms(url: URL(string: "otpauth-migration://offline?Missingdata=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgE")!)
            
            XCTFail("Decoding should have failed due to missing data")
        } catch AccountMigrationError.missingData {
            //all good
        } catch {
            XCTFail("Decoding should have failed due to missing data")
        }
    }
    
    
    func test_02_06_test_decodeToMechanisms_invalid_data() {
        do {
            let _ = try AccountMigrationManager.decodeToMechanisms(url: URL(string: "otpauth-migration://offline?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcm\\dlcm9jayACKAEwATgE")!)
            
            XCTFail("Decoding should have failed due to invalid data")
        } catch AccountMigrationError.failToDecodeData {
            //all good
        } catch {
            XCTFail("Decoding should have failed due to invalid data")
        }
    }
    
    
    //  MARK: - AccountMigrationManager.encode(urls:) tests
    
    func test_03_01_test_encode_urls_single_url() {
        do {
            let migrationUri = try AccountMigrationManager.encode(urls: [URL(string:"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=4&algorithm=SHA256")!])
            
            XCTAssertNotNil(migrationUri)
            XCTAssertEqual(migrationUri?.scheme, "otpauth-migration")
            XCTAssertEqual(migrationUri?.host, "offline")
            
            let data = migrationUri?.valueOf("data")
            XCTAssertNotNil(data)
            
            let decodedData = data?.decodeBase64()
            XCTAssertNotNil(decodedData)
            
            let migrationPayload = try MigrationPayload(serializedData: decodedData!)
            XCTAssertNotNil(migrationPayload)
            
            let otpParameters = migrationPayload.otpParameters
            XCTAssertEqual(otpParameters.count, 1)
            
            XCTAssertEqual(otpParameters.first?.type, MigrationPayload.OtpType.hotp)
            
            XCTAssertEqual(otpParameters.first?.name, "demo")
            XCTAssertEqual(otpParameters.first?.secret, "IJQWIZ3FOIQUEYLE".base32Decode())
            XCTAssertEqual(otpParameters.first?.counter, 4)
            XCTAssertEqual(otpParameters.first?.issuer, "Forgerock")
            XCTAssertEqual(otpParameters.first?.algorithm, MigrationPayload.Algorithm.sha256)
            
        } catch {
            XCTFail("AccountMigrationManager.encode(urls:) failed with unexpected reason")
        }
    }
    
    
    func test_03_02_test_encode_urls_multiple_urls() {
        do {
            let migrationUri = try AccountMigrationManager.encode(urls: [URL(string:"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=4&algorithm=SHA256")!, URL(string:"otpauth://totp/Forgerock1:demo1?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock1&digits=6&period=30")!, URL(string:"otpauth://hotp/Forgerock2:demo2?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock2&counter=4&algorithm=SHA256")!, URL(string:"otpauth://hotp/Forgerock3:demo3?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock3&algorithm=sha256")!, URL(string:"otpauth://hotp/Forgerock4:demo4?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock4&algorithm=md5")!])
            
            XCTAssertNotNil(migrationUri)
            XCTAssertEqual(migrationUri?.scheme, "otpauth-migration")
            XCTAssertEqual(migrationUri?.host, "offline")
            
            let data = migrationUri?.valueOf("data")
            XCTAssertNotNil(data)
            
            let decodedData = data?.decodeBase64()
            XCTAssertNotNil(decodedData)
            
            let migrationPayload = try MigrationPayload(serializedData: decodedData!)
            XCTAssertNotNil(migrationPayload)
            
            let otpParameters = migrationPayload.otpParameters
            XCTAssertEqual(otpParameters.count, 5)
            
            XCTAssertEqual(otpParameters[0].type, MigrationPayload.OtpType.hotp)
            XCTAssertEqual(otpParameters[1].type, MigrationPayload.OtpType.totp)
            XCTAssertEqual(otpParameters[2].type, MigrationPayload.OtpType.hotp)
            XCTAssertEqual(otpParameters[3].type, MigrationPayload.OtpType.hotp)
            XCTAssertEqual(otpParameters[4].type, MigrationPayload.OtpType.hotp)
            
            XCTAssertEqual(otpParameters[0].name, "demo")
            XCTAssertEqual(otpParameters[1].digits, MigrationPayload.DigitCount.six)
            XCTAssertEqual(otpParameters[2].secret, "IJQWIZ3FOIQUEYLE".base32Decode())
            XCTAssertEqual(otpParameters[2].counter, 4)
            XCTAssertEqual(otpParameters[3].issuer, "Forgerock3")
            XCTAssertEqual(otpParameters[4].algorithm, MigrationPayload.Algorithm.md5)
            
        } catch {
            XCTFail("AccountMigrationManager.encode(urls) failed with unexpected reason")
        }
    }
    
    
    func test_03_03_test_encode_urls_ten_urls() {
        do {
            let migrationUri = try AccountMigrationManager.encode(urls: [URL(string:"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=4&algorithm=SHA256")!, URL(string:"otpauth://totp/Forgerock1:demo1?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock1&digits=6&period=30")!, URL(string:"otpauth://hotp/Forgerock2:demo2?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock2&counter=4&algorithm=SHA256")!, URL(string:"otpauth://hotp/Forgerock3:demo3?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock3&algorithm=sha256")!, URL(string:"otpauth://hotp/Forgerock4:demo4?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock4&algorithm=md5")!, URL(string:"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=4&algorithm=SHA256")!, URL(string:"otpauth://totp/Forgerock1:demo1?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock1&digits=6&period=30")!, URL(string:"otpauth://hotp/Forgerock2:demo2?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock2&counter=4&algorithm=SHA256")!, URL(string:"otpauth://hotp/Forgerock3:demo3?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock3&algorithm=sha256")!, URL(string:"otpauth://hotp/Forgerock4:demo4?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock4&algorithm=md5")!])
            
            XCTAssertNotNil(migrationUri)
            XCTAssertEqual(migrationUri?.scheme, "otpauth-migration")
            XCTAssertEqual(migrationUri?.host, "offline")
            
            let data = migrationUri?.valueOf("data")
            XCTAssertNotNil(data)
            
            let decodedData = data?.decodeBase64()
            XCTAssertNotNil(decodedData)
            
            let migrationPayload = try MigrationPayload(serializedData: decodedData!)
            XCTAssertNotNil(migrationPayload)
            
            let otpParameters = migrationPayload.otpParameters
            XCTAssertEqual(otpParameters.count, 10)
            
        } catch {
            XCTFail("AccountMigrationManager.encode(urls:) failed with unexpected reason")
        }
    }
    
    
    func test_03_04_test_encode_urls_some_invalid() {
        do {
            let migrationUri = try AccountMigrationManager.encode(urls: [URL(string:"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=4&algorithm=SHA256")!, URL(string:"otpauth://totp/Forgerock1:demo1?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock1&digits=6&period=30")!, URL(string:"otpauth://hofffftp/Forgerock2:demo2?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock2&counter=4&algorithm=SHA256")!, URL(string:"otpauth://hotp/Forgerock3:demo3?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock3&algorithm=sha256")!, URL(string:"otpauth://hotp/Forgerock4:demo4?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock4&algorithm=md5")!, URL(string:"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=4&algorithm=SHA256")!, URL(string:"otpaufffffth://totp/Forgerock1:demo1?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock1&digits=6&period=30")!, URL(string:"otpauth://hotp/Forgerock2:demo2?secret=IJQWI\\Z3FOIQUEYLE&issuer=Forgerock2&counter=4&algorithm=SHA256")!, URL(string:"otpauth://hotp/Forgerock3:demo3?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock3&algorithm=sha256")!, URL(string:"otpauth://hotp/Forgerock4:demo4?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock4&algorithm=md5")!])
            
            XCTAssertNotNil(migrationUri)
            XCTAssertEqual(migrationUri?.scheme, "otpauth-migration")
            XCTAssertEqual(migrationUri?.host, "offline")
            
            let data = migrationUri?.valueOf("data")
            XCTAssertNotNil(data)
            
            let decodedData = data?.decodeBase64()
            XCTAssertNotNil(decodedData)
            
            let migrationPayload = try MigrationPayload(serializedData: decodedData!)
            XCTAssertNotNil(migrationPayload)
            
            let otpParameters = migrationPayload.otpParameters
            //Should be 7 as 3 of the urls are invalid
            XCTAssertEqual(otpParameters.count, 7)
            
        } catch {
            XCTFail("AccountMigrationManager.encode(urls:) failed with unexpected reason")
        }
    }
    
    
    //  MARK: - AccountMigrationManager.encode(mechanisms:) tests
    
    func test_04_01_test_encode_mechanisms_single_mechanism() {
        do {
            let hotpMechanism = HOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256", counter: 6, digits: 6)
            let migrationUri = try AccountMigrationManager.encode(mechanisms: [hotpMechanism])
            
            XCTAssertNotNil(migrationUri)
            XCTAssertEqual(migrationUri?.scheme, "otpauth-migration")
            XCTAssertEqual(migrationUri?.host, "offline")
            
            let data = migrationUri?.valueOf("data")
            XCTAssertNotNil(data)
            
            let decodedData = data?.decodeBase64()
            XCTAssertNotNil(decodedData)
            
            let migrationPayload = try MigrationPayload(serializedData: decodedData!)
            XCTAssertNotNil(migrationPayload)
            
            let otpParameters = migrationPayload.otpParameters
            XCTAssertEqual(otpParameters.count, 1)
            
            XCTAssertEqual(otpParameters.first?.type, MigrationPayload.OtpType.hotp)
            
            XCTAssertEqual(otpParameters.first?.name, "demo")
            XCTAssertEqual(otpParameters.first?.secret, "T7SIIEPTZJQQDSCB".base32Decode())
            XCTAssertEqual(otpParameters.first?.counter, 6)
            XCTAssertEqual(otpParameters.first?.issuer, "Forgerock")
            XCTAssertEqual(otpParameters.first?.digits, MigrationPayload.DigitCount.six)
            XCTAssertEqual(otpParameters.first?.algorithm, MigrationPayload.Algorithm.sha256)
            
        } catch {
            XCTFail("AccountMigrationManager.encode(urls:) failed with unexpected reason")
        }
    }
    
    
    func test_04_02_test_encode_mechanisms_multiple_mechanisms() {
        do {
            let hotpMechanism1 = HOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256", counter: 6, digits: 6)
            let totpMechanism1 = TOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256", period: 30, digits: 6)
            let hotpMechanism2 = HOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "IJQWIZ3FOIQUEYLE", algorithm: "sha256", counter: 6, digits: 8)
            let totpMechanism2 = TOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "IJQWIZ3FOIQUEYLE", algorithm: "sha256", period: 30, digits: 8)
            
            let migrationUri = try AccountMigrationManager.encode(mechanisms: [hotpMechanism1, totpMechanism1, hotpMechanism2, totpMechanism2])
            
            XCTAssertNotNil(migrationUri)
            XCTAssertEqual(migrationUri?.scheme, "otpauth-migration")
            XCTAssertEqual(migrationUri?.host, "offline")
            
            let data = migrationUri?.valueOf("data")
            XCTAssertNotNil(data)
            
            let decodedData = data?.decodeBase64()
            XCTAssertNotNil(decodedData)
            
            let migrationPayload = try MigrationPayload(serializedData: decodedData!)
            XCTAssertNotNil(migrationPayload)
            
            let otpParameters = migrationPayload.otpParameters
            XCTAssertEqual(otpParameters.count, 4)
            
        } catch {
            XCTFail("AccountMigrationManager.encode(urls:) failed with unexpected reason")
        }
    }
    
    
    func test_04_03_test_encode_mechanisms_some_invalid() {
        do {
            let hotpMechanism1 = HOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256", counter: 6, digits: 6)
            let totpMechanism1 = TOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256", period: 30, digits: 6)
            let hotpMechanism2 = HOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "IJQWIZ3FOIQUEYLE", algorithm: "sha256", counter: 6, digits: 8)
            let totpMechanism2 = TOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "IJQWIZ3FOIQUEYLE", algorithm: "sha256", period: 30, digits: 8)
            let mechanism = OathMechanism(type: "someType", issuer: "Forgerock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256")
            
            let migrationUri = try AccountMigrationManager.encode(mechanisms: [hotpMechanism1, totpMechanism1, hotpMechanism2, totpMechanism2, mechanism])
            
            XCTAssertNotNil(migrationUri)
            XCTAssertEqual(migrationUri?.scheme, "otpauth-migration")
            XCTAssertEqual(migrationUri?.host, "offline")
            
            let data = migrationUri?.valueOf("data")
            XCTAssertNotNil(data)
            
            let decodedData = data?.decodeBase64()
            XCTAssertNotNil(decodedData)
            
            let migrationPayload = try MigrationPayload(serializedData: decodedData!)
            XCTAssertNotNil(migrationPayload)
            
            let otpParameters = migrationPayload.otpParameters
            // The last mehcanism should be ignores as it's wrong type
            XCTAssertEqual(otpParameters.count, 4)
            
        } catch {
            XCTFail("AccountMigrationManager.encode(urls:) failed with unexpected reason")
        }
    }
    
    
    //  MARK: - AccountMigrationManager.createMechanism(url:) tests
    
    func test_05_01_createMechanism_with_url_hotp() {
        
        let mechanism = AccountMigrationManager.createMechanism(url: URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=4&algorithm=SHA256")!)
        
        XCTAssertNotNil(mechanism)
        
        let hotpMechanism = mechanism as? HOTPMechanism
        XCTAssertNotNil(hotpMechanism)
        
        XCTAssertEqual(hotpMechanism?.type, "hotp")
        XCTAssertEqual(hotpMechanism?.secret, "IJQWIZ3FOIQUEYLE")
        XCTAssertEqual(hotpMechanism?.issuer, "Forgerock")
        XCTAssertEqual(hotpMechanism?.accountName, "demo")
        XCTAssertEqual(hotpMechanism?.counter, 4)
        XCTAssertEqual(hotpMechanism?.algorithm, OathAlgorithm.sha256)
    }
    
    
    func test_05_02_createMechanism_with_url_totp() {
        
        let mechanism = AccountMigrationManager.createMechanism(url: URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=8&period=45&algorithm=SHA256")!)
        
        XCTAssertNotNil(mechanism)
        
        let totpMechanism = mechanism as? TOTPMechanism
        XCTAssertNotNil(totpMechanism)
        
        XCTAssertEqual(totpMechanism?.type, "totp")
        XCTAssertEqual(totpMechanism?.secret, "T7SIIEPTZJQQDSCB")
        XCTAssertEqual(totpMechanism?.issuer, "ForgeRock")
        XCTAssertEqual(totpMechanism?.accountName, "demo")
        XCTAssertEqual(totpMechanism?.digits, 8)
        XCTAssertEqual(totpMechanism?.period, 45)
        XCTAssertEqual(totpMechanism?.algorithm, OathAlgorithm.sha256)
    }
    
    
    func test_05_03_createMechanism_with_url_wrong_host() {
        
        let mechanism = AccountMigrationManager.createMechanism(url: URL(string: "otpauth://someHost/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=8&period=45&algorithm=SHA256")!)
        
        XCTAssertNil(mechanism)
    }
    
    
    func test_05_04_createMechanism_with_url_wrong_scheme() {
        
        let mechanism = AccountMigrationManager.createMechanism(url: URL(string: "otpauth://totp/ForgeRock:demo?\\secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=8&period=45&algorithm=SHA256")!)
        
        XCTAssertNil(mechanism)
    }
    
    
    func test_05_05_createMechanism_with_url_wrong_url() {
        
        let mechanism = AccountMigrationManager.createMechanism(url: URL(string: "someScheme://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=8&period=45&algorithm=SHA256")!)
        
        XCTAssertNil(mechanism)
    }
    
    
    //  MARK: - AccountMigrationManager.createUrl(mechanism:) tests
    
    func test_06_01_createUrl_with_mechanism_hotp(){
        
        let hotpMechanism = HOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256", counter: 6, digits: 4)
        
        let url = AccountMigrationManager.createUrl(mechanism: hotpMechanism)
        
        XCTAssertNotNil(url)
        
        XCTAssertEqual(url?.scheme, "otpauth")
        XCTAssertEqual(url?.host, hotpMechanism.type)
        XCTAssertEqual(url?.valueOf("secret"), hotpMechanism.secret)
        XCTAssertEqual(url?.valueOf("issuer"), hotpMechanism.issuer)
        XCTAssertEqual(url?.valueOf("algorithm"), hotpMechanism.algorithm.rawValue)
        XCTAssertEqual(url?.valueOf("counter"), String(hotpMechanism.counter))
        XCTAssertEqual(url?.valueOf("digits"), String(hotpMechanism.digits))
    }
    
    
    func test_06_02_createUrl_with_mechanism_totp() {
        
        let totpMechanism = TOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256", period: 30, digits: 4)
        
        let url = AccountMigrationManager.createUrl(mechanism: totpMechanism)
        
        XCTAssertNotNil(url)
        
        XCTAssertEqual(url?.scheme, "otpauth")
        XCTAssertEqual(url?.host, totpMechanism.type)
        XCTAssertEqual(url?.valueOf("secret"), totpMechanism.secret)
        XCTAssertEqual(url?.valueOf("issuer"), totpMechanism.issuer)
        XCTAssertEqual(url?.valueOf("algorithm"), totpMechanism.algorithm.rawValue)
        XCTAssertEqual(url?.valueOf("period"), String(totpMechanism.period))
        XCTAssertEqual(url?.valueOf("digits"), String(totpMechanism.digits))
    }
    
    
    func test_06_03_createUrl_with_mechanism_wrong_type() {
        
        let mechanism = OathMechanism(type: "someType", issuer: "Forgerock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256")
        
        let url = AccountMigrationManager.createUrl(mechanism: mechanism)
        XCTAssertNil(url)
    }
}
