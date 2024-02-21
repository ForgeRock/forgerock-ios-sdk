//
//  ViewController.m
//  FRexampleObjC
//
//  Copyright (c) 2019-2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

#import "ViewController.h"
#import <FRUI/FRUI.h>
#import <FRAuth/FRAuth.h>
#import <FRCore/FRCore.h>

#define UIColorFromRGB(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
alpha:1.0]

@interface ViewController () <FRDropDownViewProtocol, AuthorizationPolicyDelegate, FRTokenManagementPolicyDelegate>

@property (nonatomic, weak) IBOutlet UITextView *loggingView;
@property (nonatomic, weak) IBOutlet FRButton *performActionBtn;
@property (nonatomic, weak) IBOutlet FRButton *clearLogBtn;
@property (nonatomic, weak) IBOutlet FRDropDownButton *dropDown;

@property (nonatomic, strong) NSMutableArray *menuList;
@property (nonatomic, strong) NSString *currentAction;

@property (nonatomic, strong) FRServerConfig *serverConfig;
@property (nonatomic, strong) FROAuth2Client *oAuth2Client;
@property (nonatomic, strong) NSString *authServiceName;
@property (nonatomic, strong) NSString *registerServiceName;
@property (nonatomic, strong) NSURLSession *session;

@property (assign) BOOL invoke401;

@end

@implementation ViewController

# pragma mark - Lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];

    // Alter FRAuth configuration file from Info.plist
    if ([[[[NSBundle mainBundle] infoDictionary] allKeys] containsObject:@"FRConfigFileName"]) {
        FRAuth.configPlistFileName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"FRConfigFileName"];
    }
    
    UIColor *primaryColor = nil;
    // Apply different styles for SSO application
    if ([[[[NSBundle mainBundle] infoDictionary] allKeys] containsObject:@"FRExampleSSOApp"] && [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"FRExampleSSOApp"] boolValue] == YES) {
        primaryColor = UIColorFromRGB(0x495661);
    }
    else {
        primaryColor = UIColorFromRGB(0x519387);
    }
    
    
    if (@available(iOS 13, *)) {
        [self.view setBackgroundColor:[UIColor colorNamed:@"BackgroundColor"]];
    }
    else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
    }
    
    [self.performActionBtn setBackgroundColor:primaryColor];
    [self.performActionBtn setTitleColor:[UIColor whiteColor]];
    
    [self.clearLogBtn setBackgroundColor:UIColorFromRGB(0xDC143C)];
    [self.clearLogBtn setTitleColor:[UIColor whiteColor]];
    
    self.title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    self.navigationController.navigationBar.barTintColor = primaryColor;
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    
//    // - MARK: Token Management - Example starts
    FRTokenManagementPolicy *policy = [[FRTokenManagementPolicy alloc] initWithValidatingURL:@[[NSURL URLWithString:@"https://httpbin.org/status/401"], [NSURL URLWithString:@"https://httpbin.org/anything"]] delegate:self];
    self.invoke401 = NO;
    [NSURLProtocol registerClass:[FRURLProtocol class]];
    [FRURLProtocol setTokenManagementPolicy:policy];
    
    AuthorizationPolicy *authPolicy = [[AuthorizationPolicy alloc] initWithValidatingURL:@[[NSURL URLWithString:@"http://localhost:9888/policy/transfer"]] delegate:self];
    [FRURLProtocol setAuthorizationPolicy:authPolicy];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setProtocolClasses:@[[FRURLProtocol class]]];
    self.session = [NSURLSession sessionWithConfiguration:config];
