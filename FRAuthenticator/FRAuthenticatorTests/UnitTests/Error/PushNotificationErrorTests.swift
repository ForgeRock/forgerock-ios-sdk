// 
//  PushNotificationErrorTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class PushNotificationErrorTests: FRABaseTests {

    func test_01_domain() {
        XCTAssertEqual(PushNotificationError.errorDomain, "com.forgerock.ios.frauthenticator.pushnotification")
    }
    
    
    func test_02_missing_device_token() {
        let error = PushNotificationError.missingDeviceToken
        
        XCTAssertEqual(error.code, 1100000)
        XCTAssertEqual(error.errorCode, 1100000)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Device Token for Push Notification is missing")
    }
    
    
    func test_03_notification_invalid_status() {
        let error = PushNotificationError.notificationInvalidStatus
        
        XCTAssertEqual(error.code, 1100001)
        XCTAssertEqual(error.errorCode, 1100001)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "PushNotification is not in a valid status to authenticate; either PushNotification has already been authenticated or expired")
    }
    
    
    func test_04_storage_error() {
        let error = PushNotificationError.storageError("storage error")
        
        XCTAssertEqual(error.code, 1100002)
        XCTAssertEqual(error.errorCode, 1100002)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Storage error: storage error")
    }
}
