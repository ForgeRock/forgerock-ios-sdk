//
//  ViewController.swift
//  FRExample
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuth
import FRUI
import CoreLocation
import QuartzCore

class ViewController: UIViewController {

    // MARK: - Properties
    @IBOutlet weak var loggingView: UITextView?
    @IBOutlet weak var commandField: UIButton?
    @IBOutlet weak var performActionBtn: FRButton?
    @IBOutlet weak var clearLogBtn: FRButton?
    @IBOutlet weak var dropDown: FRDropDownButton?
    
    var selectedIndex: Int = 0
    var primaryColor: UIColor
    var textColor: UIColor
    var invoke401: Bool = false
    var urlSession: URLSession = URLSession.shared
    var loadingView: FRLoadingView = FRLoadingView(size: CGSize(width: 120, height: 120), showDropShadow: true, showDimmedBackground: true, loadingText: "Loading...")
    
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
        
        // Setup loading view
        loadingView.add(inView: self.view)
        
        // Styling
        self.performActionBtn?.backgroundColor = self.primaryColor
        self.performActionBtn?.tintColor = self.textColor
        
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
            "Request UserInfo",
            "User Logout",
            "Get FRUser.currentUser",
            "Invoke API (Token Mgmt)",
            "Collect Device Information",
            "JailbreakDetector.analyze()",
            "FRUser.getAccessToken()",
            "Login with UI (Accesstoken)",
            "Login with UI (Token)",
            "Register User with UI (FRUser)",
            "Register User with UI (Accesstoken)",
            "Register User with UI (Token)",
            "Login without UI (FRUser)",
            "Login without UI (Accesstoken)",
            "Login without UI (Token)",
            "Display Configurations"
        ]
        self.commandField?.setTitle("Login with UI (FRUser)", for: .normal)

        
        // - MARK: Token Management - Example starts
        // Register FRURLProtocol
        URLProtocol.registerClass(FRURLProtocol.self)
        
        // Add URLs for FRAuth SDK to validate
        // All other URLs will be ignored, and FRAuth SDK will not inject Authorization header if request is not within the list
        FRURLProtocol.validatedURLs = [URL(string: "https://httpbin.org/status/401")!, URL(string: "https://httpbin.org/anything")!]
        
        // Define customizable token refresh policy
        FRURLProtocol.refreshTokenPolicy = {(responseData, response, error) in
            var shouldHandle = false
            // refresh token policy will only be enforced when HTTP status code is equal to 401 in this case
            // Developers can define their own policy based on response data, URLResponse, and/or error from the request
            if let thisResponse = response as? HTTPURLResponse, thisResponse.statusCode == 401 {
             
                shouldHandle = true
            }
            return shouldHandle
        }
        
        let config = URLSessionConfiguration.default
        config.protocolClasses = [FRURLProtocol.self]
        self.urlSession = URLSession(configuration: config)
        // - MARK: Token Management - Example ends
        
        // Start SDK
        do {
            try FRAuth.start()
            self.displayLog("FRAuth SDK started using \(FRAuth.configPlistFileName).plist.")
        }
        catch {
            self.displayLog(String(describing: error))
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
                    }
                    else {
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
                        thisCallback.value = textField.text
                        counter += 1
                    }
                    
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
                })
                
                alert.addAction(cancelAction)
                alert.addAction(submitAction)
                
                self.present(alert, animated: true, completion: nil)
            }
        }
        else {
            self.displayLog("\(String(describing: error))")
        }
    }
    
    
    // MARK: - Helper: User Login/Registration
    
    func performActionHelperWithUI<T>(auth: FRAuth, flowType: FRAuthFlowType, expectedType: T) {
        
        if expectedType as AnyObject? === AccessToken.self {
            if flowType == .authentication {
                FRUser.authenticateWithUI(self, completion: { (token: AccessToken?, error) in
                    self.displayLog(token.debugDescription)
                })
            }
            else {
                FRUser.registerWithUI(self, completion: { (token: AccessToken?, error) in
                    self.displayLog(token.debugDescription)
                })
            }
        }
        else if expectedType as AnyObject? === Token.self {
            if flowType == .authentication {
                FRUser.authenticateWithUI(self, completion: { (token: Token?, error) in
                    self.displayLog(token.debugDescription)
                })
            }
            else {
                FRUser.registerWithUI(self, completion: { (token: Token?, error) in
                    self.displayLog(token.debugDescription)
                })
            }
        }
        else if expectedType as AnyObject? === FRUser.self {
            if flowType == .authentication {
                FRUser.authenticateWithUI(self, completion: { (user: FRUser?, error) in
                    self.displayLog(user.debugDescription)
                })
            }
            else {
                FRUser.registerWithUI(self, completion: { (user: FRUser?, error) in
                    self.displayLog(user.debugDescription)
                })
            }
        }
    }
    
    func performActionHelper<T>(auth: FRAuth, flowType: FRAuthFlowType, expectedType: T) {
        if expectedType as AnyObject as AnyObject? === AccessToken.self {
            auth.next(flowType: flowType) { (result: AccessToken?, node, error) in
                self.handleNode(result, node, error)
            }
        }
        else if expectedType as AnyObject as AnyObject? === Token.self {
            auth.next(flowType: flowType) { (result: Token?, node, error) in
                self.handleNode(result, node, error)
            }
        }
        else if expectedType as AnyObject as AnyObject? === FRUser.self {
            auth.next(flowType: flowType) { (result: FRUser?, node, error) in
                self.handleNode(result, node, error)
            }
        }
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
        user.logout()
        self.displayLog("Logout completed")
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
        guard let path = Bundle.main.path(forResource: FRAuth.configPlistFileName, ofType: "plist"),
            let config = NSDictionary(contentsOfFile: path) as? [String: Any]  else {
                self.displayLog("No configuration found (config plist file name: \(FRAuth.configPlistFileName)")
                return
        }
        
        self.displayLog("Current Configuration (\(FRAuth.configPlistFileName).plist): \(config)")
    }
    
    
    // MARK: - IBAction
    
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
            // Request user info
            self.getUserInfo()
            break
        case 2:
            // User Logout
            self.logout()
            break
        case 3:
            // Display FRUser.currentUser
            self.displayLog(String(describing: FRUser.currentUser))
            break
        case 4:
            // Invoke API
            self.invokeAPI()
            break
        case 5:
            // Device Information collector
            self.getDeviceInformation()
            break
        case 6:
            // Jailbreak detector
            self.performJailbreakDetector()
            break
        case 7:
            // Get AccessToken from FRUser.currentUser
            self.getAccessTokenFromUser()
            break
        case 8:
            // Login for AccessToken
            self.performActionHelperWithUI(auth: frAuth, flowType: .authentication, expectedType: AccessToken.self)
            break
        case 9:
            // Login for SSO Token
            self.performActionHelperWithUI(auth: frAuth, flowType: .authentication, expectedType: Token.self)
            break
        case 10:
            // Register a user for FRUser
            self.performActionHelperWithUI(auth: frAuth, flowType: .registration, expectedType: FRUser.self)
            break
        case 11:
            // Register a user for AccessToken
            self.performActionHelperWithUI(auth: frAuth, flowType: .registration, expectedType: AccessToken.self)
            break
        case 12:
            // Register a user for Token
            self.performActionHelperWithUI(auth: frAuth, flowType: .registration, expectedType: Token.self)
            break
        case 13:
            // Login for FRUser without UI
            self.performActionHelper(auth: frAuth, flowType: .authentication, expectedType: FRUser.self)
            break
        case 14:
            // Login for AccessToken without UI
            self.performActionHelper(auth: frAuth, flowType: .authentication, expectedType: AccessToken.self)
            break
        case 15:
            // Login for Token without UI
            self.performActionHelper(auth: frAuth, flowType: .authentication, expectedType: Token.self)
            break
        case 16:
            // Display current Configuration
            self.displayCurrentConfig()
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
