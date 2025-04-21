// 
//  AccountTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class AccountTests: FRABaseTests {

    func test_01_account_init_success() {
        let issuer = "issuer"
        let accountName = "accountName"
        
        let account = Account(issuer: issuer, accountName: accountName)
        
        XCTAssertNotNil(account)
        
        XCTAssertEqual(account.issuer, issuer)
        XCTAssertEqual(account.accountName, accountName)
        XCTAssertEqual(account.displayIssuer, issuer)
        XCTAssertEqual(account.displayAccountName, accountName)
        XCTAssertEqual(account.identifier, issuer + "-" + accountName)
        XCTAssertNotNil(account.timeAdded)
    }
    
    
    func test_02_account_init_with_optional_params_success() {
        let issuer = "issuer"
        let accountName = "accountName"
        let other_issuer = "other_issuer"
        let other_accountName = "other_accountName"
        let imageUrl = "https://www.forgerock.com"
        let backgroundColor = "#FFFFFF"
        let jsonPolicies = """
            {"biometricAvailable": { },"deviceTampering": {"score": 0.8}}
        """
        
        let account = Account(issuer: issuer, accountName: accountName, imageUrl: imageUrl, backgroundColor: backgroundColor, policies: jsonPolicies)
        
        XCTAssertNotNil(account)
        
        XCTAssertEqual(account.issuer, issuer)
        XCTAssertEqual(account.accountName, accountName)
        XCTAssertEqual(account.imageUrl, imageUrl)
        XCTAssertEqual(account.backgroundColor, backgroundColor)
        XCTAssertEqual(account.policies, jsonPolicies)
        XCTAssertNotNil(account.timeAdded)
        
        account.displayIssuer = other_issuer
        account.displayAccountName = other_accountName
        
        XCTAssertEqual(account.displayIssuer, other_issuer)
        XCTAssertEqual(account.displayAccountName, other_accountName)
    }
    
    
    func test_03_account_archive_obj() {
        let issuer = "issuer"
        let accountName = "accountName"
        let imageUrl = "https://www.forgerock.com"
        let backgroundColor = "#FFFFFF"
        
        let account = Account(issuer: issuer, accountName: accountName, imageUrl: imageUrl, backgroundColor: backgroundColor)
        
        if let accountData = try? NSKeyedArchiver.archivedData(withRootObject: account, requiringSecureCoding: true) {
            let accountFromData = NSKeyedUnarchiver.unarchiveObject(with: accountData) as? Account
            XCTAssertNotNil(accountFromData)
            XCTAssertEqual(account.issuer, accountFromData?.issuer)
            XCTAssertEqual(account.accountName, accountFromData?.accountName)
            XCTAssertEqual(account.imageUrl, accountFromData?.imageUrl)
            XCTAssertEqual(account.backgroundColor, accountFromData?.backgroundColor)
            XCTAssertEqual(account.timeAdded.timeIntervalSince1970, accountFromData?.timeAdded.timeIntervalSince1970)
        }
        else {
            XCTFail("Failed to serialize Account object with Secure Coding")
        }
    }
    
    
    func test_04_account_time_added_timestamp() {
        let account1 = Account(issuer: "issuer1", accountName: "accountName1")
        sleep(1)
        let account2 = Account(issuer: "issuer2", accountName: "accountName2")
        sleep(1)
        let account3 = Account(issuer: "issuer3", accountName: "accountName3")
        sleep(1)
        let account4 = Account(issuer: "issuer4", accountName: "accountName4")
        sleep(1)
        
        FRAClient.start()
        FRAClient.storage.setAccount(account: account4)
        FRAClient.storage.setAccount(account: account1)
        FRAClient.storage.setAccount(account: account3)
        FRAClient.storage.setAccount(account: account2)
        
        
        guard let accounts = FRAClient.shared?.getAllAccounts() else {
            XCTFail("Failed to retrieve Account objects")
            return
        }
        
        let accountIssuers: [String] = ["issuer1", "issuer2", "issuer3", "issuer4"]
        for (index, account) in accounts.enumerated() {
            XCTAssertEqual(accountIssuers[index], account.issuer)
        }
    }
    
    
    func test_05_codable_serialization() {
        let issuer = "issuer"
        let accountName = "accountName"
        let imageUrl = "https://www.forgerock.com"
        let backgroundColor = "#FFFFFF"
        let account = Account(issuer: issuer, accountName: accountName, imageUrl: imageUrl, backgroundColor: backgroundColor)
        
        do {
            // Encode
            let jsonData = try JSONEncoder().encode(account)
            
            // Decode
            let decodedAccount = try JSONDecoder().decode(Account.self, from: jsonData)

            XCTAssertEqual(account.issuer, decodedAccount.issuer)
            XCTAssertEqual(account.accountName, decodedAccount.accountName)
            XCTAssertEqual(account.imageUrl, decodedAccount.imageUrl)
            XCTAssertEqual(account.backgroundColor, decodedAccount.backgroundColor)
            XCTAssertEqual(account.timeAdded.millisecondsSince1970, decodedAccount.timeAdded.millisecondsSince1970)
            XCTAssertEqual(account.identifier, decodedAccount.identifier)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    
    func test_06_json_string_serialization() {
        let issuer = "issuer"
        let accountName = "accountName"
        let imageUrl = "https://www.forgerock.com"
        let backgroundColor = "#FFFFFF"
        let account = Account(issuer: issuer, accountName: accountName, imageUrl: imageUrl, backgroundColor: backgroundColor)
        
        
        guard let jsonString = account.toJson() else {
            XCTFail("Failed to serialize the object into JSON String value")
            return
        }
        
        //  Covert jsonString to Dictionary
        let jsonDictionary = FRJSONEncoder.jsonStringToDictionary(jsonString: jsonString)
            
        //  Then
        XCTAssertEqual(account.issuer, jsonDictionary?["issuer"] as! String)
        XCTAssertEqual(account.accountName, jsonDictionary?["accountName"] as! String)
        XCTAssertEqual(account.imageUrl, (jsonDictionary?["imageURL"] as! String))
        XCTAssertEqual(account.backgroundColor, (jsonDictionary?["backgroundColor"] as! String))
        XCTAssertEqual(account.timeAdded.millisecondsSince1970, jsonDictionary?["timeAdded"] as! Int64)
        XCTAssertEqual(account.identifier, jsonDictionary?["id"] as! String)
    }
    
}
