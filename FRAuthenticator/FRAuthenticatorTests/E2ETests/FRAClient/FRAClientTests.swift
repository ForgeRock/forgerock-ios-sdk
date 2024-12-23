// 
//  FRAClientTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020-2024 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class FRAClientTests: FRABaseTests {

    //  MARK: - StorageClient
    
    func test_01_storage_clinet_changed() {
        do {
            try FRAClient.setStorage(storage: DummyStorageClient())
            FRAClient.start()
            XCTAssertTrue(FRAClient.shared?.authenticatorManager.storageClient is DummyStorageClient)
            XCTAssertNotNil(FRAClient.shared)
        }
        catch {
            XCTFail("Unexpected failure on SDK init: \(error.localizedDescription)")
        }
    }
    
    
    func test_02_storage_client_changed_after_start() {
        do {
            try FRAClient.setStorage(storage: DummyStorageClient())
            FRAClient.start()
            XCTAssertTrue(FRAClient.shared?.authenticatorManager.storageClient is DummyStorageClient)
            try FRAClient.setStorage(storage: KeychainServiceClient())
        }
        catch FRAError.invalidStateForChangingStorage {
        }
        catch {
            XCTFail("Unexpected failure on SDK init: \(error.localizedDescription)")
        }
    }
    
    
    //  MARK: - Store Mechanisms
    
    func test_03_store_multiple_mechanisms_with_same_account_and_fail_for_duplication() {
        
        // Don't remove StorageClient for further testing
        self.shouldCleanup = false
        
        // Given
        let hotp = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=ForgeRock&counter=4&algorithm=SHA256")!
        let totp = URL(string: "otpauth://totp/Forgerock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        do {
            try FRAClient.setStorage(storage: DummyStorageClient())
            FRAClient.start()

            //  Store first Mechanism
            var ex = self.expectation(description: "FRAClient.createMechanismFromUri")
            FRAClient.shared?.createMechanismFromUri(uri: hotp, onSuccess: { (mechanism) in
                ex.fulfill()
            }, onError: { (error) in
                XCTFail("FRAClient.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
                ex.fulfill()
            })
            waitForExpectations(timeout: 60, handler: nil)
            
            XCTAssertEqual(FRAClient.shared?.getAllAccounts().count, 1)
            XCTAssertNotNil(FRAClient.shared?.getAccount(identifier: "ForgeRock-demo"))
            XCTAssertEqual(FRAClient.shared?.getAccount(identifier: "ForgeRock-demo")?.mechanisms.count, 1)
            
            //  Store second Mechanism under same Account
            ex = self.expectation(description: "FRAClient.createMechanismFromUri")
            FRAClient.shared?.createMechanismFromUri(uri: totp, onSuccess: { (mechanism) in
                ex.fulfill()
            }, onError: { (error) in
                XCTFail("FRAClient.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
                ex.fulfill()
            })
            waitForExpectations(timeout: 60, handler: nil)
            
            XCTAssertEqual(FRAClient.shared?.getAllAccounts().count, 1)
            XCTAssertNotNil(FRAClient.shared?.getAccount(identifier: "ForgeRock-demo"))
            XCTAssertEqual(FRAClient.shared?.getAccount(identifier: "ForgeRock-demo")?.mechanisms.count, 2)
            
            
            //  Store same TOTPMechanism under same Account
            let totp2 = URL(string: "otpauth://totp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=ForgeRock&digits=6&period=30")!
            ex = self.expectation(description: "FRAClient.createMechanismFromUri")
            FRAClient.shared?.createMechanismFromUri(uri: totp2, onSuccess: { (mechanism) in
                XCTFail("FRAClient.createMechanismFromUri was expected to fail for duplication; but somehow passed")
                ex.fulfill()
            }, onError: { (error) in
                switch error {
                case MechanismError.alreadyExists(let message):
                    XCTAssertEqual(message, "ForgeRock-demo-totp")
                    break
                default:
                    XCTFail("FRAClient.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
                    break
                }
                ex.fulfill()
            })
            waitForExpectations(timeout: 60, handler: nil)
            
            
            //  Store same HOTPMechanism under same Account
            let hotp2 = URL(string: "otpauth://hotp/Forgerock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&counter=4&algorithm=SHA256")!
            ex = self.expectation(description: "FRAClient.createMechanismFromUri")
            FRAClient.shared?.createMechanismFromUri(uri: hotp2, onSuccess: { (mechanism) in
                XCTFail("FRAClient.createMechanismFromUri was expected to fail for duplication; but somehow passed")
                ex.fulfill()
            }, onError: { (error) in
                switch error {
                case MechanismError.alreadyExists(let message):
                    XCTAssertEqual(message, "ForgeRock-demo-hotp")
                    break
                default:
                    XCTFail("FRAClient.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
                    break
                }
                ex.fulfill()
            })
            waitForExpectations(timeout: 60, handler: nil)
            
            XCTAssertEqual(FRAClient.shared?.getAllAccounts().count, 1)
            XCTAssertNotNil(FRAClient.shared?.getAccount(identifier: "ForgeRock-demo"))
            XCTAssertEqual(FRAClient.shared?.getAccount(identifier: "ForgeRock-demo")?.mechanisms.count, 2)
            
            
            //  Store another Mechanism under different Account
            let diff = URL(string: "otpauth://totp/ForgeRock:demo?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRockSandbox&digits=6&period=30")!
            ex = self.expectation(description: "FRAClient.createMechanismFromUri")
            FRAClient.shared?.createMechanismFromUri(uri: diff, onSuccess: { (mechanism) in
                ex.fulfill()
            }, onError: { (error) in
                XCTFail("FRAClient.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
                ex.fulfill()
            })
            waitForExpectations(timeout: 60, handler: nil)
                        
            XCTAssertEqual(FRAClient.shared?.getAllAccounts().count, 2)
            XCTAssertNotNil(FRAClient.shared?.getAccount(identifier: "ForgeRock-demo"))
            XCTAssertEqual(FRAClient.shared?.getAccount(identifier: "ForgeRock-demo")?.mechanisms.count, 2)
            XCTAssertNotNil(FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-demo"))
            XCTAssertEqual(FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-demo")?.mechanisms.count, 1)
        }
        catch {
            XCTFail("Unexpected failure on SDK init: \(error.localizedDescription)")
        }
    }
    
    func test_04_account_removal_from_previous_test() {
        
        self.shouldCleanup = true
        guard let fraClient = FRAClient.shared, let storageClient = fraClient.authenticatorManager.storageClient as? DummyStorageClient else {
            XCTFail("Invalid SDK state")
            return
        }
        
        //  Make sure all results were persisted from previous test
        XCTAssertEqual(fraClient.getAllAccounts().count, 2)
        XCTAssertNotNil(fraClient.getAccount(identifier: "ForgeRock-demo"))
        XCTAssertEqual(fraClient.getAccount(identifier: "ForgeRock-demo")?.mechanisms.count, 2)
        XCTAssertNotNil(fraClient.getAccount(identifier: "ForgeRockSandbox-demo"))
        XCTAssertEqual(fraClient.getAccount(identifier: "ForgeRockSandbox-demo")?.mechanisms.count, 1)
        
        //  When
        guard let account1 = fraClient.getAccount(identifier: "ForgeRockSandbox-demo") else {
            XCTFail("Failed to retrieve already stored Account object")
            return
        }
        XCTAssertTrue(fraClient.removeAccount(account: account1))
        //  Then
        XCTAssertEqual(fraClient.getAllAccounts().count, 1)
        XCTAssertNotNil(fraClient.getAccount(identifier: "ForgeRock-demo"))
        XCTAssertEqual(fraClient.getAccount(identifier: "ForgeRock-demo")?.mechanisms.count, 2)
        XCTAssertNil(fraClient.getAccount(identifier: "ForgeRockSandbox-demo"))
        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 2)
        
        //  When
        guard let account2 = fraClient.getAccount(identifier: "ForgeRock-demo") else {
            XCTFail("Failed to retrieve already stored Account object")
            return
        }
        XCTAssertTrue(fraClient.removeAccount(account: account2))
        XCTAssertNil(fraClient.getAccount(identifier: "ForgeRockSandbox-demo"))
        XCTAssertNil(fraClient.getAccount(identifier: "ForgeRock-demo"))
        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 0)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 0)
    }
    
    
    func test_05_push_mechanism_tests() {
        do {
            self.loadMockResponses(["AM_Push_Registration_Successful", "AM_Push_Authentication_Successful", "AM_Push_Authentication_Successful", "AM_Push_Authentication_Successful"])
            // Set DeviceToken before PushMechnaism registration
            let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
            guard let deviceToken = deviceTokenStr.decodeBase64() else {
                XCTFail("Failed to parse device token data")
                return
            }
            FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
            let storageClient = DummyStorageClient()
            try FRAClient.setStorage(storage: storageClient)
            FRAClient.start()
            
            let push = URL(string: "pushauth://push/ForgeRockSandbox:pushtestuser?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=-3xGWaKjfls_ZHFRnGeIvFHn--GxzjQyg1RVG_Pak1s&c=esDK4G8eYce0_Gdf4p9XGGg2cIYYoxf6CTlL_O_1aF8&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:593b6a92-f5c1-4ac0-a94a-a63e05451dd51589138620791&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!
            
            //  Store first Mechanism
            var ex = self.expectation(description: "FRAClient.createMechanismFromUri")
            FRAClient.shared?.createMechanismFromUri(uri: push, onSuccess: { (mechanism) in
                ex.fulfill()
            }, onError: { (error) in
                XCTFail("FRAClient.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
                ex.fulfill()
            })
            waitForExpectations(timeout: 60, handler: nil)
            
            XCTAssertEqual(FRAClient.shared?.getAllAccounts().count, 1)
            XCTAssertNotNil(FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser"))
            XCTAssertEqual(FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser")?.mechanisms.count, 1)
            
            XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
            XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
            XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 0)
            
            
            //  Make sure to mimic MechanismUUID
            guard let account = FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser"),
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
            
            var pushAccount = FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser")
            var pushMechanism = pushAccount?.mechanisms.first as? PushMechanism
            var notification = pushMechanism?.notifications.first
            
            XCTAssertEqual(notification?.isPending, true)
            XCTAssertEqual(notification?.isDenied, false)
            XCTAssertEqual(notification?.isApproved, false)
            XCTAssertEqual(notification?.isExpired, false)
            XCTAssertEqual(pushMechanism?.notifications.count, 1)
            XCTAssertEqual(pushMechanism?.pendingNotifications.count, 1)
            
            ex = self.expectation(description: "PushNotification.accept - #1")
            notification?.accept(onSuccess: {
                ex.fulfill()
            }, onError: { (error) in
                XCTFail("Failed to authenticate PushNotification: \(error.localizedDescription)")
                ex.fulfill()
            })
            waitForExpectations(timeout: 60, handler: nil)
            XCTAssertEqual(pushMechanism?.pendingNotifications.count, 0)
            
            
            pushAccount = FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser")
            pushMechanism = pushAccount?.mechanisms.first as? PushMechanism
            notification = pushMechanism?.notifications.first
            
            XCTAssertEqual(notification?.isPending, false)
            XCTAssertEqual(notification?.isDenied, false)
            XCTAssertEqual(notification?.isApproved, true)
            XCTAssertEqual(notification?.isExpired, false)
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
            
            pushAccount = FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser")
            pushMechanism = pushAccount?.mechanisms.first as? PushMechanism
            notification = pushMechanism?.notifications.last
            
            XCTAssertEqual(notification?.isPending, true)
            XCTAssertEqual(notification?.isDenied, false)
            XCTAssertEqual(notification?.isApproved, false)
            XCTAssertEqual(notification?.isExpired, false)
            XCTAssertEqual(pushMechanism?.notifications.count, 2)
            XCTAssertEqual(pushMechanism?.pendingNotifications.count, 1)
            
            ex = self.expectation(description: "PushNotification.accept - #2")
            notification?.deny(onSuccess: {
                ex.fulfill()
            }, onError: { (error) in
                XCTFail("Failed to authenticate PushNotification: \(error.localizedDescription)")
                ex.fulfill()
            })
            waitForExpectations(timeout: 60, handler: nil)
            XCTAssertEqual(pushMechanism?.pendingNotifications.count, 0)
            
            
            pushAccount = FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser")
            pushMechanism = pushAccount?.mechanisms.first as? PushMechanism
            notification = pushMechanism?.notifications.last
            
            XCTAssertEqual(notification?.isPending, false)
            XCTAssertEqual(notification?.isDenied, true)
            XCTAssertEqual(notification?.isApproved, false)
            XCTAssertEqual(notification?.isExpired, false)
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
            
            pushAccount = FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser")
            pushMechanism = pushAccount?.mechanisms.first as? PushMechanism
            notification = pushMechanism?.notifications.last
            
            XCTAssertEqual(notification?.isPending, true)
            XCTAssertEqual(notification?.isDenied, false)
            XCTAssertEqual(notification?.isApproved, false)
            XCTAssertEqual(notification?.isExpired, false)
            XCTAssertEqual(pushMechanism?.notifications.count, 3)
            XCTAssertEqual(pushMechanism?.pendingNotifications.count, 1)
            
            ex = self.expectation(description: "PushNotification.accept - #2")
            notification?.accept(onSuccess: {
                ex.fulfill()
            }, onError: { (error) in
                XCTFail("Failed to authenticate PushNotification: \(error.localizedDescription)")
                ex.fulfill()
            })
            waitForExpectations(timeout: 60, handler: nil)
            XCTAssertEqual(pushMechanism?.pendingNotifications.count, 0)
            
            
            pushAccount = FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser")
            pushMechanism = pushAccount?.mechanisms.first as? PushMechanism
            notification = pushMechanism?.notifications.last
            
            XCTAssertEqual(notification?.isPending, false)
            XCTAssertEqual(notification?.isDenied, false)
            XCTAssertEqual(notification?.isApproved, true)
            XCTAssertEqual(notification?.isExpired, false)
            XCTAssertEqual(pushMechanism?.notifications.count, 3)
            
            XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
            XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
            XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 3)
            
            //  All PushNotification must be retrieved in order
            if let notifications = pushMechanism?.notifications, notifications.count == 3 {
                notifications[0].messageId = "AUTHENTICATE:64e909a2-84db-4ee8-b244-f0dbbeb8b0ff1589151035455"
                notifications[1].messageId = "AUTHENTICATE:0666696b-859d-4565-b069-f13c800c5e3c1589151071515"
                notifications[2].messageId = "AUTHENTICATE:929d72b7-c3e6-4460-a7b6-8e1c950b43361589151096771"
            }
            
            // Get push notification by messageId
            guard let notification1 = FRAClient.shared?.getNotificationByMessageId(messageId: "AUTHENTICATE:64e909a2-84db-4ee8-b244-f0dbbeb8b0ff1589151035455") else {
                XCTFail("Failed to retrieve PushNotification by messageId")
                return
            }
            XCTAssertEqual(notification1.messageId, "AUTHENTICATE:64e909a2-84db-4ee8-b244-f0dbbeb8b0ff1589151035455")
            
            
            //  Remove Account object
            //  When
            guard let fraClient = FRAClient.shared, let pushAccountDelete = FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser") else {
                XCTFail("Failed to retrieve already stored Account object")
                return
            }
            XCTAssertTrue(fraClient.removeAccount(account: pushAccountDelete))
            
            XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 0)
            XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 0)
            XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 0)
        }
        catch {
            XCTFail("Unexpected failure on SDK init: \(error.localizedDescription)")
        }
    }
    
    
    func test_06_remove_mechanism_notification() {
        do {
            self.loadMockResponses(["AM_Push_Registration_Successful", "AM_Push_Authentication_Successful", "AM_Push_Authentication_Successful", "AM_Push_Authentication_Successful"])
            // Set DeviceToken before PushMechnaism registration
            let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
            guard let deviceToken = deviceTokenStr.decodeBase64() else {
                XCTFail("Failed to parse device token data")
                return
            }
            FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
            let storageClient = DummyStorageClient()
            try FRAClient.setStorage(storage: storageClient)
            FRAClient.start()
            
            let push = URL(string: "pushauth://push/ForgeRockSandbox:pushtestuser?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=-3xGWaKjfls_ZHFRnGeIvFHn--GxzjQyg1RVG_Pak1s&c=esDK4G8eYce0_Gdf4p9XGGg2cIYYoxf6CTlL_O_1aF8&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:593b6a92-f5c1-4ac0-a94a-a63e05451dd51589138620791&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!
            
            //  Store first Mechanism
            var ex = self.expectation(description: "FRAClient.createMechanismFromUri")
            FRAClient.shared?.createMechanismFromUri(uri: push, onSuccess: { (mechanism) in
                ex.fulfill()
            }, onError: { (error) in
                XCTFail("FRAClient.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
                ex.fulfill()
            })
            waitForExpectations(timeout: 60, handler: nil)
            
            XCTAssertEqual(FRAClient.shared?.getAllAccounts().count, 1)
            XCTAssertNotNil(FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser"))
            XCTAssertEqual(FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser")?.mechanisms.count, 1)
            
            XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
            XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
            XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 0)
            
            
            //  Make sure to mimic MechanismUUID
            guard let account = FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser"),
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
            
            var pushAccount = FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser")
            var pushMechanism = pushAccount?.mechanisms.first as? PushMechanism
            var notification = pushMechanism?.notifications.first
            
            XCTAssertEqual(notification?.isPending, true)
            XCTAssertEqual(notification?.isDenied, false)
            XCTAssertEqual(notification?.isApproved, false)
            XCTAssertEqual(notification?.isExpired, false)
            XCTAssertEqual(pushMechanism?.notifications.count, 1)
            
            ex = self.expectation(description: "PushNotification.accept - #1")
            notification?.accept(onSuccess: {
                ex.fulfill()
            }, onError: { (error) in
                XCTFail("Failed to authenticate PushNotification: \(error.localizedDescription)")
                ex.fulfill()
            })
            waitForExpectations(timeout: 60, handler: nil)
            
            
            pushAccount = FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser")
            pushMechanism = pushAccount?.mechanisms.first as? PushMechanism
            notification = pushMechanism?.notifications.first
            
            XCTAssertEqual(notification?.isPending, false)
            XCTAssertEqual(notification?.isDenied, false)
            XCTAssertEqual(notification?.isApproved, true)
            XCTAssertEqual(notification?.isExpired, false)
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
            
            pushAccount = FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser")
            pushMechanism = pushAccount?.mechanisms.first as? PushMechanism
            notification = pushMechanism?.notifications.last
            
            XCTAssertEqual(notification?.isPending, true)
            XCTAssertEqual(notification?.isDenied, false)
            XCTAssertEqual(notification?.isApproved, false)
            XCTAssertEqual(notification?.isExpired, false)
            XCTAssertEqual(pushMechanism?.notifications.count, 2)
            
            ex = self.expectation(description: "PushNotification.accept - #2")
            notification?.deny(onSuccess: {
                ex.fulfill()
            }, onError: { (error) in
                XCTFail("Failed to authenticate PushNotification: \(error.localizedDescription)")
                ex.fulfill()
            })
            waitForExpectations(timeout: 60, handler: nil)
            
            
            pushAccount = FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser")
            pushMechanism = pushAccount?.mechanisms.first as? PushMechanism
            notification = pushMechanism?.notifications.last
            
            XCTAssertEqual(notification?.isPending, false)
            XCTAssertEqual(notification?.isDenied, true)
            XCTAssertEqual(notification?.isApproved, false)
            XCTAssertEqual(notification?.isExpired, false)
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
            
            pushAccount = FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser")
            pushMechanism = pushAccount?.mechanisms.first as? PushMechanism
            notification = pushMechanism?.notifications.last
            
            XCTAssertEqual(notification?.isPending, true)
            XCTAssertEqual(notification?.isDenied, false)
            XCTAssertEqual(notification?.isApproved, false)
            XCTAssertEqual(notification?.isExpired, false)
            XCTAssertEqual(pushMechanism?.notifications.count, 3)
            
            ex = self.expectation(description: "PushNotification.accept - #2")
            notification?.accept(onSuccess: {
                ex.fulfill()
            }, onError: { (error) in
                XCTFail("Failed to authenticate PushNotification: \(error.localizedDescription)")
                ex.fulfill()
            })
            waitForExpectations(timeout: 60, handler: nil)
            
            
            pushAccount = FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser")
            pushMechanism = pushAccount?.mechanisms.first as? PushMechanism
            notification = pushMechanism?.notifications.last
            
            XCTAssertEqual(notification?.isPending, false)
            XCTAssertEqual(notification?.isDenied, false)
            XCTAssertEqual(notification?.isApproved, true)
            XCTAssertEqual(notification?.isExpired, false)
            XCTAssertEqual(pushMechanism?.notifications.count, 3)
            
            XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
            XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
            XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 3)
            
            //  All PushNotification must be retrieved in order
            if let notifications = pushMechanism?.notifications, notifications.count == 3 {
                notifications[0].messageId = "AUTHENTICATE:64e909a2-84db-4ee8-b244-f0dbbeb8b0ff1589151035455"
                notifications[1].messageId = "AUTHENTICATE:0666696b-859d-4565-b069-f13c800c5e3c1589151071515"
                notifications[2].messageId = "AUTHENTICATE:929d72b7-c3e6-4460-a7b6-8e1c950b43361589151096771"
            }
            
            
            //  Remove Notification object
            //  When
            pushAccount = FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser")
            pushMechanism = pushAccount?.mechanisms.first as? PushMechanism
            
            guard let fraClient = FRAClient.shared, let notification2 = pushMechanism?.notifications[1] else {
                XCTFail("Failed to read shared FRAClient")
                return
            }
            XCTAssertNotNil(pushAccount)
            XCTAssertNotNil(pushMechanism)
            XCTAssertTrue(fraClient.removeNotification(notification: notification2))
            
            XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
            XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
            XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 2)
            
            
            pushAccount = FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser")
            pushMechanism = pushAccount?.mechanisms.first as? PushMechanism
            XCTAssertEqual(pushMechanism?.notifications.count, 2)
            //  All PushNotification must be retrieved in order
            if let notifications = pushMechanism?.notifications, notifications.count == 2 {
                notifications[0].messageId = "AUTHENTICATE:64e909a2-84db-4ee8-b244-f0dbbeb8b0ff1589151035455"
                notifications[1].messageId = "AUTHENTICATE:929d72b7-c3e6-4460-a7b6-8e1c950b43361589151096771"
            }
            
            guard let mechanismToDelete = pushMechanism else {
                XCTFail("Failed to read Mechanism object from storage")
                return
            }
            
            fraClient.removeMechanism(mechanism: mechanismToDelete)
            XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
            XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 0)
            XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 0)
        }
        catch {
            XCTFail("Unexpected failure on SDK init: \(error.localizedDescription)")
        }
    }
    
    
    func test_07_get_all_notifications_for_mechanism() {
        
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
        
        FRAClient.start()
        guard let thisMechanism = pushMechanism else {
            XCTFail("Failed to retrieve PushMechanism")
            return
        }
        guard let notifications = FRAClient.shared?.getAllNotifications(mechanism: thisMechanism) else {
            XCTFail("Failed to retrieve PushNotification array")
            return
        }
        XCTAssertEqual(notifications.count, 3)
        XCTAssertEqual(notifications[0].messageId, "AUTHENTICATE:64e909a2-84db-4ee8-b244-f0dbbeb8b0ff1589151035455")
        XCTAssertEqual(notifications[1].messageId, "AUTHENTICATE:0666696b-859d-4565-b069-f13c800c5e3c1589151071515")
        XCTAssertEqual(notifications[2].messageId, "AUTHENTICATE:929d72b7-c3e6-4460-a7b6-8e1c950b43361589151096771")
    }
    
    
    func test_08_get_all_notifications() {
        
        let storageClient = DummyStorageClient()
        let policyEvaluator = FRAPolicyEvaluator()
        let authenticatorManager = AuthenticatorManager(storageClient: storageClient, policyEvaluator: policyEvaluator)

        self.loadMockResponses(["AM_Push_Registration_Successful", "AM_Push_Registration_Successful"])
        // Set DeviceToken before PushMechnaism registration
        let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
        guard let deviceToken = deviceTokenStr.decodeBase64() else {
           XCTFail("Failed to parse device token data")
           return
        }
        FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)

        let push = URL(string: "pushauth://push/ForgeRockSandbox:pushtestuser?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=-3xGWaKjfls_ZHFRnGeIvFHn--GxzjQyg1RVG_Pak1s&c=esDK4G8eYce0_Gdf4p9XGGg2cIYYoxf6CTlL_O_1aF8&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:593b6a92-f5c1-4ac0-a94a-a63e05451dd51589138620791&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!

        let push2 = URL(string: "pushauth://push/ForgeRock:pushtestuser2?a=aHR0cDovL2Rldi5vcGVuYW0uZXhhbXBsZS5jb206ODA4MS9vcGVuYW0vanNvbi9kZXYvcHVzaC9zbnMvbWVzc2FnZT9fYWN0aW9uPWF1dGhlbnRpY2F0ZQ&b=519387&r=aHR0cDovL2Rldi5vcGVuYW0uZXhhbXBsZS5jb206ODA4MS9vcGVuYW0vanNvbi9kZXYvcHVzaC9zbnMvbWVzc2FnZT9fYWN0aW9uPXJlZ2lzdGVy&s=b3uYLkQ7dRPjBaIzV0t_aijoXRgMq-NP5AwVAvRfa_E&c=9giiBAdUHjqpo0XE4YdZ7pRlv0hrQYwDz8Z1wwLLbkg&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:8be951c6-af83-438d-8f74-421bd18650421570561063169&issuer=Rm9yZ2VSb2Nr")!
        
        //  Store first Mechanism
        let ex = self.expectation(description: "FRAClient.createMechanismFromUri")
        authenticatorManager.createMechanismFromUri(uri: push, onSuccess: { (mechanism) in
           ex.fulfill()
        }, onError: { (error) in
           XCTFail("authenticatorManager.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
           ex.fulfill()
        })
        waitForExpectations(timeout: 60, handler: nil)

        
        //  Store second Mechanism
        let ex2 = self.expectation(description: "FRAClient.createMechanismFromUri")
        authenticatorManager.createMechanismFromUri(uri: push2, onSuccess: { (mechanism) in
           ex2.fulfill()
        }, onError: { (error) in
           XCTFail("authenticatorManager.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
           ex2.fulfill()
        })
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertEqual(authenticatorManager.getAllAccounts().count, 2)
        XCTAssertNotNil(authenticatorManager.getAccount(identifier: "ForgeRockSandbox-pushtestuser"))
        XCTAssertEqual(authenticatorManager.getAccount(identifier: "ForgeRockSandbox-pushtestuser")?.mechanisms.count, 1)
        XCTAssertNotNil(authenticatorManager.getAccount(identifier: "ForgeRock-pushtestuser2"))
        XCTAssertEqual(authenticatorManager.getAccount(identifier: "ForgeRock-pushtestuser2")?.mechanisms.count, 1)
        
        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 2)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 2)
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

        guard let account2 = authenticatorManager.getAccount(identifier: "ForgeRock-pushtestuser2"),
           let mechanism2 = account2.mechanisms.first as? PushMechanism else {
           XCTFail("Failed to retrieve PushMechanism")
           return
        }
        //  Update Mechanism with UUID
        mechanism2.mechanismUUID = "862BCE9A-A74A-33D2-181D-77F6B54C3A10"
        XCTAssertTrue(FRAClient.storage.setMechanism(mechanism: mechanism2))
        
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
        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 2)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 2)
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

        XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 2)
        XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 2)
        XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 2)


        //  Fake third remote-message receive action
        payload = [:]
        aps = [:]
        aps["messageId"] = "AUTHENTICATE:929d72b7-c3e6-4460-a7b6-8e1c950b43361589151096771"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoiTVkzR01Fbkl6M3EweHFkR0wrMUdBaWNKdGxFVkhGenRsaVpTS1ZqdEZpaz0iLCJ0IjoiMTIwIiwidSI6Ijg2MkJDRTlBLUE3NEEtMzNEMi0xODFELTc3RjZCNTRDM0ExMCIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSJ9.bcQqQ3zl0U9pvQEryEDtcJhrVbYxbVTLPvm9kcfyF5Y"
        aps["sound"] = "default"

        payload["aps"] = aps

        guard let _ = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload) else {
            XCTFail("Failed to parse notification payload and construct PushNotification object")
            return
        }
        
        pushAccount = authenticatorManager.getAccount(identifier: "ForgeRock-pushtestuser2")
        pushMechanism = pushAccount?.mechanisms.first as? PushMechanism

        XCTAssertEqual(pushMechanism?.notifications.count, 1)
        
        FRAClient.start()
        guard let notifications = FRAClient.shared?.getAllNotifications() else {
            XCTFail("Failed to retrieve PushNotification array")
            return
        }
        XCTAssertEqual(notifications.count, 3)
        XCTAssertEqual(notifications[0].messageId, "AUTHENTICATE:64e909a2-84db-4ee8-b244-f0dbbeb8b0ff1589151035455")
        XCTAssertEqual(notifications[1].messageId, "AUTHENTICATE:0666696b-859d-4565-b069-f13c800c5e3c1589151071515")
        XCTAssertEqual(notifications[2].messageId, "AUTHENTICATE:929d72b7-c3e6-4460-a7b6-8e1c950b43361589151096771")
    }
    
    
    func test_09_get_account_from_mechanism() {
        let hotp = URL(string: "otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=4&algorithm=SHA256")!
        
        do {
            try FRAClient.setStorage(storage: DummyStorageClient())
            FRAClient.start()

            //  Store first Mechanism
            var uuid = ""
            let ex = self.expectation(description: "FRAClient.createMechanismFromUri")
            FRAClient.shared?.createMechanismFromUri(uri: hotp, onSuccess: { (mechanism) in
                uuid = mechanism.mechanismUUID
                ex.fulfill()
            }, onError: { (error) in
                XCTFail("FRAClient.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
                ex.fulfill()
            })
            waitForExpectations(timeout: 60, handler: nil)
            
            XCTAssertEqual(FRAClient.shared?.getAllAccounts().count, 1)
            
            guard let mechanism = FRAClient.storage.getMechanismForUUID(uuid: uuid) else {
                XCTFail("Failed to retrieve Mechanism object")
                return
            }
            
            let account = FRAClient.shared?.getAccount(mechanism: mechanism)
            XCTAssertNotNil(account)
            XCTAssertEqual(account?.issuer, "Forgerock")
            XCTAssertEqual(account?.accountName, "demo")
        }
        catch {
            XCTFail("Failed to initialize SDK: \(error.localizedDescription)")
            return
        }
    }
    
    
    func test_10_get_push_mechanism_from_notification() {
        do {
            self.loadMockResponses(["AM_Push_Registration_Successful", "AM_Push_Authentication_Successful"])
            // Set DeviceToken before PushMechnaism registration
            let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
            guard let deviceToken = deviceTokenStr.decodeBase64() else {
                XCTFail("Failed to parse device token data")
                return
            }
            FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
            let storageClient = DummyStorageClient()
            try FRAClient.setStorage(storage: storageClient)
            FRAClient.start()

            let push = URL(string: "pushauth://push/ForgeRockSandbox:pushtestuser?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=-3xGWaKjfls_ZHFRnGeIvFHn--GxzjQyg1RVG_Pak1s&c=esDK4G8eYce0_Gdf4p9XGGg2cIYYoxf6CTlL_O_1aF8&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:593b6a92-f5c1-4ac0-a94a-a63e05451dd51589138620791&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!
            
            //  Store first Mechanism
            let ex = self.expectation(description: "FRAClient.createMechanismFromUri")
            FRAClient.shared?.createMechanismFromUri(uri: push, onSuccess: { (mechanism) in
                ex.fulfill()
            }, onError: { (error) in
            XCTFail("FRAClient.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
                ex.fulfill()
            })
            waitForExpectations(timeout: 60, handler: nil)

            XCTAssertEqual(FRAClient.shared?.getAllAccounts().count, 1)
            XCTAssertNotNil(FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser"))
            XCTAssertEqual(FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser")?.mechanisms.count, 1)

            XCTAssertEqual(storageClient.defaultStorageClient.accountStorage.allItems()?.count, 1)
            XCTAssertEqual(storageClient.defaultStorageClient.mechanismStorage.allItems()?.count, 1)
            XCTAssertEqual(storageClient.defaultStorageClient.notificationStorage.allItems()?.count, 0)


            //  Make sure to mimic MechanismUUID
            guard let account = FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser"),
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

            guard let notification = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload) else {
                XCTFail("Failed to parse notification payload and construct PushNotification object")
                return
            }
            
            let expectedMechanism = FRAClient.shared?.getMechanism(notification: notification)
            XCTAssertNotNil(expectedMechanism)
            XCTAssertEqual(expectedMechanism?.mechanismUUID, "759ACE9D-C64B-43E6-981D-97F7B54C3B01")
        }
        catch {
            XCTFail("Unexpected failure on SDK init: \(error.localizedDescription)")
        }
    }
       
    func test_13_store_combined_mechanisms_with_same_oath_account_and_fail() {
        
        self.shouldCleanup = true
        
        // Given
        let totp = URL(string: "otpauth://totp/ForgeRock:demo1?secret=T7SIIEPTZJQQDSCB&issuer=ForgeRock&digits=6&period=30")!
        
        do {
            self.loadMockResponses(["AM_Push_Registration_Successful", "AM_Push_Authentication_Successful", "AM_Push_Authentication_Successful", "AM_Push_Authentication_Successful"])
            // Set DeviceToken before PushMechnaism registration
            let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
            guard let deviceToken = deviceTokenStr.decodeBase64() else {
                XCTFail("Failed to parse device token data")
                return
            }
            FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
            try FRAClient.setStorage(storage: DummyStorageClient())
            FRAClient.start()

            //  Store OATH Mechanism
            var ex = self.expectation(description: "FRAClient.createMechanismFromUri")
            FRAClient.shared?.createMechanismFromUri(uri: totp, onSuccess: { (mechanism) in
                ex.fulfill()
            }, onError: { (error) in
                XCTFail("FRAClient.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
                ex.fulfill()
            })
            waitForExpectations(timeout: 60, handler: nil)
            
            XCTAssertEqual(FRAClient.shared?.getAllAccounts().count, 1)
            XCTAssertNotNil(FRAClient.shared?.getAccount(identifier: "ForgeRock-demo1"))
            XCTAssertEqual(FRAClient.shared?.getAccount(identifier: "ForgeRock-demo1")?.mechanisms.count, 1)
            
            //  Store Combined Mechanism under same Account
            let diff = URL(string: "mfauth://totp/ForgeRock:demo1?" +
                             "a=aHR0cHM6Ly9mb3JnZXJvY2suZXhhbXBsZS5jb20vb3BlbmFtL2pzb24vcHVzaC9zbnMvbWVzc2FnZT9fYWN0aW9uPWF1dGhlbnRpY2F0ZQ&" +
                             "image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&" +
                             "b=ff00ff&" +
                             "r=aHR0cHM6Ly9mb3JnZXJvY2suZXhhbXBsZS5jb20vb3BlbmFtL2pzb24vcHVzaC9zbnMvbWVzc2FnZT9fYWN0aW9uPXJlZ2lzdGVy&" +
                             "s=ryJkqNRjXYd_nX523672AX_oKdVXrKExq-VjVeRKKTc&" +
                             "c=Daf8vrc8onKu-dcptwCRS9UHmdui5u16vAdG2HMU4w0&" +
                             "l=YW1sYmNvb2tpZT0wMQ==&" +
                             "m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&" +
                             "digits=6&" +
                             "secret=R2PYFZRISXA5L25NVSSYK2RQ6E======&" +
                             "period=30&" +
                             "issuer=Rm9yZ2VSb2Nr")!
            
            ex = self.expectation(description: "FRAClient.createMechanismFromUri")
            FRAClient.shared?.createMechanismFromUri(uri: diff, onSuccess: { (mechanism) in
                XCTFail("FRAClient.createMechanismFromUri was expected to fail for duplication; but somehow passed")
                ex.fulfill()
            }, onError: { (error) in
                switch error {
                case MechanismError.alreadyExists(let message):
                    XCTAssertEqual(message, "ForgeRock-demo1-totp")
                    break
                default:
                    XCTFail("FRAClient.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
                    break
                }
                ex.fulfill()
            })
            waitForExpectations(timeout: 60, handler: nil)
                        
            XCTAssertEqual(FRAClient.shared?.getAllAccounts().count, 1)
            XCTAssertNotNil(FRAClient.shared?.getAccount(identifier: "ForgeRock-demo1"))
            XCTAssertEqual(FRAClient.shared?.getAccount(identifier: "ForgeRock-demo1")?.mechanisms.count, 1)
        }
        catch {
            XCTFail("Unexpected failure on SDK init: \(error.localizedDescription)")
        }
    }
    
    func test_14_store_combined_mechanisms_with_same_push_account_and_fail() {
        self.shouldCleanup = true
        
        // Given
        let push = URL(string: "pushauth://push/ForgeRockSandbox:pushtestuser?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=-3xGWaKjfls_ZHFRnGeIvFHn--GxzjQyg1RVG_Pak1s&c=esDK4G8eYce0_Gdf4p9XGGg2cIYYoxf6CTlL_O_1aF8&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:593b6a92-f5c1-4ac0-a94a-a63e05451dd51589138620791&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!
        
        do {
            self.loadMockResponses(["AM_Push_Registration_Successful", "AM_Push_Authentication_Successful"])
            // Set DeviceToken before PushMechnaism registration
            let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
            guard let deviceToken = deviceTokenStr.decodeBase64() else {
                XCTFail("Failed to parse device token data")
                return
            }
            FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
            try FRAClient.setStorage(storage: DummyStorageClient())
            FRAClient.start()

            //  Store first Mechanism
            var ex = self.expectation(description: "FRAClient.createMechanismFromUri")
            FRAClient.shared?.createMechanismFromUri(uri: push, onSuccess: { (mechanism) in
                ex.fulfill()
            }, onError: { (error) in
            XCTFail("FRAClient.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
                ex.fulfill()
            })
            waitForExpectations(timeout: 60, handler: nil)

            XCTAssertEqual(FRAClient.shared?.getAllAccounts().count, 1)
            XCTAssertNotNil(FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser"))
            XCTAssertEqual(FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser")?.mechanisms.count, 1)

            //  Store Combined Mechanism under same Account
            let diff = URL(string: "mfauth://totp/ForgeRockSandbox:pushtestuser?" +
                             "a=aHR0cHM6Ly9mb3JnZXJvY2suZXhhbXBsZS5jb20vb3BlbmFtL2pzb24vcHVzaC9zbnMvbWVzc2FnZT9fYWN0aW9uPWF1dGhlbnRpY2F0ZQ&" +
                             "image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&" +
                             "b=ff00ff&" +
                             "r=aHR0cHM6Ly9mb3JnZXJvY2suZXhhbXBsZS5jb20vb3BlbmFtL2pzb24vcHVzaC9zbnMvbWVzc2FnZT9fYWN0aW9uPXJlZ2lzdGVy&" +
                             "s=ryJkqNRjXYd_nX523672AX_oKdVXrKExq-VjVeRKKTc&" +
                             "c=Daf8vrc8onKu-dcptwCRS9UHmdui5u16vAdG2HMU4w0&" +
                             "l=YW1sYmNvb2tpZT0wMQ==&" +
                             "m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&" +
                             "digits=6&" +
                             "secret=R2PYFZRISXA5L25NVSSYK2RQ6E======&" +
                             "period=30&" +
                             "issuer=Rm9yZ2VSb2NrU2FuZGJveA")!
            
            ex = self.expectation(description: "FRAClient.createMechanismFromUri")
            FRAClient.shared?.createMechanismFromUri(uri: diff, onSuccess: { (mechanism) in
                XCTFail("FRAClient.createMechanismFromUri was expected to fail for duplication; but somehow passed")
                ex.fulfill()
            }, onError: { (error) in
                switch error {
                case MechanismError.alreadyExists(let message):
                    XCTAssertEqual(message, "ForgeRockSandbox-pushtestuser-push")
                    break
                default:
                    XCTFail("FRAClient.createMechanismFromUri failed with unexpected reason: \(error.localizedDescription)")
                    break
                }
                ex.fulfill()
            })
            waitForExpectations(timeout: 60, handler: nil)
                        
            XCTAssertEqual(FRAClient.shared?.getAllAccounts().count, 1)
            XCTAssertNotNil(FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser"))
            XCTAssertEqual(FRAClient.shared?.getAccount(identifier: "ForgeRockSandbox-pushtestuser")?.mechanisms.count, 1)

        }
        catch {
            XCTFail("Unexpected failure on SDK init: \(error.localizedDescription)")
        }
    }
}




//  MARK: - PolicyEvaluator

func test_11_policy_evaluator_changed() {
    do {
        let policyEvaluator = FRAPolicyEvaluator()
        try policyEvaluator.registerPolicies(policies: [DummyPolicy()])
        try FRAClient.setPolicyEvaluator(policyEvaluator: policyEvaluator)
        FRAClient.start()
        XCTAssertTrue(FRAClient.shared?.authenticatorManager.policyEvaluator.policies?.count == 1)
        XCTAssertNotNil(FRAClient.shared)
    }
    catch {
        XCTFail("Unexpected failure on SDK init: \(error.localizedDescription)")
    }
}


func test_12_policy_evaluator_changed_after_start() {
    do {
        try FRAClient.setStorage(storage: DummyStorageClient())
        FRAClient.start()
        XCTAssertTrue(FRAClient.shared?.authenticatorManager.storageClient is DummyStorageClient)
        let policyEvaluator = FRAPolicyEvaluator()
        try policyEvaluator.registerPolicies(policies: [DummyPolicy()])
        try FRAClient.setPolicyEvaluator(policyEvaluator: policyEvaluator)
    }
    catch FRAError.invalidStateForChangingPolicyEvaluator {
    }
    catch {
        XCTFail("Unexpected failure on SDK init: \(error.localizedDescription)")
    }
}
