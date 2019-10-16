//
//  FRBaseTestsObjc.h
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

#import <XCTest/XCTest.h>
#import "FRAuthTests-Swift.h"

@interface FRBaseTestsObjc : XCTestCase

@property (nonatomic, strong) FRTestConfig *config;
@property (nonatomic, strong) NSString *configFileName;
@property (assign) BOOL shouldLoadMockResponses;
@property (assign) BOOL shouldCleanup;

- (void)startSDK;
- (NSDictionary *)parseStringToDictionaryWithString:(NSString *)str;
- (void)loadMockResponses:(NSArray<NSString *> *)responseFileNames;
- (NSDictionary *)readDataFromJSON:(NSString *)fileName;
- (BOOL)waitForExpectiontion;

@end
