//
//  ObjcCustomCallbackTests.m
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

#import <XCTest/XCTest.h>
#import "FRBaseTestsObjc.h"

@interface ObjcCustomCallbackTests : FRBaseTestsObjc

@property (strong, nonatomic) NSDictionary* originalSupportedCallbacks;
@end

@implementation ObjcCustomCallbackTests

- (void)setUp {
    self.configFileName = @"Config";
    [super setUp];
    self.originalSupportedCallbacks = [FRCallbackFactory shared].supportedCallbacks;
}

- (void)tearDown {
    [super tearDown];
    NSLog(@"%@", self.originalSupportedCallbacks);
    [[FRCallbackFactory shared] setSupportedCallbacks:self.originalSupportedCallbacks];
}

- (void)test_01_Validate_CustomCallback_Registration {
    
    // Given
    [[FRCallbackFactory shared] registerCallbackWithCallbackType:@"CustomCallback" callbackClass:[CustomCallback class]];
    
    // Then
    XCTAssertTrue([[[FRCallbackFactory shared].supportedCallbacks allKeys] containsObject:@"CustomCallback"]);
    XCTAssertTrue(([[FRCallbackFactory shared].supportedCallbacks objectForKey:@"CustomCallback"] == [CustomCallback class]));
}


- (void)test_02_Validate_CustomCallback_Building_Response {
    
    // Given
    NSString *jsonStr = @"\
    {\
        \"type\": \"CustomCallback\",\
        \"output\": [{\
            \"name\": \"prompt\",\
            \"value\": \"Custom Input\"\
        },\
                   {\
                       \"name\": \"customAttribute\",\
                       \"value\": \"CustomAttributeValue\"\
                   }],\
        \"input\": [{\
            \"name\": \"IDToken1\", \"value\": \"\"\
        }],\
        \"_id\": 1\
    }";
    
    // When
    NSDictionary *json = [self parseStringToDictionaryWithString:jsonStr];
    NSError *callbackError = nil;
    CustomCallback *callback = [[CustomCallback alloc] initWithJson:json error:&callbackError];
    
    // Then
    XCTAssertNil(callbackError);
    XCTAssertTrue([callback.type isEqualToString:@"CustomCallback"]);
    XCTAssertTrue([callback.prompt isEqualToString:@"Custom Input"]);
    XCTAssertTrue([callback.customAttribute isEqualToString:@"CustomAttributeValue"]);
    XCTAssertTrue([callback.inputName isEqualToString:@"IDToken1"]);
    
    NSDictionary *callbackPayload = [callback buildResponse];
    NSDictionary *custom = callbackPayload[@"custom"];
    NSDictionary *outputs = callbackPayload[@"output"];
    
    XCTAssertNotNil(outputs);
    XCTAssertNotNil(custom);
    
    NSString *customCallbackCustomSection = custom[@"CustomCallbackInput"];
    XCTAssertNotNil(customCallbackCustomSection);
    XCTAssertTrue([customCallbackCustomSection isEqualToString:@"CustomCallbackValue"]);
    
    BOOL customOutputValidated = NO;
    for (NSDictionary *output in outputs) {
        if ([output[@"name"] isEqualToString:@"customAttribute"] && [output[@"value"] isEqualToString:@"CustomAttributeValue"]) {
            customOutputValidated = YES;
        }
    }
    
    XCTAssertTrue(customOutputValidated);
}


