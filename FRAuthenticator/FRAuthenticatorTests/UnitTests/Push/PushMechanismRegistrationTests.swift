// 
//  PushMechanismRegistrationTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020-2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRCore
@testable import FRAuthenticator

class PushMechanismRegistrationTests: FRABaseTests {
    
    func test_01_successful_registration() {
        self.loadMockResponses(["AM_Push_Registration_Successful"])
        
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
            // Then
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer, uid: parser.uid, resourceId: parser.resourceId)
            let ex = self.expectation(description: "Register PushMechanism")
            FRAPushHandler.shared.register(mechanism: mechanism, onSuccess: {
                ex.fulfill()
            }) { (error) in
                XCTFail("Failed to register PushMechanism with following error: \(error.localizedDescription)")
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Fail to create PushMechanism with given QRCode: \(qrCode.absoluteString)")
        }
    }
    
    
    func test_02_push_registration_missing_device_token() {
        
        // Given
        let qrCode = URL(string: "pushauth://push/forgerock:pushreg3?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=5GuioYhLlh-xER3n5I8vrx0uuYQo3yD86aJi6KuWDsg&c=KP0XQfZ21N_jsXP_xfVQMmsmoUiWvdDPWecHdb5_INQ&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:a8970dea-3257-4be1-a37a-23eed2b692131588282723889&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!
        
        do {
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer, uid: parser.uid, resourceId: parser.resourceId)

            let ex = self.expectation(description: "Register PushMechanism")
            FRAPushHandler.shared.register(mechanism: mechanism, onSuccess: {
                XCTFail("PushMechanism without DeviceToken was expected to fail; but somehow passed")
                ex.fulfill()
            }) { (error) in
                
                switch error {
                case PushNotificationError.missingDeviceToken:
                    break
                default:
                    XCTFail("PushMechanism without DeviceToken was expected to fail with 'PushNotificationError.missingDeviceToken'; but failed with other reason")
                }
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Fail to create PushMechanism with given QRCode: \(qrCode.absoluteString)")
        }
    }
    
    
    func test_03_push_registration_invalid_jwt() {
        self.loadMockResponses(["AM_Push_Registration_Fail_Invalid_Signed_JWT"])
        
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
            // Switch to different secret than server expected
            mechanism.secret = "5GuioYhLlh-xER3n5I8vrx0uuYQo3yD86aJi6KuWDsg"
            let ex = self.expectation(description: "Register PushMechanism")
            FRAPushHandler.shared.register(mechanism: mechanism, onSuccess: {
                XCTFail("PushMechanism without DeviceToken was expected to fail; but somehow passed")
                ex.fulfill()
            }) { (error) in
                
                switch error {
                case NetworkError.apiRequestFailure(_, _, _):
                    break
                default:
                    XCTFail("PushMechanism registration with invalid JWT failed with unexpected error")
                }
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Fail to create PushMechanism with given QRCode: \(qrCode.absoluteString)")
        }
    }
    
    
    func test_04_fail_to_generate_registration_request() {
        
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
            // Change challenge to unsafe URL encoded string which will cause failure to parse and generate challenge response
            mechanism.challenge = "KP0XQfZ21N_jsXP_xfVQMmsmoUiWvdDPWecHdb5_INQ"
            
            let ex = self.expectation(description: "Register PushMechanism")
            FRAPushHandler.shared.register(mechanism: mechanism, onSuccess: {
                XCTFail("PushMechanism without DeviceToken was expected to fail; but somehow passed")
                ex.fulfill()
            }) { (error) in
                
                switch error {
                case CryptoError.invalidParam(let message):
                    XCTAssertEqual(message, "challenge, or secret")
                    break
                default:
                    XCTFail("PushMechanism registration with invalid JWT failed with unexpected error")
                }
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Fail to create PushMechanism with given QRCode: \(qrCode.absoluteString)")
        }
    }
    
    
    func test_05_validate_push_registration_request() {
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
            let request = try FRAPushHandler.shared.buildPushRegistrationRequest(mechanism: mechanism)
            
            let bodyPayload = request.bodyParams
            
            let messageId = bodyPayload["messageId"] as? String
            let jwt = bodyPayload["jwt"] as? String
            XCTAssertNotNil(messageId)
            XCTAssertEqual(messageId, "REGISTER:a8970dea-3257-4be1-a37a-23eed2b692131588282723889")
            XCTAssertNotNil(jwt)
            XCTAssertTrue(try FRCompactJWT.verify(jwt: jwt!, secret: "5GuioYhLlh-xER3n5I8vrx0uuYQo3yD86aJi6KuWDsg"))
            
            let jwtPayload = try FRCompactJWT.extractPayload(jwt: jwt!)
            XCTAssertNotNil(jwtPayload)
            
            XCTAssertTrue(jwtPayload.keys.contains("response"))
            XCTAssertTrue(jwtPayload.keys.contains("mechanismUid"))
            XCTAssertTrue(jwtPayload.keys.contains("deviceId"))
            XCTAssertTrue(jwtPayload.keys.contains("deviceType"))
            XCTAssertTrue(jwtPayload.keys.contains("communicationType"))
            let challengeResponse = try Crypto.generatePushChallengeResponse(challenge: "KP0XQfZ21N_jsXP_xfVQMmsmoUiWvdDPWecHdb5_INQ".urlSafeDecoding(), secret: "5GuioYhLlh-xER3n5I8vrx0uuYQo3yD86aJi6KuWDsg")
            XCTAssertEqual(jwtPayload["response"] as? String, challengeResponse)
            XCTAssertEqual(jwtPayload["mechanismUid"] as? String, mechanism.mechanismUUID)
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
}
