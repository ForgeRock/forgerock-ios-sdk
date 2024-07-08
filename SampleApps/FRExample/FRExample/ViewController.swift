//
//  ViewController.swift
//  FRExample
//
//  Copyright (c) 2019-2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuth
import FRCore
import FRUI
import CoreLocation
import QuartzCore
import FRDeviceBinding
import PingProtect

class ViewController: UIViewController, ErrorAlertShowing {

    // MARK: - Properties
    @IBOutlet weak var loggingView: UITextView?
    @IBOutlet weak var commandField: UIButton?
    @IBOutlet weak var performActionBtn: FRButton?
    @IBOutlet weak var clearLogBtn: FRButton?
    @IBOutlet weak var dropDown: FRDropDownButton?
    @IBOutlet weak var invokeBtn: FRButton?
    @IBOutlet weak var urlField: FRTextField?
    
    var selectedIndex: Int = 0
    var primaryColor: UIColor
    var textColor: UIColor
    var invoke401: Bool = false
    var urlSession: URLSession = URLSession.shared
    var loadingView: FRLoadingView = FRLoadingView(size: CGSize(width: 120, height: 120), showDropShadow: true, showDimmedBackground: true, loadingText: "Loading...")
    let useDiscoveryURL = false
    let centralizedLoginBrowserType: BrowserType = .authSession

    // MARK: - UIViewController Lifecycle
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        
        // Alter FRAuth configuration file from Info.plist
        if let configFileName = Bundle.main.object(forInfoDictionaryKey: "FRConfigFileName") as? String {
            FRAuth.configPlistFileName = configFileName
        }
        
        // Apply different styles for SSO application
        if let isSSOApp = Bundle.main.object(forInfoDictionaryKey: "FRExampleSSOApp") as? Bool, isSSOApp {
            self.primaryColor = UIColor.hexStringToUIColor(hex: "#495661")
            self.textColor = UIColor.white
        }
        else {
            self.primaryColor = UIColor.hexStringToUIColor(hex: "#519387")
            self.textColor = UIColor.white
        }
        
        let navigationBarAppearace = UINavigationBar.appearance()
        navigationBarAppearace.tintColor = self.primaryColor
        navigationBarAppearace.barTintColor = self.primaryColor
        navigationBarAppearace.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        
        // Alter FRAuth configuration file from Info.plist
        if let configFileName = Bundle.main.object(forInfoDictionaryKey: "FRConfigFileName") as? String {
            FRAuth.configPlistFileName = configFileName
        }
        
        // Apply different styles for SSO application
        if let isSSOApp = Bundle.main.object(forInfoDictionaryKey: "FRExampleSSOApp") as? Bool, isSSOApp {
            self.primaryColor = UIColor.hexStringToUIColor(hex: "#495661")
            self.textColor = UIColor.white
        }
        else {
            self.primaryColor = UIColor.hexStringToUIColor(hex: "#519387")
            self.textColor = UIColor.white
        }
        
