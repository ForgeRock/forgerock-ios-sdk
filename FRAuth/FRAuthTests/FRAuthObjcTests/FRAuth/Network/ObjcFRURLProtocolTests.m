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

@interface ObjcFRURLProtocolTests : FRBaseTestsObjc <FRTokenManagementPolicyDelegate>

@property (assign) BOOL shouldUpdateRequest;
@property (assign) BOOL evaluateTokenRefresh;
@property (assign) int evaluateTokenRefreshCount;

@end


@implementation ObjcFRURLProtocolTests

- (void)setUp {
    self.configFileName = @"Config";
    [super setUp];
    [NSURLProtocol registerClass:[FRURLProtocol class]];
    
    self.shouldUpdateRequest = NO;
    self.evaluateTokenRefresh = NO;
    self.evaluateTokenRefreshCount = 0;
}

- (void)test_01_validate_auth_header_for_not_configured_frurlprotocol {

    //  Given URLSession with FRURLProtocol
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setProtocolClasses:@[[FRURLProtocol class]]];
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:config];

    //  Invalidate all configuration for FRURLProtocol
    FRURLProtocol.authorizationPolicy = nil;
    FRURLProtocol.tokenManagementPolicy = nil;
    
    //  Perform login
    [self performUsernamePasswordLogin];
    
    // When
    XCTestExpectation *ex = [self expectationWithDescription:@"Making request"];
    [[urlSession dataTaskWithURL:[NSURL URLWithString:@"https://httpbin.org/anything"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

        // Only validate specific case as request is being made to external API
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];

        NSDictionary *headers = [json objectForKey:@"headers"];
        XCTAssertFalse([[headers allKeys] containsObject:@"Authorization"]);
        [ex fulfill];
    }] resume];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    
    // Ignore cleanup to reuse session for further tests
    self.shouldCleanup = NO;
}


- (void)test_02_validate_auth_header_for_non_validating_url {
    
    //  Init SDK
    [self startSDK];
    
    if ([FRUser currentUser] == nil || [[FRUser currentUser] token] == nil) {
        XCTFail("Failed to retreive previous authenticated session");
    }
    
    //  Given URLSession with FRURLProtocol
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setProtocolClasses:@[[FRURLProtocol class]]];
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:config];


    //  Set TokenManagementPolicy, but with different URL for validation
    FRTokenManagementPolicy *tokenManagementPolicy = [[FRTokenManagementPolicy alloc] initWithValidatingURL:@[[NSURL URLWithString:@"https://httpbin.org/any"]] delegate:nil];
    FRURLProtocol.tokenManagementPolicy = tokenManagementPolicy;
    FRURLProtocol.authorizationPolicy = nil;
    
        // When
    XCTestExpectation *ex = [self expectationWithDescription:@"Making request"];
    [[urlSession dataTaskWithURL:[NSURL URLWithString:@"https://httpbin.org/anything"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

        // Only validate specific case as request is being made to external API
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];

        NSDictionary *headers = [json objectForKey:@"headers"];
        XCTAssertFalse([[headers allKeys] containsObject:@"Authorization"]);
        [ex fulfill];
    }] resume];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    
    // Ignore cleanup to reuse session for further tests
    self.shouldCleanup = NO;
}


- (void)test_03_validate_auth_header_with_validating_url {
    
    //  Init SDK
    [self startSDK];
    
    if ([FRUser currentUser] == nil || [[FRUser currentUser] token] == nil) {
        XCTFail("Failed to retreive previous authenticated session");
    }
    
    //  Given URLSession with FRURLProtocol
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setProtocolClasses:@[[FRURLProtocol class]]];
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:config];


    //  Set TokenManagementPolicy, but with different URL for validation
    FRTokenManagementPolicy *tokenManagementPolicy = [[FRTokenManagementPolicy alloc] initWithValidatingURL:@[[NSURL URLWithString:@"https://httpbin.org/anything"]] delegate:nil];
    FRURLProtocol.tokenManagementPolicy = tokenManagementPolicy;
    FRURLProtocol.authorizationPolicy = nil;
    
        // When
    XCTestExpectation *ex = [self expectationWithDescription:@"Making request"];
    [[urlSession dataTaskWithURL:[NSURL URLWithString:@"https://httpbin.org/anything"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

        // Only validate specific case as request is being made to external API
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];

        NSDictionary *headers = [json objectForKey:@"headers"];
        XCTAssertTrue([[headers allKeys] containsObject:@"Authorization"]);
        XCTAssertTrue([[[[FRUser currentUser] token] buildAuthorizationHeader] isEqualToString:[headers objectForKey:@"Authorization"]]);
        [ex fulfill];
    }] resume];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    
    // Ignore cleanup to reuse session for further tests
    self.shouldCleanup = NO;
}


