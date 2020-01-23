//
//  ObjcUserSignUpFlowTests.m
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

#import <XCTest/XCTest.h>
#import "FRBaseTestsObjc.h"

@interface ObjcUserSignUpFlowTests : FRBaseTestsObjc

@end

@implementation ObjcUserSignUpFlowTests

- (void)setUp {
    self.configFileName = @"Config";
    [super setUp];
}


- (void)testUserSignUpFlow {
    // Start SDK
    self.config.registrationServiceName = @"UserSignUp";
    [self startSDK];
    
    // Set mock responses
    [self loadMockResponses:@[@"AuthTree_PlatformUsernamePasswordNode",
                              @"AuthTree_AttributeCollectorsNode",
                              @"AuthTree_KBACreateNode",
                              @"AuthTree_TermsAndConditionsNode",
                              @"AuthTree_SSOToken_Success",
                              @"OAuth2_AuthorizeRedirect_Success",
                              @"OAuth2_Token_Success"]];
    
    // Define user registration username with timestamp to avoid conflict
    NSString *username = [NSString stringWithFormat:@"%@%f", self.config.username, [[NSDate date] timeIntervalSince1970]];
    
    __block FRNode *currentNode = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"First Node submit: Platform Username/Password creation"];
    [FRUser registerWithCompletion:^(FRUser *user, FRNode *node, NSError *error) {
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
            thisCallback.value = username;
        }
        else if ([callback isKindOfClass:[FRValidatedCreatePasswordCallback class]]) {
            FRValidatedCreatePasswordCallback *thisCallback = (FRValidatedCreatePasswordCallback *)callback;
            thisCallback.value = self.config.password;
        }
        else {
            XCTFail("Received unexpected callback %@", callback);
        }
    }
    
    ex = [self expectationWithDescription:@"Second Node submit: Attribute Collection"];
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
        if ([callback isKindOfClass:[FRStringAttributeInputCallback class]]) {
            FRStringAttributeInputCallback *thisCallback = (FRStringAttributeInputCallback *)callback;
            
            if ([thisCallback.name isEqualToString:@"sn"])
            {
                thisCallback.value = self.config.userLastName;
            }
            else if ([thisCallback.name isEqualToString:@"givenName"])
            {
                thisCallback.value = self.config.userFirstName;
            }
            else if ([thisCallback.name isEqualToString:@"mail"])
            {
                thisCallback.value = self.config.userEmail;
            }
            else {
                XCTFail("Received unexpected callback %@", [thisCallback debugDescription]);
            }
        }
        else {
            XCTFail("Received unexpected callback %@", callback);
        }
    }
    
    ex = [self expectationWithDescription:@"Third Node submit: KBA Create Node"];
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
    int counter = 0;
    for (FRCallback *callback in [currentNode callbacks]) {
        if ([callback isKindOfClass:[FRKbaCreateCallback class]]) {
            FRKbaCreateCallback *thisCallback = (FRKbaCreateCallback *)callback;
            [thisCallback setAnswer:[NSString stringWithFormat:@"Answer %d", counter]];
            [thisCallback setQuestion:[[thisCallback predefinedQuestions] objectAtIndex:counter]];

        }
        else {
            XCTFail("Received unexpected callback %@", callback);
        }
        counter++;
    }
    
    ex = [self expectationWithDescription:@"Third Node submit: Terms & Conditions"];
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
        if ([callback isKindOfClass:[FRTermsAndConditionsCallback class]]) {
            FRTermsAndConditionsCallback *thisCallback = (FRTermsAndConditionsCallback *)callback;
            thisCallback.value = [NSNumber numberWithBool:YES];
        }
        else {
            XCTFail("Received unexpected callback %@", callback);
        }
    }
    
    ex = [self expectationWithDescription:@"Fourth Node submit: FRUser, SSO Token and OAuth2 Tokens"];
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
