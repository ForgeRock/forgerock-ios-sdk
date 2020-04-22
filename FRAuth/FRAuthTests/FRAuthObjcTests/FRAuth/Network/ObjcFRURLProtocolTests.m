//
//  ObjcFRURLProtocolTests.m
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

#import <XCTest/XCTest.h>
#import "FRBaseTestsObjc.h"

@interface ObjcFRURLProtocolTests : FRBaseTestsObjc

@end

@implementation ObjcFRURLProtocolTests

- (void)setUp {
    self.configFileName = @"Config";
    [super setUp];
    
    [NSURLProtocol registerClass:[FRURLProtocol class]];
}


- (void)test_01_Validate_AuthHeader_For_URLSessionRequest_With_FRURLPRotocol_WithoutUserSession {

    // If user session is not valid, clean it up before test
    [FRTestUtils cleanUpAfterTearDown];
    
    // SDK Init
    [self startSDK];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setProtocolClasses:@[[FRURLProtocol class]]];
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:config];
    
    // When
    XCTestExpectation *ex = [self expectationWithDescription:@"Making request"];
    [[urlSession dataTaskWithURL:[NSURL URLWithString:@"https://httpbin.org/anything"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        // Only validate specific case as request is being made to external API
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        
        if ([[json allKeys] containsObject:@"headers"]) {
            NSDictionary *headers = [json objectForKey:@"headers"];
            XCTAssertFalse([[headers allKeys] containsObject:@"Authorization"]);
        }
        [ex fulfill];
    }] resume];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    
    // Ignore cleanup to reuse session for further tests
    self.shouldCleanup = NO;
}


- (void)test_02_Validate_AuthHeader_For_URLSessionRequest_Without_FRURLProtocol {
    
    // Initial session check
    [self startSDK];
    if ([FRUser currentUser] == nil) {
        [FRTestUtils cleanUpAfterTearDown];
        [self performUserLogin];
    }
    
    // Given plain URLSession
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    // When
    XCTestExpectation *ex = [self expectationWithDescription:@"Making request"];
    [[urlSession dataTaskWithURL:[NSURL URLWithString:@"https://httpbin.org/anything"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        // Only validate specific case as request is being made to external API
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        
        if ([[json allKeys] containsObject:@"headers"]) {
            NSDictionary *headers = [json objectForKey:@"headers"];
            XCTAssertFalse([[headers allKeys] containsObject:@"Authorization"]);
        }
        [ex fulfill];
    }] resume];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    
    // Ignore cleanup to reuse session for further tests
    self.shouldCleanup = NO;
}


- (void)test_03_Validate_AuthHeader_For_URLSessionRequest_With_FRURLPRotocol {
    
    // Initial session check
    [self startSDK];
    if ([FRUser currentUser] == nil) {
        [FRTestUtils cleanUpAfterTearDown];
        [self performUserLogin];
    }
    
    // SDK Init
    [self startSDK];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setProtocolClasses:@[[FRURLProtocol class]]];
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:config];
    
    // Register whitelist URLs
    [FRURLProtocol setValidatedURLs:@[[NSURL URLWithString:@"https://httpbin.org/anything"]]];
    
    // When
    XCTestExpectation *ex = [self expectationWithDescription:@"Making request"];
    [[urlSession dataTaskWithURL:[NSURL URLWithString:@"https://httpbin.org/anything"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        // Only validate specific case as request is being made to external API
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        
        if ([[json allKeys] containsObject:@"headers"]) {
            NSDictionary *headers = [json objectForKey:@"headers"];
            XCTAssertTrue([[headers allKeys] containsObject:@"Authorization"]);
        }
        [ex fulfill];
    }] resume];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    
    // Ignore cleanup to reuse session for further tests
    self.shouldCleanup = NO;
}


- (void)test_04_Validate_AuthHeader_For_URLSessionRequest_With_FRURLPRotocol_NotInWhitelist {
    
    // Initial session check
    [self startSDK];
    if ([FRUser currentUser] == nil) {
        [FRTestUtils cleanUpAfterTearDown];
        [self performUserLogin];
    }
    
    // SDK Init
    [self startSDK];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setProtocolClasses:@[[FRURLProtocol class]]];
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:config];
    
    // Register whitelist URLs
    [FRURLProtocol setValidatedURLs:@[[NSURL URLWithString:@"https://httpbin.org/notcorrect"]]];
    
    // When
    XCTestExpectation *ex = [self expectationWithDescription:@"Making request"];
    [[urlSession dataTaskWithURL:[NSURL URLWithString:@"https://httpbin.org/anything"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        // Only validate specific case as request is being made to external API
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        
        if ([[json allKeys] containsObject:@"headers"]) {
            NSDictionary *headers = [json objectForKey:@"headers"];
            XCTAssertFalse([[headers allKeys] containsObject:@"Authorization"]);
        }
        [ex fulfill];
    }] resume];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    
    self.shouldCleanup = YES;
}


