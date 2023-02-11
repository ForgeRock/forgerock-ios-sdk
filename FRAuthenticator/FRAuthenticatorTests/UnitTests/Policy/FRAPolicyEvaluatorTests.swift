// 
//  FRAPolicyEvaluatorTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuthenticator

final class FRAPolicyEvaluatorTests: FRABaseTests {

    func test_01_register_single_policy() throws {
        let policyEvaluator = FRAPolicyEvaluator()
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
        policyEvaluator.registerPolicies(policies: [DummyPolicy()])
        XCTAssertEqual(policyEvaluator.policies?.count, 1)
    }

    func test_02_register_multiple_policies() throws {
        let policyEvaluator = FRAPolicyEvaluator()
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
        policyEvaluator.registerPolicies(policies: FRAPolicyEvaluator.defaultPolicies)
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
    }
    
    func test_03_register_multiple_policies_override_true() {
        let policyEvaluator = FRAPolicyEvaluator()
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
        policyEvaluator.registerPolicies(policies: [DummyPolicy()])
        XCTAssertEqual(policyEvaluator.policies?.count, 1)
        policyEvaluator.registerPolicies(policies: FRAPolicyEvaluator.defaultPolicies, shouldOverride: true)
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
    }
    
    func test_04_register_multiple_policies_override_false() {
        let policyEvaluator = FRAPolicyEvaluator()
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
        policyEvaluator.registerPolicies(policies: [DummyPolicy()])
        XCTAssertEqual(policyEvaluator.policies?.count, 1)
        policyEvaluator.registerPolicies(policies: FRAPolicyEvaluator.defaultPolicies, shouldOverride: false)
        XCTAssertEqual(policyEvaluator.policies?.count, 3)
    }
    
    func test_05_register_empty_override_false() {
        let policyEvaluator = FRAPolicyEvaluator()
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
        policyEvaluator.registerPolicies(policies: FRAPolicyEvaluator.defaultPolicies)
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
        policyEvaluator.registerPolicies(policies: [], shouldOverride: false)
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
    }
    
    func test_06_register_empty_override_true() {
        let policyEvaluator = FRAPolicyEvaluator()
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
        policyEvaluator.registerPolicies(policies: FRAPolicyEvaluator.defaultPolicies)
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
        policyEvaluator.registerPolicies(policies: [], shouldOverride: true)
        XCTAssertEqual(policyEvaluator.policies?.count, 0)
    }
    
    func test_07_register_same_policy_twice() throws {
        let policyEvaluator = FRAPolicyEvaluator()
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
        policyEvaluator.registerPolicies(policies: FRAPolicyEvaluator.defaultPolicies)
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
        policyEvaluator.registerPolicies(policies: [DeviceTamperingPolicy()], shouldOverride: false)
        XCTAssertEqual(policyEvaluator.policies?.count, 3)
    }
    
    func test_08_evaluate_uri_successful_when_policy_registered() throws {
        let policyEvaluator = FRAPolicyEvaluator()
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
        
        policyEvaluator.registerPolicies(policies: [DummyPolicy()])
        XCTAssertEqual(policyEvaluator.policies?.count, 1)

        let qrCode = URL(string: "mfauth://totp/Forgerock:demo?" +
                         "a=aHR0cHM6Ly9mb3JnZXJvY2suZXhhbXBsZS5jb20vb3BlbmFtL2pzb24vcHVzaC9zbnMvbWVzc2FnZT9fYWN0aW9uPWF1dGhlbnRpY2F0ZQ&" +
                         "image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&" +
                         "b=ff00ff&" +
                         "r=aHR0cHM6Ly9mb3JnZXJvY2suZXhhbXBsZS5jb20vb3BlbmFtL2pzb24vcHVzaC9zbnMvbWVzc2FnZT9fYWN0aW9uPXJlZ2lzdGVy&" +
                         "s=ryJkqNRjXYd_nX523672AX_oKdVXrKExq-VjVeRKKTc&" +
                         "c=Daf8vrc8onKu-dcptwCRS9UHmdui5u16vAdG2HMU4w0&" +
                         "l=YW1sYmNvb2tpZT0wMQ==&" +
                         "m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&" +
                         "policies=eyJkdW1teSI6IHsgfX0=&" +
                         "digits=6&" +
                         "secret=R2PYFZRISXA5L25NVSSYK2RQ6E======&" +
                         "period=30&")!
        
        let result = policyEvaluator.evaluate(uri: qrCode)
        
        XCTAssertTrue(result.comply)
        XCTAssertNil(result.nonCompliancePolicy)
    }
    