        let navigationBarAppearace = UINavigationBar.appearance()
        navigationBarAppearace.tintColor = self.primaryColor
        navigationBarAppearace.barTintColor = self.primaryColor
        navigationBarAppearace.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        super.init(coder: aDecoder)
        self.navigationController?.navigationBar.tintColor = self.primaryColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            self.title = bundleName
        }
        else {
            self.title = "FRExample"
        }
        
        if #available(iOS 13.0, *) {
            self.view.backgroundColor = UIColor(named: "BackgroundColor")
        }
        else {
            self.view.backgroundColor = .white
        }
        
        // Setup loading view
        loadingView.add(inView: self.view)
        
        // Styling
        self.performActionBtn?.backgroundColor = self.primaryColor
        self.performActionBtn?.tintColor = self.textColor
        self.invokeBtn?.backgroundColor = self.primaryColor
        self.invokeBtn?.tintColor = self.textColor
        
        self.urlField?.tintColor = self.primaryColor
        self.urlField?.normalColor = self.primaryColor
        
        self.clearLogBtn?.backgroundColor = UIColor.hexStringToUIColor(hex: "#DC143C")
        self.clearLogBtn?.titleColor = UIColor.white

        self.commandField?.setTitleColor(self.primaryColor, for: .normal)
        self.commandField?.setTitleColor(self.primaryColor, for: .selected)
        self.commandField?.setTitleColor(self.primaryColor, for: .highlighted)
        
        // DropDown set-up
        self.dropDown?.themeColor = self.primaryColor
        self.dropDown?.maxHeight = 500
        self.dropDown?.delegate = self
        self.dropDown?.dataSource = [
            "Login with UI (FRUser)",
            "Login with Browser",
            "Request UserInfo",
            "User Logout",
            "Get FRUser.currentUser",
            "Invoke API (Token Mgmt)",
            "Collect Device Information",
            "JailbreakDetector.analyze()",
            "FRUser.getAccessToken()",
            "FRUser.refresh()",
            "Login with UI (Accesstoken)",
            "FRSession.authenticate with UI (Token)",
            "FRSession.logout()",
            "Register User with UI (FRUser)",
            "Register User with UI (Accesstoken)",
            "Login without UI (FRUser)",
            "Login without UI (Accesstoken)",
            "FRSession.authenticate without UI (Token)",
            "Display Configurations",
            "Revoke Access Token",
            "List WebAuthn Credentials",
            "List Device Binding Keys"
        ]
        self.commandField?.setTitle("Login with UI (FRUser)", for: .normal)
        
        // - MARK: Token Management - Example
        // Register FRURLProtocol
        URLProtocol.registerClass(FRURLProtocol.self)
        let policy = TokenManagementPolicy(validatingURL: [URL(string: "http://openig.example.com:9999/products.php")!, URL(string: "http://localhost:9888/policy/transfer")!, URL(string: "https://httpbin.org/status/401")!, URL(string: "https://httpbin.org/anything")!], delegate: self)
        FRURLProtocol.tokenManagementPolicy = policy
        
        //  - MARK: Authorization Policy - Example
        let authPolicy = AuthorizationPolicy(validatingURL: [URL(string: "http://localhost:9888/policy/transfer")!], delegate: self)
        FRURLProtocol.authorizationPolicy = authPolicy
        
        // Configure FRURLProtocol for HTTP client
        let config = URLSessionConfiguration.default
        config.protocolClasses = [FRURLProtocol.self]
        self.urlSession = URLSession(configuration: config)
        
        // Configure FRSecurityConfiguration to set SSL Pinning on the FRURLProtocol
        // This needs to be set up if using Authroization or Token Policies with FRURLProtocol
        // and want to force SSL Pinning on those endpoints.
        // Make sure to add the Key Hashes of the certificates that correspont to the URLs 
        // set on the `FRURLProtocol.tokenManagementPolicy` & `FRURLProtocol.authorizationPolicy`
        
        var sslPinningKeyHashes: [String] = []
        //sslPinningKeyHashes = ["Key1", "Key2"] --> Add Key hashes and uncomment to enable
        
        if(!sslPinningKeyHashes.isEmpty) {
            let frSecurityConfiguration = FRSecurityConfiguration(hashes: sslPinningKeyHashes)
            FRURLProtocol.frSecurityConfiguration = frSecurityConfiguration
        }
        
        //  - MARK: FRUI Customize Cell example
        // Comment out below code to demonstrate FRUI customization
