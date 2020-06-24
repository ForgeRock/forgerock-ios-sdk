// 
//  NotificationTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest

class NotificationTests: FRABaseTests {

    var payload: [String: String] = ["c": "j4i8MSuGOcqfslLpRMsYWUMkfsZnsgTCcgNZ+WN3MEE=", "l": "YW1sYmNvb2tpZT0wMQ", "t": "120", "u": "026BE51C-3B14-456D-A0DF-DD460BB8B100"]
    let messageId = "AUTHENTICATE:e84233f8-9ecf-4456-91ad-2649c4103bc01569980570407"
    let c: String = "j4i8MSuGOcqfslLpRMsYWUMkfsZnsgTCcgNZ+WN3MEE="
    let l: String = "YW1sYmNvb2tpZT0wMQ"
    let t: Double = 120
    let u: String = "026BE51C-3B14-456D-A0DF-DD460BB8B100"
    
    func test_01_notification_init_success() {
        do {
            let notification = try PushNotification(messageId: messageId, payload: payload)
            XCTAssertNotNil(notification)
            XCTAssertEqual(notification.challenge, c)
            XCTAssertEqual(notification.loadBalanceKey, "amlbcookie=01")
            XCTAssertEqual(notification.ttl, t)
            XCTAssertEqual(notification.mechanismUUID, u)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_02_notification_init_missing_challenge() {
        do {
            payload.removeValue(forKey: "c")
            let notification = try PushNotification(messageId: messageId, payload: payload)
            XCTAssertNil(notification)
        }
        catch NotificationError.invalidPayload(let msg) {
            XCTAssertEqual(msg, "missing challenge")
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_03_notification_init_missing_load_balance_key() {
        do {
            payload.removeValue(forKey: "l")
            let notification = try PushNotification(messageId: messageId, payload: payload)
            XCTAssertNil(notification)
        }
        catch NotificationError.invalidPayload(let msg) {
            XCTAssertEqual(msg, "missing load balance key")
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_04_notification_init_missing_ttl() {
        do {
            payload.removeValue(forKey: "t")
            let notification = try PushNotification(messageId: messageId, payload: payload)
            XCTAssertNil(notification)
        }
        catch NotificationError.invalidPayload(let msg) {
            XCTAssertEqual(msg, "missing or invalid ttl")
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_05_notification_init_invalid_ttl() {
        do {
            payload["t"] = "string"
            let notification = try PushNotification(messageId: messageId, payload: payload)
            XCTAssertNil(notification)
        }
        catch NotificationError.invalidPayload(let msg) {
            XCTAssertEqual(msg, "missing or invalid ttl")
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_06_notification_init_missing_mechanism_uuid() {
        do {
            payload.removeValue(forKey: "u")
            let notification = try PushNotification(messageId: messageId, payload: payload)
            XCTAssertNil(notification)
        }
        catch NotificationError.invalidPayload(let msg) {
            XCTAssertEqual(msg, "missing Mechanism UUID")
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_07_notification_is_pending() {
        do {
            let notification = try PushNotification(messageId: messageId, payload: payload)
            XCTAssertTrue(notification.isPending)
            XCTAssertFalse(notification.isDenied)
            XCTAssertFalse(notification.isApproved)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_08_notification_is_approved() {
        do {
            let notification = try PushNotification(messageId: messageId, payload: payload)
            notification.pending = false
            notification.approved = true
            XCTAssertTrue(notification.isApproved)
            XCTAssertFalse(notification.isDenied)
            XCTAssertFalse(notification.isPending)
            XCTAssertFalse(notification.isExpired)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_09_notification_is_denied() {
        do {
            let notification = try PushNotification(messageId: messageId, payload: payload)
            notification.pending = false
            notification.approved = false
            XCTAssertTrue(notification.isDenied)
            XCTAssertFalse(notification.isPending)
            XCTAssertFalse(notification.isApproved)
            XCTAssertFalse(notification.isExpired)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_09_notification_is_expired() {
        do {
            let notification = try PushNotification(messageId: messageId, payload: payload)
            XCTAssertFalse(notification.isExpired)
            let calendar = Calendar.current
            let past = calendar.date(byAdding: .minute, value: -5, to: Date())
            notification.timeAdded = past!
            XCTAssertTrue(notification.isExpired)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_10_notification_archive_obj() {
        do {
            let notification = try PushNotification(messageId: messageId, payload: payload)
            XCTAssertNotNil(notification)

            if #available(iOS 11.0, *) {
                if let notificationData = try? NSKeyedArchiver.archivedData(withRootObject: notification, requiringSecureCoding: true) {
                    let notificationFromData = NSKeyedUnarchiver.unarchiveObject(with: notificationData) as? PushNotification
                    XCTAssertEqual(notification.messageId, notificationFromData?.messageId)
                    XCTAssertEqual(notification.challenge, notificationFromData?.challenge)
                    XCTAssertEqual(notification.loadBalanceKey, notificationFromData?.loadBalanceKey)
                    XCTAssertEqual(notification.ttl, notificationFromData?.ttl)
                    XCTAssertEqual(notification.mechanismUUID, notificationFromData?.mechanismUUID)
                    XCTAssertEqual(notification.timeAdded.timeIntervalSince1970, notificationFromData?.timeAdded.timeIntervalSince1970)
                }
                else {
                    XCTFail("Failed to serialize PushNotification object with Secure Coding")
                }
            } else {
                let notificationData = NSKeyedArchiver.archivedData(withRootObject: notification)
                let notificationFromData = NSKeyedUnarchiver.unarchiveObject(with: notificationData) as? PushNotification
                
                XCTAssertEqual(notification.messageId, notificationFromData?.messageId)
                XCTAssertEqual(notification.challenge, notificationFromData?.challenge)
                XCTAssertEqual(notification.loadBalanceKey, notificationFromData?.loadBalanceKey)
                XCTAssertEqual(notification.ttl, notificationFromData?.ttl)
                XCTAssertEqual(notification.mechanismUUID, notificationFromData?.mechanismUUID)
                XCTAssertEqual(notification.timeAdded.timeIntervalSince1970, notificationFromData?.timeAdded.timeIntervalSince1970)
            }
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
}