//    // - MARK: Token Management - Example ends
    
    // Initialize SDK
    NSError *initError = nil;
    BOOL result = [FRAuth startWithOptions:nil error:&initError];
    
    
    if (!result || initError != nil) {
        [self displayLog:[NSString stringWithFormat:@"FRAuth SDK init failed: %@", [initError debugDescription]]];
    }
    else {
        [self displayLog:@"FRAuth SDK init success"];
        
        // Load configuration, and FRServerConfig and FROAuth2Client
        NSString *path = [[NSBundle mainBundle] pathForResource: FRAuth.configPlistFileName ofType: @"plist"];
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
        NSString *url = dict[@"forgerock_url"];
        NSString *realm = dict[@"forgerock_realm"];
        NSString *timeout = dict[@"forgerock_timeout"];
        
        self.serverConfig = [[[[FRServerConfigBuilder alloc] initWithUrl:[NSURL URLWithString:url] realm:realm] setWithTimeout:[timeout doubleValue]] build];
        
        NSString *clientId = dict[@"forgerock_oauth_client_id"];
        NSString *redirect_uri = dict[@"forgerock_oauth_redirect_uri"];
        NSString *scope = dict[@"forgerock_oauth_scope"];
        NSString *threshold = dict[@"forgerock_oauth_threshold"];
        
        self.oAuth2Client = [[FROAuth2Client alloc] initWithClientId:clientId scope:scope redirectUri:[NSURL URLWithString:redirect_uri] serverConfig:self.serverConfig threshold:[threshold intValue]];
        
        self.authServiceName = dict[@"forgerock_auth_service_name"];
        self.registerServiceName = dict[@"forgerock_registration_service_name"];
    }
    
    self.dropDown.delegate = self;
    [self.dropDown setThemeColor:primaryColor];
    [self.dropDown setMaxHeight:400.0];
    [self.dropDown setTitle:@"Select an option" forState:UIControlStateNormal];
    [self.dropDown setTitle:@"Select an option" forState:UIControlStateFocused];
    [self.dropDown setTitle:@"Select an option" forState:UIControlStateHighlighted];
    [self.dropDown setTitle:@"Select an option" forState:UIControlStateSelected];
    self.dropDown.dataSource = @[@"Login with UI (FRUser)", @"Request UserInfo", @"User Logout", @"Get FRUser.currentUser", @"Collect Device Information", @"JailbreakDetector.analyze()", @"FRUser.getAccessToken()", @"Login without UI (FRUser)", @"Invoke API (Token Mgmt)", @"FRSession.authenticateWithUI (Token)", @"FRSession.authenticate (Token)"];
}


# pragma mark - Logging Helper

- (void)displayLog:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.loggingView.text = [NSString stringWithFormat:@"%@%@\n", self.loggingView.text, text];
    });
}

- (IBAction)onClearLogSelected:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.loggingView.text = @"";
    });
}

- (IBAction)onPerformActionSelected:(id)sender {
    
    if ([self.currentAction isEqualToString:@"Login with UI (FRUser)"]) {
        [self performUserLoginWithUI];
    }
    else if ([self.currentAction isEqualToString:@"User Logout"]) {
        [self performUserLogout];
    }
    else if ([self.currentAction isEqualToString:@"Login without UI (FRUser)"]) {
        [self performUserLoginWithoutUI];
    }
    else if ([self.currentAction isEqualToString:@"Collect Device Information"]) {
        [self performDeviceInfoCollection];
    }
    else if ([self.currentAction isEqualToString:@"Get FRUser.currentUser"]) {
        [self displayLog:[[FRUser currentUser] debugDescription]];
    }
    else if ([self.currentAction isEqualToString:@"FRUser.getAccessToken()"]) {
        [self performGetAccessToken];
    }
    else if ([self.currentAction isEqualToString:@"Request UserInfo"]) {
        [self performGetUserInfo];
    }
    else if ([self.currentAction isEqualToString:@"JailbreakDetector.analyze()"]) {
        [self performJailbreakDetector];
    }
    else if ([self.currentAction isEqualToString:@"Invoke API (Token Mgmt)"]) {
        [self performInvokeAPI];
    }
    else if ([self.currentAction isEqualToString:@"FRSession.authenticateWithUI (Token)"]) {
        [self performSessionAuthenticate:YES];
    }
    else if ([self.currentAction isEqualToString:@"FRSession.authenticate (Token)"]) {
        [self performSessionAuthenticate:NO];
    }
    else {
        
    }
}

# pragma mark - Option Methods: Login / Register / Logout / UserInfo

- (void)performUserLoginWithUI {
    __block ViewController* blockSelf = self;
    [FRUserObjc authenticateWithRootViewController:self userCompletion:^(FRUser *user, NSError *error) {
        if (user != nil) {
            [blockSelf displayLog:user.debugDescription];
        }
        else {
            [blockSelf displayLog:error.localizedDescription];
        }
    }];
}

