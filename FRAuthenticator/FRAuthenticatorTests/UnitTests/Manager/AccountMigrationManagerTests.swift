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
    
    //  MARK: - AccountMigrationManager.decode(url:) tests
    
    func test_01_01_test_decodeToURLs_single_url() {
        do {
            let urls = try AccountMigrationManager.decode(url: URL(string: "otpauth-migration://offline?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgE")!)
            
            XCTAssertEqual(urls.count, 1)
            
            let url = urls.first!
            
            XCTAssertEqual(url.scheme, "otpauth")
            XCTAssertEqual(url.host, "hotp")
            XCTAssertEqual(url.valueOf("secret"), "IJQWIZ3FOIQUEYLE")
            XCTAssertEqual(url.valueOf("issuer"), "Forgerock")
            XCTAssertEqual(url.valueOf("counter"), "4")
            XCTAssertEqual(url.valueOf("algorithm"), "sha256")
        } catch {
            XCTFail("AccountMigrationManager.decode(url:) failed with unexpected reason")
        }
    }
    
    
    func test_01_02_test_decodeToURLs_two_different_types() {
        do {
            let urls = try AccountMigrationManager.decode(url: URL(string: "otpauth-migration://offline?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgECiMKCp/khBHzymEByEESBGRlbW8aCUZvcmdlUm9jayABKAEwAg%3D%3D")!)
            
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
            XCTFail("AccountMigrationManager.decode(url:) failed with unexpected reason")
        }
    }
    
    
    func test_01_03_test_decodeToURLs_ten_urls() {
        do {
            let urls = try AccountMigrationManager.decode(url: URL(string: "otpauth-migration://offline?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgECiUKCp/khBHzymEByEESBWRlbW8xGgpGb3JnZVJvY2sxIAEoATACCicKCkJhZGdlciFCYWQSBWRlbW8yGgpGb3JnZXJvY2syIAIoATABOAQKJQoKQmFkZ2VyIUJhZBIFZGVtbzMaCkZvcmdlcm9jazMgAigBMAEKJQoKQmFkZ2VyIUJhZBIFZGVtbzQaCkZvcmdlcm9jazQgBCgBMAEKJQoKQmFkZ2VyIUJhZBIEZGVtbxoJRm9yZ2Vyb2NrIAIoATABOAQKJQoKn+SEEfPKYQHIQRIFZGVtbzEaCkZvcmdlUm9jazEgASgBMAIKJwoKQmFkZ2VyIUJhZBIFZGVtbzIaCkZvcmdlcm9jazIgAigBMAE4BAolCgpCYWRnZXIhQmFkEgVkZW1vMxoKRm9yZ2Vyb2NrMyACKAEwAQolCgpCYWRnZXIhQmFkEgVkZW1vNBoKRm9yZ2Vyb2NrNCAEKAEwAQ%3D%3D")!)
            
            XCTAssertEqual(urls.count, 10)
            
        } catch {
            XCTFail("AccountMigrationManager.decode(url:) failed with unexpected reason")
        }
    }
    
    
    func test_01_04_test_decodeToURLs_wrong_scheme() {
        do {
            let _ = try AccountMigrationManager.decode(url: URL(string: "otpauth-migrationxxx://offline?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgE")!)
            
            XCTFail("Decoding should have failed due to wrong scheme")
        } catch AccountMigrationError.invalidScheme {
            //all good
        } catch {
            XCTFail("Decoding should have failed due to wrong scheme")
        }
    }
    
    
    func test_01_05_test_decodeToURLs_wrong_host() {
        do {
            let _ = try AccountMigrationManager.decode(url: URL(string: "otpauth-migration://offlinexxx?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgE")!)
            
            XCTFail("Decoding should have failed due to wrong host")
        } catch AccountMigrationError.invalidHost {
            //all good
        } catch {
            XCTFail("Decoding should have failed due to wrong host")
        }
    }
    
    
    func test_01_06_test_decodeToURLs_missing_data() {
        do {
            let _ = try AccountMigrationManager.decode(url: URL(string: "otpauth-migration://offline?Missingdata=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgE")!)
            
            XCTFail("Decoding should have failed due to missing data")
        } catch AccountMigrationError.missingData {
            //all good
        } catch {
            XCTFail("Decoding should have failed due to missing data")
        }
    }
    
    
    func test_01_07_test_decodeToURLs_invalid_data() {
        do {
            let _ = try AccountMigrationManager.decode(url: URL(string: "otpauth-migration://offline?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcm_dlcm9jayACKAEwATgE")!)
            
            XCTFail("Decoding should have failed due to invalid data")
        } catch AccountMigrationError.failToDecodeData {
            //all good
        } catch {
            XCTFail("Decoding should have failed due to invalid data")
        }
    }
    
    
    //  MARK: - AccountMigrationManager.decodeToAccounts(url:) tests
    
    func test_02_01_test_decodeToAccounts_single_accounts() {
        do {
            let accounts = try AccountMigrationManager.decodeToAccounts(url: URL(string: "otpauth-migration://offline?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgE")!)
            
            
            XCTAssertEqual(accounts.count, 1)
            XCTAssertEqual(accounts.first?.mechanisms.count, 1)
            
            let mechanism = accounts.first!.mechanisms.first! as! OathMechanism
            
            XCTAssertEqual(mechanism.type, AuthType.hotp.rawValue)
            XCTAssertEqual(mechanism.secret, "IJQWIZ3FOIQUEYLE")
            XCTAssertEqual(mechanism.issuer, "Forgerock")
            XCTAssertEqual(mechanism.algorithm, OathAlgorithm.sha256)
        } catch {
            XCTFail("AccountMigrationManager.decode(url:) failed with unexpected reason")
        }
    }
    
    
    func test_02_02_test_decodeToAccounts_ten_accounts() {
        do {
            let accounts = try AccountMigrationManager.decodeToAccounts(url: URL(string: "otpauth-migration://offline?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgECiUKCp/khBHzymEByEESBWRlbW8xGgpGb3JnZVJvY2sxIAEoATACCicKCkJhZGdlciFCYWQSBWRlbW8yGgpGb3JnZXJvY2syIAIoATABOAQKJQoKQmFkZ2VyIUJhZBIFZGVtbzMaCkZvcmdlcm9jazMgAigBMAEKJQoKQmFkZ2VyIUJhZBIFZGVtbzQaCkZvcmdlcm9jazQgBCgBMAEKJQoKQmFkZ2VyIUJhZBIEZGVtbxoJRm9yZ2Vyb2NrIAIoATABOAQKJQoKn+SEEfPKYQHIQRIFZGVtbzEaCkZvcmdlUm9jazEgASgBMAIKJwoKQmFkZ2VyIUJhZBIFZGVtbzIaCkZvcmdlcm9jazIgAigBMAE4BAolCgpCYWRnZXIhQmFkEgVkZW1vMxoKRm9yZ2Vyb2NrMyACKAEwAQolCgpCYWRnZXIhQmFkEgVkZW1vNBoKRm9yZ2Vyb2NrNCAEKAEwAQ%3D%3D")!)
            
            XCTAssertEqual(accounts.count, 10)
            XCTAssertEqual(accounts.map{ $0.mechanisms }.flatMap{ $0 }.count, 10)
            
        } catch {
            XCTFail("AccountMigrationManager.decode(url:) failed with unexpected reason")
        }
    }
    
    
    func test_02_03_test_decodeToAccounts_wrong_scheme() {
        do {
            let _ = try AccountMigrationManager.decodeToAccounts(url: URL(string: "otpauth-migrationxxx://offline?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgE")!)
            
            XCTFail("Decoding should have failed due to wrong scheme")
        } catch AccountMigrationError.invalidScheme {
            //all good
        } catch {
            XCTFail("Decoding should have failed due to wrong scheme")
        }
    }
    
    
    func test_02_04_test_decodeToAccounts_wrong_host() {
        do {
            let _ = try AccountMigrationManager.decodeToAccounts(url: URL(string: "otpauth-migration://offlinexxx?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgE")!)
            
            XCTFail("Decoding should have failed due to wrong host")
        } catch AccountMigrationError.invalidHost {
            //all good
        } catch {
            XCTFail("Decoding should have failed due to wrong host")
        }
    }
    
    
    func test_02_05_test_decodeToAccounts_missing_data() {
        do {
            let _ = try AccountMigrationManager.decodeToAccounts(url: URL(string: "otpauth-migration://offline?Missingdata=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcmdlcm9jayACKAEwATgE")!)
            
            XCTFail("Decoding should have failed due to missing data")
        } catch AccountMigrationError.missingData {
            //all good
        } catch {
            XCTFail("Decoding should have failed due to missing data")
        }
    }
    
    
    func test_02_06_test_decodeToAccounts_invalid_data() {
        do {
            let _ = try AccountMigrationManager.decodeToAccounts(url: URL(string: "otpauth-migration://offline?data=CiUKCkJhZGdlciFCYWQSBGRlbW8aCUZvcm_dlcm9jayACKAEwATgE")!)
            
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
            let migrationUri = try AccountMigrationManager.encode(urls: [URL(string:"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=4&algorithm=SHA256")!, URL(string:"otpauth://totp/Forgerock1:demo1?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock1&digits=6&period=60")!, URL(string:"otpauth://hotp/Forgerock2:demo2?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock2&counter=4&algorithm=SHA256")!, URL(string:"otpauth://hotp/Forgerock3:demo3?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock3&algorithm=sha256")!, URL(string:"otpauth://hotp/Forgerock4:demo4?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock4&algorithm=md5")!])
            
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
            XCTAssertEqual(otpParameters[1].period, 60)
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
            let migrationUri = try AccountMigrationManager.encode(urls: [URL(string:"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=4&algorithm=SHA256")!, URL(string:"otpauth://totp/Forgerock1:demo1?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock1&digits=6&period=30")!, URL(string:"otpauth://hofffftp/Forgerock2:demo2?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock2&counter=4&algorithm=SHA256")!, URL(string:"otpauth://hotp/Forgerock3:demo3?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock3&algorithm=sha256")!, URL(string:"otpauth://hotp/Forgerock4:demo4?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock4&algorithm=md5")!, URL(string:"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=4&algorithm=SHA256")!, URL(string:"otpaufffffth://totp/Forgerock1:demo1?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock1&digits=6&period=30")!, URL(string:"otpauth://hotp/Forgerock2:demo2?secret=IJQWI_Z3FOIQUEYLE&issuer=Forgerock2&counter=4&algorithm=SHA256")!, URL(string:"otpauth://hotp/Forgerock3:demo3?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock3&algorithm=sha256")!, URL(string:"otpauth://hotp/Forgerock4:demo4?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock4&algorithm=md5")!])
            
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
    
    
    //  MARK: - AccountMigrationManager.encode(accounts:) tests
    
    func test_04_01_test_encode_accounts_single_accounts() {
        do {
            let hotpMechanism = HOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256", counter: 6, digits: 6)
            let account = Account(issuer: hotpMechanism.issuer, accountName: hotpMechanism.accountName)
            account.mechanisms.append(hotpMechanism)
            let migrationUri = try AccountMigrationManager.encode(accounts: [account])
            
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
    
    
    func test_04_02_test_encode_accounts_multiple_accounts() {
        do {
            let hotpMechanism1 = HOTPMechanism(issuer: "Forgerock1", accountName: "demo1", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256", counter: 6, digits: 6)
            let account1 = Account(issuer: hotpMechanism1.issuer, accountName: hotpMechanism1.accountName)
            account1.imageUrl = "https://upload.wikimedia.org/wikipedia/commons/e/e5/Forgerock_Logo_190px.png"
            account1.mechanisms.append(hotpMechanism1)
            
            let totpMechanism1 = TOTPMechanism(issuer: "Forgerock2", accountName: "demo2", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256", period: 60, digits: 6)
            let account2 = Account(issuer: totpMechanism1.issuer, accountName: totpMechanism1.accountName)
            account2.imageUrl = "https://upload.wikimedia.org/wikipedia/commons/e/e5/Forgerock_Logo_190px.png"
            account2.mechanisms.append(totpMechanism1)
            
            let hotpMechanism2 = HOTPMechanism(issuer: "Forgerock3", accountName: "demo4", secret: "IJQWIZ3FOIQUEYLE", algorithm: "sha256", counter: 6, digits: 8)
            let account3 = Account(issuer: hotpMechanism2.issuer, accountName: hotpMechanism2.accountName)
            account3.imageUrl = "https://upload.wikimedia.org/wikipedia/commons/e/e5/Forgerock_Logo_190px.png"
            account3.mechanisms.append(hotpMechanism2)
            
            let totpMechanism2 = TOTPMechanism(issuer: "Forgerock4", accountName: "demo4", secret: "IJQWIZ3FOIQUEYLE", algorithm: "sha256", period: 10, digits: 8)
            let account4 = Account(issuer: totpMechanism2.issuer, accountName: totpMechanism2.accountName)
            account4.imageUrl = "https://upload.wikimedia.org/wikipedia/commons/e/e5/Forgerock_Logo_190px.png"
            account4.mechanisms.append(totpMechanism2)
            
            let migrationUri = try AccountMigrationManager.encode(accounts: [account1, account2, account3, account4])
            
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
    
    
    func test_04_03_test_encode_accounts_some_invalid() {
        do {
            let hotpMechanism1 = HOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256", counter: 6, digits: 6)
            let account1 = Account(issuer: hotpMechanism1.issuer, accountName: hotpMechanism1.accountName)
            account1.imageUrl = "https://upload.wikimedia.org/wikipedia/commons/e/e5/Forgerock_Logo_190px.png"
            account1.mechanisms.append(hotpMechanism1)
            
            let totpMechanism1 = TOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256", period: 30, digits: 6)
            let account2 = Account(issuer: totpMechanism1.issuer, accountName: totpMechanism1.accountName)
            account2.imageUrl = "https://upload.wikimedia.org/wikipedia/commons/e/e5/Forgerock_Logo_190px.png"
            account2.mechanisms.append(totpMechanism1)
            
            let hotpMechanism2 = HOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "IJQWIZ3FOIQUEYLE", algorithm: "sha256", counter: 6, digits: 8)
            let account3 = Account(issuer: hotpMechanism2.issuer, accountName: hotpMechanism2.accountName)
            account3.imageUrl = "https://upload.wikimedia.org/wikipedia/commons/e/e5/Forgerock_Logo_190px.png"
            account3.mechanisms.append(hotpMechanism2)
            
            let totpMechanism2 = TOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "IJQWIZ3FOIQUEYLE", algorithm: "sha256", period: 30, digits: 8)
            let account4 = Account(issuer: totpMechanism2.issuer, accountName: totpMechanism2.accountName)
            account4.imageUrl = "https://upload.wikimedia.org/wikipedia/commons/e/e5/Forgerock_Logo_190px.png"
            account4.mechanisms.append(totpMechanism2)
            
            let mechanism = OathMechanism(type: "someType", issuer: "Forgerock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256")
            let account = Account(issuer: mechanism.issuer, accountName: mechanism.accountName)
            account.imageUrl = "https://upload.wikimedia.org/wikipedia/commons/e/e5/Forgerock_Logo_190px.png"
            account.mechanisms.append(mechanism)
            
            let migrationUri = try AccountMigrationManager.encode(accounts: [account, account1, account2, account3, account4])
            
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
    
    
    //  MARK: - AccountMigrationManager.createAccount(url:) tests
    
    func test_05_01_createAccount_with_url_hotp() {
        
        let account = AccountMigrationManager.createAccount(url: URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=4&algorithm=SHA256")!)
        
        XCTAssertNotNil(account)
        XCTAssertNotNil(account?.mechanisms.first)
        
        let hotpMechanism = account?.mechanisms.first as? HOTPMechanism
        XCTAssertNotNil(hotpMechanism)
        
        XCTAssertEqual(hotpMechanism?.type, "hotp")
        XCTAssertEqual(hotpMechanism?.secret, "IJQWIZ3FOIQUEYLE")
        XCTAssertEqual(hotpMechanism?.issuer, "Forgerock")
        XCTAssertEqual(hotpMechanism?.accountName, "demo")
        XCTAssertEqual(hotpMechanism?.counter, 4)
        XCTAssertEqual(hotpMechanism?.algorithm, OathAlgorithm.sha256)
    }
    
    
    func test_05_02_createAccount_with_url_totp() {
        
        let account = AccountMigrationManager.createAccount(url: URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=8&period=45&algorithm=SHA256")!)
        
        XCTAssertNotNil(account)
        XCTAssertNotNil(account?.mechanisms.first)
        
        let totpMechanism = account?.mechanisms.first as? TOTPMechanism
        XCTAssertNotNil(totpMechanism)
        
        XCTAssertEqual(totpMechanism?.type, "totp")
        XCTAssertEqual(totpMechanism?.secret, "T7SIIEPTZJQQDSCB")
        XCTAssertEqual(totpMechanism?.issuer, "ForgeRock")
        XCTAssertEqual(totpMechanism?.accountName, "demo")
        XCTAssertEqual(totpMechanism?.digits, 8)
        XCTAssertEqual(totpMechanism?.period, 45)
        XCTAssertEqual(totpMechanism?.algorithm, OathAlgorithm.sha256)
    }
    
    
    func test_05_03_createAcccount_with_url_wrong_host() {
        
        let account = AccountMigrationManager.createAccount(url: URL(string: "otpauth://someHost/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=8&period=45&algorithm=SHA256")!)
        
        XCTAssertNil(account)
    }
    
    
    func test_05_04_createAccount_with_url_wrong_scheme() {
        
        let account = AccountMigrationManager.createAccount(url: URL(string: "otpauth://totp/ForgeRock:demo?_secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=8&period=45&algorithm=SHA256")!)
        
        XCTAssertNil(account)
    }
    
    
    func test_05_05_createAccount_with_url_wrong_url() {
        
        let account = AccountMigrationManager.createAccount(url: URL(string: "someScheme://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=8&period=45&algorithm=SHA256")!)
        
        XCTAssertNil(account)
    }
    
    
    //  MARK: - AccountMigrationManager.createUrl(mechanism:) tests
    
    func test_06_01_createUrl_with_mechanism_hotp(){
        
        let hotpMechanism = HOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256", counter: 6, digits: 4)
        let imageUrl = "https://upload.wikimedia.org/wikipedia/commons/e/e5/Forgerock_Logo_190px.png"
        
        let url = AccountMigrationManager.createUrl(mechanism: hotpMechanism, imageUrl: imageUrl)
        
        XCTAssertNotNil(url)
        
        XCTAssertEqual(url?.scheme, "otpauth")
        XCTAssertEqual(url?.host, hotpMechanism.type)
        XCTAssertEqual(url?.valueOf("secret"), hotpMechanism.secret)
        XCTAssertEqual(url?.valueOf("issuer"), hotpMechanism.issuer)
        XCTAssertEqual(url?.valueOf("algorithm"), hotpMechanism.algorithm.rawValue)
        XCTAssertEqual(url?.valueOf("counter"), String(hotpMechanism.counter))
        XCTAssertEqual(url?.valueOf("digits"), String(hotpMechanism.digits))
        XCTAssertEqual(url?.valueOf("image"), imageUrl.base64URLSafeEncoded())
    }
    
    
    func test_06_02_createUrl_with_mechanism_totp() {
        
        let totpMechanism = TOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256", period: 90, digits: 4)
        let imageUrl = "https://upload.wikimedia.org/wikipedia/commons/e/e5/Forgerock_Logo_190px.png"
        
        let url = AccountMigrationManager.createUrl(mechanism: totpMechanism, imageUrl: imageUrl)
        
        XCTAssertNotNil(url)
        
        XCTAssertEqual(url?.scheme, "otpauth")
        XCTAssertEqual(url?.host, totpMechanism.type)
        XCTAssertEqual(url?.valueOf("secret"), totpMechanism.secret)
        XCTAssertEqual(url?.valueOf("issuer"), totpMechanism.issuer)
        XCTAssertEqual(url?.valueOf("algorithm"), totpMechanism.algorithm.rawValue)
        XCTAssertEqual(url?.valueOf("period"), String(totpMechanism.period))
        XCTAssertEqual(url?.valueOf("digits"), String(totpMechanism.digits))
        XCTAssertEqual(url?.valueOf("image"), imageUrl.base64URLSafeEncoded())
    }
    
    
    func test_06_03_createUrl_with_mechanism_wrong_type() {
        
        let mechanism = OathMechanism(type: "someType", issuer: "Forgerock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256")
        
        let url = AccountMigrationManager.createUrl(mechanism: mechanism, imageUrl: nil)
        XCTAssertNil(url)
    }
    
    
    //  MARK: - AccountMigrationManager.createUrls(account:) tests
    
    func test_07_01_createUrls_with_account_hotp(){
        
        let hotpMechanism = HOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256", counter: 6, digits: 4)
        let imageUrl = "https://upload.wikimedia.org/wikipedia/commons/e/e5/Forgerock_Logo_190px.png"
        
        let account = Account(issuer: hotpMechanism.issuer, accountName: hotpMechanism.accountName)
        account.imageUrl = imageUrl
        account.mechanisms.append(hotpMechanism)
        
        let urls = AccountMigrationManager.createUrls(account: account)
        
        XCTAssertEqual(urls.count, 1)
        XCTAssertNotNil(urls.first)
        
        let url = urls.first
        
        XCTAssertEqual(url?.scheme, "otpauth")
        XCTAssertEqual(url?.host, hotpMechanism.type)
        XCTAssertEqual(url?.valueOf("secret"), hotpMechanism.secret)
        XCTAssertEqual(url?.valueOf("issuer"), hotpMechanism.issuer)
        XCTAssertEqual(url?.valueOf("algorithm"), hotpMechanism.algorithm.rawValue)
        XCTAssertEqual(url?.valueOf("counter"), String(hotpMechanism.counter))
        XCTAssertEqual(url?.valueOf("digits"), String(hotpMechanism.digits))
        XCTAssertEqual(url?.valueOf("image"), imageUrl.base64URLSafeEncoded())
    }
    
    
    func test_07_02_createUrl_with_account_totp() {
        
        let totpMechanism = TOTPMechanism(issuer: "Forgerock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256", period: 90, digits: 4)
        let imageUrl = "https://upload.wikimedia.org/wikipedia/commons/e/e5/Forgerock_Logo_190px.png"
        
        let account = Account(issuer: totpMechanism.issuer, accountName: totpMechanism.accountName)
        account.imageUrl = imageUrl
        account.mechanisms.append(totpMechanism)
        
        let urls = AccountMigrationManager.createUrls(account: account)
        
        XCTAssertEqual(urls.count, 1)
        XCTAssertNotNil(urls.first)
        
        let url = urls.first
        
        XCTAssertEqual(url?.scheme, "otpauth")
        XCTAssertEqual(url?.host, totpMechanism.type)
        XCTAssertEqual(url?.valueOf("secret"), totpMechanism.secret)
        XCTAssertEqual(url?.valueOf("issuer"), totpMechanism.issuer)
        XCTAssertEqual(url?.valueOf("algorithm"), totpMechanism.algorithm.rawValue)
        XCTAssertEqual(url?.valueOf("period"), String(totpMechanism.period))
        XCTAssertEqual(url?.valueOf("digits"), String(totpMechanism.digits))
        XCTAssertEqual(url?.valueOf("image"), imageUrl.base64URLSafeEncoded())
    }
    
    
    func test_07_03_createUrl_with_account_wrong_type() {
        
        let mechanism = OathMechanism(type: "someType", issuer: "Forgerock", accountName: "demo", secret: "T7SIIEPTZJQQDSCB", algorithm: "sha256")
        
        let account = Account(issuer: mechanism.issuer, accountName: mechanism.accountName)
        account.mechanisms.append(mechanism)
        
        let urls = AccountMigrationManager.createUrls(account: account)
        XCTAssertNil(urls.first)
    }
}
