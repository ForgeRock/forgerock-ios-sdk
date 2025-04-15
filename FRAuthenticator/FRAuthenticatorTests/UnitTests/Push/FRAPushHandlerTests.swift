// 
//  FRAPushHandlerTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020-2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class FRAPushHandlerTests: FRABaseTests {

    func test_01_set_device_token() {
        let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
        guard let deviceToken = deviceTokenStr.decodeBase64() else {
            XCTFail("Failed to parse device token data")
            return
        }
        FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        XCTAssertEqual(FRAPushHandler.shared.deviceToken, "3C9E9DEE4F2E33602F2BE4F58C94CC0580F9B28F92AC79EF54BA06CF632D7B70")
        
        let pushDeviceToken = FRAClient.storage.getPushDeviceToken()
        XCTAssertNotNil(pushDeviceToken)
        XCTAssertEqual(pushDeviceToken?.tokenId, "3C9E9DEE4F2E33602F2BE4F58C94CC0580F9B28F92AC79EF54BA06CF632D7B70")
    }
    
    
    func test_02_set_invalid_device_token() {
        FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: Data())
        XCTAssertEqual(FRAPushHandler.shared.deviceToken, "")
    }
    
    
    func test_03_fail_to_register_notification() {
        let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
        guard let deviceToken = deviceTokenStr.decodeBase64() else {
            XCTFail("Failed to parse device token data")
            return
        }
        FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        XCTAssertEqual(FRAPushHandler.shared.deviceToken, "3C9E9DEE4F2E33602F2BE4F58C94CC0580F9B28F92AC79EF54BA06CF632D7B70")
        
        FRAPushHandler.shared.application(UIApplication.shared, didFailToRegisterForRemoteNotificationsWithError: FRAError.invalidStateForChangingStorage)
        XCTAssertNil(FRAPushHandler.shared.deviceToken)
    }
    
    
    func test_04_get_notification_and_pushnotification_object() {
        
        // Given
        let qrCode = URL(string: "pushauth://push/forgerock:pushtestuser?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=-3xGWaKjfls_ZHFRnGeIvFHn--GxzjQyg1RVG_Pak1s&c=esDK4G8eYce0_Gdf4p9XGGg2cIYYoxf6CTlL_O_1aF8&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:593b6a92-f5c1-4ac0-a94a-a63e05451dd51589138620791&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!
        
        do {
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer, uid: parser.uid, resourceId: parser.resourceId)
            mechanism.mechanismUUID = "759ACE9D-C64B-43E6-981D-97F7B54C3B01"
            FRAClient.storage.setMechanism(mechanism: mechanism)
            var payload: [String: Any] = [:]
            var aps: [String: Any] = [:]
            aps["messageId"] = "AUTHENTICATE:e29b50b6-bf3d-4993-aa84-144d09fe19cf1589138699819"
            aps["content-available"] = true
            aps["alert"] = "Login attempt from user at ForgeRockSandbox"
            aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoibFltZmVQUzllYisrMWtpbzJJSUpBdHdVV1dDY1pDcytCU2dLUGpaS04yOD0iLCJ0IjoiMTIwIiwidSI6Ijc1OUFDRTlELUM2NEItNDNFNi05ODFELTk3RjdCNTRDM0IwMSIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSJ9.Kflihn5sCXFQ3TDWe8GBayCinguSLs9nsu4j4JxddtY"
            aps["sound"] = "default"

            payload["aps"] = aps

            guard let notification = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload) else {
               XCTFail("Failed to parse notification payload and construct PushNotification object")
               return
            }
            XCTAssertNotNil(notification)
            XCTAssertEqual(notification.messageId, "AUTHENTICATE:e29b50b6-bf3d-4993-aa84-144d09fe19cf1589138699819")
            XCTAssertEqual(notification.mechanismUUID, "759ACE9D-C64B-43E6-981D-97F7B54C3B01")
            XCTAssertEqual(notification.loadBalanceKey, "amlbcookie=01")
            XCTAssertEqual(notification.ttl, 120.0)
            XCTAssertTrue(notification.isPending)
            XCTAssertFalse(notification.isExpired)
            XCTAssertFalse(notification.isApproved)
            XCTAssertFalse(notification.isDenied)
        }
        catch {
            XCTFail("Failed to parse remote-notification: \(error.localizedDescription)")
        }
    }
    
    
    func test_05_parse_invalid_notification_payload_non_jwt() {
        
        var payload: [String: Any] = [:]
        var aps: [String: Any] = [:]
        
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoid3h3QWdtTmxWV1NvSSsxaTVjZUhEZFFkaEgxMTkrNE85S0N0amREYm9KST0iLCJ0IjoiMTIwIiwidSI6IkNCNENBN0I3LTQ0N0QtNEY4Ri1BODI5LTVCMUIxNTZEQzAwMSIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSJ9.RuwhTrgrOvDj-UUFOkyhZTKYkUpqa5kMEWYRCTQWNh0"
        aps["sound"] = "default"
        
        payload["aps"] = aps
        
        let notification = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload)
        XCTAssertNil(notification)
    }
    
    
    func test_06_parse_invalid_notification_payload_missing_message_id() {
        
        var payload: [String: Any] = [:]
        var aps: [String: Any] = [:]
        
        aps["messageId"] = "AUTHENTICATE:f7234068-7217-4d40-8184-58cb976b7d461588712419081"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "non-jwt"
        aps["sound"] = "default"
        
        payload["aps"] = aps
        
        let notification = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload)
        XCTAssertNil(notification)
    }
    
    
    func test_07_parse_invalid_notification_payload_missing_load_balancer_key_jwt_claim() {
    
        var payload: [String: Any] = [:]
        var aps: [String: Any] = [:]
        
        aps["messageId"] = "AUTHENTICATE:f7234068-7217-4d40-8184-58cb976b7d461588712419081"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoid3h3QWdtTmxWV1NvSSsxaTVjZUhEZFFkaEgxMTkrNE85S0N0amREYm9KST0iLCJ0IjoiMTIwIiwidSI6IkNCNENBN0I3LTQ0N0QtNEY4Ri1BODI5LTVCMUIxNTZEQzAwMSJ9.6CHMdmN0WRt-FmPzsdgVFch030bfFfSwjgBRikW94XQ"
        aps["sound"] = "default"
        
        payload["aps"] = aps
        
        let notification = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload)
        XCTAssertNil(notification)
    }
    
    
    func test_08_parse_invalid_notification_payload_mechanism_uuid_jwt_claim() {
    
        var payload: [String: Any] = [:]
        var aps: [String: Any] = [:]
        
        aps["messageId"] = "AUTHENTICATE:f7234068-7217-4d40-8184-58cb976b7d461588712419081"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoid3h3QWdtTmxWV1NvSSsxaTVjZUhEZFFkaEgxMTkrNE85S0N0amREYm9KST0iLCJ0IjoiMTIwIiwibCI6IllXMXNZbU52YjJ0cFpUMHdNUT09In0.GYdmtnA8r0nBzmg2ZSnlENyr0Pjoi8uEnRra_Cu-nh0"
        aps["sound"] = "default"
        
        payload["aps"] = aps
        
        let notification = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload)
        XCTAssertNil(notification)
    }
    
    
    func test_09_parse_invalid_notification_payload_ttl_jwt_claim() {
    
        var payload: [String: Any] = [:]
        var aps: [String: Any] = [:]
        
        aps["messageId"] = "AUTHENTICATE:f7234068-7217-4d40-8184-58cb976b7d461588712419081"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoid3h3QWdtTmxWV1NvSSsxaTVjZUhEZFFkaEgxMTkrNE85S0N0amREYm9KST0iLCJ1IjoiQ0I0Q0E3QjctNDQ3RC00RjhGLUE4MjktNUIxQjE1NkRDMDAxIiwibCI6IllXMXNZbU52YjJ0cFpUMHdNUT09In0.Jzdw5Wf59Ow1m8zsTRVRxy5iiOgACVu0V4P9MDoFneA"
        aps["sound"] = "default"
        
        payload["aps"] = aps
        
        let notification = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload)
        XCTAssertNil(notification)
    }
    
    
    func test_10_parse_invalid_notification_payload_challenge_jwt_claim() {
    
        var payload: [String: Any] = [:]
        var aps: [String: Any] = [:]
        
        aps["messageId"] = "AUTHENTICATE:f7234068-7217-4d40-8184-58cb976b7d461588712419081"
        aps["content-available"] = true
        aps["alert"] = "Login attempt from user at ForgeRockSandbox"
        aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ0IjoiMTIwIiwidSI6IkNCNENBN0I3LTQ0N0QtNEY4Ri1BODI5LTVCMUIxNTZEQzAwMSIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSJ9.jMiSNb8fMvA0kDWK1L1eePQo6T8zsjeYEHMEAlo_awk"
        aps["sound"] = "default"
        
        payload["aps"] = aps
        
        let notification = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload)
        XCTAssertNil(notification)
    }
    
    
    func test_11_pushnotification_already_exist() {
        
        // Given
        let storage = KeychainServiceClient()
        let account = Account(issuer: "Rm9yZ2Vyb2Nr", accountName: "demo")
        storage.setAccount(account: account)
        
        let qrCode = URL(string: "pushauth://push/forgerock:demo?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI=&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr")!
        
        do {
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer, uid: parser.uid, resourceId: parser.resourceId)
            mechanism.mechanismUUID = "759ACE9D-C64B-43E6-981D-97F7B54C3B01"
            FRAClient.storage.setMechanism(mechanism: mechanism)
            
            let payload: [String: String] = ["c": "j4i8MSuGOcqfslLpRMsYWUMkfsZnsgTCcgNZ+WN3MEE=", "l": "ZnJfc3NvX2FtbGJfcHJvZD0wMQ==", "t": "120", "u": mechanism.mechanismUUID, "messageId": "AUTHENTICATE:e84233f8-9ecf-4456-91ad-2649c4103bc01569980570407"]

            let messageId = "AUTHENTICATE:e84233f8-9ecf-4456-91ad-2649c4103bc01569980570407"

            let notification = try PushNotification(messageId: messageId, payload: payload)
            
            storage.setNotification(notification: notification)
            let notifications = storage.getAllNotificationsForMechanism(mechanism: mechanism)
            
            XCTAssertNotNil(notifications)
            XCTAssertEqual(notifications.count, 1)
            XCTAssertEqual(notifications.first?.messageId, messageId)

            var newPayload: [String: Any] = [:]
            var aps: [String: Any] = [:]
            aps["messageId"] = "AUTHENTICATE:e84233f8-9ecf-4456-91ad-2649c4103bc01569980570407"
            aps["content-available"] = true
            aps["alert"] = "Login attempt from user at ForgeRockSandbox"
            aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoibFltZmVQUzllYisrMWtpbzJJSUpBdHdVV1dDY1pDcytCU2dLUGpaS04yOD0iLCJ0IjoiMTIwIiwidSI6Ijc1OUFDRTlELUM2NEItNDNFNi05ODFELTk3RjdCNTRDM0IwMSIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSJ9.Kflihn5sCXFQ3TDWe8GBayCinguSLs9nsu4j4JxddtY"
            aps["sound"] = "default"
            newPayload["aps"] = aps
            
            guard let storedNotification = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: newPayload) else {
               XCTFail("Failed to parse notification payload and construct PushNotification object")
               return
            }
            XCTAssertNotNil(storedNotification)
            XCTAssertEqual(storedNotification.messageId, messageId)        }
        catch {
            XCTFail("Failed to parse remote-notification: \(error.localizedDescription)")
        }
    }
    
    
    func test_12_validate_push_update_request() {
        // Set DeviceToken before PushMechnaism registration
        let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
        guard let deviceToken = deviceTokenStr.decodeBase64() else {
            XCTFail("Failed to parse device token data")
            return
        }
        FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        
        // Given
        let qrCode = URL(string: "pushauth://push/forgerock:pushreg3?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=5GuioYhLlh-xER3n5I8vrx0uuYQo3yD86aJi6KuWDsg&c=KP0XQfZ21N_jsXP_xfVQMmsmoUiWvdDPWecHdb5_INQ&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:a8970dea-3257-4be1-a37a-23eed2b692131588282723889&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!

        do {
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer, uid: parser.uid, resourceId: parser.resourceId)
            let request = try FRAPushHandler.shared.buildPushUpdateRequest(mechanism: mechanism, deviceToken: deviceTokenStr)
            
            let bodyPayload = request.bodyParams
            
            let mechanismUid = bodyPayload["mechanismUid"] as? String
            let jwt = bodyPayload["jwt"] as? String
            XCTAssertNotNil(mechanismUid)
            XCTAssertEqual(mechanismUid, mechanism.mechanismUUID)
            XCTAssertNotNil(jwt)
            XCTAssertTrue(try FRCompactJWT.verify(jwt: jwt!, secret: "5GuioYhLlh-xER3n5I8vrx0uuYQo3yD86aJi6KuWDsg"))
            
            let jwtPayload = try FRCompactJWT.extractPayload(jwt: jwt!)
            XCTAssertNotNil(jwtPayload)
            
            XCTAssertTrue(jwtPayload.keys.contains("mechanismUid"))
            XCTAssertTrue(jwtPayload.keys.contains("deviceName"))
            XCTAssertTrue(jwtPayload.keys.contains("deviceId"))
            XCTAssertTrue(jwtPayload.keys.contains("deviceType"))
            XCTAssertTrue(jwtPayload.keys.contains("communicationType"))

            XCTAssertEqual(jwtPayload["mechanismUid"] as? String, mechanism.mechanismUUID)
            XCTAssertEqual(jwtPayload["deviceName"] as? String, UIDevice.current.name)
            XCTAssertEqual(jwtPayload["deviceId"] as? String, FRAPushHandler.shared.deviceToken)
            XCTAssertEqual(jwtPayload["deviceType"] as? String, "ios")
            XCTAssertEqual(jwtPayload["communicationType"] as? String, "apns")

            let header = request.headers
            
            let loadBalancerKey = header["Set-Cookie"]
            XCTAssertNotNil(loadBalancerKey)
            XCTAssertEqual(loadBalancerKey, "amlbcookie=01")
            
            let acceptAPIVersion = header["accept-api-version"]
            XCTAssertNotNil(acceptAPIVersion)
            XCTAssertEqual(acceptAPIVersion, "resource=1.0, protocol=1.0")
        }
        catch {
           XCTFail("Fail to create PushMechanism registration request with given QRCode: \(qrCode.absoluteString)")
        }
    }
    
    
    func test_13_push_device_token_update_fail_no_push_mechanism() {
        // Given
        let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="

        // When
        let accounts = FRAClient.storage.getAllAccounts()
        XCTAssertEqual(accounts.count, 0)
        
        // Then
        let ex = self.expectation(description: "Failed to retrieve PushMechanism objects")
        FRAPushHandler.shared.updateDeviceToken(deviceToken: deviceTokenStr, onSuccess: {
            XCTFail("PushMechanism without DeviceToken was expected to fail; but somehow passed")
            ex.fulfill()
        }) { (error) in
            
            switch error {
            case PushNotificationError.storageError:
                break
            default:
                XCTFail("Push device token update without PushMechanisms was expected to fail with 'PushNotificationError.storageError'; but failed with other reason")
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_14_parse_notification_with_user_id() {
        
        // Given
        let qrCode = URL(string: "pushauth://push/forgerock:pushtestuser?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=-3xGWaKjfls_ZHFRnGeIvFHn--GxzjQyg1RVG_Pak1s&c=esDK4G8eYce0_Gdf4p9XGGg2cIYYoxf6CTlL_O_1aF8&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:593b6a92-f5c1-4ac0-a94a-a63e05451dd51589138620791&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!
        
        do {
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer, uid: parser.uid, resourceId: parser.resourceId)
            mechanism.mechanismUUID = "759ACE9D-C64B-43E6-981D-97F7B54C3B01"
            FRAClient.storage.setMechanism(mechanism: mechanism)
            var payload: [String: Any] = [:]
            var aps: [String: Any] = [:]
            aps["messageId"] = "AUTHENTICATE:e29b50b6-bf3d-4993-aa84-144d09fe19cf1589138699819"
            aps["content-available"] = true
            aps["alert"] = "Login attempt from user at ForgeRockSandbox"
            aps["data"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjIjoibFltZmVQUzllYisrMWtpbzJJSUpBdHdVV1dDY1pDcytCU2dLUGpaS04yOD0iLCJ0IjoiMTIwIiwidSI6Ijc1OUFDRTlELUM2NEItNDNFNi05ODFELTk3RjdCNTRDM0IwMSIsImwiOiJZVzFzWW1OdmIydHBaVDB3TVE9PSIsImQiOiJ1c2VyMSJ9.24GeB5p2tpHfgIIqtdAsGtRIb-L9kK3OBwFyX-ksHGg"
            aps["sound"] = "default"
            
            payload["aps"] = aps
            
            guard let notification = FRAPushHandler.shared.application(UIApplication.shared, didReceiveRemoteNotification: payload) else {
                XCTFail("Failed to parse notification payload and construct PushNotification object")
                return
            }
            XCTAssertNotNil(notification)
            XCTAssertEqual(notification.messageId, "AUTHENTICATE:e29b50b6-bf3d-4993-aa84-144d09fe19cf1589138699819")
            XCTAssertEqual(notification.mechanismUUID, "759ACE9D-C64B-43E6-981D-97F7B54C3B01")
            XCTAssertEqual(notification.loadBalanceKey, "amlbcookie=01")
            
            let updatedMechanism = FRAClient.storage.getMechanismForUUID(uuid: notification.mechanismUUID)
            XCTAssertEqual(updatedMechanism?.uid, "user1")
        } catch {
            XCTFail("Failed to parse remote-notification: \(error.localizedDescription)")
        }
    }
}