- (void)test_03_Validate_Unsupported_Callback {
    
    if (!self.shouldLoadMockResponses) {
        // Ignoring test if test is against actual server, and not against mock response
        return;
    }
    
    if (self.config.serverConfig == nil) {
        XCTFail(@"Failed to load ServerConfig from test configuration");
        return;
    }
    
    // Set mock response
    [self loadMockResponses:@[@"AuthTree_UsernamePasswordNodeWithCustomCallback"]];
    
    // Given
    
    FRAuthService *authService = [[FRAuthService alloc] initWithName:@"CustomCallbackService" serverConfig:self.config.serverConfig];
    
    // When
    XCTestExpectation *ex = [self expectationWithDescription:@"Node Submit"];
    [authService nextWithTokenCompletion:^(Token *token, FRNode *node, NSError *error) {
        
        // Then
        
        // Validate response
        XCTAssertNil(token);
        XCTAssertNil(node);
        XCTAssertNotNil(error);
        
        XCTAssertTrue([error.domain isEqualToString:@"com.forgerock.ios.frauth.authentication"]);
        XCTAssertTrue(error.code == 1000008);
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
}


- (void)test_04_Validate_Node_With_CustomCallback {
    
    if (!self.shouldLoadMockResponses) {
        // Ignoring test if test is against actual server, and not against mock response
        return;
    }
    
    if (self.config.serverConfig == nil) {
        XCTFail(@"Failed to load ServerConfig from test configuration");
        return;
    }
    
    // Set mock response
    [self loadMockResponses:@[@"AuthTree_UsernamePasswordNodeWithCustomCallback"]];
    
    // Given
    NSString *customCallbackValue = @"Custom Value";
    NSString *customAttributeInputValue = @"Custom Attribute Test";
    FRAuthService *authService = [[FRAuthService alloc] initWithName:@"CustomCallbackService" serverConfig:self.config.serverConfig];
    
    // Register
    [[FRCallbackFactory shared] registerCallbackWithCallbackType:@"CustomCallback" callbackClass:[CustomCallback class]];
    
    // When
    __block FRNode *currentNode = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"Node Submit"];
    [authService nextWithTokenCompletion:^(Token *token, FRNode *node, NSError *error) {
        
        // Then
        
        // Validate response
        currentNode = node;
        XCTAssertNil(token);
        XCTAssertNil(error);
        XCTAssertNotNil(node);
        
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
        else if ([callback isKindOfClass:[CustomCallback class]]) {
            CustomCallback *thisCallback = (CustomCallback *)callback;
            thisCallback.value = customCallbackValue;
            thisCallback.customAttribute = customAttributeInputValue;
        }
        else {
            XCTFail("Received unexpected callback %@", callback);
        }
    }
    
    NSDictionary *requestPayload = [currentNode buildRequestPayload];
    NSDictionary *callbacks = requestPayload[@"callbacks"];
    
    XCTAssertNotNil(callbacks);
    
    for (NSDictionary *callback in callbacks) {
        
        if ([callback[@"type"] isEqualToString:@"CustomCallback"]) {
            
            NSDictionary *inputs = callback[@"input"];
            NSDictionary *outputs = callback[@"output"];
            NSDictionary *custom = callback[@"custom"];
            
            XCTAssertNotNil(inputs);
            XCTAssertNotNil(outputs);
            XCTAssertNotNil(custom);
            
            XCTAssertTrue([custom[@"CustomCallbackInput"] isEqualToString:@"CustomCallbackValue"]);
            
            BOOL customOutputValidated = NO;
            for (NSDictionary *output in outputs) {
                if ([output[@"name"] isEqualToString:@"customAttribute"] && [output[@"value"] isEqualToString:@"CustomAttributeValue"]) {
                    customOutputValidated = YES;
                }
            }
            XCTAssertTrue(customOutputValidated);
            
            
            BOOL customAttributeInputValidated = NO;
            BOOL customCallbackValueInputValidated = NO;
            
            for (NSDictionary *input in inputs) {
                if ([input[@"name"] isEqualToString:@"customAttribute"] && [input[@"value"] isEqualToString:customAttributeInputValue]) {
                    customAttributeInputValidated = YES;
                }
                else if ([input[@"name"] isEqualToString:@"IDToken3"] && [input[@"value"] isEqualToString:customCallbackValue]) {
                    customCallbackValueInputValidated = YES;
                }
            }
            
            XCTAssertTrue(customAttributeInputValidated);
            XCTAssertTrue(customCallbackValueInputValidated);
        }
    }
}


- (void)test_05_Validate_Overriding_Exisiting_CallbackType {
    
    if (!self.shouldLoadMockResponses) {
        // Ignoring test if test is against actual server, and not against mock response
        return;
    }
    
    if (self.config.serverConfig == nil) {
        XCTFail(@"Failed to load ServerConfig from test configuration");
        return;
    }
    
    // Set mock response
    [self loadMockResponses:@[@"AuthTree_UsernamePasswordNode"]];
    
    // Given
    NSString *customCallbackValue = @"Custom Value";
    NSString *customAttributeInputValue = @"Custom Attribute Test";
    FRAuthService *authService = [[FRAuthService alloc] initWithName:@"CustomCallbackService" serverConfig:self.config.serverConfig];
    
    // Register
    [[FRCallbackFactory shared] registerCallbackWithCallbackType:@"NameCallback" callbackClass:[CustomCallback class]];
    
    // When
    __block FRNode *currentNode = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"Node Submit"];
    [authService nextWithTokenCompletion:^(Token *token, FRNode *node, NSError *error) {
        
        // Then
        
        // Validate response
        currentNode = node;
        XCTAssertNil(token);
        XCTAssertNil(error);
        XCTAssertNotNil(node);
        
        [ex fulfill];
    }];
    XCTAssertTrue([self waitForExpectiontion], @"Expectation failure - %@", [ex description]);
    
    XCTAssertNotNil(currentNode);
    
    for (FRCallback *callback in [currentNode callbacks]) {
        if ([callback isKindOfClass:[FRPasswordCallback class]]) {
            FRPasswordCallback *thisCallback = (FRPasswordCallback *)callback;
            thisCallback.value = self.config.password;
        }
        else if ([callback isKindOfClass:[CustomCallback class]]) {
            CustomCallback *thisCallback = (CustomCallback *)callback;
            thisCallback.value = customCallbackValue;
            thisCallback.customAttribute = customAttributeInputValue;
        }
        else {
            XCTFail("Received unexpected callback %@", callback);
        }
    }
    
    NSDictionary *requestPayload = [currentNode buildRequestPayload];
    NSDictionary *callbacks = requestPayload[@"callbacks"];
    
    XCTAssertNotNil(callbacks);
    
    for (NSDictionary *callback in callbacks) {
        
        if ([callback[@"type"] isEqualToString:@"NameCallback"]) {
            
            NSDictionary *inputs = callback[@"input"];
            NSDictionary *outputs = callback[@"output"];
            NSDictionary *custom = callback[@"custom"];
            
            XCTAssertNotNil(inputs);
            XCTAssertNotNil(outputs);
            XCTAssertNotNil(custom);
            
            XCTAssertTrue([custom[@"CustomCallbackInput"] isEqualToString:@"CustomCallbackValue"]);
            
            BOOL customAttributeInputValidated = NO;
            BOOL customCallbackValueInputValidated = NO;
            
            for (NSDictionary *input in inputs) {
                if ([input[@"name"] isEqualToString:@"customAttribute"] && [input[@"value"] isEqualToString:customAttributeInputValue]) {
                    customAttributeInputValidated = YES;
                }
                else if ([input[@"name"] isEqualToString:@"IDToken1"] && [input[@"value"] isEqualToString:customCallbackValue]) {
                    customCallbackValueInputValidated = YES;
                }
            }
            
            XCTAssertTrue(customAttributeInputValidated);
            XCTAssertTrue(customCallbackValueInputValidated);
        }
    }
}

@end