- (void)test_04_validate_auth_header_with_validating_url_in_custom_header {
    
    //  Init SDK
    [self startSDK];
    
    if ([FRUser currentUser] == nil || [[FRUser currentUser] token] == nil) {
        XCTFail("Failed to retreive previous authenticated session");
    }
    
    //  Given URLSession with FRURLProtocol
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setProtocolClasses:@[[FRURLProtocol class]]];
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:config];


    //  Set TokenManagementPolicy, but with different URL for validation
    FRTokenManagementPolicy *tokenManagementPolicy = [[FRTokenManagementPolicy alloc] initWithValidatingURL:@[[NSURL URLWithString:@"https://httpbin.org/anything"]] delegate:self];
    FRURLProtocol.tokenManagementPolicy = tokenManagementPolicy;
    FRURLProtocol.authorizationPolicy = nil;
    
        // When
    XCTestExpectation *ex = [self expectationWithDescription:@"Making request"];
    [[urlSession dataTaskWithURL:[NSURL URLWithString:@"https://httpbin.org/anything"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

        // Only validate specific case as request is being made to external API
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];

        NSDictionary *headers = [json objectForKey:@"headers"];
        XCTAssertTrue([[headers allKeys] containsObject:@"Auth"]);
        XCTAssertTrue([[[[FRUser currentUser] token] buildAuthorizationHeader] isEqualToString:[headers objectForKey:@"Auth"]]);
        [ex fulfill];
    }] resume];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    
    // Ignore cleanup to reuse session for further tests
    self.shouldCleanup = NO;
}


- (void)test_05_validate_token_refresh_evaluation_and_token_renewal {
    
    //  Init SDK
    [self startSDK];
    
    //  Mock update token response
    [self loadMockResponses:@[@"OAuth2_Token_Refresh_Success"]];
    
    if ([FRUser currentUser] == nil || [[FRUser currentUser] token] == nil) {
        XCTFail("Failed to retreive previous authenticated session");
    }
    AccessToken *token = [[FRUser currentUser] token];
    //  Given URLSession with FRURLProtocol
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setProtocolClasses:@[[FRURLProtocol class]]];
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:config];


    //  Set TokenManagementPolicy, but with different URL for validation
    self.evaluateTokenRefresh = YES;
    FRTokenManagementPolicy *tokenManagementPolicy = [[FRTokenManagementPolicy alloc] initWithValidatingURL:@[[NSURL URLWithString:@"https://httpbin.org/anything"]] delegate:self];
    FRURLProtocol.tokenManagementPolicy = tokenManagementPolicy;
    FRURLProtocol.authorizationPolicy = nil;
    
        // When
    XCTestExpectation *ex = [self expectationWithDescription:@"Making request"];
    [[urlSession dataTaskWithURL:[NSURL URLWithString:@"https://httpbin.org/anything"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

        // Only validate specific case as request is being made to external API
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];

        NSDictionary *headers = [json objectForKey:@"headers"];
        XCTAssertTrue([[headers allKeys] containsObject:@"Auth"]);
        XCTAssertTrue([[[[FRUser currentUser] token] buildAuthorizationHeader] isEqualToString:[headers objectForKey:@"Auth"]]);
        XCTAssertFalse([[token buildAuthorizationHeader] isEqualToString:[headers objectForKey:@"Auth"]]);
        [ex fulfill];
    }] resume];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    
    // Ignore cleanup to reuse session for further tests
    self.shouldCleanup = NO;
}


- (void)test_06_validate_token_refresh_evaluation_keep_failing_and_test_max_retry_count {
    
    //  Init SDK
    [self startSDK];

    //  Mock update token response
    [self loadMockResponses:@[@"OAuth2_Token_Refresh_Success"]];

    if ([FRUser currentUser] == nil || [[FRUser currentUser] token] == nil) {
        XCTFail("Failed to retreive previous authenticated session");
    }
    //  Given URLSession with FRURLProtocol
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setProtocolClasses:@[[FRURLProtocol class]]];
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:config];


    //  Set TokenManagementPolicy, but with different URL for validation
    FRTokenManagementPolicy *tokenManagementPolicy = [[FRTokenManagementPolicy alloc] initWithValidatingURL:@[[NSURL URLWithString:@"https://httpbin.org/status/401"]] delegate:self];
    FRURLProtocol.tokenManagementPolicy = tokenManagementPolicy;
    FRURLProtocol.authorizationPolicy = nil;
    
        // When
    XCTestExpectation *ex = [self expectationWithDescription:@"Making request"];
    [[urlSession dataTaskWithURL:[NSURL URLWithString:@"https://httpbin.org/status/401"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        XCTAssertEqual(httpResponse.statusCode, 401);
        [ex fulfill];
    }] resume];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);

    //  While API keeps returning 401; TokenManagementPolicyDelegate.evaluateTokenRefresh must only be invoked twice due to maximum retry count
    XCTAssertEqual(self.evaluateTokenRefreshCount, 2);
}


# pragma mark - FRTokenManagementPolicyDelegate

- (BOOL)evaluateTokenRefreshWithResponseData:(NSData *)responseData response:(NSURLResponse *)response error:(NSError *)error {
    self.evaluateTokenRefreshCount++;
    
    if (self.evaluateTokenRefresh) {
        self.evaluateTokenRefresh = NO;
        return YES;
    }
    else {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 401) {
            return YES;
        }
        else {
            return NO;
        }
    }
}

- (NSURLRequest *)updateRequestWithOriginalRequest:(NSURLRequest *)originalRequest token:(AccessToken *)token {
    NSMutableURLRequest *mutableRequest = [originalRequest mutableCopy];
    [mutableRequest setValue:[token buildAuthorizationHeader] forHTTPHeaderField:@"Auth"];
    return (NSURLRequest *)mutableRequest;
}

@end
