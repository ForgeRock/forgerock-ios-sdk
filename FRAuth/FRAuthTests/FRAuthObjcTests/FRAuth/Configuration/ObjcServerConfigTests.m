//
//  ObjcServerConfigTests.m
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

#import <XCTest/XCTest.h>
#import "FRBaseTestsObjc.h"

@interface ObjcServerConfigTests : FRBaseTestsObjc

@property (nonatomic, strong) NSString *realm;
@property (nonatomic, strong) NSString *serverURL;
@property (assign) double timeout;

@end

@implementation ObjcServerConfigTests

- (void)setUp {
    self.realm = @"customRealm";
    self.serverURL = @"http://localhost:8080/am";
    self.timeout = 90.0;
}


- (void)test_01_default_server_config {
    
    // Given
    FRServerConfig *config = [[[FRServerConfigBuilder alloc] initWithUrl:[NSURL URLWithString:self.serverURL] realm:self.realm] build];
    
    // Then
    XCTAssertNotNil(config);
    XCTAssertEqual(config.baseURL.absoluteString, self.serverURL);
    XCTAssertEqual(config.realm, self.realm);
    XCTAssertEqual(config.timeout, 60.0);
    XCTAssertEqual(config.enableCookie, YES);
    NSString *authenticateURL = [NSString stringWithFormat:@"%@/json/realms/%@/authenticate", self.serverURL, self.realm];
    XCTAssertTrue([config.authenticateURL isEqualToString:authenticateURL]);
    NSString *tokenURL = [NSString stringWithFormat:@"%@/oauth2/realms/%@/access_token", self.serverURL, self.realm];
    XCTAssertTrue([config.tokenURL isEqualToString:tokenURL]);
    NSString *authorizeURL = [NSString stringWithFormat:@"%@/oauth2/realms/%@/authorize", self.serverURL, self.realm];
    XCTAssertTrue([config.authorizeURL isEqualToString:authorizeURL]);
    NSString *userInfoURL = [NSString stringWithFormat:@"%@/oauth2/realms/%@/userinfo", self.serverURL, self.realm];
    XCTAssertTrue([config.userInfoURL isEqualToString:userInfoURL]);
    NSString *tokenRevokeURL = [NSString stringWithFormat:@"%@/oauth2/realms/%@/token/revoke", self.serverURL, self.realm];
    XCTAssertTrue([config.tokenRevokeURL isEqualToString:tokenRevokeURL]);
    NSString *sessionUrl = [NSString stringWithFormat:@"%@/json/realms/%@/sessions", self.serverURL, self.realm];
    XCTAssertTrue([config.sessionPath isEqualToString:sessionUrl]);
}


- (void)test_02_custom_timeout_server_config {
    // Given
    FRServerConfigBuilder *builder = [[FRServerConfigBuilder alloc] initWithUrl:[NSURL URLWithString:self.serverURL] realm:self.realm];
    FRServerConfig *config = [[builder setWithTimeout:self.timeout] build];
    // Then
    XCTAssertNotNil(config);
    XCTAssertEqual(config.timeout, self.timeout);
}


- (void)test_03_custom_enable_cookie_server_config {
    // Given
    FRServerConfigBuilder *builder = [[FRServerConfigBuilder alloc] initWithUrl:[NSURL URLWithString:self.serverURL] realm:self.realm];
    FRServerConfig *config = [[builder setWithEnableCookie:NO] build];
    // Then
    XCTAssertNotNil(config);
    XCTAssertEqual(config.enableCookie, NO);
}


