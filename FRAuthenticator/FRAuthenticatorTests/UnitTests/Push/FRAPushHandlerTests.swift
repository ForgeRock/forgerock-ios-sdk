// 
//  FRAPushHandlerTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest

class FRAPushHandlerTests: FRABaseTests {

    func test_01_set_device_token() {
        let deviceTokenStr = "PJ6d7k8uM2AvK+T1jJTMBYD5so+SrHnvVLoGz2Mte3A="
        guard let deviceToken = deviceTokenStr.decodeBase64() else {
            XCTFail("Failed to parse device token data")
            return
        }
        FRAPushHandler.shared.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        XCTAssertEqual(FRAPushHandler.shared.deviceToken, "3C9E9DEE4F2E33602F2BE4F58C94CC0580F9B28F92AC79EF54BA06CF632D7B70")
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
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer)
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
}
