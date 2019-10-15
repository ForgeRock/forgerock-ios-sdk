//
//  ObjcFRDeviceCollectorTests.m
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

#import <XCTest/XCTest.h>
#import "FRBaseTestsObjc.h"

@interface ObjcFRDeviceCollectorTests : FRBaseTestsObjc

@end

@implementation ObjcFRDeviceCollectorTests

- (void)setUp {
    self.configFileName = @"Config";
    [super setUp];
}


- (void)testExample {
    // Givne
    [self startSDK];
    // Should return FRDevice
    XCTAssertNotNil([FRDevice currentDevice]);
    XCTAssertNotNil([FRDeviceCollector shared]);
    
    // Collect Device Information
    __block NSDictionary *deviceInfo = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"FRUser.login"];
    [[FRDeviceCollector shared] collectWithCompletion:^(NSDictionary<NSString *,id> *result) {
        deviceInfo = result;
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    XCTAssertNotNil(deviceInfo);
    
    // Device Identifier, and Version
    XCTAssertNotNil([deviceInfo objectForKey:@"identifier"]);
    XCTAssertTrue([[deviceInfo objectForKey:@"identifier"] isKindOfClass:[NSString class]]);
    XCTAssertNotNil([deviceInfo objectForKey:@"version"]);
    XCTAssertTrue([[deviceInfo objectForKey:@"version"] isKindOfClass:[NSString class]]);
    
    // Platform information
    NSDictionary *platform = [deviceInfo objectForKey:@"platform"];
    XCTAssertNotNil(platform);
    
    XCTAssertNotNil([platform objectForKey:@"version"]);
    XCTAssertTrue([[platform objectForKey:@"version"] isKindOfClass:[NSString class]]);
    XCTAssertNotNil([platform objectForKey:@"platform"]);
    XCTAssertTrue([[platform objectForKey:@"platform"] isKindOfClass:[NSString class]]);
    XCTAssertNotNil([platform objectForKey:@"device"]);
    XCTAssertTrue([[platform objectForKey:@"device"] isKindOfClass:[NSString class]]);
    XCTAssertNotNil([platform objectForKey:@"deviceName"]);
    XCTAssertTrue([[platform objectForKey:@"deviceName"] isKindOfClass:[NSString class]]);
    XCTAssertNotNil([platform objectForKey:@"locale"]);
    XCTAssertTrue([[platform objectForKey:@"locale"] isKindOfClass:[NSString class]]);
    XCTAssertNotNil([platform objectForKey:@"timezone"]);
    XCTAssertTrue([[platform objectForKey:@"timezone"] isKindOfClass:[NSString class]]);
    XCTAssertNotNil([platform objectForKey:@"model"]);
    XCTAssertTrue([[platform objectForKey:@"model"] isKindOfClass:[NSString class]]);
    XCTAssertNotNil([platform objectForKey:@"brand"]);
    XCTAssertTrue([[platform objectForKey:@"brand"] isKindOfClass:[NSString class]]);
    XCTAssertNotNil([platform objectForKey:@"jailbreakScore"]);
    XCTAssertTrue([[platform objectForKey:@"jailbreakScore"] isKindOfClass:[NSNumber class]]);
    
    // Hardware information
    NSDictionary *hardware = [deviceInfo objectForKey:@"hardware"];
    XCTAssertNotNil(hardware);
    
    XCTAssertNotNil([hardware objectForKey:@"cpu"]);
    XCTAssertTrue([[hardware objectForKey:@"cpu"] isKindOfClass:[NSNumber class]]);
    XCTAssertNotNil([hardware objectForKey:@"memory"]);
    XCTAssertTrue([[hardware objectForKey:@"memory"] isKindOfClass:[NSNumber class]]);
    XCTAssertNotNil([hardware objectForKey:@"storage"]);
    XCTAssertTrue([[hardware objectForKey:@"storage"] isKindOfClass:[NSNumber class]]);
    XCTAssertNotNil([hardware objectForKey:@"manufacturer"]);
    XCTAssertTrue([[hardware objectForKey:@"manufacturer"] isKindOfClass:[NSString class]]);
    
    // Display information
    NSDictionary *display = [hardware objectForKey:@"display"];
    XCTAssertNotNil(display);
    
    XCTAssertNotNil([display objectForKey:@"orientation"]);
    XCTAssertTrue([[display objectForKey:@"orientation"] isKindOfClass:[NSNumber class]]);
    XCTAssertNotNil([display objectForKey:@"height"]);
    XCTAssertTrue([[display objectForKey:@"height"] isKindOfClass:[NSNumber class]]);
    XCTAssertNotNil([display objectForKey:@"width"]);
    XCTAssertTrue([[display objectForKey:@"width"] isKindOfClass:[NSNumber class]]);
    
    // Camera information
    NSDictionary *camera = [hardware objectForKey:@"camera"];
    XCTAssertNotNil(camera);
    XCTAssertNotNil([camera objectForKey:@"numberOfCameras"]);
    XCTAssertTrue([[camera objectForKey:@"numberOfCameras"] isKindOfClass:[NSNumber class]]);
    
//    // Bluetooth information
//    NSDictionary *bluetooth = [deviceInfo objectForKey:@"bluetooth"];
//    XCTAssertNotNil(bluetooth);
//
//    XCTAssertNotNil([bluetooth objectForKey:@"supported"]);
//    XCTAssertTrue([[bluetooth objectForKey:@"supported"] isKindOfClass:[NSNumber class]]);
    
    // Network information
    NSDictionary *network = [deviceInfo objectForKey:@"network"];
    XCTAssertNotNil(network);
    
    XCTAssertNotNil([network objectForKey:@"connected"]);
    XCTAssertTrue([[network objectForKey:@"connected"] isKindOfClass:[NSNumber class]]);
    
    // Browser information
    NSDictionary *browser = [deviceInfo objectForKey:@"browser"];
    XCTAssertNotNil(browser);
    
    XCTAssertNotNil([browser objectForKey:@"agent"]);
    XCTAssertTrue([[browser objectForKey:@"agent"] isKindOfClass:[NSString class]]);

    // Telephony information
    NSDictionary *telephony = [deviceInfo objectForKey:@"telephony"];
    XCTAssertNotNil(telephony);
    
    XCTAssertNotNil([telephony objectForKey:@"carrierName"]);
    XCTAssertTrue([[telephony objectForKey:@"carrierName"] isKindOfClass:[NSString class]]);
    XCTAssertNotNil([telephony objectForKey:@"networkCountryIso"]);
    XCTAssertTrue([[telephony objectForKey:@"networkCountryIso"] isKindOfClass:[NSString class]]);
    
    
//    // Location information
//    NSDictionary *location = [deviceInfo objectForKey:@"location"];
//    XCTAssertNotNil(location);
//    
//    XCTAssertNotNil([location objectForKey:@"longitude"]);
//    XCTAssertTrue([[location objectForKey:@"longitude"] isKindOfClass:[NSNumber class]]);
//    XCTAssertNotNil([location objectForKey:@"latitude"]);
//    XCTAssertTrue([[location objectForKey:@"latitude"] isKindOfClass:[NSNumber class]]);
}

@end
