// 
//  ActionTests.swift
//  FRCoreTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest

class ActionTests: FRBaseTestCase {
    
    func test_01_action_start_authenticate() {
        let action = Action(type: .START_AUTHENTICATE)
        XCTAssertEqual(action.type, "START_AUTHENTICATE")
    }
    
    
    func test_02_action_authenticate() {
        let action = Action(type: .AUTHENTICATE)
        XCTAssertEqual(action.type, "AUTHENTICATE")
    }
    
    
    func test_03_action_authorize() {
        let action = Action(type: .AUTHORIZE)
        XCTAssertEqual(action.type, "AUTHORIZE")
    }
    
    
    func test_04_action_exchange_token() {
        let action = Action(type: .EXCHANGE_TOKEN)
        XCTAssertEqual(action.type, "EXCHANGE_TOKEN")
    }
    
    
    func test_05_action_refresh_token() {
        let action = Action(type: .REFRESH_TOKEN)
        XCTAssertEqual(action.type, "REFRESH_TOKEN")
    }
    
    
    func test_06_action_revoke_token() {
        let action = Action(type: .REVOKE_TOKEN)
        XCTAssertEqual(action.type, "REVOKE_TOKEN")
    }
    
    
    func test_07_action_logout() {
        let action = Action(type: .LOGOUT)
        XCTAssertEqual(action.type, "LOGOUT")
    }
    
    
    func test_08_action_push_register() {
        let action = Action(type: .PUSH_REGISTER)
        XCTAssertEqual(action.type, "PUSH_REGISTER")
    }
    
    
    func test_09_action_push_authenticate() {
        let action = Action(type: .PUSH_AUTHENTICATE)
        XCTAssertEqual(action.type, "PUSH_AUTHENTICATE")
    }
    
    
    func test_10_action_user_info() {
        let action = Action(type: .USER_INFO)
        XCTAssertEqual(action.type, "USER_INFO")
    }
    
    
    func test_11_action_end_session() {
        let action = Action(type: .END_SESSION)
        XCTAssertEqual(action.type, "END_SESSION")
    }
}
