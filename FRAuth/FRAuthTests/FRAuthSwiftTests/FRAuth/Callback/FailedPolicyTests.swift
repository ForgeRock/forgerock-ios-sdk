// 
//  FailedPolicyTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class FailedPolicyTests: FRAuthBaseTest {
    
    // - MARK: FailedPolicy
    
    func testFailedPolicyInitWithInvalidFormat() {
        // Given
        let jsonStr = """
        {
            "params": {"numNums": 1}
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let _ = try FailedPolicy("Username", failedPolicyJson)
            XCTFail("Succeed while expecting failure for invalid FailedPolicy response: \(failedPolicyJson)")
        } catch {
        }
    }
    
    
    func testFailedPolicyInit_UNKNOWN_FORMAT() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "UNKNOWN_FORMAT"
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "UNKNOWN_FORMAT")
            XCTAssertEqual(failedPolicy.failedDescription(), "Username: Unknown policy requirement - UNKNOWN_FORMAT")
            
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_REQUIRED() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "REQUIRED"
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "REQUIRED")
            XCTAssertEqual(failedPolicy.failedDescription(), "Username is required")
            
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_UNIQUE() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "UNIQUE"
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "UNIQUE")
            XCTAssertEqual(failedPolicy.failedDescription(), "Username must be unique")
            
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_INVALID_DATE() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "VALID_DATE"
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "VALID_DATE")
            XCTAssertEqual(failedPolicy.failedDescription(), "Invalid date")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_INVALID_EMAIL_FORMAT() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "VALID_EMAIL_ADDRESS_FORMAT"
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "VALID_EMAIL_ADDRESS_FORMAT")
            XCTAssertEqual(failedPolicy.failedDescription(), "Invalid Email format")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_INVALID_NAME_FORMAT() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "VALID_NAME_FORMAT"
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "VALID_NAME_FORMAT")
            XCTAssertEqual(failedPolicy.failedDescription(), "Invalid name format")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_INVALID_PHONE_FORMAT() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "VALID_PHONE_FORMAT"
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "VALID_PHONE_FORMAT")
            XCTAssertEqual(failedPolicy.failedDescription(), "Invalid phone number")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_AtLeastCapital() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "AT_LEAST_X_CAPITAL_LETTERS",
            "params" : {
                "numCaps" : 5
            }
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNotNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "AT_LEAST_X_CAPITAL_LETTERS")
            XCTAssertEqual(failedPolicy.failedDescription(), "Username must contain at least 5 capital letter(s)")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_AtLeastNumber() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "AT_LEAST_X_NUMBERS",
            "params" : {
                "numNums" : 5
            }
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNotNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "AT_LEAST_X_NUMBERS")
            XCTAssertEqual(failedPolicy.failedDescription(), "Username must contain at least 5 numeric value(s)")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_INVALID_NUMBER() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "VALID_NUMBER"
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "VALID_NUMBER")
            XCTAssertEqual(failedPolicy.failedDescription(), "Invalid number")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_MIN_LENGTH() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "MIN_LENGTH",
            "params" : {
                "minLength" : 5
            }
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNotNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "MIN_LENGTH")
            XCTAssertEqual(failedPolicy.failedDescription(), "Username must be at least 5 character(s)")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }
    
    
    func testFailedPolicyInit_MAX_LENGTH() {
        // Given
        let jsonStr = """
        {
            "policyRequirement" : "MAX_LENGTH",
            "params" : {
                "maxLength" : 5
            }
        }
        """
        let failedPolicyJson = self.parseStringToDictionary(jsonStr)
        
        // Try
        do {
            let failedPolicy = try FailedPolicy("Username", failedPolicyJson)
            
            XCTAssertNotNil(failedPolicy.params)
            XCTAssertEqual(failedPolicy.policyRequirement, "MAX_LENGTH")
            XCTAssertEqual(failedPolicy.failedDescription(), "Username must be at most 5 character(s)")
        } catch let error {
            XCTFail("Failed while expecting success: \(error)")
        }
    }    
}