//        CallbackTableViewCellFactory.shared.registerCallbackTableViewCell(callbackType: "NameCallback", cellClass: CustomNameCallbackCell.self, nibName: "CustomNameCallbackCell")
        
        
        //  - MARK: RequestInterceptor example
        
        //  By commenting out below code, it registers 'ForceAuthIntercetpr' class into FRCore and FRAuth's RequestInterceptor which then allows developers to customize requests being made by ForgeRock SDK, and modify as needed
        // FRRequestInterceptorRegistry.shared.registerInterceptors(interceptors: [ForceAuthInterceptor()])
        
        /*
        //  - MARK: URLSessionConfiguration && SSL Pinning example
         // Create URLSessionConfiguration & Subclass the FRURLSessionHandler class
         // override func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
         // override func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
         // And provide your custom pinning implementation
         // set the Configuration and the Handler using the
         // RestClient.shared.setURLSessionConfiguration(config: URLSessionConfiguration?, handler: FRURLSessionHandlerProtocol?) method.
        let customConfig = URLSessionConfiguration()
        customConfig.timeoutIntervalForRequest = 90
        let customPinner = CustomPin(frSecurityConfiguration: FRSecurityConfiguration(hashes: [Public Key Hashes]))
        RestClient.shared.setURLSessionConfiguration(config: customConfig, handler: customPinner)
         
        */
        
        // Start SDK
      if !useDiscoveryURL {
        // use the Config Plist file
        do {
          try FRAuth.start()
          self.displayLog("FRAuth SDK started using \(FRAuth.configPlistFileName).plist.")
        }
        catch {
          self.displayLog(String(describing: error))
        }
      } else {
        // use the discovery URL
        if #available(iOS 13.0, *) {
          Task {
            do {
              let config =
              ["forgerock_oauth_client_id": "CLIENT_ID_PLACEHOLDER",
               "forgerock_oauth_redirect_uri": "org.forgerock.demo://oauth2redirect",
               "forgerock_oauth_sign_out_redirect_uri": "org.forgerock.demo://oauth2redirect",
               "forgerock_oauth_scope": "openid profile email address revoke",
              /* "forgerock_ssl_pinning_public_key_hashes": ["SSL_PINNING_HASH_PLACEHOLDER"]*/]

              let discoveryURL = "DISCOVERY_URL_PLACEHOLDER"

              let options = try await FROptions(config: config).discover(discoveryURL: discoveryURL)
              
              try FRAuth.start(options: options)
              self.displayLog("FRAuth SDK started using \(discoveryURL) discovery URL")
            }
            catch {
              self.displayLog(String(describing: error))
            }
          }
        } else {
          self.displayLog("Please run on iOS 13 and above")
        }
      }
    }
    
    
    // MARK: - Helper: Loading
    func startLoading() {
        self.loadingView.startLoading()
    }
    
    func stopLoading() {
        self.loadingView.stopLoading()
    }
    
    
    // MARK: - Helper: Handle Node object and result
    
    func handleNode<T>(_ result: T?, _ node: Node?, _ error: Error?) {
        
        if let token = result as? Token {
            self.displayLog("Token(s) received: \n\(token.debugDescription)")
        }
        else if let token = result as? AccessToken {
            self.displayLog("AccessToken(s) received: \n\(token.debugDescription)")
        }
        else if let user = result as? FRUser {
            self.displayLog("FRUser received: \n\(user.debugDescription)")
        }
        else if let node = node {
            // TODO: Currently only supports NameCallback / PasswordCallback / ChoiceCallback; any additional callback type can be added in the future
            DispatchQueue.main.async {
                
                let title = "FRAuth"
                
                let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
                
                for callback:Callback in node.callbacks {
                    
                    if callback.type == "NameCallback", let nameCallback = callback as? NameCallback {
                        
                        alert.addTextField(configurationHandler: { (textField) in
                            textField.placeholder = nameCallback.prompt
                            textField.autocorrectionType = .no
                            textField.autocapitalizationType = .none
                        })
                    }
                    else if callback.type == "TextInputCallback", let textInputCallback = callback as? TextInputCallback {
                        
                        alert.addTextField(configurationHandler: { (textField) in
                            textField.placeholder = textInputCallback.prompt
                            textField.autocorrectionType = .no
                            textField.autocapitalizationType = .none
                            textField.text = textInputCallback.getDefaultText()
                        })
                    }
                    else if callback.type == "PasswordCallback", let passwordCallback = callback as? PasswordCallback {
                        alert.addTextField(configurationHandler: { (textField) in
                            textField.placeholder = passwordCallback.prompt
                            textField.isSecureTextEntry = true
                            textField.autocorrectionType = .no
                            textField.autocapitalizationType = .none
                        })
                    }
                    else if callback.type == "ChoiceCallback", let choiceCallback = callback as? ChoiceCallback {
                        
                        var descriptionText = "Enter the int value: "
                        
                        for (index, choice) in choiceCallback.choices.enumerated() {
                            var leadingStr = ""
                            if index > 0 {
                                leadingStr = " ,"
                            }
                            
                            descriptionText = descriptionText + leadingStr + choice + "=" + String(index)
                        }
                        
                        alert.title = descriptionText
                        
                        alert.addTextField(configurationHandler: { (textField) in
                            textField.placeholder = choiceCallback.prompt
                            textField.autocorrectionType = .no
                            textField.autocapitalizationType = .none
                        })
                    } else if callback.type == "TextOutputCallback", let textOutputCallback = callback as? TextOutputCallback {
                        alert.title = textOutputCallback.message
                    } else if callback.type == "ConfirmationCallback", let confirmationCallback = callback as? ConfirmationCallback {
                        if let options = confirmationCallback.options {
                            for (index, option) in options.enumerated() {
                                let action = UIAlertAction(title: option, style: .default, handler: { (_) in
                                    confirmationCallback.value = index
                                    handleNode(node)
                                })
                                alert.addAction(action)
                            }
                        }
                        self.present(alert, animated: true, completion: nil)
                        return
                    } else if callback.type == "DeviceBindingCallback", let deviceBindingCallback = callback as? DeviceBindingCallback {
                        let customPrompt: Prompt = Prompt(title: "Custom Title", subtitle: "Custom Subtitle", description: "Custom Description")
                        deviceBindingCallback.bind(prompt: customPrompt) { result in
                            DispatchQueue.main.async {
                                var bindingResult = ""
                                switch result {
                                case .success:
                                    bindingResult = "Success"
                                case .failure(let error):
                                    if error == .invalidCustomClaims {
                                        self.showErrorAlert(title: "Device Binding Error", message: error.errorMessage)
                                        return
                                    }
                                    bindingResult = error.errorMessage
                                }
                                
                                self.displayLog("Device Binding Result: \n\(bindingResult)")
                                handleNode(node)
                            }
                        }
                        return
                    } else if callback.type == "DeviceSigningVerifierCallback", let deviceSigningVerifierCallback = callback as? DeviceSigningVerifierCallback {
                        let customPrompt: Prompt = Prompt(title: "Custom Title", subtitle: "Custom Subtitle", description: "Custom Description")
                        deviceSigningVerifierCallback.sign(customClaims: ["isCompanyPhone": true, "lastUpdated": Int(Date().timeIntervalSince1970)], prompt: customPrompt) { result in
                            DispatchQueue.main.async {
                                var signingResult = ""
                                switch result {
                                case .success:
                                    signingResult = "Success"
                                case .failure(let error):
                                    if error == .invalidCustomClaims {
                                        self.showErrorAlert(title: "Device Signing Error", message: error.errorMessage)
                                        return
                                    }
                                    signingResult = error.errorMessage
                                }
                                
                                self.displayLog("Signing Verifier Result: \n\(signingResult)")
                                handleNode(node)
                            }
                        }
                        return
                    } else if callback.type == "PingOneProtectInitializeCallback", let pingOneProtectInitCallback = callback as? PingOneProtectInitializeCallback {
                        pingOneProtectInitCallback.start { result in
                            DispatchQueue.main.async {
                                var signalsResult = ""
                                switch result {
                                case .success:
                                    signalsResult = "Success"
                                case .failure(let error):
                                    signalsResult = "Error: \(error.localizedDescription)"
                                }
                                self.displayLog("PingOne Protect Initialize Result: \n\(signalsResult)")
                                handleNode(node)
                            }
                        }
                        return
                    } else if callback.type == "PingOneProtectEvaluationCallback", let pingOneProtectEvaluationCallback = callback as? PingOneProtectEvaluationCallback {
                        pingOneProtectEvaluationCallback.getData{ result in
                            DispatchQueue.main.async {
                                var signalsResult = ""
                                switch result {
                                case .success:
                                    signalsResult = "Success"
                                case .failure(let error):
                                    signalsResult = "Error: \(error.localizedDescription)"
                                }
                                self.displayLog("PingOne Protect Evaluation Result: \n\(signalsResult)")
                                handleNode(node)
                            }
                        }
                        return
                    } else {
                        let errorAlert = UIAlertController(title: "Invalid Callback", message: "\(callback.type) is not supported.", preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: "Ok", style: .cancel, handler:nil)
                        errorAlert.addAction(cancelAction)
                        self.present(errorAlert, animated: true, completion: nil)
                        break
                    }
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                })
                
                let submitAction = UIAlertAction(title: "Submit", style: .default, handler: { (_) in
                    
                    var counter = 0
                    for textField in alert.textFields! {
                        
                        let thisCallback:SingleValueCallback = node.callbacks[counter] as! SingleValueCallback
                        thisCallback.setValue(textField.text)
                        counter += 1
                    }
                    
                    handleNode(node)
                })
                
                alert.addAction(cancelAction)
                alert.addAction(submitAction)
                
                self.present(alert, animated: true, completion: nil)
            }
        }
        else if let error = error {
            self.displayLog("\(String(describing: error))")
        }
        else {
            self.displayLog("Authentication Tree flow was successful; no result returned")
        }
        
        func handleNode(_ node: Node) {
            if T.self as AnyObject? === AccessToken.self {
                node.next(completion: { (token: AccessToken?, node, error) in
                    self.handleNode(token, node, error)
                })
            }
            else if T.self as AnyObject? === Token.self {
                node.next(completion: { (token: Token?, node, error) in
                    self.handleNode(token, node, error)
                })
            }
            else if T.self as AnyObject? === FRUser.self {
                node.next(completion: { (user: FRUser?, node, error) in
                    self.handleNode(user, node, error)
                })
            }
        }
    }
    
    
    // MARK: - Helper: User Login/Registration
    
    func performActionHelperWithUI<T>(auth: FRAuth, flowType: FRAuthFlowType, expectedType: T) {
        
        if expectedType as AnyObject? === AccessToken.self {
            if flowType == .authentication {
                FRUser.authenticateWithUI(self, completion: { (token: AccessToken?, error) in
                    if let error = error {
                        self.displayLog(error.localizedDescription)
                    }
                    else if let token = token {
                        self.displayLog(token.debugDescription)
                    }
                    else {
                        self.displayLog("Authentication Tree flow was successful; no result returned")
                    }
                })
            }
            else {
                FRUser.registerWithUI(self, completion: { (token: AccessToken?, error) in
                    if let error = error {
                        self.displayLog(error.localizedDescription)
                    }
                    else if let token = token {
                        self.displayLog(token.debugDescription)
                    }
                    else {
                        self.displayLog("Authentication Tree flow was successful; no result returned")
                    }
                })
            }
        }
        else if expectedType as AnyObject? === Token.self {
            if flowType == .authentication {
                FRUser.authenticateWithUI(self, completion: { (token: Token?, error) in
                    if let error = error {
                        self.displayLog(error.localizedDescription)
                    }
                    else if let token = token {
                        self.displayLog(token.debugDescription)
                    }
                    else {
                        self.displayLog("Authentication Tree flow was successful; no result returned")
                    }
                })
            }
            else {
                FRUser.registerWithUI(self, completion: { (token: Token?, error) in
                    if let error = error {
                        self.displayLog(error.localizedDescription)
                    }
                    else if let token = token {
                        self.displayLog(token.debugDescription)
                    }
                    else {
                        self.displayLog("Authentication Tree flow was successful; no result returned")
                    }
                })
            }
        }
        else if expectedType as AnyObject? === FRUser.self {
            if flowType == .authentication {
                FRUser.authenticateWithUI(self, completion: { (user: FRUser?, error) in
                    if let error = error {
                        self.displayLog(error.localizedDescription)
                    }
                    else if let user = user {
                        self.displayLog(user.debugDescription)
                    }
                    else {
                        self.displayLog("Authentication Tree flow was successful; no result returned")
                    }
                })
            }
            else {
                FRUser.registerWithUI(self, completion: { (user: FRUser?, error) in
                    if let error = error {
                        self.displayLog(error.localizedDescription)
                    }
                    else if let user = user {
                        self.displayLog(user.debugDescription)
                    }
                    else {
                        self.displayLog("Authentication Tree flow was successful; no result returned")
                    }
                })
            }
        }
    }
    
    func performActionHelper<T>(auth: FRAuth, flowType: FRAuthFlowType, expectedType: T) {
        
        if expectedType as AnyObject? === FRUser.self {
            let completionBlock: NodeCompletion = {(user: FRUser?, node, error) in
               
               DispatchQueue.main.async {
                   self.stopLoading()
                   self.handleNode(user, node, error)
               }
           }
            
            if flowType == .registration {
                FRUser.register(completion: completionBlock)
            }
            else {
                FRUser.login(completion: completionBlock)
            }
        }
        else if expectedType as AnyObject? === AccessToken.self {
            let completionBlock: NodeCompletion = {(user: FRUser?, node, error) in
                DispatchQueue.main.async {
                    self.stopLoading()
                    self.handleNode(user?.token, node, error)
                }
            }
            
            if flowType == .registration {
                FRUser.register(completion: completionBlock)
            }
            else {
                FRUser.login(completion: completionBlock)
            }
        }
    }
    
    func performSessionAuthenticate(handleWithUI: Bool) {

        let alert = UIAlertController(title: "FRSession Authenticate", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Enter authIndex (tree name) value"
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let submitAction = UIAlertAction(title: "Continue", style: .default, handler: { (_) in
             
            if let authIndexValue = alert.textFields?.first?.text {
                
                if handleWithUI {
                    FRSession.authenticateWithUI(authIndexValue, "service", self) { (token: Token?, error) in
                        
                        if let error = error {
                            self.displayLog(error.localizedDescription)
                        }
                        else if let token = token {
                            self.displayLog(token.debugDescription)
                        }
                        else {
                            self.displayLog("Authentication Tree flow was successful; no result returned")
                        }
                    }
                }
                else {
                    FRSession.authenticate(authIndexValue: authIndexValue) { (token: Token?, node, error) in
                        DispatchQueue.main.async {
                            self.handleNode(token, node, error)
                        }
                    }
                }
            }
            else {
                self.displayLog("Invalid authIndexValue.")
            }
        });
        
        alert.addAction(cancelAction)
        alert.addAction(submitAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func getAccessTokenFromUser() {
        guard let user = FRUser.currentUser else {
            // If no currently authenticated user is found, log error
            self.displayLog("FRUser.currentUser does not exist")
            return
        }
        
        user.getAccessToken { (user, error) in
            if let error = error {
                self.displayLog("Error while getting AccessToken: \(String(describing: error))")
            }
            else {
                self.displayLog("\(String(describing: FRUser.currentUser))")
            }
        }
    }

    func refreshAccessToken() {
        guard let user = FRUser.currentUser else {
            // If no currently authenticated user is found, log error
            self.displayLog("FRUser.currentUser does not exist")
            return
        }
        
        user.refresh(completion: { (user, error) in
            if let tokenError = error {
                self.displayLog(tokenError.localizedDescription)
            } else {
                self.displayLog("Access token refreshed (forcefully)!")
                self.displayLog("\(String(describing: user))")
            }
        })
    }
    
    // MARK: - Helper: Logout / UserInfo / JailbreakDetector / Device Collector / Invoke API
    
    func getDeviceInformation() {
        guard let _ = FRDevice.currentDevice else {
            // If SDK is not initialized, then don't perform
            self.displayLog("FRDevice.currentDevice does not exist")
            return
        }
        
        FRDeviceCollector.shared.collect { (result) in
            self.displayLog("\(result)")
        }
    }
    

    func performCentralizedLogin() {
        FRUser.browser()?
            .set(presentingViewController: self)
            .set(browserType: centralizedLoginBrowserType)
            .setCustomParam(key: "custom", value: "value")
            .build().login { (user, error) in
                self.displayLog("User: \(String(describing: user)) || Error: \(String(describing: error))")
        }
        return
        
    }
    
    func getUserInfo() {
        
        guard let user = FRUser.currentUser else {
            // If no currently authenticated user is found, log error
            self.displayLog("FRUser.currentUser does not exist")
            return
        }

        // If FRUser.currentUser exists, perform getUserInfo
        user.getUserInfo { (userInfo, error) in
            if let error = error {
                self.displayLog(String(describing: error))
            }
            else if let _ = userInfo {
                self.displayLog(userInfo.debugDescription)
            }
            else {
                self.displayLog("Invalid state: UserInfo returns no result")
            }
        }
    }
    
    
    func logout() {
        guard let user = FRUser.currentUser else {
            // If no currently authenticated user is found, log error
            self.displayLog("FRUser.currentUser does not exist")
            return
        }
        
        // If FRUser.currentUser exists, perform logout
        user.logout(presentingViewController: self, browserType: centralizedLoginBrowserType)
        self.displayLog("Logout completed")
    }
    
    func revokeAccessToken() {
        FRUser.currentUser?.revokeAccessToken(completion: { (user, error) in
            if let tokenError = error {
                self.displayLog(tokenError.localizedDescription)
            } else {
                self.displayLog("Access token revoked")
                self.displayLog("\(String(describing: user))")
            }
        })
    }
    
    
    func listWebAuthnCredentialsByRpId() {
        
        let alert = UIAlertController(title: "List WebAuthn Credentials",
                                      message: "List all credentials by RpId", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "RpId"
        }
        
        alert.addAction(UIAlertAction(title: "List", style: .default, handler: { [weak alert] (_) in
            guard let textField = alert?.textFields?[0], let rpid = textField.text else { return }
            
            let viewController = WebAuthnCredentialsTableViewController(rpId: rpid)
            alert!.view.addSubview(viewController.view)
            self.present(viewController, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
    
    
    func listUserKeys() {
        let viewController = UserKeysTableViewController()
        view.addSubview(viewController.view)
        self.present(viewController, animated: true, completion: nil)
    }
    
    
    func performJailbreakDetector() {
        let result = FRJailbreakDetector.shared.analyze()
        self.displayLog("JailbreakDetector: \(String(describing: result))")
    }
    
    
    func invokeAPI() {
        
        if self.invoke401 {
            self.invoke401 = false
            
            // Invoke API
            self.urlSession.dataTask(with: URL(string: "https://httpbin.org/status/401")!) { (data, response, error) in
                guard let responseData = data, let httpresponse = response as? HTTPURLResponse, error == nil else {
                    self.displayLog("Invoking API failed as expected")
                    return
                }
                
                let responseStr = String(decoding: responseData, as: UTF8.self)
                self.displayLog("Response Data: \(responseStr)")
                self.displayLog("Response Header: \n\(httpresponse.allHeaderFields)")
            }.resume()
        }
        else {
            self.invoke401 = true
            
            // Invoke API
            self.urlSession.dataTask(with: URL(string: "https://httpbin.org/anything")!) { (data, response, error) in
                guard let responseData = data, let httpresponse = response as? HTTPURLResponse, error == nil else {
                    self.displayLog("Invoking API failed with unexpected result")
                    return
                }
                
                let responseStr = String(decoding: responseData, as: UTF8.self)
                self.displayLog("Response Data: \(responseStr)")
                self.displayLog("Response Header: \n\(httpresponse.allHeaderFields)")
            }.resume()
        }
    }
    
    
    // MARK: - Helper: Log
    
    func displayLog(_ text: String) {
        DispatchQueue.main.async {
            guard let textView = self.loggingView else {
                return
            }
            self.loggingView?.text = textView.text + "\(text)\n"
        }
    }
    
    
    func displayCurrentConfig() {
      if !useDiscoveryURL {
        guard let path = Bundle.main.path(forResource: FRAuth.configPlistFileName, ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path) as? [String: Any]  else {
          self.displayLog("No configuration found (config plist file name: \(FRAuth.configPlistFileName)")
          return
        }

        self.displayLog("Current Configuration (\(FRAuth.configPlistFileName).plist): \(config)")
      } else {
        self.displayLog("Current Configuration from discovery URL: \(FRAuth.shared?.options?.optionsDictionary() ?? ["Error displaying configuration":""])")
      }
    }
    
    
    // MARK: - IBAction
    
    @IBAction func invokeAPIButton(sender: UIButton) {
        
        guard let urlStr = urlField?.text, let url = URL(string: urlStr) else {
            return
        }
        
        //  Default Cookie Name for SSO Token in AM
        var cookieName = "iPlanetDirectoryPro"
        
        //  If custom cookie name is defined in configuration file, update the cookie name
        if let path = Bundle.main.path(forResource: FRAuth.configPlistFileName, ofType: "plist"), let config = NSDictionary(contentsOfFile: path) as? [String: Any], let configCookieName = config["forgerock_cookie_name"] as? String {
            cookieName = configCookieName
        }
        
        var request = URLRequest(url: url)
        
        request.setValue("header", forHTTPHeaderField: "x-authenticate-response")
        
        //  TODO: - Change following code as needed for authorization policy, and PEP
        //  Setting SSO Token in the request cookie is expected for Identity Gateway set-up, and where IG is acting as Policy Enforcement Points (PEP)
        request.setValue("\(cookieName)="+(FRSession.currentSession?.sessionToken?.value ?? ""), forHTTPHeaderField: "Cookie")
        //  If custom web application is acting as PEP, and expecting user's authenticated session in other form (such as in URL query param, or request body), set the given SSO Token accordingly
        //  Below line of code is for an agent expecting SSO Token in the header of request with header name being "SSOToken"
        request.setValue((FRSession.currentSession?.sessionToken?.value ?? ""), forHTTPHeaderField: "SSOToken")
        self.urlSession.dataTask(with: request) { (data, response, error) in
            guard let responseData = data, let httpresponse = response as? HTTPURLResponse, error == nil else {
                self.displayLog("Invoking API failed\n\nError: \(String(describing: error))")
                return
            }

            let responseStr = String(decoding: responseData, as: UTF8.self)
            self.displayLog("Response Data: \(responseStr)")
            self.displayLog("Response Header: \n\(httpresponse.allHeaderFields)")
            FRLog.i("Response Data: \(responseStr)")
            FRLog.i("Response Header: \n\(httpresponse.allHeaderFields)")
        }.resume()
    }
    
    
    @IBAction func clearLogBtnClicked(sender: UIButton) {
        DispatchQueue.main.async {
            self.loggingView?.text = ""
        }
    }
    
    
    @IBAction func performAction(sender: UIButton) {
        guard let frAuth = FRAuth.shared else {
            self.displayLog("Invalid SDK State")
            return
        }
        
        switch self.selectedIndex {
        case 0:
            // Login for FRUser
            self.performActionHelperWithUI(auth: frAuth, flowType: .authentication, expectedType: FRUser.self)
            break
        case 1:
            self.performCentralizedLogin()
            break
        case 2:
            // Request user info
            self.getUserInfo()
            break
        case 3:
            // User Logout
            self.logout()
            break
        case 4:
            // Display FRUser.currentUser
            self.displayLog(String(describing: FRUser.currentUser))
            break
        case 5:
            // Invoke API
            self.invokeAPI()
            break
        case 6:
            // Device Information collector
            self.getDeviceInformation()
            break
        case 7:
            // Jailbreak detector
            self.performJailbreakDetector()
            break
        case 8:
            // Get AccessToken from FRUser.currentUser
            self.getAccessTokenFromUser()
            break
        case 9:
            // Force Refresh AccessToken
            self.refreshAccessToken()
            break
        case 10:
            // Login for AccessToken
            self.performActionHelperWithUI(auth: frAuth, flowType: .authentication, expectedType: AccessToken.self)
            break
        case 11:
            // FRSession.authenticate with UI (Token)
            self.performSessionAuthenticate(handleWithUI: true)
            break
        case 12:
            // FRSession.logout
            FRSession.currentSession?.logout()
            break
        case 13:
            // Register a user for FRUser
            self.performActionHelperWithUI(auth: frAuth, flowType: .registration, expectedType: FRUser.self)
            break
        case 14:
            // Register a user for AccessToken
            self.performActionHelperWithUI(auth: frAuth, flowType: .registration, expectedType: AccessToken.self)
            break
        case 15:
            // Login for FRUser without UI
            self.performActionHelper(auth: frAuth, flowType: .authentication, expectedType: FRUser.self)
            break
        case 16:
            // Login for AccessToken without UI
            self.performActionHelper(auth: frAuth, flowType: .authentication, expectedType: AccessToken.self)
            break
        case 17:
            // FRSession.authenticate without UI (Token)
            self.performSessionAuthenticate(handleWithUI: false)
            break
        case 18:
            // Display current Configuration
            self.displayCurrentConfig()
            break
        case 19:
            // Revoke Access Token
            self.revokeAccessToken()
            break
        case 20:
            // List WebAuthn Credentials by rpId
            self.listWebAuthnCredentialsByRpId()
            break
        case 21:
            // List device binding user keys
            self.listUserKeys()
            break
        default:
            break
        }
    }
}


extension ViewController: FRDropDownViewProtocol {
    func selectedItem(index: Int, item: String) {
        self.selectedIndex = index
    }
}

extension UIColor {
    static func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}


//  - MARK: TokenManagementPolicy example
extension ViewController: TokenManagementPolicyDelegate {
    func evaluateTokenRefresh(responseData: Data?, response: URLResponse?, error: Error?) -> Bool {
        var shouldHandle = false
        // refresh token policy will only be enforced when HTTP status code is equal to 401 in this case
        // Developers can define their own policy based on response data, URLResponse, and/or error from the request
        if let thisResponse = response as? HTTPURLResponse, thisResponse.statusCode == 401 {
         
            shouldHandle = true
        }
        return shouldHandle
    }
}

//  - MARK: AuthorizationPolicy example
extension ViewController: AuthorizationPolicyDelegate {
    func onPolicyAdviseReceived(policyAdvice: PolicyAdvice, completion: @escaping FRCompletionResultCallback) {
        DispatchQueue.main.async {
            FRSession.authenticateWithUI(policyAdvice, self) { (token: Token?, error) in
                if let _ = token, error == nil {
                    completion(true)
                }
                else {
                    completion(false)
                }
            }
        }
    }
    
//    func evaluateAuthorizationPolicy(responseData: Data?, response: URLResponse?, error: Error?) -> PolicyAdvice? {
//        // Example to evaluate given response data, and constructs PolicyAdvice object
//        // Following code expects JSON response payload with 'advice' attribute in JSON which contains an array of 'advice' response from AM
//        if let data = responseData, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
//            if let advice = json["advice"], let adviceData = advice.data(using: .utf8), let adviceJSON = try? JSONSerialization.jsonObject(with: adviceData, options: []) as? [[String: Any]], let evalResult = adviceJSON.first, let policyAdvice = PolicyAdvice(json: evalResult) {
//                return policyAdvice
//            }
//        }
//        return nil
//    }
    
//    func updateRequest(originalRequest: URLRequest, txId: String?) -> URLRequest {
//        let mutableRequest = ((originalRequest as NSURLRequest).mutableCopy() as? NSMutableURLRequest)!
//        // Appends given transactionId into header
//        mutableRequest.setValue(txId, forHTTPHeaderField: "transactionId")
//        return mutableRequest as URLRequest
//    }
}

class WebAuthnCredentialsTableViewController: UITableViewController {
    let identifier = "cell"
    var rpId = ""
    var credentialSource: [PublicKeyCredentialSource] = []
    
    init(rpId: String) {
        self.rpId = rpId
        self.credentialSource = FRWebAuthn.loadAllCredentials(by: rpId)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.identifier)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return credentialSource.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.identifier)!
        cell.textLabel?.text = self.credentialSource[indexPath.row].otherUI
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
      if(editingStyle == .delete) {
        FRWebAuthn.deleteCredential(with: self.credentialSource[indexPath.row])
        self.credentialSource = FRWebAuthn.loadAllCredentials(by: self.rpId)
        tableView.reloadData()
       }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Found \(credentialSource.count) WebAuthn Credentials for rpID \"\(self.rpId)\""
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        let deleteAllButton = UIButton()
        deleteAllButton.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 30)
        deleteAllButton.setTitle("Delete All", for: .normal)
        deleteAllButton.setTitleColor(.white, for: .normal)
        deleteAllButton.backgroundColor = .red
        deleteAllButton.addTarget(self, action: #selector(deleteAllAction), for: .touchUpInside)
        
        footerView.addSubview(deleteAllButton)
        return footerView
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 30
    }
    
    @objc func deleteAllAction(sender: UIButton!) {
        let alert = UIAlertController(title: "Delete WebAuthn Credentials",
                                      message: "Are you sure you want to delete all credentials for RpId \"\(self.rpId)\"?",
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (alert: UIAlertAction!) in
            FRWebAuthn.deleteCredentials(by: self.rpId)
            self.credentialSource = FRWebAuthn.loadAllCredentials(by: self.rpId)
            self.tableView.reloadData()
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
}


class UserKeysTableViewController: UITableViewController, ErrorAlertShowing {
    let identifier = "cell"
    let frUserKeys = FRUserKeys()
    var userKeys: [UserKey] = []
    
    init() {
        userKeys = frUserKeys.loadAll()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.identifier)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userKeys.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.identifier)!
        cell.textLabel?.text = "\(self.userKeys[indexPath.row].userName) - \(self.userKeys[indexPath.row].authType)"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
      if(editingStyle == .delete) {
          
          do {
              try frUserKeys.delete(userKey: self.userKeys[indexPath.row], forceDelete: false)
          }
          catch {
              self.showErrorAlert(title: "Delete Remote UserKey", message: error.localizedDescription)
          }
          self.userKeys = frUserKeys.loadAll()
          tableView.reloadData()
       }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Found \(userKeys.count) user key(s)"
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        let deleteAllButton = UIButton()
        deleteAllButton.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 30)
        deleteAllButton.setTitle("Delete All", for: .normal)
        deleteAllButton.setTitleColor(.white, for: .normal)
        deleteAllButton.backgroundColor = .red
        deleteAllButton.addTarget(self, action: #selector(deleteAllAction), for: .touchUpInside)
        
        footerView.addSubview(deleteAllButton)
        return footerView
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 30
    }
    
    @objc func deleteAllAction(sender: UIButton!) {
        let alert = UIAlertController(title: "Delete all user keys?",
                                      message: "Are you sure you want to delete all (\(userKeys.count)) user keys from the device?",
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (alert: UIAlertAction!) in
            for (_, userKey) in self.userKeys.enumerated().reversed()
            {
                do {
                    try self.frUserKeys.delete(userKey: userKey, forceDelete: false)
                }
                catch {
                    self.showErrorAlert(title: "Delete Remote UserKey", message: error.localizedDescription)
                }
            }
            self.userKeys = self.frUserKeys.loadAll()
            self.tableView.reloadData()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
}

protocol ErrorAlertShowing: UIViewController {
    func showErrorAlert(title: String, message: String)
}

extension ErrorAlertShowing {
    func showErrorAlert(title: String, message: String) {
        let errorAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Ok", style: .cancel, handler:nil)
        errorAlert.addAction(cancelAction)
        self.present(errorAlert, animated: true, completion: nil)
    }
}
