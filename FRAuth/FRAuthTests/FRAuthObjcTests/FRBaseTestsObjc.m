//
//  FRBaseTestsObjc.m
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

#import "FRBaseTestsObjc.h"

@implementation FRBaseTestsObjc

- (void)setUp {
    self.shouldLoadMockResponses = YES;
    self.shouldCleanup = YES;
    self.continueAfterFailure = NO;
    self.config = [[FRTestConfig alloc] init];
    
    if (self.configFileName != nil && [self.configFileName length] > 0) {
        NSError *configError = nil;
        self.config = [[FRTestConfig alloc] init:self.configFileName error:&configError];
        
        if (configError != nil) {
            XCTFail(@"Configuration load failure: %@", self.configFileName);
        }
    }
    
    if (self.shouldLoadMockResponses) {
        [NSURLProtocol registerClass:[FRTestNetworkStubProtocol class]];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.protocolClasses = @[[FRTestNetworkStubProtocol class]];
        
        [FRRestClient setURLSessionConfigurationWithConfig:config];
    }
}


- (void)tearDown {
    
    if (self.shouldCleanup) {
        [FRTestUtils cleanUpAfterTearDown];
        [FRAuthBaseTest cleanUp];
    }
}


- (void)startSDK {
    [FRAuthBaseTest startSDK:self.config];
}


- (NSDictionary *)parseStringToDictionaryWithString:(NSString *)str {
    return [FRTestUtils parseStringToDictionary:str];
}


- (void)loadMockResponses:(NSArray<NSString *> *)responseFileNames {
    [FRTestUtils loadMockResponses:responseFileNames];
}


- (NSDictionary *)readDataFromJSON:(NSString *)fileName {
    return [FRTestUtils readDataFromJSON:fileName];
}


- (BOOL)waitForExpectiontion
{
    __block BOOL result = YES;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self waitForExpectationsWithTimeout:60.0 handler:^(NSError * _Nullable error) {
        
        if (error)
        {
            result = NO;
            NSLog(@"Expectation failed with an error: %@", [error debugDescription]);
        }
        
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return result;
}


- (void)performUsernamePasswordLogin {
    
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