- (void)test_05_Validate_AuthHeader_For_URLSessionRequest_With_FRURLPRotocol_TokenRefresh_With_UnsatisfiedRefreshPolicy {
    
    // Initial session check
    [self startSDK];
    if ([FRUser currentUser] == nil) {
        [FRTestUtils cleanUpAfterTearDown];
        [self performUserLogin];
    }
    
    // Set mock response
    [self loadMockResponses:@[@"OAuth2_Token_Refresh_Success"]];
    
    // SDK Init
    [self startSDK];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setProtocolClasses:@[[FRURLProtocol class]]];
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:config];
    
    // Register whitelist URLs
    [FRURLProtocol setValidatedURLs:@[[NSURL URLWithString:@"https://httpbin.org/anything"]]];
    
    // Only satisfy refresh policy upon HTTP 401
    [FRURLProtocol setRefreshTokenPolicy:^BOOL(NSData *responseData, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        // Refresh token when 401 received
        if (httpResponse.statusCode == 401) {
            return YES;
        }
        else {
            return NO;
        }
    }];
    
    // Make sure to capture previous AccessToken
    NSString *originalAuthHeader = [[[FRUser currentUser] token] buildAuthorizationHeader];
    
    // When
    XCTestExpectation *ex = [self expectationWithDescription:@"Making request"];
    [[urlSession dataTaskWithURL:[NSURL URLWithString:@"https://httpbin.org/anything"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        // Only validate specific case as request is being made to external API
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        
        if ([[json allKeys] containsObject:@"headers"]) {
            NSDictionary *headers = [json objectForKey:@"headers"];
            XCTAssertTrue([[headers allKeys] containsObject:@"Authorization"]);
            XCTAssertTrue([originalAuthHeader isEqualToString:[headers objectForKey:@"Authorization"]]);
        }
        [ex fulfill];
    }] resume];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    
    // Ignore cleanup to reuse session for further tests
    self.shouldCleanup = NO;
}


- (void)test_06_Validate_AuthHeader_For_URLSessionRequest_With_FRURLPRotocol_TokenRefresh_With_SatisfiedRefreshPolicy {
    
    // Initial session check
    [self startSDK];
    if ([FRUser currentUser] == nil) {
        [FRTestUtils cleanUpAfterTearDown];
        [self performUserLogin];
    }
    
    // Set mock response
    [self loadMockResponses:@[@"OAuth2_Token_Refresh_Success"]];
    
    // SDK Init
    [self startSDK];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setProtocolClasses:@[[FRURLProtocol class]]];
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:config];
    
    // Register whitelist URLs
    [FRURLProtocol setValidatedURLs:@[[NSURL URLWithString:@"https://httpbin.org/anything"]]];
    
    // Should always satisfy refresh policy
    [FRURLProtocol setRefreshTokenPolicy:^BOOL(NSData *responseData, NSURLResponse *response, NSError *error) {
        return YES;
    }];
    
    // Make sure to capture previous AccessToken
    NSString *originalAuthHeader = [[[FRUser currentUser] token] buildAuthorizationHeader];
    
    // When
    XCTestExpectation *ex = [self expectationWithDescription:@"Making request"];
    [[urlSession dataTaskWithURL:[NSURL URLWithString:@"https://httpbin.org/anything"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        // Only validate specific case as request is being made to external API
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        
        if ([[json allKeys] containsObject:@"headers"]) {
            NSDictionary *headers = [json objectForKey:@"headers"];
            XCTAssertTrue([[headers allKeys] containsObject:@"Authorization"]);
            
            NSLog(@"user token: %@", [[[FRUser currentUser] token] buildAuthorizationHeader]);
            NSLog(@"response token: %@", [headers objectForKey:@"Authorization"]);
            XCTAssertFalse([originalAuthHeader isEqualToString:[headers objectForKey:@"Authorization"]]);
        }
        [ex fulfill];
    }] resume];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    
    // Should cleanup for further tests
    self.shouldCleanup = YES;
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

@end
