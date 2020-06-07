// 
//  AccountTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest

class AccountTests: FRABaseTests {

    func test_01_account_init_success() {
        let issuer = "issuer"
        let accountName = "accountName"
        
        let account = Account(issuer: issuer, accountName: accountName)
        
        XCTAssertNotNil(account)
        
        XCTAssertEqual(account.issuer, issuer)
        XCTAssertEqual(account.accountName, accountName)
        XCTAssertEqual(account.identifier, issuer + "-" + accountName)
        XCTAssertNotNil(account.timeAdded)
    }
    
    
    func test_02_account_init_with_optional_params_success() {
        let issuer = "issuer"
        let accountName = "accountName"
        let imageUrl = "https://www.forgerock.com"
        let backgroundColor = "#FFFFFF"
        
        let account = Account(issuer: issuer, accountName: accountName, imageUrl: imageUrl, backgroundColor: backgroundColor)
        
        XCTAssertNotNil(account)
        
        XCTAssertEqual(account.issuer, issuer)
        XCTAssertEqual(account.accountName, accountName)
        XCTAssertEqual(account.imageUrl, imageUrl)
        XCTAssertEqual(account.backgroundColor, backgroundColor)
        XCTAssertNotNil(account.timeAdded)
    }
    
    
    func test_03_account_archive_obj() {
        let issuer = "issuer"
        let accountName = "accountName"
        let imageUrl = "https://www.forgerock.com"
        let backgroundColor = "#FFFFFF"
        
        let account = Account(issuer: issuer, accountName: accountName, imageUrl: imageUrl, backgroundColor: backgroundColor)
        
        let accountData = NSKeyedArchiver.archivedData(withRootObject: account)
        let accountFromData = NSKeyedUnarchiver.unarchiveObject(with: accountData) as? Account
        
        XCTAssertNotNil(accountFromData)
        XCTAssertEqual(account.issuer, accountFromData?.issuer)
        XCTAssertEqual(account.accountName, accountFromData?.accountName)
        XCTAssertEqual(account.imageUrl, accountFromData?.imageUrl)
        XCTAssertEqual(account.backgroundColor, accountFromData?.backgroundColor)
        XCTAssertEqual(account.timeAdded.timeIntervalSince1970, accountFromData?.timeAdded.timeIntervalSince1970)
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
}
