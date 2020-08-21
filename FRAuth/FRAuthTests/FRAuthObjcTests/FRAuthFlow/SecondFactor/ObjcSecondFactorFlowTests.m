//
//  ObjcSecondFactorFlowTests.m
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

#import <XCTest/XCTest.h>
#import "FRBaseTestsObjc.h"

@interface ObjcSecondFactorFlowTests : FRBaseTestsObjc

@end

@implementation ObjcSecondFactorFlowTests

- (void)setUp {
    self.configFileName = @"Config";
    [super setUp];
}

- (void)testSecondFactorFlow {
    // Start SDK
    self.config.authServiceName = @"SecondFactor";
    [self startSDK];
    
    // Set mock responses
    [self loadMockResponses:@[@"AuthTree_UsernamePasswordNode",
                              @"AuthTree_SecondFactorChoiceNode",
                              @"AuthTree_SecondFactorOTPNode",
                              @"AuthTree_SSOToken_Success",
                              @"OAuth2_AuthorizeRedirect_Success",
                              @"OAuth2_Token_Success"]];

    __block FRNode *currentNode = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"First Node submit"];
    [FRUser loginWithCompletion:^(FRUser *user, FRNode *node, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(user);
        XCTAssertNotNil(node);
        currentNode = node;
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    XCTAssertNotNil(currentNode);
    
    // Provide input value for callbacks
    for (FRCallback *callback in [currentNode callbacks]) {
        if ([callback isKindOfClass:[FRNameCallback class]]) {
            FRNameCallback *thisCallback = (FRNameCallback *)callback;
            [thisCallback setInputValue:self.config.username];
        }
        else if ([callback isKindOfClass:[FRPasswordCallback class]]) {
            FRPasswordCallback *thisCallback = (FRPasswordCallback *)callback;
            [thisCallback setInputValue:self.config.password];
        }
        else {
            XCTFail("Received unexpected callback %@", callback);
        }
    }
    
    ex = [self expectationWithDescription:@"Second Node submit"];
    [currentNode nextWithUserCompletion:^(FRUser *user, FRNode *node, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(user);
        XCTAssertNotNil(node);
        currentNode = node;
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    XCTAssertNotNil(currentNode);
    
    // Provide input value for callbacks
    for (FRCallback *callback in [currentNode callbacks]) {
        if ([callback isKindOfClass:[FRChoiceCallback class]]) {
            FRChoiceCallback *thisCallback = (FRChoiceCallback *)callback;
            [thisCallback setInputValue:[NSNumber numberWithInteger: thisCallback.defaultChoice]];
        }
        else {
            XCTFail("Received unexpected callback %@", callback);
        }
    }
    
    if (!self.shouldLoadMockResponses) {
        // Stop testing for SecondFactor as this is testing against actual server, and requires valid OTP credentials
        return;
    }
    
    ex = [self expectationWithDescription:@"Third Node submit: OTP Credentials Node"];
    [currentNode nextWithUserCompletion:^(FRUser *user, FRNode *node, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(user);
        XCTAssertNotNil(node);
        currentNode = node;
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    XCTAssertNotNil(currentNode);
    
    // Provide input value for callbacks
    for (FRCallback *callback in [currentNode callbacks]) {
        if ([callback isKindOfClass:[FRPasswordCallback class]]) {
            FRPasswordCallback *thisCallback = (FRPasswordCallback *)callback;
            [thisCallback setInputValue:@"OTP Dummy Credentials"];
        }
        else {
            XCTFail("Received unexpected callback %@", callback);
        }
    }
    
    ex = [self expectationWithDescription:@"Fourth Node submit: After OTP Credentials submit; OAuth2 Token is expected to be returned for this flow"];
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
