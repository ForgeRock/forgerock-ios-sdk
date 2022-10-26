// 
//  NotificationTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020-2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class NotificationTests: FRABaseTests {

    var payload: [String: String] = ["c": "j4i8MSuGOcqfslLpRMsYWUMkfsZnsgTCcgNZ+WN3MEE=", "l": "YW1sYmNvb2tpZT0wMQ", "t": "120", "u": "026BE51C-3B14-456D-A0DF-DD460BB8B100", "i": "1629261902660"]
    var newPayload: [String: String] = [
        "c": "j4i8MSuGOcqfslLpRMsYWUMkfsZnsgTCcgNZ+WN3MEE=",
        "l": "YW1sYmNvb2tpZT0wMQ",
        "t": "120",
        "u": "026BE51C-3B14-456D-A0DF-DD460BB8B100",
        "i": "1629261902660",
        "p": "{\"ipAddress\": \"9.9.9.9\"}",
        "x": "{\"location\":{\"latitude\":49.2208569,\"longitude\":-123.1174431},\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36\",\"platform\":\"MacIntel\"}",
        "m": "Login attempt at ForgeRock",
        "k": "challenge",
        "n": "34,56,82"]
    let messageId = "AUTHENTICATE:e84233f8-9ecf-4456-91ad-2649c4103bc01569980570407"
    let c: String = "j4i8MSuGOcqfslLpRMsYWUMkfsZnsgTCcgNZ+WN3MEE="
    let l: String = "YW1sYmNvb2tpZT0wMQ"
    let t: Double = 120
    let u: String = "026BE51C-3B14-456D-A0DF-DD460BB8B100"
    let i: Int64 = 1629261902660
    let p: String =  """
    {"ipAddress": "9.9.9.9"}
    """
    let x: String =  """
{"location":{"latitude":49.2208569,"longitude":-123.1174431},"userAgent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36","platform":"MacIntel"}
"""
    let m: String = "Login attempt at ForgeRock"
    let k: String = "challenge"
    let n: String = "34,56,82"
    let numbersChallengeArray: [Int] = [34,56,82]
    
    func test_01_notification_init_success() {
        do {
            let notification = try PushNotification(messageId: messageId, payload: payload)
            XCTAssertNotNil(notification)
            XCTAssertEqual(notification.challenge, c)
            XCTAssertEqual(notification.loadBalanceKey, "amlbcookie=01")
            XCTAssertEqual(notification.ttl, t)
            XCTAssertEqual(notification.mechanismUUID, u)
            XCTAssertEqual(notification.timeAdded, Date(milliseconds: i))
            XCTAssertNil(notification.customPayload)
            XCTAssertNil(notification.message)
            XCTAssertEqual(notification.pushType, PushType.default)
            XCTAssertNil(notification.numbersChallenge)
            XCTAssertNil(notification.contextInfo)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_01_1_notification_new_payload_init_success() {
        do {
            let notification = try PushNotification(messageId: messageId, payload: newPayload)
            XCTAssertNotNil(notification)
            XCTAssertEqual(notification.challenge, c)
            XCTAssertEqual(notification.loadBalanceKey, "amlbcookie=01")
            XCTAssertEqual(notification.ttl, t)
            XCTAssertEqual(notification.mechanismUUID, u)
            XCTAssertEqual(notification.timeAdded, Date(milliseconds: i))
            XCTAssertEqual(notification.customPayload, p)
            XCTAssertEqual(notification.message, m)
            XCTAssertEqual(notification.pushType, PushType(rawValue: k))
            XCTAssertEqual(notification.numbersChallenge, n)
            XCTAssertEqual(notification.contextInfo, x)
            
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
    
    func test_07_1_notification_is_pending_with_interval() {
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
    
    func test_07_notification_is_pending_without_interval() {
        do {
            payload.removeValue(forKey: "i")
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
    
    
    func test_10_1_notification_archive_obj_with_new_payload() {
        do {
            let notification = try PushNotification(messageId: messageId, payload: newPayload)
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
                    XCTAssertEqual(notification.customPayload, notificationFromData?.customPayload)
                    XCTAssertEqual(notification.message, notificationFromData?.message)
                    XCTAssertEqual(notification.pushType, notificationFromData?.pushType)
                    XCTAssertEqual(notification.numbersChallenge, notificationFromData?.numbersChallenge)
                    XCTAssertEqual(notification.contextInfo, notificationFromData?.contextInfo)
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
                XCTAssertEqual(notification.customPayload, notificationFromData?.customPayload)
                XCTAssertEqual(notification.message, notificationFromData?.message)
                XCTAssertEqual(notification.pushType, notificationFromData?.pushType)
                XCTAssertEqual(notification.numbersChallenge, notificationFromData?.numbersChallenge)
                XCTAssertEqual(notification.contextInfo, notificationFromData?.contextInfo)
            }
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_11_codable_serialization() {
        do {
            let notification = try PushNotification(messageId: messageId, payload: payload)
            XCTAssertNotNil(notification)
            
            //  Encode
            let encodedData = try JSONEncoder().encode(notification)
            
            //  Decode
            let decodedNotification = try JSONDecoder().decode(PushNotification.self, from: encodedData)
            
            //  Then
            XCTAssertEqual(notification.messageId, decodedNotification.messageId)
            XCTAssertEqual(notification.challenge, decodedNotification.challenge)
            XCTAssertEqual(notification.loadBalanceKey, decodedNotification.loadBalanceKey)
            XCTAssertEqual(notification.ttl, decodedNotification.ttl)
            XCTAssertEqual(notification.mechanismUUID, decodedNotification.mechanismUUID)
            XCTAssertEqual(notification.timeAdded.millisecondsSince1970, decodedNotification.timeAdded.millisecondsSince1970)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_11_1_codable_serialization_with_new_payload() {
        do {
            let notification = try PushNotification(messageId: messageId, payload: newPayload)
            XCTAssertNotNil(notification)
            
            //  Encode
            let encodedData = try JSONEncoder().encode(notification)
            
            //  Decode
            let decodedNotification = try JSONDecoder().decode(PushNotification.self, from: encodedData)
            
            //  Then
            XCTAssertEqual(notification.messageId, decodedNotification.messageId)
            XCTAssertEqual(notification.challenge, decodedNotification.challenge)
            XCTAssertEqual(notification.loadBalanceKey, decodedNotification.loadBalanceKey)
            XCTAssertEqual(notification.ttl, decodedNotification.ttl)
            XCTAssertEqual(notification.mechanismUUID, decodedNotification.mechanismUUID)
            XCTAssertEqual(notification.timeAdded.millisecondsSince1970, decodedNotification.timeAdded.millisecondsSince1970)
            XCTAssertEqual(notification.customPayload, decodedNotification.customPayload)
            XCTAssertEqual(notification.message, decodedNotification.message)
            XCTAssertEqual(notification.pushType, decodedNotification.pushType)
            XCTAssertEqual(notification.numbersChallenge, decodedNotification.numbersChallenge)
            XCTAssertEqual(notification.contextInfo, decodedNotification.contextInfo)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }

    
    func test_12_json_string_serialization() {
        do {
            let notification = try PushNotification(messageId: messageId, payload: payload)
            XCTAssertNotNil(notification)
            
            guard let jsonString = notification.toJson() else {
                XCTFail("Failed to serialize the object into JSON String value")
                return
            }
            
            //  Covert jsonString to Dictionary
            let jsonDictionary = FRJSONEncoder.jsonStringToDictionary(jsonString: jsonString)
            
            //  Then
            XCTAssertEqual(notification.identifier, jsonDictionary?["id"] as! String)
            XCTAssertEqual(notification.messageId, jsonDictionary?["messageId"] as! String)
            XCTAssertEqual(notification.challenge, jsonDictionary?["challenge"] as! String)
            XCTAssertEqual(notification.loadBalanceKey, jsonDictionary?["amlbCookie"] as? String)
            XCTAssertEqual(notification.ttl, jsonDictionary?["ttl"] as! Double)
            XCTAssertEqual(notification.mechanismUUID, jsonDictionary?["mechanismUID"] as! String)
            XCTAssertEqual(notification.approved, jsonDictionary?["approved"] as! Bool)
            XCTAssertEqual(notification.pending, jsonDictionary?["pending"] as! Bool)
            XCTAssertEqual(notification.timeAdded.millisecondsSince1970, jsonDictionary?["timeAdded"] as! Int64)
            XCTAssertEqual(notification.timeAdded.millisecondsSince1970 + Int64(notification.ttl * 1000), jsonDictionary?["timeExpired"] as! Int64)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_12_1_json_string_serialization_with_new_payload() {
        do {
            let notification = try PushNotification(messageId: messageId, payload: newPayload)
            XCTAssertNotNil(notification)
            
            guard let jsonString = notification.toJson() else {
                XCTFail("Failed to serialize the object into JSON String value")
                return
            }
            
            //  Covert jsonString to Dictionary
            let jsonDictionary = FRJSONEncoder.jsonStringToDictionary(jsonString: jsonString)
            
            //  Then
            XCTAssertEqual(notification.identifier, jsonDictionary?["id"] as! String)
            XCTAssertEqual(notification.messageId, jsonDictionary?["messageId"] as! String)
            XCTAssertEqual(notification.challenge, jsonDictionary?["challenge"] as! String)
            XCTAssertEqual(notification.loadBalanceKey, jsonDictionary?["amlbCookie"] as? String)
            XCTAssertEqual(notification.ttl, jsonDictionary?["ttl"] as! Double)
            XCTAssertEqual(notification.mechanismUUID, jsonDictionary?["mechanismUID"] as! String)
            XCTAssertEqual(notification.approved, jsonDictionary?["approved"] as! Bool)
            XCTAssertEqual(notification.pending, jsonDictionary?["pending"] as! Bool)
            XCTAssertEqual(notification.timeAdded.millisecondsSince1970, jsonDictionary?["timeAdded"] as! Int64)
            XCTAssertEqual(notification.timeAdded.millisecondsSince1970 + Int64(notification.ttl * 1000), jsonDictionary?["timeExpired"] as! Int64)
            XCTAssertEqual(notification.customPayload, jsonDictionary?["customPayload"] as? String)
            XCTAssertEqual(notification.message, jsonDictionary?["message"] as? String)
            XCTAssertEqual(notification.pushType, PushType(rawValue:  jsonDictionary?["pushType"] as! String))
            XCTAssertEqual(notification.numbersChallenge, jsonDictionary?["numbersChallenge"] as? String)
            XCTAssertEqual(notification.contextInfo, jsonDictionary?["contextInfo"] as? String)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test13_notification_init_missing_interval() {
        do {
            payload.removeValue(forKey: "i")
            let notification = try PushNotification(messageId: messageId, payload: payload)
            XCTAssertNotNil(notification)
            XCTAssertNotEqual(notification.timeAdded, Date(milliseconds: i))
            XCTAssertNotNil(notification.timeAdded)
            XCTAssertGreaterThan(notification.timeAdded, Date() - 10)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_14_notification_init_invalid_interval() {
        do {
            payload["i"] = "string"
            let notification = try PushNotification(messageId: messageId, payload: payload)
            XCTAssertNotNil(notification)
            XCTAssertNotEqual(notification.timeAdded, Date(milliseconds: i))
            XCTAssertNotNil(notification.timeAdded)
            XCTAssertGreaterThan(notification.timeAdded, Date() - 10)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    func test_15_notification_numbers_challenge_array() {
        do {
            let notification = try PushNotification(messageId: messageId, payload: newPayload)
            XCTAssertNotNil(notification)
            XCTAssertEqual(notification.numbersChallengeArray, numbersChallengeArray)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    func test_16_init_with_no_pushtype() {
        do {
            newPayload.removeValue(forKey: "k")
            let notification = try PushNotification(messageId: messageId, payload: newPayload)
            XCTAssertNotNil(notification)
            XCTAssertEqual(notification.pushType, PushType.default)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    func test_17_init_with_invalid_pushtype() {
        do {
            newPayload["k"] = "invalid"
            let notification = try PushNotification(messageId: messageId, payload: newPayload)
            XCTAssertNotNil(notification)
            XCTAssertEqual(notification.pushType, PushType.default)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    func test_18_init_with_challenge_pushtype() {
        do {
            newPayload["k"] = "challenge"
            let notification = try PushNotification(messageId: messageId, payload: newPayload)
            XCTAssertNotNil(notification)
            XCTAssertEqual(notification.pushType, PushType.challenge)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    func test_18_init_with_biometric_pushtype() {
        do {
            newPayload["k"] = "biometric"
            let notification = try PushNotification(messageId: messageId, payload: newPayload)
            XCTAssertNotNil(notification)
            XCTAssertEqual(notification.pushType, PushType.biometric)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
   
}
