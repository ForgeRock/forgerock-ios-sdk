// 
//  RequestInterceptorTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRCore
@testable import FRAuthenticator

class RequestInterceptorTests: FRABaseTests {
    
    override func setUp() {
        super.setUp()
        RequestInterceptorTests.intercepted = []
    }
    
    override func tearDown() {
        RequestInterceptorTests.intercepted = []
        super.tearDown()
    }
    
    static var intercepted: [String] = []
    
    
    func test_01_push_registration() {
        // Register RequestInterceptors
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [PushRequestInterceptor()])
        
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
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer)
            let ex = self.expectation(description: "Register PushMechanism")
            mechanism.register(onSuccess: {
                ex.fulfill()
            }) { (error) in
                XCTFail("Failed to register PushMechanism with following error: \(error.localizedDescription)")
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            XCTAssertEqual(RequestInterceptorTests.intercepted.count, 1)
            let interceptorsInOrder: [String] = ["PUSH_REGISTER"]
            for (index, intercepted) in RequestInterceptorTests.intercepted.enumerated() {
                XCTAssertEqual(interceptorsInOrder[index], intercepted)
            }
        }
        catch {
            XCTFail("Fail to create PushMechanism with given QRCode: \(qrCode.absoluteString)")
        }
    }
    
    func test_02_push_authentication() {
        // Register RequestInterceptors
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [PushRequestInterceptor()])
        
        self.loadMockResponses(["AM_Push_Authentication_Successful"])
        
        let qrCode = URL(string: "pushauth://push/forgerock:pushdemouser1?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=O9JHEGfOsaZqc5JT0DHM5hYFA8jofohw5vAP0EpG4JU&c=75OQ3FXmzV99TPf0ihevFfB0s43XsxQ747sY6BopgME&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:fe6311ab-013e-4599-9c0e-4c4e2525199b1588721418483&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!
        
        do {
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer)
            mechanism.mechanismUUID = "32E28B44-153C-4BDE-9FDB-38069BC23D9C"
            FRAClient.storage.setMechanism(mechanism: mechanism)
            
            let messageId = "AUTHENTICATE:8af40ee6-8fa0-4bdd-949c-1dd29d5e55931588721432364"
            var notificationPayload: [String: String] = [:]
            notificationPayload["c"] = "6ggPLysKJ6wSwBsQFtPclHQKebpOTMNwHP53kZxIGE4="
            notificationPayload["t"] = "120"
            notificationPayload["u"] = "32E28B44-153C-4BDE-9FDB-38069BC23D9C"
            notificationPayload["l"] = "YW1sYmNvb2tpZT0wMQ=="
            
            let ex = self.expectation(description: "PushNotification Authentication")
            let notification = try PushNotification(messageId: messageId, payload: notificationPayload)
            notification.accept(onSuccess: {
                // Expected to be successful
                ex.fulfill()
            }) { (error) in
                XCTFail("Push authentication failed while expecting to be successful")
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            XCTAssertEqual(RequestInterceptorTests.intercepted.count, 1)
            let interceptorsInOrder: [String] = ["PUSH_AUTHENTICATE"]
            for (index, intercepted) in RequestInterceptorTests.intercepted.enumerated() {
                XCTAssertEqual(interceptorsInOrder[index], intercepted)
            }
        }
        catch {
            XCTFail("Push authentication failed to prepare auth request")
        }
    }
}

class PushRequestInterceptor: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        if action.type == "PUSH_REGISTER" {
            RequestInterceptorTests.intercepted.append("PUSH_REGISTER")
        }
        else if action.type == "PUSH_AUTHENTICATE" {
            RequestInterceptorTests.intercepted.append("PUSH_AUTHENTICATE")
        }
        return request
    }
}