    func test_09_evaluate_uri_successful_when_failure_policy_not_registered() throws {
        let policyEvaluator = FRAPolicyEvaluator()
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
        
        policyEvaluator.registerPolicies(policies: [DummyPolicy()])
        XCTAssertEqual(policyEvaluator.policies?.count, 1)

        let qrCode = URL(string: "mfauth://totp/Forgerock:demo?" +
                         "a=aHR0cHM6Ly9mb3JnZXJvY2suZXhhbXBsZS5jb20vb3BlbmFtL2pzb24vcHVzaC9zbnMvbWVzc2FnZT9fYWN0aW9uPWF1dGhlbnRpY2F0ZQ&" +
                         "image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&" +
                         "b=ff00ff&" +
                         "r=aHR0cHM6Ly9mb3JnZXJvY2suZXhhbXBsZS5jb20vb3BlbmFtL2pzb24vcHVzaC9zbnMvbWVzc2FnZT9fYWN0aW9uPXJlZ2lzdGVy&" +
                         "s=ryJkqNRjXYd_nX523672AX_oKdVXrKExq-VjVeRKKTc&" +
                         "c=Daf8vrc8onKu-dcptwCRS9UHmdui5u16vAdG2HMU4w0&" +
                         "l=YW1sYmNvb2tpZT0wMQ==&" +
                         "m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&" +
                         "policies=eyJkdW1teSI6IHsgfSwgImR1bW15RmFpbHVyZSI6IHsgfX0=&" +
                         "digits=6&" +
                         "secret=R2PYFZRISXA5L25NVSSYK2RQ6E======&" +
                         "period=30&")!
        
        let result = policyEvaluator.evaluate(uri: qrCode)
        
        XCTAssertTrue(result.comply)
        XCTAssertNil(result.nonCompliancePolicy)
    }
    
    func test_10_evaluate_uri_unsuccessful_when_failure_policy_registered() throws {
        let policyEvaluator = FRAPolicyEvaluator()
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
        
        policyEvaluator.registerPolicies(policies: [DummyPolicy(), DummyWithDataPolicy()])
        XCTAssertEqual(policyEvaluator.policies?.count, 2)

        let qrCode = URL(string: "mfauth://totp/Forgerock:demo?" +
                         "a=aHR0cHM6Ly9mb3JnZXJvY2suZXhhbXBsZS5jb20vb3BlbmFtL2pzb24vcHVzaC9zbnMvbWVzc2FnZT9fYWN0aW9uPWF1dGhlbnRpY2F0ZQ&" +
                         "image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&" +
                         "b=ff00ff&" +
                         "r=aHR0cHM6Ly9mb3JnZXJvY2suZXhhbXBsZS5jb20vb3BlbmFtL2pzb24vcHVzaC9zbnMvbWVzc2FnZT9fYWN0aW9uPXJlZ2lzdGVy&" +
                         "s=ryJkqNRjXYd_nX523672AX_oKdVXrKExq-VjVeRKKTc&" +
                         "c=Daf8vrc8onKu-dcptwCRS9UHmdui5u16vAdG2HMU4w0&" +
                         "l=YW1sYmNvb2tpZT0wMQ==&" +
                         "m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&" +
                         "policies=eyJkdW1teSI6IHsgfSwgImR1bW15V2l0aERhdGEiOiB7ICJyZXN1bHQiIDogZmFsc2UgfX0=&" +
                         "digits=6&" +
                         "secret=R2PYFZRISXA5L25NVSSYK2RQ6E======&" +
                         "period=30&")!
        
        let result = policyEvaluator.evaluate(uri: qrCode)
        
        XCTAssertFalse(result.comply)
        XCTAssertNotNil(result.nonCompliancePolicy)
        XCTAssertEqual(result.nonCompliancePolicy?.name, "dummyWithData")
    }
    
