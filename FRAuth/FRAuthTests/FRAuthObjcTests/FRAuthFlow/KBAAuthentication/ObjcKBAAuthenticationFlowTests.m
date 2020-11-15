//
//  ObjcKBAAuthenticationFlowTests.m
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

#import <XCTest/XCTest.h>
#import "FRBaseTestsObjc.h"

@interface ObjcKBAAuthenticationFlowTests : FRBaseTestsObjc

@end

@implementation ObjcKBAAuthenticationFlowTests

- (void)setUp {
    self.configFileName = @"Config";
//    self.shouldLoadMockResponses = false;
    [super setUp];
}

- (void)testKBAAuthenticationFlow {
    // Start SDK
    self.config.authServiceName = @"KBAAuthentication";
    [self startSDK];
    
    // Set mock responses
    [self loadMockResponses:@[@"AuthTree_PlatformUsernamePasswordNode",
                              @"AuthTree_KBAVerificationNode",
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
        if ([callback isKindOfClass:[FRValidatedCreateUsernameCallback class]]) {
            FRValidatedCreateUsernameCallback *thisCallback = (FRValidatedCreateUsernameCallback *)callback;
            [thisCallback setInputValue:self.config.username];
        }
        else if ([callback isKindOfClass:[FRValidatedCreatePasswordCallback class]]) {
            FRValidatedCreatePasswordCallback *thisCallback = (FRValidatedCreatePasswordCallback *)callback;
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
        if ([callback isKindOfClass:[FRPasswordCallback class]]) {
            FRPasswordCallback *thisCallback = (FRPasswordCallback *)callback;
            NSString *kbaAnswer = self.config.kba[thisCallback.prompt];
            if (kbaAnswer != nil && [kbaAnswer length] > 0)
            {
                [thisCallback setInputValue:kbaAnswer];
            }
            else {
                XCTFail(@"KBA Answer was not identified %@", [thisCallback debugDescription]);
            }
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
