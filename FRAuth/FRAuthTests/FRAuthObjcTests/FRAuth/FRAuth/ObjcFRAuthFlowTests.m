//
//  ObjcFRAuthFlowTests.m
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

#import <XCTest/XCTest.h>
#import "FRBaseTestsObjc.h"

@interface ObjcFRAuthFlowTests : FRBaseTestsObjc

@end

@implementation ObjcFRAuthFlowTests

- (void)setUp {
    self.configFileName = @"Config";
    [super setUp];
}


- (void)test_01_Get_SSOTokenWithoutCleanup {
    
    // Start SDK
    self.config.authServiceName = @"UsernamePassword";
    [self startSDK];
    XCTAssertNotNil([FRAuth shared]);
    
    // Should not clean up session for next test
    self.shouldCleanup = NO;
    
    // Set mock response
    [self loadMockResponses:@[@"AuthTree_UsernamePasswordNode",
                              @"AuthTree_SSOToken_Success",
                              @"OAuth2_AuthorizeRedirect_Success",
                              @"OAuth2_Token_Success"]];
    
    __block FRNode *currentNode = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"First Node submit"];
    [[FRAuth shared] nextWithFlowType:FRAuthFlowTypeAuthentication tokenCompletion:^(Token *token, FRNode *node, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(token);
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
    [currentNode nextWithTokenCompletion:^(Token *token, FRNode *node, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(node);
        XCTAssertNotNil(token);
        currentNode = node;
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    XCTAssertNil(currentNode);
}


- (void)test_02_Get_SSOTokenFromPreviousTest {
    
    // Start SDK
    self.config.authServiceName = @"UsernamePassword";
    [self startSDK];
    XCTAssertNotNil([FRAuth shared]);
    
    // Should not clean up session for next test
    self.shouldCleanup = NO;
    
    XCTestExpectation *ex = [self expectationWithDescription:@"First Node submit"];
    [[FRAuth shared] nextWithFlowType:FRAuthFlowTypeAuthentication tokenCompletion:^(Token *token, FRNode *node, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(node);
        XCTAssertNotNil(token);
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
}


- (void)test_03_Get_AccessTokenFromPreviousSSOToken {
    
    // Start SDK
    self.config.authServiceName = @"UsernamePassword";
    [self startSDK];
    XCTAssertNotNil([FRAuth shared]);
    
    // Set mock response
    [self loadMockResponses:@[@"OAuth2_AuthorizeRedirect_Success",
                              @"OAuth2_Token_Success"]];
    
    XCTestExpectation *ex = [self expectationWithDescription:@"First Node submit"];
    [[FRAuth shared] nextWithFlowType:FRAuthFlowTypeAuthentication accessTokenCompletion:^(AccessToken *token, FRNode *node, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(node);
        XCTAssertNotNil(token);
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
}


- (void)test_04_Get_AccessTokenWithoutPreviousSession {
    
    // Start SDK
    self.config.authServiceName = @"UsernamePassword";
    [self startSDK];
    XCTAssertNotNil([FRAuth shared]);
    
    // Should not clean up session for next test
    self.shouldCleanup = NO;
    
    // Set mock response
    [self loadMockResponses:@[@"AuthTree_UsernamePasswordNode",
                              @"AuthTree_SSOToken_Success",
                              @"OAuth2_AuthorizeRedirect_Success",
                              @"OAuth2_Token_Success"]];
    
    __block FRNode *currentNode = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"First Node submit"];
    [[FRAuth shared] nextWithFlowType:FRAuthFlowTypeAuthentication accessTokenCompletion:^(AccessToken *token, FRNode *node, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(token);
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
    [currentNode nextWithAccessTokenCompletion:^(AccessToken *token, FRNode *node, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(node);
        XCTAssertNotNil(token);
        currentNode = node;
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    XCTAssertNil(currentNode);
}


- (void)test_05_Get_AccessTokenFromPreviousAccessToken {
    
    // Start SDK
    self.config.authServiceName = @"UsernamePassword";
    [self startSDK];
    XCTAssertNotNil([FRAuth shared]);
    
    // Should not clean up session for next test
    self.shouldCleanup = NO;
    
    XCTestExpectation *ex = [self expectationWithDescription:@"First Node submit"];
    [[FRAuth shared] nextWithFlowType:FRAuthFlowTypeAuthentication accessTokenCompletion:^(AccessToken *token, FRNode *node, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(node);
        XCTAssertNotNil(token);
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
}


- (void)test_06_Get_FRUserFromPreviousAccessToken {
    
    // Start SDK
    self.config.authServiceName = @"UsernamePassword";
    [self startSDK];
    XCTAssertNotNil([FRAuth shared]);
    
    XCTestExpectation *ex = [self expectationWithDescription:@"First Node submit"];
    [[FRAuth shared] nextWithFlowType:FRAuthFlowTypeAuthentication userCompletion:^(FRUser *user, FRNode *node, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(node);
        XCTAssertNotNil(user);
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    XCTAssertNotNil([FRUser currentUser]);
}


- (void)test_07_Get_FRUserWithoutPreviousSession {
    
    // Start SDK
    self.config.authServiceName = @"UsernamePassword";
    [self startSDK];
    XCTAssertNotNil([FRAuth shared]);
    
    // Should not clean up session for next test
    self.shouldCleanup = NO;
    
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


- (void)test_08_Get_FRUserFromPreviousLogin {
    
    // Start SDK
    self.config.authServiceName = @"UsernamePassword";
    [self startSDK];
    XCTAssertNotNil([FRAuth shared]);
    
    XCTestExpectation *ex = [self expectationWithDescription:@"First Node submit"];
    [[FRAuth shared] nextWithFlowType:FRAuthFlowTypeAuthentication userCompletion:^(FRUser *user, FRNode *node, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(node);
        XCTAssertNotNil(user);
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    XCTAssertNotNil([FRUser currentUser]);
}

@end