- (void)performUserLogout {
    [[FRUser currentUser] logout];
    [self displayLog:@"User logout completed"];
}

- (void)performUserLoginWithoutUI {
    __block ViewController* blockSelf = self;
    [FRUser loginWithCompletion:^(FRUser *user, FRNode *node, NSError * error) {
        [blockSelf handleNodeWithObj:user expectedResult:[FRUser class] node:node error:error];
    }];
}

- (void)performFRAuthServiceForToken {
    __block ViewController* blockSelf = self;
    FRAuthService *authService = [[FRAuthService alloc] initWithName:self.authServiceName serverConfig:self.serverConfig];
    [authService nextWithUserCompletion:^(FRUser *user, FRNode *node, NSError *error) {
        [blockSelf handleNodeWithObj:user expectedResult:[FRUser class] node:node error:error];
    }];
}

- (void)performDeviceInfoCollection {
    __block ViewController* blockSelf = self;
    [[FRDeviceCollector shared] collectWithCompletion:^(NSDictionary<NSString *,id> *deviceInfo) {
        [blockSelf displayLog:[NSString stringWithFormat:@"%@", deviceInfo]];
    }];
}

- (void)performGetAccessToken {
    __block ViewController* blockSelf = self;
    if ([FRUser currentUser]) {
        [[FRUser currentUser] getAccessTokenWithCompletion:^(FRUser *user, NSError *error) {
            [blockSelf displayLog: [user debugDescription]];
        }];
    }
    else {
        [self displayLog:@"[FRUser currentUser] does not exist"];
    }
}

- (void)performGetUserInfo {
    __block ViewController* blockSelf = self;
    if ([FRUser currentUser]) {
        [[FRUser currentUser] getUserInfoWithCompletion:^(FRUserInfo *userInfo, NSError *error) {
            [blockSelf displayLog: [userInfo debugDescription]];
        }];
    }
    else {
        [self displayLog:@"[FRUser currentUser] does not exist"];
    }
}

- (void)performJailbreakDetector {
    if ([FRJailbreakDetector shared]) {
        double score = [[FRJailbreakDetector shared] analyze];
        [self displayLog:[NSString stringWithFormat:@"JailbreakDetectore score: %f", score]];
    }
    else {
        [self displayLog:@"[FRJailbreakDetector shared] does not exist"];
    }
}

- (void)performInvokeAPI {
    
    NSURL *url = nil;
    if (self.invoke401) {
        self.invoke401 = NO;
        url = [NSURL URLWithString:@"https://httpbin.org/status/401"];
    }
    else {
        self.invoke401 = YES;
        url = [NSURL URLWithString:@"https://httpbin.org/anything"];
    }
    
    __block ViewController* blockSelf = self;
    NSURLSessionDataTask *task = [self.session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (error != nil || httpResponse == nil || data == nil) {
            if (blockSelf.invoke401) {
                [blockSelf displayLog:@"Invoking API failed as expected"];
            }
            else {
                [blockSelf displayLog:@"Invoking API failed with unexpected result"];
            }
        }
        
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [blockSelf displayLog:responseString];
        [blockSelf displayLog:[NSString stringWithFormat:@"HTTP Status Code %ld", (long)httpResponse.statusCode]];
        [blockSelf displayLog:[NSString stringWithFormat:@"%@", httpResponse.allHeaderFields]];
    }];
    [task resume];
}


