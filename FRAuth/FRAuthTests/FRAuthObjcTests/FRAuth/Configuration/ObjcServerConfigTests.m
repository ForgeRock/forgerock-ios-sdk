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
    self.realm = @"root";
    self.serverURL = @"http://localhost:8080/am";
    self.timeout = 90.0;
}


- (void)testBasicServerConfig {
    
    // Given
    FRServerConfig *config = [[FRServerConfig alloc] initWithUrl:[NSURL URLWithString:self.serverURL] realm:self.realm timeout:self.timeout enableCookie:YES];
    
    // Then
    XCTAssertNotNil(config);
    XCTAssertEqual(config.baseURL.absoluteString, self.serverURL);
    XCTAssertEqual(config.realm, self.realm);
    XCTAssertEqual(config.timeout, self.timeout);
    NSString *treeURL = [NSString stringWithFormat:@"%@/json/realms/%@/authenticate", self.serverURL, self.realm];
    XCTAssertTrue([config.treeURL isEqualToString:treeURL]);
    NSString *tokenURL = [NSString stringWithFormat:@"%@/oauth2/realms/%@/access_token", self.serverURL, self.realm];
    XCTAssertTrue([config.tokenURL isEqualToString:tokenURL]);
    NSString *authorizeURL = [NSString stringWithFormat:@"%@/oauth2/realms/%@/authorize", self.serverURL, self.realm];
    XCTAssertTrue([config.authorizeURL isEqualToString:authorizeURL]);
    NSString *userInfoURL = [NSString stringWithFormat:@"%@/oauth2/realms/%@/userinfo", self.serverURL, self.realm];
    XCTAssertTrue([config.userInfoURL isEqualToString:userInfoURL]);
    NSString *tokenRevokeURL = [NSString stringWithFormat:@"%@/oauth2/realms/%@/token/revoke", self.serverURL, self.realm];
    XCTAssertTrue([config.tokenRevokeURL isEqualToString:tokenRevokeURL]);
    NSString *ssoTokenLogoutURL = [NSString stringWithFormat:@"%@/json/realms/%@/sessions", self.serverURL, self.realm];
    XCTAssertTrue([config.ssoTokenLogoutURL isEqualToString:ssoTokenLogoutURL]);
}

@end