    func test_11_evaluate_account_successful() throws {
        let policyEvaluator = FRAPolicyEvaluator()
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
        
        policyEvaluator.registerPolicies(policies: [DummyPolicy()])
        XCTAssertEqual(policyEvaluator.policies?.count, 1)
        
        let account = Account(issuer: "Forgerock", displayIssuer: nil, accountName: "demo", displayAccountName: nil, imageUrl: nil, backgroundColor: nil, timeAdded: Date().timeIntervalSince1970, policies: "{\"dummy\": { }}", lockingPolicy: nil, lock: false)
        
        let result = policyEvaluator.evaluate(account: account!)
        
        XCTAssertTrue(result.comply)
        XCTAssertNil(result.nonCompliancePolicy)
    }
    
    func test_12_evaluate_account_unsuccessful() throws {
        let policyEvaluator = FRAPolicyEvaluator()
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
        
        policyEvaluator.registerPolicies(policies: [DummyPolicy(), DummyWithDataPolicy()])
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
        
        let account = Account(issuer: "Forgerock", displayIssuer: nil, accountName: "demo", displayAccountName: nil, imageUrl: nil, backgroundColor: nil, timeAdded: Date().timeIntervalSince1970, policies: "{\"dummy\": { }, \"dummyWithData\": { \"result\" : false }}", lockingPolicy: nil, lock: false)
        
        let result = policyEvaluator.evaluate(account: account!)
        
        XCTAssertFalse(result.comply)
        XCTAssertNotNil(result.nonCompliancePolicy)
        XCTAssertEqual(result.nonCompliancePolicy?.name, "dummyWithData")
    }
    
    func test_13_evaluate_account_successful_when_no_policy_registered() throws {
        let policyEvaluator = FRAPolicyEvaluator()
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
        
        policyEvaluator.registerPolicies(policies: [])
        XCTAssertEqual(policyEvaluator.policies?.count, 0)
        
        let account = Account(issuer: "Forgerock", displayIssuer: nil, accountName: "demo", displayAccountName: nil, imageUrl: nil, backgroundColor: nil, timeAdded: Date().timeIntervalSince1970, policies: "{\"dummy\": { }, \"dummyWithData\": { \"result\" : false }}", lockingPolicy: nil, lock: false)
        
        let result = policyEvaluator.evaluate(account: account!)
        
        XCTAssertTrue(result.comply)
        XCTAssertNil(result.nonCompliancePolicy)
    }
    
    func test_14_evaluate_account_successful_when_no_policy_attached_to_account() throws {
        let policyEvaluator = FRAPolicyEvaluator()
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
        
        policyEvaluator.registerPolicies(policies: [DummyPolicy(), DummyWithDataPolicy()])
        XCTAssertEqual(policyEvaluator.policies?.count, 2)
        
        let account = Account(issuer: "Forgerock", displayIssuer: nil, accountName: "demo", displayAccountName: nil, imageUrl: nil, backgroundColor: nil, timeAdded: Date().timeIntervalSince1970, policies: nil, lockingPolicy: nil, lock: false)
        
        let result = policyEvaluator.evaluate(account: account!)
        
        XCTAssertTrue(result.comply)
        XCTAssertNil(result.nonCompliancePolicy)
    }
    
}

