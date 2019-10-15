//
//  ObjcFRUserTests.m
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

#import <XCTest/XCTest.h>
#import "FRBaseTestsObjc.h"

@interface ObjcFRUserTests : FRBaseTestsObjc

@end

@implementation ObjcFRUserTests

- (void)setUp {
    self.configFileName = @"Config";
    [super setUp];
}


# pragma mark - FRUser login

- (void)testFRUserLogin {
    // Start SDK
    self.config.authServiceName = @"UsernamePassword";
    [self startSDK];
    
    // Set mock response
    [self loadMockResponses:@[@"AuthTree_UsernamePasswordNode",
                              @"AuthTree_SSOToken_Success",
                              @"OAuth2_AuthorizeRedirect_Success",
                              @"OAuth2_Token_Success"]];
    
    __block FRNode *currentNode = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"FRUser.login"];
    [FRUser loginWithCompletion:^(FRUser *user, FRNode *node, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(user);
        XCTAssertNotNil(node);
        currentNode = node;
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    XCTAssertNotNil(currentNode);
    
    for (FRCallback *callback in [currentNode callbacks]) {
        if ([callback isKindOfClass:[FRNameCallback class]]) {
            FRNameCallback *thisCallback = (FRNameCallback *)callback;
            thisCallback.value = self.config.username;
        }
        else if ([callback isKindOfClass:[FRPasswordCallback class]]) {
            FRPasswordCallback *thisCallback = (FRPasswordCallback *)callback;
            thisCallback.value = self.config.password;
        }
        else {
            XCTFail("Received unexpected callback %@", callback);
        }
    }
    
    ex = [self expectationWithDescription:@"Second Node submit"];
    [currentNode nextWithUserCompletion:^(FRUser *user, FRNode *node, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(node);
        XCTAssertNotNil(user);
        currentNode = node;
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    XCTAssertNil(currentNode);
    
    XCTAssertNotNil([FRUser currentUser]);
}


- (void)testFRUserLoginAfterAlreadyLoggedIn {
    // Perform User login first
    [self performUserLogin];
    
    // Then
    __block FRNode *currentNode = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"FRUser.login"];
    [FRUser loginWithCompletion:^(FRUser *user, FRNode *node, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(node);
        XCTAssertNotNil(user);
        currentNode = node;
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    XCTAssertNil(currentNode);
    XCTAssertNotNil([FRUser currentUser]);
}


# pragma mark - FRUser UserInfo

- (void)testGetUserInfoFailure {
    
    // Perform User login first
    [self performUserLogin];
    
    // Then USer should not be nil
    XCTAssertNotNil([FRUser currentUser]);
    
    // Load mock responses for failure response of /userinfo
    [self loadMockResponses:@[@"OAuth2_UserInfo_Failure"]];
    
    AccessToken *token = [[FRUser currentUser] token];
    token.value = [[NSUUID UUID] UUIDString];
    [[FRUser currentUser] setToken:token];
    
    XCTestExpectation *ex = [self expectationWithDescription:@"FRUser.login"];
    [[FRUser currentUser] getUserInfoWithCompletion:^(FRUserInfo *userInfo, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(userInfo);
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
}


- (void)testGetUserInfoSuccess {
    
    // Perform User login first
    [self performUserLogin];
    
    // Then User should not be nil
    XCTAssertNotNil([FRUser currentUser]);
    
    // Load mock responses for retrieving UserInfo from /userinfo
    [self loadMockResponses:@[@"OAuth2_UserInfo_Success"]];
    
    __block FRUserInfo *currentUserInfo = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"FRUser.login"];
    [[FRUser currentUser] getUserInfoWithCompletion:^(FRUserInfo *userInfo, NSError *error) {
        XCTAssertNotNil(userInfo);
        XCTAssertNil(error);
        currentUserInfo = userInfo;
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    
    // Then
    XCTAssertNotNil(currentUserInfo);
}


- (void)testUserInfoObjAndDescription {
    
    if (!self.shouldLoadMockResponses) {
        // No point of testing pre-loaded userInfo for real server
        return;
    }
    
    // Perform User login first
    [self performUserLogin];
    
    // Then USer should not be nil
    XCTAssertNotNil([FRUser currentUser]);
    
    // Load mock responses for retrieving UserInfo from /userinfo
    [self loadMockResponses:@[@"OAuth2_UserInfo_Success"]];
    
    __block FRUserInfo *currentUserInfo = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"FRUser.login"];
    [[FRUser currentUser] getUserInfoWithCompletion:^(FRUserInfo *userInfo, NSError *error) {
        XCTAssertNotNil(userInfo);
        XCTAssertNil(error);
        currentUserInfo = userInfo;
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    
    // Then
    XCTAssertNotNil(currentUserInfo);
    
    // Then validate
    NSString *userDebugInfo = [currentUserInfo debugDescription];
    NSDictionary *mockUserInfo = self.config.userInfo;
    
    if (mockUserInfo[@"address"] != nil) {
        NSDictionary *address = mockUserInfo[@"address"];
        
        XCTAssertTrue([currentUserInfo.address.formatted isEqualToString:address[@"formatted"]]);
        XCTAssertTrue([userDebugInfo containsString:address[@"street_address"]]);
        XCTAssertTrue([currentUserInfo.address.streetAddress isEqualToString:address[@"street_address"]]);
        XCTAssertTrue([userDebugInfo containsString:currentUserInfo.address.streetAddress]);
        XCTAssertTrue([currentUserInfo.address.locality isEqualToString:address[@"locality"]]);
        XCTAssertTrue([userDebugInfo containsString:address[@"locality"]]);
        XCTAssertTrue([currentUserInfo.address.region isEqualToString:address[@"region"]]);
        XCTAssertTrue([userDebugInfo containsString:address[@"region"]]);
        XCTAssertTrue([currentUserInfo.address.postalCode isEqualToString:address[@"postal_code"]]);
        XCTAssertTrue([userDebugInfo containsString:address[@"postal_code"]]);
        XCTAssertTrue([currentUserInfo.address.country isEqualToString:address[@"country"]]);
        XCTAssertTrue([userDebugInfo containsString:address[@"country"]]);
    }
    
    XCTAssertTrue([currentUserInfo.name isEqualToString:mockUserInfo[@"name"]]);
    XCTAssertTrue([userDebugInfo containsString:mockUserInfo[@"name"]]);
    XCTAssertTrue([currentUserInfo.familyName isEqualToString:mockUserInfo[@"family_name"]]);
    XCTAssertTrue([userDebugInfo containsString:mockUserInfo[@"family_name"]]);
    XCTAssertTrue([currentUserInfo.givenName isEqualToString:mockUserInfo[@"given_name"]]);
    XCTAssertTrue([userDebugInfo containsString:mockUserInfo[@"given_name"]]);
    XCTAssertTrue([currentUserInfo.middleName isEqualToString:mockUserInfo[@"middle_name"]]);
    XCTAssertTrue([userDebugInfo containsString:mockUserInfo[@"middle_name"]]);
    XCTAssertTrue([currentUserInfo.email isEqualToString:mockUserInfo[@"email"]]);
    XCTAssertTrue([userDebugInfo containsString:mockUserInfo[@"email"]]);
    XCTAssertTrue([currentUserInfo.phoneNumber isEqualToString:mockUserInfo[@"phone_number"]]);
    XCTAssertTrue([userDebugInfo containsString:mockUserInfo[@"phone_number"]]);
    XCTAssertTrue([currentUserInfo.sub isEqualToString:mockUserInfo[@"sub"]]);
    XCTAssertTrue([userDebugInfo containsString:mockUserInfo[@"sub"]]);
    XCTAssertTrue([currentUserInfo.nickName isEqualToString:mockUserInfo[@"nickname"]]);
    XCTAssertTrue([userDebugInfo containsString:mockUserInfo[@"nickname"]]);
    XCTAssertTrue([currentUserInfo.preferredUsername isEqualToString:mockUserInfo[@"preferred_username"]]);
    XCTAssertTrue([userDebugInfo containsString:mockUserInfo[@"preferred_username"]]);
    XCTAssertTrue([currentUserInfo.profile.absoluteString isEqualToString:mockUserInfo[@"profile"]]);
    XCTAssertTrue([userDebugInfo containsString:mockUserInfo[@"profile"]]);
    XCTAssertTrue([currentUserInfo.website.absoluteString isEqualToString:mockUserInfo[@"website"]]);
    XCTAssertTrue([userDebugInfo containsString:mockUserInfo[@"website"]]);
    XCTAssertTrue([currentUserInfo.picture.absoluteString isEqualToString:mockUserInfo[@"picture"]]);
    XCTAssertTrue([userDebugInfo containsString:mockUserInfo[@"picture"]]);
    XCTAssertTrue([currentUserInfo.gender isEqualToString:mockUserInfo[@"gender"]]);
    XCTAssertTrue([userDebugInfo containsString:mockUserInfo[@"gender"]]);
    XCTAssertTrue([userDebugInfo containsString:mockUserInfo[@"birthdate"]]);
    XCTAssertTrue([currentUserInfo.zoneInfo isEqualToString:mockUserInfo[@"zoneinfo"]]);
    XCTAssertTrue([userDebugInfo containsString:mockUserInfo[@"zoneinfo"]]);
    XCTAssertTrue([currentUserInfo.locale isEqualToString:mockUserInfo[@"locale"]]);
    XCTAssertTrue([userDebugInfo containsString:mockUserInfo[@"locale"]]);
}


# pragma mark - FRUser logout

- (void)testUserLogoutFailOnAMAPI {
    // Perform login first
    [self performUserLogin];
    
    // Then USer should not be nil
    XCTAssertNotNil([FRUser currentUser]);
    
    // Load mock responses for retrieving UserInfo from /userinfo
    [self loadMockResponses:@[@"AM_Session_Logout_Failure",
                              @"OAuth2_Token_Revoke_Success",
                              @"AuthTree_UsernamePasswordNode"]];
    
    // Perform logout
    [[FRUser currentUser] logout];
    sleep(5);
    
    // Then
    XCTAssertNil([FRUser currentUser]);
    
    XCTestExpectation *ex = [self expectationWithDescription:@"Validate FRAuth.next after logout"];
    [[FRAuth shared] nextWithFlowType:FRAuthFlowTypeAuthentication userCompletion:^(FRUser *user, FRNode *node, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(user);
        XCTAssertNotNil(node);
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
}


- (void)testUserLogOutSuccess {
    // Perform login first
    [self performUserLogin];
    
    // Then USer should not be nil
    XCTAssertNotNil([FRUser currentUser]);
    
    // Load mock responses for retrieving UserInfo from /userinfo
    [self loadMockResponses:@[@"AM_Session_Logout_Success",
                              @"OAuth2_Token_Revoke_Success",
                              @"AuthTree_UsernamePasswordNode"]];
    
    // Perform logout
    [[FRUser currentUser] logout];
    sleep(5);
    
    // Then
    XCTAssertNil([FRUser currentUser]);
    
    XCTestExpectation *ex = [self expectationWithDescription:@"Validate FRAuth.next after logout"];
    [[FRAuth shared] nextWithFlowType:FRAuthFlowTypeAuthentication userCompletion:^(FRUser *user, FRNode *node, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(user);
        XCTAssertNotNil(node);
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
}


# pragma mark - Helper for Login

- (void)performUserLogin {
    
    // Start SDK
    self.config.authServiceName = @"UsernamePassword";
    [self startSDK];
    
    // Set mock response
    [self loadMockResponses:@[@"AuthTree_UsernamePasswordNode",
                              @"AuthTree_SSOToken_Success",
                              @"OAuth2_AuthorizeRedirect_Success",
                              @"OAuth2_Token_Success"]];
    
    __block FRNode *currentNode = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"First Node submit"];
    [[FRAuth shared] nextWithFlowType:FRAuthFlowTypeAuthentication userCompletion:^(FRUser *user, FRNode *node, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(user);
        XCTAssertNotNil(node);
        currentNode = node;
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    XCTAssertNotNil(currentNode);
    
    for (FRCallback *callback in [currentNode callbacks]) {
        if ([callback isKindOfClass:[FRNameCallback class]]) {
            FRNameCallback *thisCallback = (FRNameCallback *)callback;
            thisCallback.value = self.config.username;
        }
        else if ([callback isKindOfClass:[FRPasswordCallback class]]) {
            FRPasswordCallback *thisCallback = (FRPasswordCallback *)callback;
            thisCallback.value = self.config.password;
        }
        else {
            XCTFail("Received unexpected callback %@", callback);
        }
    }
    
    ex = [self expectationWithDescription:@"Second Node submit"];
    [currentNode nextWithUserCompletion:^(FRUser *user, FRNode *node, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(node);
        XCTAssertNotNil(user);
        currentNode = node;
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    XCTAssertNil(currentNode);
    
    XCTAssertNotNil([FRUser currentUser]);
}

@end
