// 
//  PushNotificationAuthenticationTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest

class PushNotificationAuthenticationTests: FRABaseTests {

    func test_01_push_authentication_accept_successful() {
        
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
            
            XCTAssertEqual(notification.isApproved, true)
            XCTAssertEqual(notification.isPending, false)
            XCTAssertEqual(notification.isDenied, false)
            
            let notifications = FRAClient.storage.getAllNotificationsForMechanism(mechanism: mechanism)
            XCTAssertEqual(notifications.count, 1)
            let notificationFromStorage = notifications.first
            guard let pushNotification = notificationFromStorage else {
                XCTFail("Failed to parse notifications from storage")
                return
            }
            XCTAssertEqual(pushNotification.isApproved, true)
            XCTAssertEqual(pushNotification.isPending, false)
            XCTAssertEqual(pushNotification.isDenied, false)
        }
        catch {
            XCTFail("Push authentication failed to prepare auth request")
        }
    }
    
    
    func test_02_push_authentication_deny_successful() {
        
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
            notification.deny(onSuccess: {
                // Expected to be successful
                ex.fulfill()
            }) { (error) in
                XCTFail("Push authentication failed while expecting to be successful")
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Push authentication failed to prepare auth request")
        }
    }

    
    func test_03_push_notification_accept_request_validation() {
        let qrCode = URL(string: "pushauth://push/forgerock:pushdemouser1?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=O9JHEGfOsaZqc5JT0DHM5hYFA8jofohw5vAP0EpG4JU&c=75OQ3FXmzV99TPf0ihevFfB0s43XsxQ747sY6BopgME&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:fe6311ab-013e-4599-9c0e-4c4e2525199b1588721418483&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!
        
        do {
            
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer)
            mechanism.mechanismUUID = "32E28B44-153C-4BDE-9FDB-38069BC23D9C"
            FRAClient.storage.setMechanism(mechanism: mechanism)
            
            let notificationMessageId = "AUTHENTICATE:8af40ee6-8fa0-4bdd-949c-1dd29d5e55931588721432364"
            var notificationPayload: [String: String] = [:]
            notificationPayload["c"] = "6ggPLysKJ6wSwBsQFtPclHQKebpOTMNwHP53kZxIGE4="
            notificationPayload["t"] = "120"
            notificationPayload["u"] = "32E28B44-153C-4BDE-9FDB-38069BC23D9C"
            notificationPayload["l"] = "YW1sYmNvb2tpZT0wMQ=="
            
            let notification = try PushNotification(messageId: notificationMessageId, payload: notificationPayload)

            let request = try notification.buildPushAuthenticationRequest(result: true, mechanism: mechanism)
            
            let bodyPayload = request.bodyParams
            let messageId = bodyPayload["messageId"] as? String
            let jwt = bodyPayload["jwt"] as? String
            XCTAssertNotNil(messageId)
            XCTAssertEqual(messageId, "AUTHENTICATE:8af40ee6-8fa0-4bdd-949c-1dd29d5e55931588721432364")
            XCTAssertNotNil(jwt)
            XCTAssertTrue(try FRCompactJWT.verify(jwt: jwt!, secret: mechanism.secret))
            
            let jwtPayload = try FRCompactJWT.extractPayload(jwt: jwt!)
            XCTAssertNotNil(jwtPayload)
            XCTAssertTrue(jwtPayload.keys.contains("response"))
            let challengeResponse = try Crypto.generatePushChallengeResponse(challenge: "6ggPLysKJ6wSwBsQFtPclHQKebpOTMNwHP53kZxIGE4=".urlSafeDecoding(), secret: mechanism.secret)
            XCTAssertEqual(jwtPayload["response"] as? String, challengeResponse)
            XCTAssertFalse(jwtPayload.keys.contains("deny"))
            
            let header = request.headers
            
            let loadBalancerKey = header["Set-Cookie"]
            XCTAssertNotNil(loadBalancerKey)
            XCTAssertEqual(loadBalancerKey, "amlbcookie=01")
            
            let acceptAPIVersion = header["accept-api-version"]
            XCTAssertNotNil(acceptAPIVersion)
            XCTAssertEqual(acceptAPIVersion, "resource=1.0, protocol=1.0")
        }
        catch {
            XCTFail("Push authentication failed to prepare auth request")
        }
    }
    
    
    func test_04_push_notification_deny_request_validation() {
        let qrCode = URL(string: "pushauth://push/forgerock:pushdemouser1?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=O9JHEGfOsaZqc5JT0DHM5hYFA8jofohw5vAP0EpG4JU&c=75OQ3FXmzV99TPf0ihevFfB0s43XsxQ747sY6BopgME&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:fe6311ab-013e-4599-9c0e-4c4e2525199b1588721418483&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!
        
        do {
            
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer)
            mechanism.mechanismUUID = "32E28B44-153C-4BDE-9FDB-38069BC23D9C"
            FRAClient.storage.setMechanism(mechanism: mechanism)
            
            let notificationMessageId = "AUTHENTICATE:8af40ee6-8fa0-4bdd-949c-1dd29d5e55931588721432364"
            var notificationPayload: [String: String] = [:]
            notificationPayload["c"] = "6ggPLysKJ6wSwBsQFtPclHQKebpOTMNwHP53kZxIGE4="
            notificationPayload["t"] = "120"
            notificationPayload["u"] = "32E28B44-153C-4BDE-9FDB-38069BC23D9C"
            notificationPayload["l"] = "YW1sYmNvb2tpZT0wMQ=="
            
            let notification = try PushNotification(messageId: notificationMessageId, payload: notificationPayload)

            let request = try notification.buildPushAuthenticationRequest(result: false, mechanism: mechanism)
            
            let bodyPayload = request.bodyParams
            let messageId = bodyPayload["messageId"] as? String
            let jwt = bodyPayload["jwt"] as? String
            XCTAssertNotNil(messageId)
            XCTAssertEqual(messageId, "AUTHENTICATE:8af40ee6-8fa0-4bdd-949c-1dd29d5e55931588721432364")
            XCTAssertNotNil(jwt)
            XCTAssertTrue(try FRCompactJWT.verify(jwt: jwt!, secret: mechanism.secret))
            
            let jwtPayload = try FRCompactJWT.extractPayload(jwt: jwt!)
            XCTAssertNotNil(jwtPayload)
            XCTAssertTrue(jwtPayload.keys.contains("response"))
            let challengeResponse = try Crypto.generatePushChallengeResponse(challenge: "6ggPLysKJ6wSwBsQFtPclHQKebpOTMNwHP53kZxIGE4=".urlSafeDecoding(), secret: mechanism.secret)
            XCTAssertEqual(jwtPayload["response"] as? String, challengeResponse)
            XCTAssertTrue(jwtPayload.keys.contains("deny"))
            XCTAssertEqual(jwtPayload["deny"] as? Bool, true)
            
            let header = request.headers
            
            let loadBalancerKey = header["Set-Cookie"]
            XCTAssertNotNil(loadBalancerKey)
            XCTAssertEqual(loadBalancerKey, "amlbcookie=01")
            
            let acceptAPIVersion = header["accept-api-version"]
            XCTAssertNotNil(acceptAPIVersion)
            XCTAssertEqual(acceptAPIVersion, "resource=1.0, protocol=1.0")
        }
        catch {
            XCTFail("Push authentication failed to prepare auth request")
        }
    }
    
    
    func test_05_push_auth_without_saved_mechanism() {

        do {
            let messageId = "AUTHENTICATE:8af40ee6-8fa0-4bdd-949c-1dd29d5e55931588721432364"
            var notificationPayload: [String: String] = [:]
            notificationPayload["c"] = "6ggPLysKJ6wSwBsQFtPclHQKebpOTMNwHP53kZxIGE4="
            notificationPayload["t"] = "120"
            notificationPayload["u"] = "32E28B44-153C-4BDE-9FDB-38069BC23D9C"
            notificationPayload["l"] = "YW1sYmNvb2tpZT0wMQ=="
            
            let ex = self.expectation(description: "PushNotification Authentication")
            let notification = try PushNotification(messageId: messageId, payload: notificationPayload)
            notification.accept(onSuccess: {
                XCTFail("Push authentication is expected to be failed due to missing PushMechanism object, but somehow passed")
                ex.fulfill()
            }) { (error) in
                switch error {
                case PushNotificationError.storageError(let message):
                    XCTAssertEqual(message, "Failed to retrieve PushMechanism object with given UUID: 32E28B44-153C-4BDE-9FDB-38069BC23D9C")
                    break
                default:
                    XCTFail("Push authentication is expected to failed with PushNotificationError.storageError for missing PushMechanism object, but failed with different reason: \(error.localizedDescription)")
                    break
                }
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Push authentication failed to prepare auth request")
        }
    }
    
    
    func test_06_push_auth_already_authenticated() {
        
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
            
            var ex = self.expectation(description: "PushNotification Authentication: 1st attempt")
            let notification = try PushNotification(messageId: messageId, payload: notificationPayload)
            notification.accept(onSuccess: {
                // Expected to be successful
                ex.fulfill()
            }) { (error) in
                XCTFail("Push authentication failed while expecting to be successful")
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            ex = self.expectation(description: "PushNotification Authentication: 2nd attempt")
            notification.accept(onSuccess: {
                XCTFail("Push authentication is expected failed for already authenticated, but somehow passed")
                ex.fulfill()
            }) { (error) in
                switch error {
                case PushNotificationError.notificationInvalidStatus:
                    break
                default:
                XCTFail("Push authentication is expected to failed with PushNotificationError.notificationInvalidStatus for already authenticated PushNotification object, but failed with different reason: \(error.localizedDescription)")
                    break
                }
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Push authentication failed to prepare auth request")
        }
    }
    
    
    func test_07_push_notification_expired() {
        let qrCode = URL(string: "pushauth://push/forgerock:pushdemouser1?a=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1hdXRoZW50aWNhdGU&b=519387&r=aHR0cDovL29wZW5hbS5leGFtcGxlLmNvbTo4MDgxL29wZW5hbS9qc29uL3B1c2gvc25zL21lc3NhZ2U_X2FjdGlvbj1yZWdpc3Rlcg&s=O9JHEGfOsaZqc5JT0DHM5hYFA8jofohw5vAP0EpG4JU&c=75OQ3FXmzV99TPf0ihevFfB0s43XsxQ747sY6BopgME&l=YW1sYmNvb2tpZT0wMQ&m=REGISTER:fe6311ab-013e-4599-9c0e-4c4e2525199b1588721418483&issuer=Rm9yZ2VSb2NrU2FuZGJveA")!
        
        do {
            let parser = try PushQRCodeParser(url: qrCode)
            let mechanism = PushMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, authEndpoint: parser.authenticationEndpoint, regEndpoint: parser.registrationEndpoint, messageId: parser.messageId, challenge: parser.challenge, loadBalancer: parser.loadBalancer)
            mechanism.mechanismUUID = "32E28B44-153C-4BDE-9FDB-38069BC23D9C"
            FRAClient.storage.setMechanism(mechanism: mechanism)
            
            let messageId = "AUTHENTICATE:8af40ee6-8fa0-4bdd-949c-1dd29d5e55931588721432364"
            var notificationPayload: [String: String] = [:]
            notificationPayload["c"] = "6ggPLysKJ6wSwBsQFtPclHQKebpOTMNwHP53kZxIGE4="
            notificationPayload["t"] = "10"
            notificationPayload["u"] = "32E28B44-153C-4BDE-9FDB-38069BC23D9C"
            notificationPayload["l"] = "YW1sYmNvb2tpZT0wMQ=="
            
            let notification = try PushNotification(messageId: messageId, payload: notificationPayload)
            sleep(15)
            let ex = self.expectation(description: "PushNotification Authentication: 1st attempt")
            notification.accept(onSuccess: {
                XCTFail("Push authentication is expected failed for expired status, but somehow passed")
                ex.fulfill()
            }) { (error) in
                switch error {
                case PushNotificationError.notificationInvalidStatus:
                    break
                default:
                XCTFail("Push authentication is expected to failed with PushNotificationError.notificationInvalidStatus for expired status, but failed with different reason: \(error.localizedDescription)")
                    break
                }
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Push authentication failed to prepare auth request")
        }
    }
}
