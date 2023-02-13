// 
//  AuthenticatorManager.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class AuthenticatorManagerTests: FRABaseTests {

    func test_01_authenticator_manager_init() {
        let storageClient = KeychainServiceClient()
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        XCTAssertNotNil(storageClient)
        XCTAssertNotNil(authenticatorManager)
    }
    
    
    //  MARK: - Account store/remove/get
    
    func test_02_account_store_operation() {
        //  Given
        let storageClient = KeychainServiceClient()
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let account = Account(issuer: "issuer", accountName: "accountName", imageUrl: "imageUrl", backgroundColor: "#ffffff")
        
        do {
            //  When
            try authenticatorManager.storeAccount(account: account)
            let accountFromManager = authenticatorManager.getAccount(identifier: "issuer-accountName")
            
            //  Then
            XCTAssertNotNil(accountFromManager)
            XCTAssertEqual(accountFromManager?.issuer, account.issuer)
            XCTAssertEqual(accountFromManager?.accountName, account.accountName)
            XCTAssertEqual(accountFromManager?.imageUrl, account.imageUrl)
            XCTAssertEqual(accountFromManager?.backgroundColor, account.backgroundColor)
        }
        catch {
            XCTFail("Account store operation failed: \(error.localizedDescription)")
        }
    }
    
    
    func test_03_multiple_accounts_store_operation() {
        //  Given
        let storageClient = KeychainServiceClient()
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let account = Account(issuer: "issuer", accountName: "accountName", imageUrl: "imageUrl", backgroundColor: "#ffffff")
        let account1 = Account(issuer: "issuer1", accountName: "accountName1", imageUrl: "imageUrl1", backgroundColor: "#ffffff")
        let account2 = Account(issuer: "issuer2", accountName: "accountName2", imageUrl: "imageUrl2", backgroundColor: "#ffffff")
        
        do {
            //  When
            try authenticatorManager.storeAccount(account: account)
            try authenticatorManager.storeAccount(account: account1)
            
            //  Then
            var accounts = authenticatorManager.getAllAccounts()
            XCTAssertEqual(accounts.count, 2)
            try authenticatorManager.storeAccount(account: account2)
            accounts = authenticatorManager.getAllAccounts()
            XCTAssertEqual(accounts.count, 3)
            
            for acc in accounts {
                if acc.identifier != account.identifier && acc.identifier != account1.identifier && acc.identifier != account2.identifier {
                    XCTFail("Failed to find an Account object (\(acc.identifier)) from storage")
                }
            }
            
            //  When remove account1
            authenticatorManager.removeAccount(account: account1)
            accounts = authenticatorManager.getAllAccounts()
            XCTAssertEqual(accounts.count, 2)
            XCTAssertNil(authenticatorManager.getAccount(identifier: "issuer1-accountName1"))
            for acc in accounts {
                if acc.identifier != account.identifier && acc.identifier != account2.identifier {
                    XCTFail("Failed to find an Account object (\(acc.identifier)) from storage")
                }
            }
            
            //  When remove account2
            authenticatorManager.removeAccount(account: account2)
            accounts = authenticatorManager.getAllAccounts()
            XCTAssertNil(authenticatorManager.getAccount(identifier: "issuer2-accountName2"))
            XCTAssertEqual(accounts.count, 1)
            for acc in accounts {
                if acc.identifier != account.identifier {
                    XCTFail("Failed to find an Account object (\(acc.identifier)) from storage")
                }
            }
        }
        catch {
            XCTFail("Multiple Accounts store operation failed: \(error.localizedDescription)")
        }
    }
    
    
    func test_04_store_account_fail() {
        //  Given
        let storageClient = DummyStorageClient()
        storageClient.setAccountResult = false
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let account = Account(issuer: "issuer", accountName: "accountName", imageUrl: "imageUrl", backgroundColor: "#ffffff")
        
        do {
            try authenticatorManager.storeAccount(account: account)
            XCTFail("AuthenticatorManager.storeAccount() expected to fail; but passed")
        }
        catch FRAError.failToSaveIntoStorageClient(let message) {
            // Pass
            XCTAssertEqual(message, "Failed to store Account (\(account.identifier)) object into storage")
        }
        catch {
            XCTFail("AuthenticatorManager.storeAccount() failed with unexpected reason: \(error.localizedDescription)")
        }
    }
    
    
    func test_05_store_existing_account() {
        //  Given
        let authenticatorManager = AuthenticatorManager(storageClient: FRAClient.storage, policyEvaluator: FRAClient.policyEvaluator)
        let account = Account(issuer: "issuer", accountName: "accountName", imageUrl: "imageUrl", backgroundColor: "#ffffff")
        
        do {
            try authenticatorManager.storeAccount(account: account)
            let accountFromStorage = authenticatorManager.getAccount(identifier: account.identifier)
            let accountsFromStorage = authenticatorManager.getAllAccounts()
            XCTAssertNotNil(accountFromStorage)
            XCTAssertEqual(accountsFromStorage.count, 1)

            let account = Account(issuer: "issuer", accountName: "accountName", imageUrl: "imageUrl1", backgroundColor: "#000000")
            try authenticatorManager.storeAccount(account: account)
            let accountFromStorage1 = authenticatorManager.getAccount(identifier: account.identifier)
            let accountsFromStorage1 = authenticatorManager.getAllAccounts()
            XCTAssertNotNil(accountFromStorage1)
            XCTAssertEqual(accountsFromStorage1.count, 1)
            
            XCTAssertEqual(accountFromStorage1?.backgroundColor, "#000000")
            XCTAssertEqual(accountFromStorage1?.imageUrl, "imageUrl1")
        }
        catch {
            XCTFail("AuthenticatorManager.storeAccount() failed with unexpected reason: \(error.localizedDescription)")
        }
    }
    
    
    func test_06_remove_account_fail() {
        //  Given
        let storageClient = DummyStorageClient()
        storageClient.setAccountResult = true
        storageClient.removeAccountResult = false
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let account = Account(issuer: "issuer", accountName: "accountName", imageUrl: "imageUrl", backgroundColor: "#ffffff")
        
        do {
            try authenticatorManager.storeAccount(account: account)
            XCTAssertFalse(authenticatorManager.removeAccount(account: account))
        }
        catch {
            XCTFail("AuthenticatorManager.storeAccount() failed with unexpected reason: \(error.localizedDescription)")
        }
    }
    
    
    func test_06_1_account_auto_lock_operation_policy_pass() {
        do {
            //  Given
            let storageClient = KeychainServiceClient()
            let policyEvaluator = FRAPolicyEvaluator()
            try policyEvaluator.registerPolicies(policies: [DummyPolicy()])
            let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
            let account = Account(issuer: "Forgerock", displayIssuer: nil, accountName: "demo", displayAccountName: nil, imageUrl: nil, backgroundColor: nil, timeAdded: Date().timeIntervalSince1970, policies: "{\"dummy\": { }}", lockingPolicy: nil, lock: false)!
            
            //  When
            try authenticatorManager.storeAccount(account: account)
            let accountFromManager = authenticatorManager.getAccount(identifier: "Forgerock-demo")
            
            //  Then
            XCTAssertNotNil(accountFromManager)
            XCTAssertEqual(accountFromManager?.issuer, account.issuer)
            XCTAssertEqual(accountFromManager?.accountName, account.accountName)
            XCTAssertEqual(accountFromManager?.lock, false)
        }
        catch {
            XCTFail("Account auto lock operation failed: \(error.localizedDescription)")
        }
    }
    
    
    func test_06_2_account_auto_lock_operation_policy_fail() {
        do {
            //  Given
            let storageClient = KeychainServiceClient()
            let policyEvaluator = FRAPolicyEvaluator()
            try policyEvaluator.registerPolicies(policies: [DummyPolicy(), DummyWithDataPolicy()])
            let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
            let account = Account(issuer: "Forgerock", displayIssuer: nil, accountName: "demo", displayAccountName: nil, imageUrl: nil, backgroundColor: nil, timeAdded: Date().timeIntervalSince1970, policies: "{\"dummy\": { }, \"dummyWithData\": { \"result\" : false }}", lockingPolicy: nil, lock: false)!
            
            
            //  When
            try authenticatorManager.storeAccount(account: account)
            let accountFromManager = authenticatorManager.getAccount(identifier: "Forgerock-demo")
            
            //  Then
            XCTAssertNotNil(accountFromManager)
            XCTAssertEqual(accountFromManager?.issuer, account.issuer)
            XCTAssertEqual(accountFromManager?.accountName, account.accountName)
            XCTAssertEqual(accountFromManager?.lock, true)
        }
        catch {
            XCTFail("Account auto lock operation failed: \(error.localizedDescription)")
        }
    }
    
    
    func test_06_3_account_unlock_operation() {
        do {
            //  Given
            let storageClient = KeychainServiceClient()
            let policyEvaluator = FRAPolicyEvaluator()
            try policyEvaluator.registerPolicies(policies: [DummyPolicy(), DummyWithDataPolicy()])
            let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
            let account = Account(issuer: "Forgerock", displayIssuer: nil, accountName: "demo", displayAccountName: nil, imageUrl: nil, backgroundColor: nil, timeAdded: Date().timeIntervalSince1970, policies: "{\"dummy\": { }, \"dummyWithData\": { \"result\" : false }}", lockingPolicy: nil, lock: false)!
            
            //  When
            try authenticatorManager.storeAccount(account: account)
            let accountFromManager = authenticatorManager.getAccount(identifier: "Forgerock-demo")
            
            //  Then
            XCTAssertNotNil(accountFromManager)
            XCTAssertEqual(accountFromManager?.issuer, account.issuer)
            XCTAssertEqual(accountFromManager?.accountName, account.accountName)
            XCTAssertEqual(accountFromManager?.lock, true)
            
            try authenticatorManager.unlockAccount(account: accountFromManager!)
            XCTAssertEqual(accountFromManager?.lock, false)
            XCTAssertNil(accountFromManager?.lockingPolicy)
        }
        catch {
            XCTFail("Account unlock operation failed: \(error.localizedDescription)")
        }
    }
    
    
    func test_06_4_account_lock_operation() {
        do {
            //  Given
            let storageClient = KeychainServiceClient()
            let policyEvaluator = FRAPolicyEvaluator()
            try policyEvaluator.registerPolicies(policies: [DummyPolicy()])
            let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
            let account = Account(issuer: "Forgerock", displayIssuer: nil, accountName: "demo", displayAccountName: nil, imageUrl: nil, backgroundColor: nil, timeAdded: Date().timeIntervalSince1970, policies: "{\"dummy\": { }}", lockingPolicy: nil, lock: false)!
            
            //  When
            try authenticatorManager.storeAccount(account: account)
            let accountFromManager = authenticatorManager.getAccount(identifier: "Forgerock-demo")
            
            //  Then
            XCTAssertNotNil(accountFromManager)
            XCTAssertEqual(accountFromManager?.issuer, account.issuer)
            XCTAssertEqual(accountFromManager?.accountName, account.accountName)
            XCTAssertEqual(accountFromManager?.lock, false)
            
            try authenticatorManager.lockAccount(account: accountFromManager!, policy: DummyPolicy())
            XCTAssertEqual(accountFromManager?.lock, true)
            XCTAssertNotNil(accountFromManager?.lockingPolicy)
        }
        catch {
            XCTFail("Account lock operation failed: \(error.localizedDescription)")
        }
    }
    
    
    func test_06_5_account_lock_operation_fail_already_locked() {
        do {
            //  Given
            let storageClient = KeychainServiceClient()
            let policyEvaluator = FRAPolicyEvaluator()
            try policyEvaluator.registerPolicies(policies: [DummyPolicy(), DummyWithDataPolicy()])
            let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
            let account = Account(issuer: "Forgerock", displayIssuer: nil, accountName: "demo", displayAccountName: nil, imageUrl: nil, backgroundColor: nil, timeAdded: Date().timeIntervalSince1970, policies: "{\"dummy\": { }, \"dummyWithData\": { \"result\" : false }}", lockingPolicy: nil, lock: false)!
            
            //  When
            try authenticatorManager.storeAccount(account: account)
            let accountFromManager = authenticatorManager.getAccount(identifier: "Forgerock-demo")
            
            //  Then
            XCTAssertNotNil(accountFromManager)
            XCTAssertEqual(accountFromManager?.issuer, account.issuer)
            XCTAssertEqual(accountFromManager?.accountName, account.accountName)
            XCTAssertEqual(accountFromManager?.lock, true)
            
            XCTAssertThrowsError(try authenticatorManager.lockAccount(account: accountFromManager!, policy: DummyWithDataPolicy())) { error in
                guard case AccountError.failToLockAccountAlreadyLocked = error else {
                    return XCTFail()
                }
            }
            
        }
        catch {
            XCTFail("AuthenticatorManager.lockAccount() failed with unexpected reason: \(error.localizedDescription)")
        }
    }
    
    
    func test_06_6_account_lock_operation_fail_invalid_policy() {
        do {
            //  Given
            let storageClient = KeychainServiceClient()
            let policyEvaluator = FRAPolicyEvaluator()
            try policyEvaluator.registerPolicies(policies: [DummyPolicy()])
            let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
            let account = Account(issuer: "Forgerock", displayIssuer: nil, accountName: "demo", displayAccountName: nil, imageUrl: nil, backgroundColor: nil, timeAdded: Date().timeIntervalSince1970, policies: "{\"dummy\": { }}", lockingPolicy: nil, lock: false)!
            
            //  When
            try authenticatorManager.storeAccount(account: account)
            let accountFromManager = authenticatorManager.getAccount(identifier: "Forgerock-demo")
            
            //  Then
            XCTAssertNotNil(accountFromManager)
            XCTAssertEqual(accountFromManager?.issuer, account.issuer)
            XCTAssertEqual(accountFromManager?.accountName, account.accountName)
            XCTAssertEqual(accountFromManager?.lock, false)
            
            XCTAssertThrowsError(try authenticatorManager.lockAccount(account: accountFromManager!, policy: DummyWithDataPolicy())) { error in
                guard case AccountError.failToLockInvalidPolicy = error else {
                    return XCTFail()
                }
            }
        }
        catch {
            XCTFail("AuthenticatorManager.lockAccount() failed with unexpected reason: \(error.localizedDescription)")
        }
    }
    
    
    func test_06_7_account_unlock_operation_fail() {
        do {
            //  Given
            let storageClient = KeychainServiceClient()
            let policyEvaluator = FRAPolicyEvaluator()
            try policyEvaluator.registerPolicies(policies: [DummyPolicy()])
            let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
            let account = Account(issuer: "Forgerock", displayIssuer: nil, accountName: "demo", displayAccountName: nil, imageUrl: nil, backgroundColor: nil, timeAdded: Date().timeIntervalSince1970, policies: "{\"dummy\": { }}", lockingPolicy: nil, lock: false)!
            
            //  When
            try authenticatorManager.storeAccount(account: account)
            let accountFromManager = authenticatorManager.getAccount(identifier: "Forgerock-demo")
            
            //  Then
            XCTAssertNotNil(accountFromManager)
            XCTAssertEqual(accountFromManager?.issuer, account.issuer)
            XCTAssertEqual(accountFromManager?.accountName, account.accountName)
            XCTAssertEqual(accountFromManager?.lock, false)
            
            XCTAssertThrowsError(try authenticatorManager.unlockAccount(account: accountFromManager!)) { error in
                guard case AccountError.failToUnlockAccountNotLocked = error else {
                    return XCTFail()
                }
            }
        }
        catch {
            XCTFail("Account unlock operation failed: \(error.localizedDescription)")
        }
    }
    
    
    //  MARK: - storeOathQRCode - Push (Invalid)
    
    func test_07_store_invalid_oath_qrcode() {
        
        // Given
        let qrCode = URL(string: "pushauth://push/forgerock:pushreg3?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=5GuioYhLlh-xER3n5I8vrx0uuYQo3yD86aJi6KuWDsg&c=KP0XQfZ21N_jsXP_xfVQMmsmoUiWvdDPWecHdb5_INQ&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:a8970dea-3257-4be1-a37a-23eed2b692131588282723889&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!
        let authenticatorManager = AuthenticatorManager(storageClient: FRAClient.storage, policyEvaluator: FRAClient.policyEvaluator)
        
        
        do {
            let _ = try authenticatorManager.storeOathQRCode(uri: qrCode)
            XCTFail("AuthenticatorManager.storeOathQRCode with Push QR Code is expected to fail, but somehow passed")
        }
        catch MechanismError.invalidQRCode {
        }
        catch {
            XCTFail("AuthenticatorManager.storeOathQRCode with Push QR Code failed with unexpected reason")
        }
    }
    
    
    //  MARK: - storeOathQRCode - HOTP
    
    func test_08_store_hotp_oath_qrcode() {
        
        // Given
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=4&algorithm=SHA256")!
        let authenticatorManager = AuthenticatorManager(storageClient: FRAClient.storage, policyEvaluator: FRAClient.policyEvaluator)
        
        do {
            let mechanism = try authenticatorManager.storeOathQRCode(uri: qrCode)
            XCTAssertNotNil(mechanism)
            let accountFromStorage = authenticatorManager.getAccount(identifier: "Forgerock-demo")
            XCTAssertNotNil(accountFromStorage)
            XCTAssertNotNil(accountFromStorage?.mechanisms)
            XCTAssertEqual(accountFromStorage?.mechanisms.count, 1)
            XCTAssertEqual(accountFromStorage?.mechanisms.first?.identifier, mechanism.identifier)
        }
        catch {
            XCTFail("AuthenticatorManager.storeOathQRCode with HOTP QR Code failed with unexpected reason")
        }
    }
    
    func test_09_store_hotp_oath_qrcode_fail() {
        
        //  Given
        let storageClient = DummyStorageClient()
        storageClient.setMechanismResult = false
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=4&algorithm=SHA256")!
        
        do {
            let _ = try authenticatorManager.storeOathQRCode(uri: qrCode)
            XCTFail("AuthenticatorManager.storeOathQRCode is expected to fail, but somehow passed")
        }
        catch FRAError.failToSaveIntoStorageClient {
            XCTAssertEqual(authenticatorManager.getAllAccounts().count, 0)
            XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 0)
        }
        catch {
            XCTFail("AuthenticatorManager.storeOathQRCode failed with unexpected reason")
        }
    }
    
    
    func test_10_store_hotp_oath_qrcode_fail_for_duplication() {
        
        //  Given
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=4&algorithm=SHA256")!
        let authenticatorManager = AuthenticatorManager(storageClient: FRAClient.storage, policyEvaluator: FRAClient.policyEvaluator)
        
        do {
            let mechanism = try authenticatorManager.storeOathQRCode(uri: qrCode)
            XCTAssertNotNil(mechanism)
            let accountFromStorage = authenticatorManager.getAccount(identifier: "Forgerock-demo")
            XCTAssertNotNil(accountFromStorage)
            XCTAssertNotNil(accountFromStorage?.mechanisms)
            XCTAssertEqual(accountFromStorage?.mechanisms.count, 1)
            XCTAssertEqual(accountFromStorage?.mechanisms.first?.identifier, mechanism.identifier)
            
            let _ = try authenticatorManager.storeOathQRCode(uri: qrCode)
            XCTFail("AuthenticatorManager.storeOathQRCode with duplicated Mechanism was expected to fail; but somehow passed")
        }
        catch MechanismError.alreadyExists(let message) {
            XCTAssertEqual(message, "Forgerock-demo-hotp")
        }
        catch {
            XCTFail("AuthenticatorManager.storeOathQRCode with HOTP QR Code failed with unexpected reason")
        }
    }
    
    
    //  MARK: - storeOathQRCode - TOTP
    
    func test_11_store_totp_oath_qrcode() {
        
        // Given
        let qrCode = URL(string: "otpauth://totp/Forgerock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        let authenticatorManager = AuthenticatorManager(storageClient: FRAClient.storage, policyEvaluator: FRAClient.policyEvaluator)
        
        do {
            let mechanism = try authenticatorManager.storeOathQRCode(uri: qrCode)
            XCTAssertNotNil(mechanism)
            let accountFromStorage = authenticatorManager.getAccount(identifier: "ForgeRock-demo")
            XCTAssertNotNil(accountFromStorage)
            XCTAssertNotNil(accountFromStorage?.mechanisms)
            XCTAssertEqual(accountFromStorage?.mechanisms.count, 1)
            XCTAssertEqual(accountFromStorage?.mechanisms.first?.identifier, mechanism.identifier)
        }
        catch {
            XCTFail("AuthenticatorManager.storeOathQRCode with TOTP QR Code failed with unexpected reason")
        }
    }
    
    
    func test_12_store_totp_oath_qrcode_fail() {
        
        //  Given
        let storageClient = DummyStorageClient()
        storageClient.setMechanismResult = false
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        do {
            let _ = try authenticatorManager.storeOathQRCode(uri: qrCode)
            XCTFail("AuthenticatorManager.storeOathQRCode is expected to fail, but somehow passed")
        }
        catch FRAError.failToSaveIntoStorageClient {
            XCTAssertEqual(authenticatorManager.getAllAccounts().count, 0)
            XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 0)
        }
        catch {
            XCTFail("AuthenticatorManager.storeOathQRCode failed with unexpected reason")
        }
    }
    
    
    func test_13_store_totp_oath_qrcode_fail_for_duplication() {
        
        //  Given
        let qrCode = URL(string: "otpauth://totp/Forgerock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        let authenticatorManager = AuthenticatorManager(storageClient: FRAClient.storage, policyEvaluator: FRAClient.policyEvaluator)
        
        do {
            let mechanism = try authenticatorManager.storeOathQRCode(uri: qrCode)
            XCTAssertNotNil(mechanism)
            let accountFromStorage = authenticatorManager.getAccount(identifier: "ForgeRock-demo")
            XCTAssertNotNil(accountFromStorage)
            XCTAssertNotNil(accountFromStorage?.mechanisms)
            XCTAssertEqual(accountFromStorage?.mechanisms.count, 1)
            XCTAssertEqual(accountFromStorage?.mechanisms.first?.identifier, mechanism.identifier)
            
            let _ = try authenticatorManager.storeOathQRCode(uri: qrCode)
            XCTFail("AuthenticatorManager.storeOathQRCode with duplicated Mechanism was expected to fail; but somehow passed")
        }
        catch MechanismError.alreadyExists(let message) {
            XCTAssertEqual(message, "ForgeRock-demo-totp")
        }
        catch {
            XCTFail("AuthenticatorManager.storeOathQRCode with TOTP QR Code failed with unexpected reason")
        }
    }
    
    
    //  MARK: - storePushQRCode
    
    func test_14_store_push_qrcode_fail_with_invaid_host() {
        
        // Given
        let storageClient = DummyStorageClient()
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let qrCode = URL(string: "pushauth://totp/forgerock:pushreg3?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=5GuioYhLlh-xER3n5I8vrx0uuYQo3yD86aJi6KuWDsg&c=KP0XQfZ21N_jsXP_xfVQMmsmoUiWvdDPWecHdb5_INQ&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:a8970dea-3257-4be1-a37a-23eed2b692131588282723889&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!

        let ex = self.expectation(description: "Register PushMechanism")
        authenticatorManager.storePushQRcode(uri: qrCode, onSuccess: { (mechanism) in
            XCTFail("AuthenticatorManager.storePushQRCode succeeded while expecting failure")
            ex.fulfill()
        }) { (error) in
            if error.localizedDescription == "Invalid or missing auth type from given QR Code" {
            }
            else {
                XCTFail("AuthenticatorManager.storePushQRCode failed with unexpected reason")
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_15_store_push_qrcode_successful_registration_request() {
        
        self.loadMockResponses(["AM_Push_Registration_Successful"])
        // Set DeviceToken before PushMechnaism registration
        let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
        guard let deviceToken = deviceTokenStr.decodeBase64() else {
            XCTFail("Failed to parse device token data")
            return
        }
        FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        
        // Given
        let storageClient = DummyStorageClient()
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let qrCode = URL(string: "pushauth://push/forgerock:pushreg3?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=5GuioYhLlh-xER3n5I8vrx0uuYQo3yD86aJi6KuWDsg&c=KP0XQfZ21N_jsXP_xfVQMmsmoUiWvdDPWecHdb5_INQ&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:a8970dea-3257-4be1-a37a-23eed2b692131588282723889&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!
        
        let ex = self.expectation(description: "Register PushMechanism")
        authenticatorManager.storePushQRcode(uri: qrCode, onSuccess: { (mechanism) in
            XCTAssertNotNil(mechanism)
            let accountFromStorage = authenticatorManager.getAccount(identifier: "forgerock-pushreg3")
            XCTAssertNotNil(accountFromStorage)
            XCTAssertEqual(authenticatorManager.getAllAccounts().count, 1)
            XCTAssertEqual(accountFromStorage?.mechanisms.count, 1)
            ex.fulfill()
        }) { (error) in
            XCTFail("AuthenticatorManager.storePushQRCode failed while expecting successful registration")
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_16_store_push_qrcode_failed_registration_request() {
        
        self.loadMockResponses(["AM_Push_Registration_Fail_Invalid_Signed_JWT"])
        // Set DeviceToken before PushMechnaism registration
        let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
        guard let deviceToken = deviceTokenStr.decodeBase64() else {
            XCTFail("Failed to parse device token data")
            return
        }
        FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        
        // Given
        let storageClient = DummyStorageClient()
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let qrCode = URL(string: "pushauth://push/forgerock:pushreg3?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=5GuioYhLlh-xER3n5I8vrx0uuYQo3yD86aJi6KuWDsg&c=KP0XQfZ21N_jsXP_xfVQMmsmoUiWvdDPWecHdb5_INQ&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:a8970dea-3257-4be1-a37a-23eed2b692131588282723889&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!
        
        let ex = self.expectation(description: "Register PushMechanism")
        authenticatorManager.storePushQRcode(uri: qrCode, onSuccess: { (mechanism) in
            XCTFail("AuthenticatorManager.storePushQRCode was expected to fail, but somehow passed")
            ex.fulfill()
        }) { (error) in
            XCTAssertNil(authenticatorManager.getAccount(identifier: "Rm9yZ2VSb2NrU2FuZGJveA-pushreg3"))
            XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 0)
            XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 0)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_17_store_push_qrcode_successful_registration_request_failed_on_storage() {
        
        self.loadMockResponses(["AM_Push_Registration_Successful"])
        // Set DeviceToken before PushMechnaism registration
        let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
        guard let deviceToken = deviceTokenStr.decodeBase64() else {
            XCTFail("Failed to parse device token data")
            return
        }
        FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        
        // Given
        let storageClient = DummyStorageClient()
        // Mock failure on Mechanism store
        storageClient.setMechanismResult = false
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let qrCode = URL(string: "pushauth://push/forgerock:pushreg3?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=5GuioYhLlh-xER3n5I8vrx0uuYQo3yD86aJi6KuWDsg&c=KP0XQfZ21N_jsXP_xfVQMmsmoUiWvdDPWecHdb5_INQ&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:a8970dea-3257-4be1-a37a-23eed2b692131588282723889&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!
        
        let ex = self.expectation(description: "Register PushMechanism")
        authenticatorManager.storePushQRcode(uri: qrCode, onSuccess: { (mechanism) in
            XCTFail("AuthenticatorManager.storePushQRCode was expected to fail, but somehow passed")
            ex.fulfill()
        }) { (error) in
            XCTAssertEqual(error.localizedDescription, "Failed to save data into StorageClient: Failed to store Mechanism (forgerock-pushreg3-push) object into StorageClient")
            XCTAssertNil(authenticatorManager.getAccount(identifier: "forgerock-pushreg3"))
            XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 0)
            XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 0)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_18_store_push_qrcode_registration_request_failed_with_duplication() {
        
        self.loadMockResponses(["AM_Push_Registration_Successful", "AM_Push_Registration_Successful"])
        // Set DeviceToken before PushMechnaism registration
        let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
        guard let deviceToken = deviceTokenStr.decodeBase64() else {
            XCTFail("Failed to parse device token data")
            return
        }
        FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        
        // Given
        let storageClient = DummyStorageClient()
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let qrCode = URL(string: "pushauth://push/ForgeRockSandbox:pushreg3?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=5GuioYhLlh-xER3n5I8vrx0uuYQo3yD86aJi6KuWDsg&c=KP0XQfZ21N_jsXP_xfVQMmsmoUiWvdDPWecHdb5_INQ&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:a8970dea-3257-4be1-a37a-23eed2b692131588282723889&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!
        
        var ex = self.expectation(description: "Register PushMechanism")
        authenticatorManager.storePushQRcode(uri: qrCode, onSuccess: { (mechanism) in
            XCTAssertNotNil(mechanism)
            let accountFromStorage = authenticatorManager.getAccount(identifier: "ForgeRockSandbox-pushreg3")
            XCTAssertNotNil(accountFromStorage)
            XCTAssertEqual(authenticatorManager.getAllAccounts().count, 1)
            XCTAssertEqual(accountFromStorage?.mechanisms.count, 1)
            ex.fulfill()
        }) { (error) in
            XCTFail("AuthenticatorManager.storePushQRCode failed while expecting successful registration")
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
                
        ex = self.expectation(description: "Register PushMechanism for duplication")
        authenticatorManager.storePushQRcode(uri: qrCode, onSuccess: { (mechanism) in
            XCTFail("AuthenticatorManager.storePushQRCode was expected to fail with duplication; but somehow passed")
            ex.fulfill()
        }) { (error) in
            switch error {
            case MechanismError.alreadyExists(let message):
                XCTAssertEqual("ForgeRockSandbox-pushreg3-push", message)
                break
            default:
                XCTFail("AuthenticatorManager.storePushQRCode failed while expecting successful registration")
                break
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    //  MARK: - createMechanismFromUri
    
    func test_19_create_mechanism_from_uri_invalid_type() {
        
        // Given
        let storageClient = DummyStorageClient()
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let qrCode = URL(string: "pushauth://unknown/forgerock:pushreg3")!
        
        let ex = self.expectation(description: "AuthenticatorManager.createMechanismFromUri")
        authenticatorManager.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            XCTFail("AuthenticatorManager.createMechanismFromUri was expected to fail; but somehow passed")
            ex.fulfill()
        }) { (error) in
            XCTAssertEqual(error.localizedDescription, "Invalid or missing auth type from given QR Code")
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_20_create_mechanism_from_uri_topt_success() {
        
        //  Given
        let storageClient = DummyStorageClient()
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        let ex = self.expectation(description: "AuthenticatorManager.createMechanismFromUri")
        authenticatorManager.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            XCTAssertNotNil(mechanism)
            let accountFromStorage = authenticatorManager.getAccount(identifier: "ForgeRock-demo")
            XCTAssertNotNil(accountFromStorage)
            XCTAssertEqual(accountFromStorage?.mechanisms.count, 1)
            XCTAssertEqual(authenticatorManager.getAllAccounts().count, 1)
            ex.fulfill()
        }) { (error) in
            XCTFail("authenticatorManager.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_21_create_mechanism_from_uri_topt_failure() {
        
        //  Given
        let storageClient = DummyStorageClient()
        storageClient.setMechanismResult = false
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        let ex = self.expectation(description: "AuthenticatorManager.createMechanismFromUri")
        authenticatorManager.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            XCTFail("AuthenticatorManager.createMechanismFromUri was expected to fail; but somehow passed")
            ex.fulfill()
        }) { (error) in
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_22_create_mechanism_from_uri_hopt_success() {
        
        //  Given
        let storageClient = DummyStorageClient()
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=4&algorithm=SHA256")!
        
        let ex = self.expectation(description: "AuthenticatorManager.createMechanismFromUri")
        authenticatorManager.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            XCTAssertNotNil(mechanism)
            let accountFromStorage = authenticatorManager.getAccount(identifier: "Forgerock-demo")
            XCTAssertNotNil(accountFromStorage)
            XCTAssertEqual(accountFromStorage?.mechanisms.count, 1)
            XCTAssertEqual(authenticatorManager.getAllAccounts().count, 1)
            ex.fulfill()
        }) { (error) in
            XCTFail("authenticatorManager.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_23_create_mechanism_from_uri_hopt_failure() {
        
        //  Given
        let storageClient = DummyStorageClient()
        storageClient.setMechanismResult = false
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let qrCode = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=4&algorithm=SHA%20256")!
        
        let ex = self.expectation(description: "AuthenticatorManager.createMechanismFromUri")
        authenticatorManager.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            XCTFail("AuthenticatorManager.createMechanismFromUri was expected to fail; but somehow passed")
            ex.fulfill()
        }) { (error) in
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_24_create_mechanism_from_uri_push_success() {
        
        self.loadMockResponses(["AM_Push_Registration_Successful"])
        // Set DeviceToken before PushMechnaism registration
        let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
        guard let deviceToken = deviceTokenStr.decodeBase64() else {
            XCTFail("Failed to parse device token data")
            return
        }
        FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        
        // Given
        let storageClient = DummyStorageClient()
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let qrCode = URL(string: "pushauth://push/forgerock:pushreg3?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=5GuioYhLlh-xER3n5I8vrx0uuYQo3yD86aJi6KuWDsg&c=KP0XQfZ21N_jsXP_xfVQMmsmoUiWvdDPWecHdb5_INQ&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:a8970dea-3257-4be1-a37a-23eed2b692131588282723889")!
        
        let ex = self.expectation(description: "Register PushMechanism")
        authenticatorManager.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            XCTAssertNotNil(mechanism)
            let accountFromStorage = authenticatorManager.getAccount(identifier: "forgerock-pushreg3")
            XCTAssertNotNil(accountFromStorage)
            XCTAssertEqual(authenticatorManager.getAllAccounts().count, 1)
            XCTAssertEqual(accountFromStorage?.mechanisms.count, 1)
            ex.fulfill()
        }) { (error) in
            XCTFail("authenticatorManager.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_25_create_mechanism_from_uri_push_failure() {
        
        self.loadMockResponses(["AM_Push_Registration_Fail_Invalid_Signed_JWT"])
        // Set DeviceToken before PushMechnaism registration
        let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
        guard let deviceToken = deviceTokenStr.decodeBase64() else {
            XCTFail("Failed to parse device token data")
            return
        }
        FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        
        // Given
        let storageClient = DummyStorageClient()
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let qrCode = URL(string: "pushauth://push/forgerock:pushreg3?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=5GuioYhLlh-xER3n5I8vrx0uuYQo3yD86aJi6KuWDsg&c=KP0XQfZ21N_jsXP_xfVQMmsmoUiWvdDPWecHdb5_INQ&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:a8970dea-3257-4be1-a37a-23eed2b692131588282723889&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!
        
        let ex = self.expectation(description: "Register PushMechanism")
        authenticatorManager.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            let accountFromStorage = authenticatorManager.getAccount(identifier: "Rm9yZ2VSb2NrU2FuZGJveA-pushreg3")
            XCTAssertNotNil(accountFromStorage)
            XCTAssertEqual(authenticatorManager.getAllAccounts().count, 0)
            XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 0)
            XCTFail("AuthenticatorManager.createMechanismFromUri was expected to fail; but somehow passed")
            ex.fulfill()
        }) { (error) in
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    func test_25_1_create_mechanism_from_uri_push_oath_success() {
        
        self.loadMockResponses(["AM_Push_Registration_Successful"])
        // Set DeviceToken before PushMechnaism registration
        let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
        guard let deviceToken = deviceTokenStr.decodeBase64() else {
            XCTFail("Failed to parse device token data")
            return
        }
        FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        
        // Given
        let storageClient = DummyStorageClient()
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let qrCode = URL(string: "mfauth://totp/forgerock:pushreg3?" +
                         "a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&" +
                         "b=519387&" +
                         "r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&" + "s=5GuioYhLlh-xER3n5I8vrx0uuYQo3yD86aJi6KuWDsg&c=KP0XQfZ21N_jsXP_xfVQMmsmoUiWvdDPWecHdb5_INQ&" +
                         "l=YW1sYmNvb2tpZT0wMQ&" +
                         "m=REGISTER:a8970dea-3257-4be1-a37a-23eed2b692131588282723889" +
                         "digits=6&" +
                         "secret=R2PYFZRISXA5L25NVSSYK2RQ6E======&" +
                         "period=30&")!
        
        let ex = self.expectation(description: "Register PushMechanism")
        authenticatorManager.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            XCTAssertNotNil(mechanism)
            let accountFromStorage = authenticatorManager.getAccount(identifier: "forgerock-pushreg3")
            XCTAssertNotNil(accountFromStorage)
            XCTAssertEqual(authenticatorManager.getAllAccounts().count, 1)
            XCTAssertEqual(accountFromStorage?.mechanisms.count, 2)
            ex.fulfill()
        }) { (error) in
            XCTFail("authenticatorManager.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    func test_25_2_create_mechanism_from_uri_policy_evaluation_failure() {
        
        let policyEvaluator = FRAPolicyEvaluator()
        do {
            try policyEvaluator.registerPolicies(policies: [DummyPolicy(), DummyWithDataPolicy()])
            XCTAssertEqual(policyEvaluator.policies?.count, 2)
        } catch {
            XCTFail("AuthenticatorManager.createMechanismFromUri failed: \(error.localizedDescription)")
        }
        
        // Given
        let qrCode = URL(string: "mfauth://totp/Forgerock:demo?" +
                         "a=aHR0cHM6Ly9mb3JnZXJvY2suZXhhbXBsZS5jb20vb3BlbmFtL2pzb24vcHVzaC9zbnMvbWVzc2FnZT9fYWN0aW9uPWF1dGhlbnRpY2F0ZQ&" +
                         "image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&" +
                         "b=ff00ff&" +
                         "r=aHR0cHM6Ly9mb3JnZXJvY2suZXhhbXBsZS5jb20vb3BlbmFtL2pzb24vcHVzaC9zbnMvbWVzc2FnZT9fYWN0aW9uPXJlZ2lzdGVy&" +
                         "s=ryJkqNRjXYd_nX523672AX_oKdVXrKExq-VjVeRKKTc&" +
                         "c=Daf8vrc8onKu-dcptwCRS9UHmdui5u16vAdG2HMU4w0&" +
                         "l=YW1sYmNvb2tpZT0wMQ==&" +
                         "m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&" +
                         "policies=eyJkdW1teSI6IHsgfSwgImR1bW15V2l0aERhdGEiOiB7ICJyZXN1bHQiIDogZmFsc2UgfX0=&" +
                         "digits=6&" +
                         "secret=R2PYFZRISXA5L25NVSSYK2RQ6E======&" +
                         "period=30&")!
        let authenticatorManager = AuthenticatorManager(storageClient: FRAClient.storage, policyEvaluator: policyEvaluator)
        
        let ex = self.expectation(description: "AuthenticatorManager.createMechanismFromUri")
        authenticatorManager.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            XCTFail("AuthenticatorManager.createMechanismFromUri was expected to fail; but somehow passed")
            ex.fulfill()
        }) { (error) in
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    func test_25_3_create_mechanism_from_uri_policy_evaluation_success() {
        
        self.loadMockResponses(["AM_Push_Registration_Successful"])
        // Set DeviceToken before PushMechnaism registration
        let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
        guard let deviceToken = deviceTokenStr.decodeBase64() else {
            XCTFail("Failed to parse device token data")
            return
        }
        FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        
        // Given
        let storageClient = DummyStorageClient()
        let policyEvaluator = FRAPolicyEvaluator()
        
        do {
            try policyEvaluator.registerPolicies(policies: [DummyPolicy()])
        } catch {
            XCTFail("AuthenticatorManager.createMechanismFromUri failed: \(error.localizedDescription)")
        }
        
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let qrCode = URL(string: "mfauth://totp/forgerock:pushreg3?" +
                         "a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&" +
                         "b=519387&" +
                         "r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&" +
                         "s=5GuioYhLlh-xER3n5I8vrx0uuYQo3yD86aJi6KuWDsg&" +
                         "c=KP0XQfZ21N_jsXP_xfVQMmsmoUiWvdDPWecHdb5_INQ&" +
                         "l=YW1sYmNvb2tpZT0wMQ&" +
                         "m=REGISTER:a8970dea-3257-4be1-a37a-23eed2b692131588282723889&" +
                         "policies=eyJkdW1teSI6IHsgfX0=&" +
                         "digits=6&" +
                         "secret=R2PYFZRISXA5L25NVSSYK2RQ6E======&" +
                         "period=30&")!
        
        let ex = self.expectation(description: "Register PushMechanism")
        authenticatorManager.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            XCTAssertNotNil(mechanism)
            let accountFromStorage = authenticatorManager.getAccount(identifier: "forgerock-pushreg3")
            XCTAssertNotNil(accountFromStorage)
            XCTAssertEqual(authenticatorManager.getAllAccounts().count, 1)
            XCTAssertEqual(accountFromStorage?.mechanisms.count, 2)
            ex.fulfill()
        }) { (error) in
            XCTFail("authenticatorManager.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    //  MARK: - removeMechanism
    
    func test_26_remove_mechanism_success() {
        
        //  Given
        let storageClient = KeychainServiceClient()
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        var tmpMechanism: Mechanism?
        let ex = self.expectation(description: "AuthenticatorManager.createMechanismFromUri")
        authenticatorManager.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            XCTAssertNotNil(mechanism)
            let accountFromStorage = authenticatorManager.getAccount(identifier: "ForgeRock-demo")
            XCTAssertNotNil(accountFromStorage)
            XCTAssertEqual(accountFromStorage?.mechanisms.count, 1)
            XCTAssertEqual(authenticatorManager.getAllAccounts().count, 1)
            tmpMechanism = mechanism
            ex.fulfill()
        }) { (error) in
            XCTFail("authenticatorManager.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let mechanism = tmpMechanism else {
            XCTFail("Failed to capture Mechanism object")
            return
        }
        
        let accounts = authenticatorManager.getAllAccounts()
        XCTAssertEqual(accounts.count, 1)
        let account = accounts.first
        XCTAssertEqual(account?.mechanisms.count, 1)
        XCTAssertEqual(account?.identifier, "ForgeRock-demo")
        XCTAssertEqual(account?.mechanisms.first?.identifier, "ForgeRock-demo-totp")
        XCTAssertTrue(authenticatorManager.removeMechanism(mechanism: mechanism))
        
        let account2 = authenticatorManager.getAccount(identifier: "ForgeRock-demo")
        XCTAssertEqual(account2?.mechanisms.count, 0)
    }
    
    
    func test_27_remove_mechanism_failure() {
        
        //  Given
        let storageClient = DummyStorageClient()
        storageClient.removeMechanismResult = false
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)
        let qrCode = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        var tmpMechanism: Mechanism?
        let ex = self.expectation(description: "AuthenticatorManager.createMechanismFromUri")
        authenticatorManager.createMechanismFromUri(uri: qrCode, onSuccess: { (mechanism) in
            XCTAssertNotNil(mechanism)
            let accountFromStorage = authenticatorManager.getAccount(identifier: "ForgeRock-demo")
            XCTAssertNotNil(accountFromStorage)
            XCTAssertEqual(accountFromStorage?.mechanisms.count, 1)
            XCTAssertEqual(authenticatorManager.getAllAccounts().count, 1)
            tmpMechanism = mechanism
            ex.fulfill()
        }) { (error) in
            XCTFail("authenticatorManager.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let mechanism = tmpMechanism else {
            XCTFail("Failed to capture Mechanism object")
            return
        }
        
        let accounts = authenticatorManager.getAllAccounts()
        XCTAssertEqual(accounts.count, 1)
        let account = accounts.first
        XCTAssertEqual(account?.mechanisms.count, 1)
        XCTAssertEqual(account?.identifier, "ForgeRock-demo")
        XCTAssertEqual(account?.mechanisms.first?.identifier, "ForgeRock-demo-totp")
        XCTAssertFalse(authenticatorManager.removeMechanism(mechanism: mechanism))
        
        let account2 = authenticatorManager.getAccount(identifier: "ForgeRock-demo")
        XCTAssertEqual(account2?.mechanisms.count, 1)
    }
    
    
    func test_28_remove_push_mechanism_success() {

        let storageClient = DummyStorageClient()
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)

        self.loadMockResponses(["AM_Push_Registration_Successful"])
        // Set DeviceToken before PushMechnaism registration
        let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
        guard let deviceToken = deviceTokenStr.decodeBase64() else {
           XCTFail("Failed to parse device token data")
           return
        }
        FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)

        let push = URL(string: "pushauth://push/ForgeRockSandbox:pushtestuser?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=-3xGWaKjfls_ZHFRnGeIvFHn--GxzjQyg1RVG_Pak1s&c=esDK4G8eYce0_Gdf4p9XGGg2cIYYoxf6CTlL_O_1aF8&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:593b6a92-f5c1-4ac0-a94a-a63e05451dd51589138620791&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!

        //  Store first Mechanism
        let ex = self.expectation(description: "FRAClient.createMechanismFromUri")
        authenticatorManager.createMechanismFromUri(uri: push, onSuccess: { (mechanism) in
           ex.fulfill()
        }, onError: { (error) in
           XCTFail("authenticatorManager.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
           ex.fulfill()
        })
        waitForExpectations(timeout: 60, handler: nil)

        XCTAssertEqual(authenticatorManager.getAllAccounts().count, 1)
        XCTAssertNotNil(authenticatorManager.getAccount(identifier: "ForgeRockSandbox-pushtestuser"))
        XCTAssertEqual(authenticatorManager.getAccount(identifier: "ForgeRockSandbox-pushtestuser")?.mechanisms.count, 1)

        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 0)


        //  Make sure to mimic MechanismUUID
        guard let account = authenticatorManager.getAccount(identifier: "ForgeRockSandbox-pushtestuser"),
           let mechanism = account.mechanisms.first as? PushMechanism else {
           XCTFail("Failed to retrieve PushMechanism")
           return
        }
        //  Update Mechanism with UUID
        mechanism.mechanismUUID = "759ACE9D-C64B-43E6-981D-97F7B54C3B01"
        XCTAssertTrue(FRAClient.storage.setMechanism(mechanism: mechanism))

        //  Fake first remote-message receive action
        var payload: [String: Any] = [:]
        var aps: [String: Any] = [:]
        aps["messageId"] = "AUTHENTICATE:64e909a2-84db-4ee8-b244-f0dbbeb8b0ff1589151035455"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoicGtJZm1rZDFSbDNJWnFhSmNZSUhLUzJic2wvZnhiWGNPYTEvNE83Z2pMTT0iLCJ0IjoiMTIwIiwidSI6Ijc1OUFDRTlELUM2NEItNDNFNi05ODFELTk3RjdCNTRDM0IwMSIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSJ9.o_F0jvSiQlcpInyexi5ED4pjKNHxoHknPIsowYbpyYQ"
        aps["sound"] = "default"

        payload["aps"] = aps

        guard let _ = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload) else {
          XCTFail("Failed to parse notification payload and construct PushNotification object")
          return
        }

        var pushAccount = authenticatorManager.getAccount(identifier: "ForgeRockSandbox-pushtestuser")
        var pushMechanism = pushAccount?.mechanisms.first as? PushMechanism

        XCTAssertEqual(pushMechanism?.notifications.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 1)

        //  Fake second remote-message receive action
        payload = [:]
        aps = [:]
        aps["messageId"] = "AUTHENTICATE:0666696b-859d-4565-b069-f13c800c5e3c1589151071515"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoiK2ZreklzbG1PN01GcHYzZEppQVY4Sm5yRzFra0hUdDA2NkRaaEcxamJwbz0iLCJ0IjoiMTIwIiwidSI6Ijc1OUFDRTlELUM2NEItNDNFNi05ODFELTk3RjdCNTRDM0IwMSIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSJ9.1zuEgWy1gN7QAaJscGKgAqGxt_58Ad5HAZjOe8PLMBo"
        aps["sound"] = "default"

        payload["aps"] = aps

        guard let _ = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload) else {
          XCTFail("Failed to parse notification payload and construct PushNotification object")
          return
        }


        pushAccount = authenticatorManager.getAccount(identifier: "ForgeRockSandbox-pushtestuser")
        pushMechanism = pushAccount?.mechanisms.first as? PushMechanism

        XCTAssertEqual(pushMechanism?.notifications.count, 2)

        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 2)


        //  Fake third remote-message receive action
        payload = [:]
        aps = [:]
        aps["messageId"] = "AUTHENTICATE:929d72b7-c3e6-4460-a7b6-8e1c950b43361589151096771"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoiTVkzR01Fbkl6M3EweHFkR0wrMUdBaWNKdGxFVkhGenRsaVpTS1ZqdEZpaz0iLCJ0IjoiMTIwIiwidSI6Ijc1OUFDRTlELUM2NEItNDNFNi05ODFELTk3RjdCNTRDM0IwMSIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSJ9._cRsNnhNbHJ-AUnFTnW-jd6m4u7te1mIJXR9AHJUQhE"
        aps["sound"] = "default"

        payload["aps"] = aps

        guard let _ = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload) else {
          XCTFail("Failed to parse notification payload and construct PushNotification object")
          return
        }

        pushAccount = authenticatorManager.getAccount(identifier: "ForgeRockSandbox-pushtestuser")
        pushMechanism = pushAccount?.mechanisms.first as? PushMechanism

        XCTAssertEqual(pushMechanism?.notifications.count, 3)

        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 3)

        //  All PushNotification must be retrieved in order
        if let notifications = pushMechanism?.notifications, notifications.count == 3 {
            XCTAssertEqual(notifications[0].messageId, "AUTHENTICATE:64e909a2-84db-4ee8-b244-f0dbbeb8b0ff1589151035455")
            XCTAssertEqual(notifications[1].messageId, "AUTHENTICATE:0666696b-859d-4565-b069-f13c800c5e3c1589151071515")
            XCTAssertEqual(notifications[2].messageId, "AUTHENTICATE:929d72b7-c3e6-4460-a7b6-8e1c950b43361589151096771")
        }

        //  Remove Account object
        //  When
        guard let mechanismToDelete = pushMechanism else {
           XCTFail("Failed to retrieve already stored Account object")
           return
        }
        XCTAssertTrue(authenticatorManager.removeMechanism(mechanism: mechanismToDelete))

        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 0)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 0)
    }
    
    
    func test_29_remove_push_mechanism_failure() {

        let storageClient = DummyStorageClient()
        storageClient.removeMechanismResult = false
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)

        self.loadMockResponses(["AM_Push_Registration_Successful"])
        // Set DeviceToken before PushMechnaism registration
        let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
        guard let deviceToken = deviceTokenStr.decodeBase64() else {
           XCTFail("Failed to parse device token data")
           return
        }
        FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)

        let push = URL(string: "pushauth://push/ForgeRockSandbox:pushtestuser?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=-3xGWaKjfls_ZHFRnGeIvFHn--GxzjQyg1RVG_Pak1s&c=esDK4G8eYce0_Gdf4p9XGGg2cIYYoxf6CTlL_O_1aF8&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:593b6a92-f5c1-4ac0-a94a-a63e05451dd51589138620791&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!

        //  Store first Mechanism
        let ex = self.expectation(description: "FRAClient.createMechanismFromUri")
        authenticatorManager.createMechanismFromUri(uri: push, onSuccess: { (mechanism) in
           ex.fulfill()
        }, onError: { (error) in
           XCTFail("authenticatorManager.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
           ex.fulfill()
        })
        waitForExpectations(timeout: 60, handler: nil)

        XCTAssertEqual(authenticatorManager.getAllAccounts().count, 1)
        XCTAssertNotNil(authenticatorManager.getAccount(identifier: "ForgeRockSandbox-pushtestuser"))
        XCTAssertEqual(authenticatorManager.getAccount(identifier: "ForgeRockSandbox-pushtestuser")?.mechanisms.count, 1)

        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 0)


        //  Make sure to mimic MechanismUUID
        guard let account = authenticatorManager.getAccount(identifier: "ForgeRockSandbox-pushtestuser"),
           let mechanism = account.mechanisms.first as? PushMechanism else {
           XCTFail("Failed to retrieve PushMechanism")
           return
        }
        //  Update Mechanism with UUID
        mechanism.mechanismUUID = "759ACE9D-C64B-43E6-981D-97F7B54C3B01"
        XCTAssertTrue(FRAClient.storage.setMechanism(mechanism: mechanism))

        //  Fake first remote-message receive action
        var payload: [String: Any] = [:]
        var aps: [String: Any] = [:]
        aps["messageId"] = "AUTHENTICATE:64e909a2-84db-4ee8-b244-f0dbbeb8b0ff1589151035455"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoicGtJZm1rZDFSbDNJWnFhSmNZSUhLUzJic2wvZnhiWGNPYTEvNE83Z2pMTT0iLCJ0IjoiMTIwIiwidSI6Ijc1OUFDRTlELUM2NEItNDNFNi05ODFELTk3RjdCNTRDM0IwMSIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSJ9.o_F0jvSiQlcpInyexi5ED4pjKNHxoHknPIsowYbpyYQ"
        aps["sound"] = "default"

        payload["aps"] = aps

        guard let _ = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload) else {
          XCTFail("Failed to parse notification payload and construct PushNotification object")
          return
        }

        var pushAccount = authenticatorManager.getAccount(identifier: "ForgeRockSandbox-pushtestuser")
        var pushMechanism = pushAccount?.mechanisms.first as? PushMechanism

        XCTAssertEqual(pushMechanism?.notifications.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 1)

        //  Fake second remote-message receive action
        payload = [:]
        aps = [:]
        aps["messageId"] = "AUTHENTICATE:0666696b-859d-4565-b069-f13c800c5e3c1589151071515"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoiK2ZreklzbG1PN01GcHYzZEppQVY4Sm5yRzFra0hUdDA2NkRaaEcxamJwbz0iLCJ0IjoiMTIwIiwidSI6Ijc1OUFDRTlELUM2NEItNDNFNi05ODFELTk3RjdCNTRDM0IwMSIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSJ9.1zuEgWy1gN7QAaJscGKgAqGxt_58Ad5HAZjOe8PLMBo"
        aps["sound"] = "default"

        payload["aps"] = aps

        guard let _ = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload) else {
          XCTFail("Failed to parse notification payload and construct PushNotification object")
          return
        }


        pushAccount = authenticatorManager.getAccount(identifier: "ForgeRockSandbox-pushtestuser")
        pushMechanism = pushAccount?.mechanisms.first as? PushMechanism

        XCTAssertEqual(pushMechanism?.notifications.count, 2)

        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 2)


        //  Fake third remote-message receive action
        payload = [:]
        aps = [:]
        aps["messageId"] = "AUTHENTICATE:929d72b7-c3e6-4460-a7b6-8e1c950b43361589151096771"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoiTVkzR01Fbkl6M3EweHFkR0wrMUdBaWNKdGxFVkhGenRsaVpTS1ZqdEZpaz0iLCJ0IjoiMTIwIiwidSI6Ijc1OUFDRTlELUM2NEItNDNFNi05ODFELTk3RjdCNTRDM0IwMSIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSJ9._cRsNnhNbHJ-AUnFTnW-jd6m4u7te1mIJXR9AHJUQhE"
        aps["sound"] = "default"

        payload["aps"] = aps

        guard let _ = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload) else {
          XCTFail("Failed to parse notification payload and construct PushNotification object")
          return
        }

        pushAccount = authenticatorManager.getAccount(identifier: "ForgeRockSandbox-pushtestuser")
        pushMechanism = pushAccount?.mechanisms.first as? PushMechanism

        XCTAssertEqual(pushMechanism?.notifications.count, 3)

        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 3)

        //  All PushNotification must be retrieved in order
        if let notifications = pushMechanism?.notifications, notifications.count == 3 {
            XCTAssertEqual(notifications[0].messageId, "AUTHENTICATE:64e909a2-84db-4ee8-b244-f0dbbeb8b0ff1589151035455")
            XCTAssertEqual(notifications[1].messageId, "AUTHENTICATE:0666696b-859d-4565-b069-f13c800c5e3c1589151071515")
            XCTAssertEqual(notifications[2].messageId, "AUTHENTICATE:929d72b7-c3e6-4460-a7b6-8e1c950b43361589151096771")
        }

        //  Remove Account object
        //  When
        guard let mechanismToDelete = pushMechanism else {
           XCTFail("Failed to retrieve already stored Account object")
           return
        }
        XCTAssertFalse(authenticatorManager.removeMechanism(mechanism: mechanismToDelete))

        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 0)
    }
    
    
    func test_30_remove_push_account_success() {

        let storageClient = DummyStorageClient()
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)

        self.loadMockResponses(["AM_Push_Registration_Successful"])
        // Set DeviceToken before PushMechnaism registration
        let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
        guard let deviceToken = deviceTokenStr.decodeBase64() else {
           XCTFail("Failed to parse device token data")
           return
        }
        FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)

        let push = URL(string: "pushauth://push/forgerock:pushtestuser?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=-3xGWaKjfls_ZHFRnGeIvFHn--GxzjQyg1RVG_Pak1s&c=esDK4G8eYce0_Gdf4p9XGGg2cIYYoxf6CTlL_O_1aF8&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:593b6a92-f5c1-4ac0-a94a-a63e05451dd51589138620791&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!

        //  Store first Mechanism
        let ex = self.expectation(description: "FRAClient.createMechanismFromUri")
        authenticatorManager.createMechanismFromUri(uri: push, onSuccess: { (mechanism) in
           ex.fulfill()
        }, onError: { (error) in
           XCTFail("authenticatorManager.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
           ex.fulfill()
        })
        waitForExpectations(timeout: 60, handler: nil)

        XCTAssertEqual(authenticatorManager.getAllAccounts().count, 1)
        XCTAssertNotNil(authenticatorManager.getAccount(identifier: "forgerock-pushtestuser"))
        XCTAssertEqual(authenticatorManager.getAccount(identifier: "forgerock-pushtestuser")?.mechanisms.count, 1)

        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 0)


        //  Make sure to mimic MechanismUUID
        guard let account = authenticatorManager.getAccount(identifier: "forgerock-pushtestuser"),
           let mechanism = account.mechanisms.first as? PushMechanism else {
           XCTFail("Failed to retrieve PushMechanism")
           return
        }
        //  Update Mechanism with UUID
        mechanism.mechanismUUID = "759ACE9D-C64B-43E6-981D-97F7B54C3B01"
        XCTAssertTrue(FRAClient.storage.setMechanism(mechanism: mechanism))

        //  Fake first remote-message receive action
        var payload: [String: Any] = [:]
        var aps: [String: Any] = [:]
        aps["messageId"] = "AUTHENTICATE:64e909a2-84db-4ee8-b244-f0dbbeb8b0ff1589151035455"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoicGtJZm1rZDFSbDNJWnFhSmNZSUhLUzJic2wvZnhiWGNPYTEvNE83Z2pMTT0iLCJ0IjoiMTIwIiwidSI6Ijc1OUFDRTlELUM2NEItNDNFNi05ODFELTk3RjdCNTRDM0IwMSIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSJ9.o_F0jvSiQlcpInyexi5ED4pjKNHxoHknPIsowYbpyYQ"
        aps["sound"] = "default"

        payload["aps"] = aps

        guard let _ = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload) else {
          XCTFail("Failed to parse notification payload and construct PushNotification object")
          return
        }

        var pushAccount = authenticatorManager.getAccount(identifier: "forgerock-pushtestuser")
        var pushMechanism = pushAccount?.mechanisms.first as? PushMechanism

        XCTAssertEqual(pushMechanism?.notifications.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 1)

        //  Fake second remote-message receive action
        payload = [:]
        aps = [:]
        aps["messageId"] = "AUTHENTICATE:0666696b-859d-4565-b069-f13c800c5e3c1589151071515"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoiK2ZreklzbG1PN01GcHYzZEppQVY4Sm5yRzFra0hUdDA2NkRaaEcxamJwbz0iLCJ0IjoiMTIwIiwidSI6Ijc1OUFDRTlELUM2NEItNDNFNi05ODFELTk3RjdCNTRDM0IwMSIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSJ9.1zuEgWy1gN7QAaJscGKgAqGxt_58Ad5HAZjOe8PLMBo"
        aps["sound"] = "default"

        payload["aps"] = aps

        guard let _ = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload) else {
          XCTFail("Failed to parse notification payload and construct PushNotification object")
          return
        }


        pushAccount = authenticatorManager.getAccount(identifier: "forgerock-pushtestuser")
        pushMechanism = pushAccount?.mechanisms.first as? PushMechanism

        XCTAssertEqual(pushMechanism?.notifications.count, 2)

        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 2)


        //  Fake third remote-message receive action
        payload = [:]
        aps = [:]
        aps["messageId"] = "AUTHENTICATE:929d72b7-c3e6-4460-a7b6-8e1c950b43361589151096771"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoiTVkzR01Fbkl6M3EweHFkR0wrMUdBaWNKdGxFVkhGenRsaVpTS1ZqdEZpaz0iLCJ0IjoiMTIwIiwidSI6Ijc1OUFDRTlELUM2NEItNDNFNi05ODFELTk3RjdCNTRDM0IwMSIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSJ9._cRsNnhNbHJ-AUnFTnW-jd6m4u7te1mIJXR9AHJUQhE"
        aps["sound"] = "default"

        payload["aps"] = aps

        guard let _ = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload) else {
          XCTFail("Failed to parse notification payload and construct PushNotification object")
          return
        }

        pushAccount = authenticatorManager.getAccount(identifier: "forgerock-pushtestuser")
        pushMechanism = pushAccount?.mechanisms.first as? PushMechanism

        XCTAssertEqual(pushMechanism?.notifications.count, 3)

        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 3)

        //  All PushNotification must be retrieved in order
        if let notifications = pushMechanism?.notifications, notifications.count == 3 {
            XCTAssertEqual(notifications[0].messageId, "AUTHENTICATE:64e909a2-84db-4ee8-b244-f0dbbeb8b0ff1589151035455")
            XCTAssertEqual(notifications[1].messageId, "AUTHENTICATE:0666696b-859d-4565-b069-f13c800c5e3c1589151071515")
            XCTAssertEqual(notifications[2].messageId, "AUTHENTICATE:929d72b7-c3e6-4460-a7b6-8e1c950b43361589151096771")
        }

        //  Remove Account object
        //  When
        guard let accountToBeDeleted = pushAccount else {
           XCTFail("Failed to retrieve already stored Account object")
           return
        }
        XCTAssertTrue(authenticatorManager.removeAccount(account: accountToBeDeleted))

        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 0)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 0)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 0)
    }
    
    //  MARK: - removeNotification
    
    func test_31_remove_notification_success() {

        let storageClient = DummyStorageClient()
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)

        self.loadMockResponses(["AM_Push_Registration_Successful"])
        // Set DeviceToken before PushMechnaism registration
        let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
        guard let deviceToken = deviceTokenStr.decodeBase64() else {
           XCTFail("Failed to parse device token data")
           return
        }
        FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)

        let push = URL(string: "pushauth://push/forgerock:pushtestuser?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=-3xGWaKjfls_ZHFRnGeIvFHn--GxzjQyg1RVG_Pak1s&c=esDK4G8eYce0_Gdf4p9XGGg2cIYYoxf6CTlL_O_1aF8&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:593b6a92-f5c1-4ac0-a94a-a63e05451dd51589138620791&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!

        //  Store first Mechanism
        let ex = self.expectation(description: "FRAClient.createMechanismFromUri")
        authenticatorManager.createMechanismFromUri(uri: push, onSuccess: { (mechanism) in
           ex.fulfill()
        }, onError: { (error) in
           XCTFail("authenticatorManager.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
           ex.fulfill()
        })
        waitForExpectations(timeout: 60, handler: nil)

        XCTAssertEqual(authenticatorManager.getAllAccounts().count, 1)
        XCTAssertNotNil(authenticatorManager.getAccount(identifier: "forgerock-pushtestuser"))
        XCTAssertEqual(authenticatorManager.getAccount(identifier: "forgerock-pushtestuser")?.mechanisms.count, 1)

        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 0)


        //  Make sure to mimic MechanismUUID
        guard let account = authenticatorManager.getAccount(identifier: "forgerock-pushtestuser"),
           let mechanism = account.mechanisms.first as? PushMechanism else {
           XCTFail("Failed to retrieve PushMechanism")
           return
        }
        //  Update Mechanism with UUID
        mechanism.mechanismUUID = "759ACE9D-C64B-43E6-981D-97F7B54C3B01"
        XCTAssertTrue(FRAClient.storage.setMechanism(mechanism: mechanism))

        //  Fake first remote-message receive action
        var payload: [String: Any] = [:]
        var aps: [String: Any] = [:]
        aps["messageId"] = "AUTHENTICATE:64e909a2-84db-4ee8-b244-f0dbbeb8b0ff1589151035455"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoicGtJZm1rZDFSbDNJWnFhSmNZSUhLUzJic2wvZnhiWGNPYTEvNE83Z2pMTT0iLCJ0IjoiMTIwIiwidSI6Ijc1OUFDRTlELUM2NEItNDNFNi05ODFELTk3RjdCNTRDM0IwMSIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSJ9.o_F0jvSiQlcpInyexi5ED4pjKNHxoHknPIsowYbpyYQ"
        aps["sound"] = "default"

        payload["aps"] = aps

        guard let _ = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload) else {
          XCTFail("Failed to parse notification payload and construct PushNotification object")
          return
        }

        var pushAccount = authenticatorManager.getAccount(identifier: "forgerock-pushtestuser")
        var pushMechanism = pushAccount?.mechanisms.first as? PushMechanism

        XCTAssertEqual(pushMechanism?.notifications.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 1)

        //  Fake second remote-message receive action
        payload = [:]
        aps = [:]
        aps["messageId"] = "AUTHENTICATE:0666696b-859d-4565-b069-f13c800c5e3c1589151071515"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoiK2ZreklzbG1PN01GcHYzZEppQVY4Sm5yRzFra0hUdDA2NkRaaEcxamJwbz0iLCJ0IjoiMTIwIiwidSI6Ijc1OUFDRTlELUM2NEItNDNFNi05ODFELTk3RjdCNTRDM0IwMSIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSJ9.1zuEgWy1gN7QAaJscGKgAqGxt_58Ad5HAZjOe8PLMBo"
        aps["sound"] = "default"

        payload["aps"] = aps

        guard let _ = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload) else {
          XCTFail("Failed to parse notification payload and construct PushNotification object")
          return
        }


        pushAccount = authenticatorManager.getAccount(identifier: "forgerock-pushtestuser")
        pushMechanism = pushAccount?.mechanisms.first as? PushMechanism

        XCTAssertEqual(pushMechanism?.notifications.count, 2)

        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 2)


        //  Fake third remote-message receive action
        payload = [:]
        aps = [:]
        aps["messageId"] = "AUTHENTICATE:929d72b7-c3e6-4460-a7b6-8e1c950b43361589151096771"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoiTVkzR01Fbkl6M3EweHFkR0wrMUdBaWNKdGxFVkhGenRsaVpTS1ZqdEZpaz0iLCJ0IjoiMTIwIiwidSI6Ijc1OUFDRTlELUM2NEItNDNFNi05ODFELTk3RjdCNTRDM0IwMSIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSJ9._cRsNnhNbHJ-AUnFTnW-jd6m4u7te1mIJXR9AHJUQhE"
        aps["sound"] = "default"

        payload["aps"] = aps

        guard let _ = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload) else {
          XCTFail("Failed to parse notification payload and construct PushNotification object")
          return
        }

        pushAccount = authenticatorManager.getAccount(identifier: "forgerock-pushtestuser")
        pushMechanism = pushAccount?.mechanisms.first as? PushMechanism

        XCTAssertEqual(pushMechanism?.notifications.count, 3)

        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 3)

        //  All PushNotification must be retrieved in order
        if let notifications = pushMechanism?.notifications, notifications.count == 3 {
            XCTAssertEqual(notifications[0].messageId, "AUTHENTICATE:64e909a2-84db-4ee8-b244-f0dbbeb8b0ff1589151035455")
            XCTAssertEqual(notifications[1].messageId, "AUTHENTICATE:0666696b-859d-4565-b069-f13c800c5e3c1589151071515")
            XCTAssertEqual(notifications[2].messageId, "AUTHENTICATE:929d72b7-c3e6-4460-a7b6-8e1c950b43361589151096771")
        }

        //  Remove Account object
        //  When
        guard let notification1 = pushMechanism?.notifications[0], let notification2 = pushMechanism?.notifications[1], let notification3 = pushMechanism?.notifications[2] else {
            XCTFail("Failed to read notification from stored Mechanism")
            return
        }
        
        XCTAssertTrue(authenticatorManager.removeNotification(notification: notification1))
        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 2)
        
        storageClient.removeNotificationResult = false
        
        XCTAssertFalse(authenticatorManager.removeNotification(notification: notification2))
        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 2)
        
        storageClient.removeNotificationResult = nil
        
        XCTAssertTrue(authenticatorManager.removeNotification(notification: notification2))
        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 1)
        
        XCTAssertTrue(authenticatorManager.removeNotification(notification: notification3))
        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 0)
    }
    
    
    func test32_get_all_notifications() {
        
        let storageClient = DummyStorageClient()
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)

        self.loadMockResponses(["AM_Push_Registration_Successful"])
        // Set DeviceToken before PushMechnaism registration
        let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
        guard let deviceToken = deviceTokenStr.decodeBase64() else {
           XCTFail("Failed to parse device token data")
           return
        }
        FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)

        let push = URL(string: "pushauth://push/forgerock:pushtestuser?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=-3xGWaKjfls_ZHFRnGeIvFHn--GxzjQyg1RVG_Pak1s&c=esDK4G8eYce0_Gdf4p9XGGg2cIYYoxf6CTlL_O_1aF8&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:593b6a92-f5c1-4ac0-a94a-a63e05451dd51589138620791&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!

        //  Store first Mechanism
        let ex = self.expectation(description: "FRAClient.createMechanismFromUri")
        authenticatorManager.createMechanismFromUri(uri: push, onSuccess: { (mechanism) in
           ex.fulfill()
        }, onError: { (error) in
           XCTFail("authenticatorManager.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
           ex.fulfill()
        })
        waitForExpectations(timeout: 60, handler: nil)

        XCTAssertEqual(authenticatorManager.getAllAccounts().count, 1)
        XCTAssertNotNil(authenticatorManager.getAccount(identifier: "forgerock-pushtestuser"))
        XCTAssertEqual(authenticatorManager.getAccount(identifier: "forgerock-pushtestuser")?.mechanisms.count, 1)

        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 0)


        //  Make sure to mimic MechanismUUID
        guard let account = authenticatorManager.getAccount(identifier: "forgerock-pushtestuser"),
           let mechanism = account.mechanisms.first as? PushMechanism else {
           XCTFail("Failed to retrieve PushMechanism")
           return
        }
        //  Update Mechanism with UUID
        mechanism.mechanismUUID = "759ACE9D-C64B-43E6-981D-97F7B54C3B01"
        XCTAssertTrue(FRAClient.storage.setMechanism(mechanism: mechanism))

        //  Fake first remote-message receive action
        var payload: [String: Any] = [:]
        var aps: [String: Any] = [:]
        aps["messageId"] = "AUTHENTICATE:64e909a2-84db-4ee8-b244-f0dbbeb8b0ff1589151035455"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoicGtJZm1rZDFSbDNJWnFhSmNZSUhLUzJic2wvZnhiWGNPYTEvNE83Z2pMTT0iLCJ0IjoiMTIwIiwidSI6Ijc1OUFDRTlELUM2NEItNDNFNi05ODFELTk3RjdCNTRDM0IwMSIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSJ9.o_F0jvSiQlcpInyexi5ED4pjKNHxoHknPIsowYbpyYQ"
        aps["sound"] = "default"

        payload["aps"] = aps

        guard let _ = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload) else {
          XCTFail("Failed to parse notification payload and construct PushNotification object")
          return
        }

        var pushAccount = authenticatorManager.getAccount(identifier: "forgerock-pushtestuser")
        var pushMechanism = pushAccount?.mechanisms.first as? PushMechanism

        XCTAssertEqual(pushMechanism?.notifications.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 1)

        //  Fake second remote-message receive action
        payload = [:]
        aps = [:]
        aps["messageId"] = "AUTHENTICATE:0666696b-859d-4565-b069-f13c800c5e3c1589151071515"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoiK2ZreklzbG1PN01GcHYzZEppQVY4Sm5yRzFra0hUdDA2NkRaaEcxamJwbz0iLCJ0IjoiMTIwIiwidSI6Ijc1OUFDRTlELUM2NEItNDNFNi05ODFELTk3RjdCNTRDM0IwMSIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSJ9.1zuEgWy1gN7QAaJscGKgAqGxt_58Ad5HAZjOe8PLMBo"
        aps["sound"] = "default"

        payload["aps"] = aps

        guard let _ = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload) else {
          XCTFail("Failed to parse notification payload and construct PushNotification object")
          return
        }


        pushAccount = authenticatorManager.getAccount(identifier: "forgerock-pushtestuser")
        pushMechanism = pushAccount?.mechanisms.first as? PushMechanism

        XCTAssertEqual(pushMechanism?.notifications.count, 2)

        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 2)


        //  Fake third remote-message receive action
        payload = [:]
        aps = [:]
        aps["messageId"] = "AUTHENTICATE:929d72b7-c3e6-4460-a7b6-8e1c950b43361589151096771"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoiTVkzR01Fbkl6M3EweHFkR0wrMUdBaWNKdGxFVkhGenRsaVpTS1ZqdEZpaz0iLCJ0IjoiMTIwIiwidSI6Ijc1OUFDRTlELUM2NEItNDNFNi05ODFELTk3RjdCNTRDM0IwMSIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSJ9._cRsNnhNbHJ-AUnFTnW-jd6m4u7te1mIJXR9AHJUQhE"
        aps["sound"] = "default"

        payload["aps"] = aps

        guard let _ = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload) else {
          XCTFail("Failed to parse notification payload and construct PushNotification object")
          return
        }
        
        guard let thisMechanism = pushMechanism else {
            XCTFail("Failed to retrieve PushMechanism")
            return
        }
        let notifications = authenticatorManager.getAllNotifications(mechanism: thisMechanism)
        XCTAssertEqual(notifications.count, 3)
        
        XCTAssertEqual(notifications[0].messageId, "AUTHENTICATE:64e909a2-84db-4ee8-b244-f0dbbeb8b0ff1589151035455")
        XCTAssertEqual(notifications[1].messageId, "AUTHENTICATE:0666696b-859d-4565-b069-f13c800c5e3c1589151071515")
        XCTAssertEqual(notifications[2].messageId, "AUTHENTICATE:929d72b7-c3e6-4460-a7b6-8e1c950b43361589151096771")
    }
}