- (void)performSessionAuthenticate:(BOOL)shouldUseUI {

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"FRSession.authenticate" message:nil preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Enter authIndex (tree name) value";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
    
    __block ViewController* blockSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        UITextField *textField = alert.textFields.firstObject;

        dispatch_async(dispatch_get_main_queue(), ^{
            if (shouldUseUI) {
                [FRSessionObjc authenticateWithUI:textField.text authIndexType:@"service" rootViewController:self userCompletion:^(Token *token, NSError *error) {
                    if (token != nil) {
                        [blockSelf displayLog:token.debugDescription];
                    }
                    else {
                        [blockSelf displayLog:error.localizedDescription];
                    }
                }];
            }
            else {
                [FRSession authenticateWithAuthIndexValue:textField.text authIndexType:@"service" completion:^(Token *token, FRNode *node, NSError *error) {
                    [blockSelf handleNodeWithObj:token expectedResult:[Token class] node:node error:error];
                }];
            }
        });
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

# pragma mark - FRDropDownViewDelegate

- (void)selectedItemWithIndex:(NSInteger)index item:(NSString *)item {
    self.currentAction = item;
}


# pragma mark - FRNode handling helper

- (void)handleNodeWithObj:(id)resultObj expectedResult:(Class)expectedResult node:(FRNode *)node error:(NSError *)error {
    
    if (node != nil) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
                
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"FRNode Hanlding" message:nil preferredStyle:UIAlertControllerStyleAlert];
            __block FRNode *nodeBlock = node;
            __block ViewController *blockSelf = self;
            for (id callback in node.callbacks) {
                
                if ([callback isKindOfClass:[FRNameCallback class]] ||
                    [callback isKindOfClass:[FRTextInputCallback class]] ||
                    [callback isKindOfClass:[FRValidatedCreateUsernameCallback class]] ||
                    [callback isKindOfClass:[FRPasswordCallback class]] ||
                    [callback isKindOfClass:[FRValidatedCreatePasswordCallback class]]) {
                    
                    FRSingleValueCallback *thisCallback = (FRSingleValueCallback *)callback;
                    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                        textField.placeholder = thisCallback.prompt;
                        textField.accessibilityIdentifier = thisCallback.type;
                        textField.textColor = [UIColor blueColor];
                        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
                        textField.borderStyle = UITextBorderStyleRoundedRect;
                    }];
                }
                else if ([callback isKindOfClass:[FRChoiceCallback class]]) {
                    FRChoiceCallback *choiceCallback = (FRChoiceCallback *)callback;
                    
                    __block NSString *titleText = @"Enter the int value: ";
                    [choiceCallback.choices enumerateObjectsUsingBlock:^(NSString *item, NSUInteger idx, BOOL *stop)
                    {
                        NSString *leadingStr = @"";
                        if (idx > 0) {
                            leadingStr = @" ,";
                        }
                        titleText = [NSString stringWithFormat:@"%@%@%@=%lu", titleText, leadingStr, item, (unsigned long)idx];
                    }];
                    alert.title = titleText;
                    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                        textField.placeholder = choiceCallback.prompt;
                        textField.accessibilityIdentifier = choiceCallback.type;
                        textField.textColor = [UIColor blueColor];
                        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
                        textField.borderStyle = UITextBorderStyleRoundedRect;
                    }];
                }
            }
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                
                for (UITextField *textField in alert.textFields) {
                    NSString *callbackType = textField.accessibilityIdentifier;
                    NSString *value = textField.text;
                    
                    for (id callback in nodeBlock.callbacks) {
                        FRSingleValueCallback *thisCallback = (FRSingleValueCallback *)callback;
                        if ([thisCallback.type isEqualToString:callbackType]) {
                            [thisCallback setInputValue:value];
                        }
                    }
                }
                
                if ([expectedResult isEqual:[FRUser class]]) {
                    [nodeBlock nextWithUserCompletion:^(FRUser *user, FRNode *node, NSError *error) {
                        [blockSelf handleNodeWithObj:user expectedResult:expectedResult node:node error:error];
                    }];
                }
                else if ([expectedResult isEqual:[AccessToken class]]) {
                    [nodeBlock nextWithAccessTokenCompletion:^(AccessToken *accessToken, FRNode *node, NSError *error) {
                        [blockSelf handleNodeWithObj:accessToken expectedResult:expectedResult node:node error:error];
                    }];
                }
                else if ([expectedResult isEqual:[Token class]]) {
                    [nodeBlock nextWithTokenCompletion:^(Token *token, FRNode *node, NSError *error) {
                        [blockSelf handleNodeWithObj:token expectedResult:expectedResult node:node error:error];
                    }];
                }
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
        });
    }
    else if (resultObj != nil) {
        [self displayLog:[resultObj debugDescription]];
    }
    else if (error != nil) {
        [self displayLog:[error debugDescription]];
    }
}

# pragma mark - AuthorizationPolicyDelegate

- (void)onPolicyAdviseReceivedWithPolicyAdvice:(PolicyAdvice * _Nonnull)policyAdvice completion:(void (^ _Nonnull)(BOOL))completion {
    // Hanlde Authentication policy
}

@end