- (void)test_04_custom_path_server_config {
    // Given
    FRServerConfigBuilder *builder = [[FRServerConfigBuilder alloc] initWithUrl:[NSURL URLWithString:self.serverURL] realm:self.realm];
    
    FRServerConfig *config;
    
    // authenticate path
    config = [[builder setWithAuthenticatePath:@"/custom/authenticate/path"] build];
    XCTAssertNotNil(config);
    NSString *authenticate = [NSString stringWithFormat:@"%@/custom/authenticate/path", self.serverURL];
    XCTAssertTrue([config.authenticateURL isEqualToString:authenticate]);
    
    // token path
    config = [[builder setWithTokenPath:@"/custom/token/path"] build];
    XCTAssertNotNil(config);
    NSString *token = [NSString stringWithFormat:@"%@/custom/token/path", self.serverURL];
    XCTAssertTrue([config.tokenURL isEqualToString:token]);
    
    // authorize path
    config = [[builder setWithAuthorizePath:@"/custom/authorize/path"] build];
    XCTAssertNotNil(config);
    NSString *authorize = [NSString stringWithFormat:@"%@/custom/authorize/path", self.serverURL];
    XCTAssertTrue([config.authorizeURL isEqualToString:authorize]);
    
    // userinfo path
    config = [[builder setWithUserInfoPath:@"/custom/userinfo/path"] build];
    XCTAssertNotNil(config);
    NSString *userinfo = [NSString stringWithFormat:@"%@/custom/userinfo/path", self.serverURL];
    XCTAssertTrue([config.userInfoURL isEqualToString:userinfo]);
    
    // token revoke path
    config = [[builder setWithRevokePath:@"/custom/token/revoke/path"] build];
    XCTAssertNotNil(config);
    NSString *revoke = [NSString stringWithFormat:@"%@/custom/token/revoke/path", self.serverURL];
    XCTAssertTrue([config.tokenRevokeURL isEqualToString:revoke]);
    
    // session path
    config = [[builder setWithSessionPath:@"/custom/session/path"] build];
    XCTAssertNotNil(config);
    NSString *session = [NSString stringWithFormat:@"%@/custom/session/path", self.serverURL];
    XCTAssertTrue([config.sessionPath isEqualToString:session]);
}


- (void)test_05_custom_nested_server_config {
    // Given
    FRServerConfigBuilder *builder = [[FRServerConfigBuilder alloc] initWithUrl:[NSURL URLWithString:self.serverURL] realm:self.realm];
    
    FRServerConfig *config = [[[[[builder setWithEnableCookie:NO] setWithTimeout:self.timeout] setWithAuthenticatePath:@"/custom/authenticate/path"] setWithSessionPath:@"/custom/session/path"] build];
    
    XCTAssertNotNil(config);
    XCTAssertEqual(config.baseURL.absoluteString, self.serverURL);
    XCTAssertEqual(config.realm, self.realm);
    XCTAssertEqual(config.timeout, self.timeout);
    XCTAssertEqual(config.enableCookie, NO);
    NSString *authenticateURL = [NSString stringWithFormat:@"%@/custom/authenticate/path", self.serverURL];
    XCTAssertTrue([config.authenticateURL isEqualToString:authenticateURL]);
    NSString *tokenURL = [NSString stringWithFormat:@"%@/oauth2/realms/%@/access_token", self.serverURL, self.realm];
    XCTAssertTrue([config.tokenURL isEqualToString:tokenURL]);
    NSString *authorizeURL = [NSString stringWithFormat:@"%@/oauth2/realms/%@/authorize", self.serverURL, self.realm];
    XCTAssertTrue([config.authorizeURL isEqualToString:authorizeURL]);
    NSString *userInfoURL = [NSString stringWithFormat:@"%@/oauth2/realms/%@/userinfo", self.serverURL, self.realm];
    XCTAssertTrue([config.userInfoURL isEqualToString:userInfoURL]);
    NSString *tokenRevokeURL = [NSString stringWithFormat:@"%@/oauth2/realms/%@/token/revoke", self.serverURL, self.realm];
    XCTAssertTrue([config.tokenRevokeURL isEqualToString:tokenRevokeURL]);
    NSString *sessionUrl = [NSString stringWithFormat:@"%@/custom/session/path", self.serverURL];
    XCTAssertTrue([config.sessionPath isEqualToString:sessionUrl]);
}

@end
