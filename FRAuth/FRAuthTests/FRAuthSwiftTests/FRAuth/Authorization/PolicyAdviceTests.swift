// 
//  PolicyAdviceTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class PolicyAdviceTests: FRAuthBaseTest {
    
    
    func test_01_policy_advice_init_with_invalid_json() {
        
        //  Given
        let adviceStr = """
        {
            "resource": "http://localhost:9888/policy/transfer",
            "actions": [],
            "attributes": [],
            "ttl": 0
        }
        """
        let adviceJSON = self.parseStringToDictionary(adviceStr)
        
        //  Then
        let advice = PolicyAdvice(json: adviceJSON)
        XCTAssertNil(advice)
    }
    
    
    func test_02_policy_advice_init_with_json_authenticate_to_service() {
        //  Given
        let adviceStr = """
        {
            "resource": "http://localhost:9888/policy/transfer",
            "actions": [],
            "attributes": [],
            "ttl": 0,
            "advices": {
                "TransactionConditionAdvice": ["5afff42a-2715-40c8-98e7-919abc1b2dfc"]
            }
        }
        """
        let adviceJSON = self.parseStringToDictionary(adviceStr)
        
        //  Then
        let advice = PolicyAdvice(json: adviceJSON)
        XCTAssertNotNil(advice)
        XCTAssertNotNil(advice?.txId)
        XCTAssertEqual(advice?.txId, "5afff42a-2715-40c8-98e7-919abc1b2dfc")
        XCTAssertEqual(advice?.value, "5afff42a-2715-40c8-98e7-919abc1b2dfc")
        XCTAssertEqual(advice?.type, AdviceType.transactionCondition)
        XCTAssertEqual(advice?.authIndexType, OpenAM.compositeAdvice)
        XCTAssertEqual(advice?.authIndexValue, "<Advices><AttributeValuePair><Attribute name=\"TransactionConditionAdvice\"/><Value>5afff42a-2715-40c8-98e7-919abc1b2dfc</Value></AttributeValuePair></Advices>")
    }
    

    func test_03_policy_advice_init_with_json_authenticate_to_service() {
        
        //  Given
        let adviceStr = """
        {
            "advices": {
                "AuthenticateToServiceConditionAdvice": ["/:UsernamePassword"]
            },
            "ttl": 9223372036854775807,
            "resource": "http://localhost:9888/policy/transfer",
            "actions": [],
            "attributes": []
        }
        """
        let adviceJSON = self.parseStringToDictionary(adviceStr)
        
        //  Then
        let advice = PolicyAdvice(json: adviceJSON)
        XCTAssertNotNil(advice)
        XCTAssertNil(advice?.txId)
        XCTAssertEqual(advice?.value, "/:UsernamePassword")
        XCTAssertEqual(advice?.type, AdviceType.authenticateToService)
        XCTAssertEqual(advice?.authIndexType, OpenAM.compositeAdvice)
        XCTAssertEqual(advice?.authIndexValue, "<Advices><AttributeValuePair><Attribute name=\"AuthenticateToServiceConditionAdvice\"/><Value>/:UsernamePassword</Value></AttributeValuePair></Advices>")
    }
    
    
    func test_04_policy_advice_init_with_params() {
        //  Given
        var advice = PolicyAdvice(type: "TransactionConditionAdvice", value: "5afff42a-2715-40c8-98e7-919abc1b2dfc")
        //  Then
        XCTAssertNotNil(advice)
        XCTAssertNotNil(advice?.txId)
        XCTAssertEqual(advice?.txId, "5afff42a-2715-40c8-98e7-919abc1b2dfc")
        XCTAssertEqual(advice?.value, "5afff42a-2715-40c8-98e7-919abc1b2dfc")
        XCTAssertEqual(advice?.type, AdviceType.transactionCondition)
        XCTAssertEqual(advice?.authIndexType, OpenAM.compositeAdvice)
        XCTAssertEqual(advice?.authIndexValue, "<Advices><AttributeValuePair><Attribute name=\"TransactionConditionAdvice\"/><Value>5afff42a-2715-40c8-98e7-919abc1b2dfc</Value></AttributeValuePair></Advices>")
        
        
        //  Given
        advice = PolicyAdvice(type: "AuthenticateToServiceConditionAdvice", value: "/:UsernamePassword")
        //  Then
        XCTAssertNotNil(advice)
        XCTAssertNil(advice?.txId)
        XCTAssertEqual(advice?.value, "/:UsernamePassword")
        XCTAssertEqual(advice?.type, AdviceType.authenticateToService)
        XCTAssertEqual(advice?.authIndexType, OpenAM.compositeAdvice)
        XCTAssertEqual(advice?.authIndexValue, "<Advices><AttributeValuePair><Attribute name=\"AuthenticateToServiceConditionAdvice\"/><Value>/:UsernamePassword</Value></AttributeValuePair></Advices>")
        
        //  Given
        advice = PolicyAdvice(type: "AuthSchemeConditionAdvice", value: "/:UsernamePassword")
        //  Then
        XCTAssertNil(advice)
    }
    
    
    func test_05_policy_advice_init_with_url_transaction() {
        //  Given
        let redirectURL = "https://openam.example.com/openam/?goto=https://openam.example.com:443/anything?_txid%3D88d1d52a-5d6b-4c66-9130-3ad78e9395de&realm=/&authIndexType=composite_advice&authIndexValue=%3CAdvices%3E%3CAttributeValuePair%3E%3CAttribute%20name%3D%22TransactionConditionAdvice%22/%3E%3CValue%3E88d1d52a-5d6b-4c66-9130-3ad78e9395de%3C/Value%3E%3C/AttributeValuePair%3E%3C/Advices%3E"
        
        //  Then
        let advice = PolicyAdvice(redirectUrl: redirectURL)
        XCTAssertNotNil(advice)
        XCTAssertNotNil(advice?.txId)
        XCTAssertEqual(advice?.txId, "88d1d52a-5d6b-4c66-9130-3ad78e9395de")
        XCTAssertEqual(advice?.value, "88d1d52a-5d6b-4c66-9130-3ad78e9395de")
        XCTAssertEqual(advice?.type, AdviceType.transactionCondition)
        XCTAssertEqual(advice?.authIndexType, OpenAM.compositeAdvice)
        XCTAssertEqual(advice?.authIndexValue, "<Advices><AttributeValuePair><Attribute name=\"TransactionConditionAdvice\"/><Value>88d1d52a-5d6b-4c66-9130-3ad78e9395de</Value></AttributeValuePair></Advices>")
    }
    
    
    func test_06_policy_advice_init_with_url_authenticate_to_service() {
        //  Given
        let redirectURL = "https://openam.example.com/openam/?goto=https://openam.example.com:443/anything&realm=/&authIndexType=composite_advice&authIndexValue=%3CAdvices%3E%3CAttributeValuePair%3E%3CAttribute%20name%3D%22AuthenticateToServiceConditionAdvice%22/%3E%3CValue%3E/:UsernamePassword%3C/Value%3E%3C/AttributeValuePair%3E%3C/Advices%3E"
        
        //  Then
        let advice = PolicyAdvice(redirectUrl: redirectURL)
        XCTAssertNotNil(advice)
        XCTAssertNil(advice?.txId)
        XCTAssertEqual(advice?.value, "/:UsernamePassword")
        XCTAssertEqual(advice?.type, AdviceType.authenticateToService)
        XCTAssertEqual(advice?.authIndexType, OpenAM.compositeAdvice)
        XCTAssertEqual(advice?.authIndexValue, "<Advices><AttributeValuePair><Attribute name=\"AuthenticateToServiceConditionAdvice\"/><Value>/:UsernamePassword</Value></AttributeValuePair></Advices>")
    }
    
    
    func test_07_policy_advice_init_with_invalid_url() {
        //  Given invalid URL
        var redirectURL = "not_url"
        
        //  Then
        var advice = PolicyAdvice(redirectUrl: redirectURL)
        XCTAssertNil(advice)
        
        
        //  Given regular URL
        redirectURL = "https://openam.example.com/openam/"
        
        //  Then
        advice = PolicyAdvice(redirectUrl: redirectURL)
        XCTAssertNil(advice)
        
        
        //  Given missing authIndexValue
        redirectURL = "https://openam.example.com/openam/?goto=https://openam.example.com:443/anything&realm=/&authIndexType=composite_advice"
        
        //  Then
        advice = PolicyAdvice(redirectUrl: redirectURL)
        XCTAssertNil(advice)
        
        
        //  Given missing authIndexType
        redirectURL = "https://openam.example.com/openam/?goto=https://openam.example.com:443/anything&realm=/&authIndexValue=%3CAdvices%3E%3CAttributeValuePair%3E%3CAttribute%20name%3D%22AuthenticateToServiceConditionAdvice%22/%3E%3CValue%3E/:UsernamePassword%3C/Value%3E%3C/AttributeValuePair%3E%3C/Advices%3E"
        
        //  Then
        advice = PolicyAdvice(redirectUrl: redirectURL)
        XCTAssertNil(advice)
        
        
        //  Given wrong XML tag
        redirectURL = "https://openam.example.com/openam/?goto=https://openam.example.com:443/anything&realm=/&authIndexValue=%3CAdvices%3E%3CAttributeValuePair%3E%3CAttribute%20name%3D%22AuthenticateToServiceConditionAdvice%22/%3E%3CValueOne%3E/:UsernamePassword%3C/ValueOne%3E%3C/AttributeValuePair%3E%3C/Advices%3E"
        
        //  Then
        advice = PolicyAdvice(redirectUrl: redirectURL)
        XCTAssertNil(advice)
        
        
        //  Given wrong XML tag
        redirectURL = "https://openam.example.com/openam/?goto=https://openam.example.com:443/anything&realm=/&authIndexValue=%3CAdvices%3E%3CAttributeValuePair%3E%3CAttributeOne%20name%3D%22AuthenticateToServiceConditionAdvice%22/%3E%3CValueOne%3E/:UsernamePassword%3C/ValueOne%3E%3C/AttributeValuePair%3E%3C/Advices%3E"
        
        //  Then
        advice = PolicyAdvice(redirectUrl: redirectURL)
        XCTAssertNil(advice)
        
    }
}
