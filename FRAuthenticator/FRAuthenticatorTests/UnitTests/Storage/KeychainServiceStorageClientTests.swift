// 
//  KeychainServiceStorageClientTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020-2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class KeychainServiceStorageClientTests: FRABaseTests {

    var cleanUpData: Bool = true
    
    override func tearDown() {
        if cleanUpData {
            let storage = KeychainServiceClient()
            storage.accountStorage.deleteAll()
            storage.mechanismStorage.deleteAll()
            storage.notificationStorage.deleteAll()
        }
    }
    
    func test_01_init_success() {
        let storage = KeychainServiceClient()
        
        XCTAssertNotNil(storage)
        XCTAssertNotNil(storage.accountStorage)
        XCTAssertNotNil(storage.mechanismStorage)
        XCTAssertNotNil(storage.notificationStorage)
    }
    
    
    func test_02_save_retrieve_and_remove_account() {
        let storage = KeychainServiceClient()
        
        let account1 = Account(issuer: "issuer", accountName: "accountName")
        
        storage.setAccount(account: account1)
        
        guard let accountFromStorage1 = storage.getAccount(accountIdentifier: account1.identifier) else {
            XCTFail("Failed to retrieve Account objects from storage")
            return
        }
        
        XCTAssertEqual(account1.issuer, accountFromStorage1.issuer)
        XCTAssertEqual(account1.accountName, accountFromStorage1.accountName)
        XCTAssertEqual(account1.imageUrl, accountFromStorage1.imageUrl)
        XCTAssertEqual(account1.backgroundColor, accountFromStorage1.backgroundColor)
        
        storage.removeAccount(account: account1)
        XCTAssertNil(storage.getAccount(accountIdentifier: account1.identifier))
    }
    
    
    func test_03_save_multiple_accounts() {
        
        let storage = KeychainServiceClient()
        let account1 = Account(issuer: "issuer", accountName: "accountName")
        let account2 = Account(issuer: "issuer2", accountName: "accountName2")
        
        storage.setAccount(account: account1)
        storage.setAccount(account: account2)
        var accounts: [Account] = storage.getAllAccounts()
        XCTAssertEqual(accounts.count, 2)

        let account3 = Account(issuer: "issuer3", accountName: "accountName3")
        storage.setAccount(account: account3)
        accounts = storage.getAllAccounts()
        XCTAssertEqual(accounts.count, 3)
    }
    
    
    func test_04_no_account() {
        let storage = KeychainServiceClient()
        let account1 = Account(issuer: "issuer", accountName: "accountName")
        let account2 = Account(issuer: "issuer2", accountName: "accountName2")
        
        storage.setAccount(account: account1)
        storage.setAccount(account: account2)
        let accounts: [Account] = storage.getAllAccounts()
        XCTAssertEqual(accounts.count, 2)
        
        let account = storage.getAccount(accountIdentifier: "issuer3-accountName3")
        XCTAssertNil(account)
    }
    
    
    func test_05_update_existing_account() {
        let storage = KeychainServiceClient()
        
        let account1 = Account(issuer: "issuer", accountName: "accountName")
        
        storage.setAccount(account: account1)
        
        guard let accountFromStorage1 = storage.getAccount(accountIdentifier: account1.identifier) else {
            XCTFail("Failed to retrieve Account objects from storage")
            return
        }
        
        XCTAssertEqual(account1.issuer, accountFromStorage1.issuer)
        XCTAssertEqual(account1.accountName, accountFromStorage1.accountName)
        XCTAssertNil(accountFromStorage1.imageUrl)
        XCTAssertNil(accountFromStorage1.backgroundColor)
        
        account1.imageUrl = "https://www.forgerock.com"
        account1.backgroundColor = "#FFFFFF"
        
        storage.setAccount(account: account1)
        
        guard let accountFromStorage2 = storage.getAccount(accountIdentifier: account1.identifier) else {
            XCTFail("Failed to retrieve Account objects from storage")
            return
        }
        
        XCTAssertEqual("issuer", accountFromStorage2.issuer)
        XCTAssertEqual("accountName", accountFromStorage2.accountName)
        XCTAssertEqual("#FFFFFF", accountFromStorage2.backgroundColor)
        XCTAssertEqual("https://www.forgerock.com", accountFromStorage2.imageUrl)
    }
    
    
    func test_06_get_account_with_mechanism() {
        
        let storage = KeychainServiceClient()
        let account = Account(issuer: "Forgerock", accountName: "demo")
        storage.setAccount(account: account)
        
        let qrCode = URL(string: "pushauth://push/forgerock:demo?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI=&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr")!
        
        do {
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer, uid: parser.uid, resourceId: parser.resourceId)
            storage.setMechanism(mechanism: mechanism)
            
            let accountFromStorage = storage.getAccount(accountIdentifier: account.identifier)
            
            XCTAssertNotNil(accountFromStorage?.mechanisms)
            XCTAssertEqual(accountFromStorage?.mechanisms.count, 0)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_07_get_account_with_mechanism_and_verify_remove() {
        
        let storage = KeychainServiceClient()
        let account = Account(issuer: "ForgeRock", accountName: "demo")
        storage.setAccount(account: account)
        
        let hotp = URL(string: "otpauth://hotp/ForgeRock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=ForgeRock&counter=0&algorithm=SHA256")!
        let totp = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        do {
            let tparser = try OathQRCodeParser(url: totp)
            let totpMechanism = TOTPMechanism(issuer: tparser.issuer, accountName: tparser.label, secret: tparser.secret, algorithm: tparser.algorithm, uid: tparser.uid, resourceId: tparser.resourceId, period: tparser.period, digits: tparser.digits)
            
            let hparser = try OathQRCodeParser(url: hotp)
            let hotpMechanism = HOTPMechanism(issuer: hparser.issuer, accountName: hparser.label, secret: hparser.secret, algorithm: hparser.algorithm, uid: hparser.uid, resourceId: hparser.resourceId, counter: hparser.counter, digits: hparser.digits)
            
            storage.setMechanism(mechanism: hotpMechanism)
            var accountFromStorage = storage.getAccount(accountIdentifier: account.identifier)
            var mechanismsFromStorage = storage.getMechanismsForAccount(account: accountFromStorage!)
            XCTAssertNotNil(accountFromStorage?.mechanisms)
            XCTAssertEqual(mechanismsFromStorage.count, 1)
            
            storage.setMechanism(mechanism: totpMechanism)
            accountFromStorage = storage.getAccount(accountIdentifier: account.identifier)
            mechanismsFromStorage = storage.getMechanismsForAccount(account: accountFromStorage!)
            XCTAssertNotNil(accountFromStorage?.mechanisms)
            XCTAssertEqual(mechanismsFromStorage.count, 2)
            
            storage.removeMechanism(mechanism: totpMechanism)
            accountFromStorage = storage.getAccount(accountIdentifier: account.identifier)
            mechanismsFromStorage = storage.getMechanismsForAccount(account: accountFromStorage!)
            XCTAssertNotNil(accountFromStorage?.mechanisms)
            XCTAssertEqual(mechanismsFromStorage.count, 1)
            
            XCTAssertEqual(mechanismsFromStorage.first?.identifier, "ForgeRock-demo-hotp")
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_08_test_save_retrieve_and_remove_notification() {
        
        let storage = KeychainServiceClient()
        let account = Account(issuer: "Rm9yZ2Vyb2Nr", accountName: "demo")
        storage.setAccount(account: account)
        
        let qrCode = URL(string: "pushauth://push/forgerock:demo?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI=&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr")!
        
        do {
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer, uid: parser.uid, resourceId: parser.resourceId)
            storage.setMechanism(mechanism: mechanism)
            
            let payload1: [String: String] = ["c": "j4i8MSuGOcqfslLpRMsYWUMkfsZnsgTCcgNZ+WN3MEE=", "l": "ZnJfc3NvX2FtbGJfcHJvZD0wMQ==", "t": "120", "u": mechanism.mechanismUUID]
            let payload2: [String: String] = ["c": "Y2hhbGxlbmdlLWJhc2U2NC1lbmNvZGVk=", "l": "bG9hZC1iYWxhbmNlLWtleS1iYXNlNjQtZW5jb2RlZA==", "t": "120", "u": mechanism.mechanismUUID]

            let messageId1 = "AUTHENTICATE:e84233f8-9ecf-4456-91ad-2649c4103bc01569980570407"
            let messageId2 = "AUTHENTICATE:e84233f8-9ecf-4456-91ad-2649c4103bc01562382721826"

            let notification1 = try PushNotification(messageId: messageId1, payload: payload1)
            sleep(1) // Waiting 1s to avoid have two PushNotifications with same id
            let notification2 = try PushNotification(messageId: messageId2, payload: payload2)
            
            storage.setNotification(notification: notification1)
            var notifications = storage.getAllNotificationsForMechanism(mechanism: mechanism)
            
            XCTAssertNotNil(notifications)
            XCTAssertEqual(notifications.count, 1)
            XCTAssertEqual(notifications.first?.messageId, messageId1)
            
            storage.setNotification(notification: notification2)
            notifications = storage.getAllNotificationsForMechanism(mechanism: mechanism)
            
            XCTAssertNotNil(notifications)
            XCTAssertEqual(notifications.count, 2)
            
            storage.removeNotification(notification: notification1)
            notifications = storage.getAllNotificationsForMechanism(mechanism: mechanism)
            XCTAssertEqual(notifications.count, 1)
            XCTAssertEqual(notifications.first?.messageId, messageId2)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_09_save_push_notifications_and_validate_with_account() {
        
        let storage = KeychainServiceClient()
        let account = Account(issuer: "Forgerock", accountName: "demo")
        storage.setAccount(account: account)
        
        let qrCode = URL(string: "pushauth://push/Forgerock:demo?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI=&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr")!
        
        do {
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer, uid: parser.uid, resourceId: parser.resourceId)
            storage.setMechanism(mechanism: mechanism)
            
            let payload1: [String: String] = ["c": "j4i8MSuGOcqfslLpRMsYWUMkfsZnsgTCcgNZ+WN3MEE=", "l": "ZnJfc3NvX2FtbGJfcHJvZD0wMQ==", "t": "120", "u": mechanism.mechanismUUID]
            let payload2: [String: String] = ["c": "Y2hhbGxlbmdlLWJhc2U2NC1lbmNvZGVk=", "l": "bG9hZC1iYWxhbmNlLWtleS1iYXNlNjQtZW5jb2RlZA==", "t": "120", "u": mechanism.mechanismUUID]
            let messageId1 = "AUTHENTICATE:e84233f8-9ecf-4456-91ad-2649c4103bc01569980570407"
            let messageId2 = "AUTHENTICATE:e84233f8-9ecf-4456-91ad-2649c4103bc01562382721826"

            let notification1 = try PushNotification(messageId: messageId1, payload: payload1)
            sleep(1) // Waiting 1s to avoid have two PushNotifications with same id
            let notification2 = try PushNotification(messageId: messageId2, payload: payload2)
            storage.setNotification(notification: notification1)
            storage.setNotification(notification: notification2)
            
            let mechanismFromStorage = storage.getMechanismsForAccount(account: account).first as? PushMechanism
            XCTAssertNotNil(mechanismFromStorage)
            
            let notifications = storage.getAllNotificationsForMechanism(mechanism: mechanismFromStorage!)
            XCTAssertNotNil(notifications)
            XCTAssertEqual(notifications.count, 2)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_10_save_push_notifications_and_retreive_with_mechanism_uuid() {
        
        let storage = KeychainServiceClient()
        let account = Account(issuer: "Rm9yZ2Vyb2Nr", accountName: "demo")
        storage.setAccount(account: account)
        
        let qrCode = URL(string: "pushauth://push/forgerock:demo?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI=&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr")!
        
        do {
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer, uid: parser.uid, resourceId: parser.resourceId)
            storage.setMechanism(mechanism: mechanism)
            let mechanismUUID = mechanism.mechanismUUID
            
            let mechanismFromStorage = storage.getMechanismForUUID(uuid: mechanismUUID)
            XCTAssertNotNil(mechanismFromStorage)
            
            XCTAssertTrue(storage.removeMechanism(mechanism: mechanism))
            let mechanismFromStorage2 = storage.getMechanismForUUID(uuid: mechanismUUID)
            XCTAssertNil(mechanismFromStorage2)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_11_is_empty() {
        
        //  Given
        let storage = KeychainServiceClient()
        
        //  Then
        XCTAssertTrue(storage.isEmpty())
        
        //  When
        let account = Account(issuer: "Rm9yZ2Vyb2Nr", accountName: "demo")
        storage.setAccount(account: account)
        
        //  Then
        XCTAssertFalse(storage.isEmpty())
    }
    
    
    func test_12_retrieve_notification_by_message_id() {
        
        let storage = KeychainServiceClient()
        let account = Account(issuer: "Rm9yZ2Vyb2Nr", accountName: "demo")
        storage.setAccount(account: account)
        
        let qrCode = URL(string: "pushauth://push/forgerock:demo?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI=&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr")!
        
        do {
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer, uid: parser.uid, resourceId: parser.resourceId)
            storage.setMechanism(mechanism: mechanism)
            
            let payload1: [String: String] = ["c": "j4i8MSuGOcqfslLpRMsYWUMkfsZnsgTCcgNZ+WN3MEE=", "l": "ZnJfc3NvX2FtbGJfcHJvZD0wMQ==", "t": "120", "u": mechanism.mechanismUUID]

            let messageId1 = "AUTHENTICATE:e84233f8-9ecf-4456-91ad-2649c4103bc01569980570407"

            let notification1 = try PushNotification(messageId: messageId1, payload: payload1)
            
            storage.setNotification(notification: notification1)
            let notifications = storage.getAllNotificationsForMechanism(mechanism: mechanism)
            
            XCTAssertNotNil(notifications)
            XCTAssertEqual(notifications.count, 1)
            XCTAssertEqual(notifications.first?.messageId, messageId1)
            
            let storedNotification = storage.getNotificationByMessageId(messageId: messageId1)
            XCTAssertNotNil(storedNotification)
            XCTAssertEqual(storedNotification?.messageId, messageId1)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
}
