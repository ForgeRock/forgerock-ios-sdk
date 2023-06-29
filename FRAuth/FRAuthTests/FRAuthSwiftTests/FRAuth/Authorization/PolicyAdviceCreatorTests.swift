// 
//  PolicyAdviceCreatorTests.swift
//  FRAuthTests
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

final class PolicyAdviceCreatorTests: XCTestCase {

    func test_legacy_IG_response() {
        
        //  Given
        let adviceStr = """
        https://default.forgeops.petrov.ca/am/?goto=http://openig.petrov.ca/products?_txid%3Dcbac1559-ec42-4bdb-9d30-61c3abaf5a6b&realm=/&authIndexType=composite_advice&authIndexValue=%3CAdvices%3E%3CAttributeValuePair%3E%3CAttribute%20name%3D%22TransactionConditionAdvice%22/%3E%3CValue%3Ecbac1559-ec42-4bdb-9d30-61c3abaf5a6b%3C/Value%3E%3C/AttributeValuePair%3E%3C/Advices%3E
        """
        
        let policyAdviceCreator = PolicyAdviceCreator()
        let result = policyAdviceCreator.parse(advice: adviceStr)
        XCTAssertEqual(result?.authIndexType, "composite_advice")
        XCTAssertEqual(result?.authIndexValue, "<Advices><AttributeValuePair><Attribute name=\"TransactionConditionAdvice\"/><Value>cbac1559-ec42-4bdb-9d30-61c3abaf5a6b</Value></AttributeValuePair></Advices>")
        XCTAssertEqual(result?.type, AdviceType.transactionCondition)
        XCTAssertEqual(result?.value, "cbac1559-ec42-4bdb-9d30-61c3abaf5a6b")
        
    }
    
    func test_encoded_legacy_IG_response() {
        
        //  Given
        let adviceStr = """
        https://default.forgeops.petrov.ca/am/?goto=http://openig.petrov.ca/products?_txid%3Debfbbd31-36d7-486f-89fd-7bf7694d3e7e&realm=/&authIndexType=composite_advice&authIndexValue=PEFkdmljZXM-PEF0dHJpYnV0ZVZhbHVlUGFpcj48QXR0cmlidXRlIG5hbWU9IlRyYW5zYWN0aW9uQ29uZGl0aW9uQWR2aWNlIi8-PFZhbHVlPmViZmJiZDMxLTM2ZDctNDg2Zi04OWZkLTdiZjc2OTRkM2U3ZTwvVmFsdWU-PC9BdHRyaWJ1dGVWYWx1ZVBhaXI-PC9BZHZpY2VzPg
        """
        
        let policyAdviceCreator = PolicyAdviceCreator()
        let result = policyAdviceCreator.parse(advice: adviceStr)
        XCTAssertEqual(result?.authIndexType, "composite_advice")
        XCTAssertEqual(result?.authIndexValue, "<Advices><AttributeValuePair><Attribute name=\"TransactionConditionAdvice\"/><Value>ebfbbd31-36d7-486f-89fd-7bf7694d3e7e</Value></AttributeValuePair></Advices>")
        XCTAssertEqual(result?.type, AdviceType.transactionCondition)
        XCTAssertEqual(result?.value, "ebfbbd31-36d7-486f-89fd-7bf7694d3e7e")
        
    }
    
    
    func test_invalid_legacy_IG_response() {
        
        //  Given
        let adviceStr = """
        https://default.forgeops.petrov.ca/am/?goto=http://openig.petrov.ca/products?_txid%3Dcbac1559-ec42-4bdb-9d30-61c3abaf5a6b&realm=/&authIndexType=composite_advice&authIndexValue=%3CAdvices%3E%3CAttributeValuePair%3E%3CAttribute%20name%3D%/Value%3E%3C/AttributeValuePair%3E%3C/Advices%3E
        """
        
        let policyAdviceCreator = PolicyAdviceCreator()
        let result = policyAdviceCreator.parse(advice: adviceStr)
        XCTAssertEqual(result, nil)
    }

    func test_new_JSON_IG_response() {
        
        //  Given
        let adviceStr = "SSOADVICE realm=\"/\",advices=\"eyJUcmFuc2FjdGlvbkNvbmRpdGlvbkFkdmljZSI6WyI1ODY2OWUxOS00MjVhLTQzMzMtOTFkOC03MDk5NWFmMDY5MjciXX0=\",am_uri=\"https://default.forgeops.petrov.ca/am/\""
        
        let policyAdviceCreator = PolicyAdviceCreator()
        let result = policyAdviceCreator.parseAsBase64(advice: adviceStr)
        XCTAssertEqual(result?.authIndexType, "composite_advice")
        XCTAssertEqual(result?.authIndexValue, "<Advices><AttributeValuePair><Attribute name=\"TransactionConditionAdvice\"/><Value>58669e19-425a-4333-91d8-70995af06927</Value></AttributeValuePair></Advices>")
        XCTAssertEqual(result?.type, AdviceType.transactionCondition)
        XCTAssertEqual(result?.value, "58669e19-425a-4333-91d8-70995af06927")
        
    }
    
    func test_invalid_JSON_IG_response() {
        
        //  Given
        let adviceStr = "SSOADVICE realm=\"/\",advices=\"hLTQzMzMtOTFkOC03MDk5NWFmMDY5MjciXX0=\",am_uri=\"https://default.forgeops.petrov.ca/am/\""
        
        let policyAdviceCreator = PolicyAdviceCreator()
        let result = policyAdviceCreator.parseAsBase64(advice: adviceStr)
        XCTAssertEqual(result, nil)
    }
    
}
