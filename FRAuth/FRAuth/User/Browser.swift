// 
//  Browser.swift
//  FRAuth
//
//  Copyright (c) 2020-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore
import AuthenticationServices
import SafariServices


/// BrowserType enum is a representation of type of external user-agent supported in Browser object
@objc public enum BrowserType: Int {
    case nativeBrowserApp = 1
    case sfViewController = 2
    case authSession = 0
}


/// Browser is a representation of external user-agent (using Authentication Service, Native Browser Application, or SFSafariViewController)
@objc(FRBrowser) public class Browser: NSObject {
    
    /// Static shared instance of current Browser object
    @objc public static var currentBrowser: Browser?
    /// Type of external user-agent; Authentication Service, Native Browser App, or SFSafariViewController
    var browserType: BrowserType
    /// Boolean indicator whether or not current Browser object is in progress
    var isInProgress: Bool = false
    /// Root ViewController that is used to display SFSafariViewController or ASWebAuthenticationSession
    var presentingViewController: UIViewController?
    /// OAuth2Client instance to perform token exchange and retrieve OAuth2 client information
    var oAuth2Client: OAuth2Client
    /// KeychainManager instance to manage and persist current session
    var keychainManager: KeychainManager
    /// Custom URL query parameter for /authorize request
    var customParam: [String: String] = [:]
    /// PKCE instance for /authorize request
    var pkce: PKCE
    /// Current external user-agent instance
    var currentSession: Any?
    /// Completion callback for authentication
    var completionCallback: UserCallback?
    
    
    //  MARK: - Init / Lifecycle
    
    /// Prevents init
    private override init() { fatalError("Browser() is prohibited. Use FRUser.browser() to initiate flow") }

    
    /// Constructs Browser object; internal method only, for public interface, it can only be constructed through BrowserBuilder
    /// - Parameters:
    ///   - browserType: BrowserType of /authorize to be invoked
    ///   - oAuth2Client: OAuth2Client instance of current SDK state
    ///   - keychainManager: KeychainManager instance of current SDK state
    ///   - presentingViewController: Presenting ViewController for ASPresentationAnchor
    ///   - customParam: Custom URL Query parameters
    init(_ browserType: BrowserType, _ oAuth2Client: OAuth2Client, _ keychainManager: KeychainManager, _ presentingViewController: UIViewController?, _ customParam: [String: String]? = nil) {
        self.browserType = browserType
        self.presentingViewController = presentingViewController
        self.customParam = customParam ?? [:]
        self.pkce = PKCE()
        self.keychainManager = keychainManager
        self.oAuth2Client = oAuth2Client
    }
    
    
    //  MARK: - Authentication
    
    /// Performs external user-agent login with /authorize request to obtain authorization_code, and exchange with OAuth2 token(s)
    /// - Parameter completion: Completion callback that returns FRUser object on success, or error on failure
    @objc
    public func login(completion: @escaping UserCallback) {
        
        //  Makes sure if the user is already authenticated or not
        if let _ = FRUser.currentUser?.token {
            completion(nil, AuthError.userAlreadyAuthenticated(true))
            return
        }
        
        //  Or make sure that either same Browser instance or other Browser instance is currently running
        if let isInProgress = Browser.currentBrowser?.isInProgress, isInProgress {
            completion(nil, BrowserError.externalUserAgentAuthenticationInProgress)
            return
        }
        else if self.isInProgress == true {
            completion(nil, BrowserError.externalUserAgentAuthenticationInProgress)
            return
        }
        
        // Generate new PKCE
        self.pkce = PKCE()
        // Completion callback
        self.completionCallback = completion
        
        // If /authorize request URL can be constructed based on given information, proceed
        if let url = self.buildAuthorizeRequestURL() {
            if self.browserType == .nativeBrowserApp {
                self.isInProgress = true
                UIApplication.shared.open(url, options: [:]) { (result) in
                    self.isInProgress = result
                    if result {
                        FRLog.v("Opened native browser app for authorization process")
                    }
                    else {
                        completion(nil, BrowserError.externalUserAgentFailure)
                        self.close()
                        self.cleanUp()
                    }
                }
            }
            else if self.browserType == .sfViewController {
                self.isInProgress = self.loginWithSFViewController(url: url, completion: completion)
                if self.isInProgress {
                    FRLog.v("Presented SFSafariViewController for authorization process")
                }
                else {
                    completion(nil, BrowserError.externalUserAgentFailure)
                    self.close()
                    self.cleanUp()
                }
            }
            else {
                if #available(iOS 12.0, *) {
                    self.isInProgress = self.loginWithASWebSession(url: url, completion: completion)
                }
                else if #available(iOS 11.0, *) {
                    self.isInProgress = self.loginWithSFWebSession(url: url, completion: completion)
                }
                else {
                    self.isInProgress = self.loginWithSFViewController(url: url, completion: completion)
                }
                
                if self.isInProgress {
                    FRLog.v("Opened Safari app for authorization process")
                }
                else {
                    completion(nil, BrowserError.externalUserAgentFailure)
                }
            }
        }
        else {
            completion(nil, NetworkError.invalidRequest("failed to generate /authorize request for external user agent"))
        }
    }
    
    
    /// Cancels currently performing authentication process, and closes all current browser session
    @objc
    public func cancel() {
        
        guard self.isInProgress == true else {
            return
        }
        
        if let completionCallback = self.completionCallback {
            completionCallback(nil, BrowserError.externalUserAgentCancelled)
        }
        
        self.close()
        self.cleanUp()
    }
    
    
    /// Cleans up the object for subsequent request
    func cleanUp() {
        self.currentSession = nil
        self.completionCallback = nil
        Browser.currentBrowser = nil
    }
    
    
    /// Closes currently presenting ViewController
    func close() {
        
        if let sfViewController = self.currentSession as? SFSafariViewController {
            FRLog.v("Close called with SFSafariViewController: \(String(describing: self.currentSession))")
            DispatchQueue.main.async {
                sfViewController.dismiss(animated: true, completion: nil)
            }
        }
        
        if #available(iOS 12, *) {
            if let asAuthSession = self.currentSession as? ASWebAuthenticationSession {
                FRLog.v("Close called with iOS 12 or above: \(String(describing: self.currentSession))")
                DispatchQueue.main.async {
                    asAuthSession.cancel()
                }
            }
        }
        
        if #available(iOS 11, *) {
            if let sfAuthSession = self.currentSession as? SFAuthenticationSession {
                FRLog.v("Close called with iOS 11 or above: \(String(describing: self.currentSession))")
                DispatchQueue.main.async {
                    sfAuthSession.cancel()
                }
            }
        }
    }
    
    
    /// Validates if URL is returning from Centralized Login /authorize flow, and exchanges authorization code for OAuth2 token
    ///
    /// **Note:** If `authorization_code` is not found in URL, Browser authentication process will be automatically cancelled.
    ///
    /// - Parameter url: Returning URL
    /// - Returns: Boolean result of whether or not URL contains authorization_code
    @objc static public func validateBrowserLogin(url: URL) -> Bool {
        FRLog.v("URL received: \(url)")
        
        if let viewController = Browser.currentBrowser?.currentSession as? SFSafariViewController {
            FRLog.v("SFSafariViewController is detected; closing SFSafariViewController")
            viewController.dismiss(animated: true, completion: nil)
        }
        
        if let code = url.valueOf("code") {
            FRLog.i("authorization_code is found in URL; exchanging authorization_code for OAuth2 token")
            Browser.currentBrowser?.exchangeAuthCode(code: code)
            return true
        }
        else {
            
            if let completionCallback = Browser.currentBrowser?.completionCallback {
                completionCallback(nil, OAuth2Error.convertOAuth2Error(urlValue: url.absoluteString))
            }
            Browser.currentBrowser?.close()
            Browser.currentBrowser?.cleanUp()
            FRLog.w("authorization_code is not found from URL")
            return false
        }
    }
    
    
    //  MARK: - External User-Agent
    
    /// Performs authentication through /authorize endpoint using ASWebAuthenticationSession
    /// - Parameters:
    ///   - url: URL of /authorize including all URL query parameter
    ///   - completion: Completion callback to nofiy the result
    /// - Returns: Boolean indicator whether or not launching external user-agent was successful
    @available(iOS 12.0, *)
    func loginWithASWebSession(url: URL, completion: @escaping UserCallback) -> Bool {
        let asWebAuthSession = ASWebAuthenticationSession(url: url, callbackURLScheme: self.oAuth2Client.redirectUri.scheme) { (url, error) in

            if let error = error {
                FRLog.e("Failed to complete authorization using ASWebAuthenticationSession: \(error.localizedDescription)")
                completion(nil, error)
                self.close()
                self.cleanUp()
                return
            }
            
            if let authCode = url?.valueOf("code") {
                self.exchangeAuthCode(code: authCode, completion: completion)
            }
            else {
                completion(nil, OAuth2Error.convertOAuth2Error(urlValue: url?.absoluteString))
                self.close()
                self.cleanUp()
            }
        }
        //  Provide Context Provider with given viewController for iOS 13 or above
        if #available(iOS 13.0, *) {
            asWebAuthSession.presentationContextProvider = self
        }
        self.currentSession = asWebAuthSession
        return asWebAuthSession.start()
    }
    
    
    /// Performs authentication through /authorize endpoint using SFAuthenticationsession
    /// - Parameters:
    ///   - url: URL of /authorize including all URL query parameter
    ///   - completion: Completion callback to nofiy the result
    /// - Returns: Boolean indicator whether or not launching external user-agent was successful
    @available(iOS 11.0, *)
    func loginWithSFWebSession(url: URL, completion: @escaping UserCallback) -> Bool {
        let sfAuthSession = SFAuthenticationSession(url: url, callbackURLScheme: self.oAuth2Client.redirectUri.absoluteString) { (url, error) in
        
            if let error = error {
                FRLog.e("Failed to complete authorization using SFAuthenticationSession: \(error.localizedDescription)")
                completion(nil, error)
                self.close()
                self.cleanUp()
                return
            }
            
            if let authCode = url?.valueOf("code") {
                self.exchangeAuthCode(code: authCode, completion: completion)
            }
            else {
                completion(nil, OAuth2Error.convertOAuth2Error(urlValue: url?.absoluteString))
                self.close()
                self.cleanUp()
            }
        }
        self.currentSession = sfAuthSession
        return sfAuthSession.start()
    }
    
    
    /// Performs authentication through /authorize endpoint using SFSafariViewController
    /// - Parameters:
    ///   - url: URL of /authorize including all URL query parameter
    ///   - completion: Completion callback to nofiy the result
    /// - Returns: Boolean indicator whether or not launching external user-agent was successful
    func loginWithSFViewController(url: URL, completion: @escaping UserCallback) -> Bool {
        
        var viewController: SFSafariViewController?
        if #available(iOS 11.0, *) {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true
            viewController = SFSafariViewController(url: url, configuration: config)
            viewController?.delegate = self
        }
        else {
            viewController = SFSafariViewController(url: url)
            viewController?.delegate = self
        }
        self.currentSession = viewController
        if let currentViewController = self.presentingViewController, let sfVC = viewController {
            currentViewController.present(sfVC, animated: true)
            return true
        }
        else {
            FRLog.e("Fail to launch SFSafariViewController; missing presenting ViewController")
            return false
        }
    }
    
    
    //  MARK: - OAuth2
    
    /// Builds /authorize URL based on given OAuth2Client, current PKCE and custom URL query parameters
    /// - Returns: URL object
    func buildAuthorizeRequestURL() -> URL? {
        let request = self.oAuth2Client.buildAuthorizeRequestForExternalAgent(pkce: self.pkce, customParams: self.customParam)
        if let urlRequest = request.build(), let url = urlRequest.url {
            return url
        }
        else {
            return nil
        }
    }
    
    
    /// Exchanges authorization_code for OAuth2 access_token
    /// - Parameters:
    ///   - code: Authorization Code received from /authorize endpoint
    ///   - completion: Completion callback to notify the result
    func exchangeAuthCode(code: String, completion: UserCallback? = nil) {
        
        let completionCallback = completion != nil ? completion : (self.completionCallback != nil ? self.completionCallback! : nil)
        self.oAuth2Client.exchangeToken(code: code, pkce: self.pkce) { (token, error) in

            self.close()
            self.cleanUp()
            
            if let error = error {
                completionCallback?(nil, error)
            }
            else {
                do {
                    try self.keychainManager.setAccessToken(token: token)
                    let user = FRUser(token: token)
                    completionCallback?(user, nil)
                }
                catch {
                    FRLog.e("Unexpected error while stroing AccessToken: \(error.localizedDescription)")
                    completionCallback?(nil, error)
                }
            }
        }
    }
}


//  MARK: - SFSafariViewControllerDelegate
extension Browser: SFSafariViewControllerDelegate {
    
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        FRLog.i("User cancelled the authorization process by closing the window")
        self.cancel()
    }
    
    public func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL) {
        
        FRLog.v("Redirect in SFSafariViewController: \(URL.absoluteString)")
        if URL.absoluteString.hasPrefix(oAuth2Client.redirectUri.absoluteString) {
            FRLog.i("Found matching redirect_uri in SFSafariViewController; closing SFSafariViewController and trying to exchange authorization_code with OAuth2 token(s)")
            controller.dismiss(animated: true, completion: nil)
            
            if let code = URL.valueOf("code") {
                self.exchangeAuthCode(code: code)
            }
            else {
                FRLog.e("Failed to retrieve authorization_code upon redirect_uri; completed redirect: \(URL.absoluteString)")
                if let completionCallback = self.completionCallback {
                    completionCallback(nil, OAuth2Error.convertOAuth2Error(urlValue: URL.absoluteString))
                }
                self.close()
                self.cleanUp()
            }
        }
    }
}


//  MARK: - ASWebAuthenticationPresentationContextProviding
extension Browser: ASWebAuthenticationPresentationContextProviding {
    /// Delegation method for ASWebAuthenticationPresentationContextProviding; only available for iOS 13.0 or above
    @available(iOS 13.0, *)
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let presentingViewController = self.presentingViewController, let window = presentingViewController.view.window {
            return window
        }
        else {
            return ASPresentationAnchor()
        }
    }
}


//  MARK: - BrowserBuilder

/// BrowserBuilder is a builder class for progressive construction of Browser object.
@objc(FRBrowserBuilder)
public class BrowserBuilder: NSObject {
    
    /// Presenting ViewController which will be the root ViewController to display Authentication Service
    var presentingViewController: UIViewController?
    /// Additional URL Query Parameters for /authorize request
    var customParam: [String: String] = [:]
    /// An external user-agent type; default to Authentication Service
    var browserType: BrowserType = .authSession
    /// Current OAuth2Client for /authorize flow
    var oAuth2Client: OAuth2Client
    /// Current KeychainManager to persist OIDC session
    var keychainManager: KeychainManager
    
    
    /// Constructs BrowserBuilder object with OAuth2Client, and SessionManager
    /// - Parameters:
    ///   - oAuth2Client: OAuth2Client to be used for constructing /authorize request
    ///   - sessionManager: KeychainManager to be used to persist user's OIDC sessionn
    init(_ oAuth2Client: OAuth2Client, _ keychainManager: KeychainManager) {
        self.oAuth2Client = oAuth2Client
        self.keychainManager = keychainManager
    }
    
    
    /// Sets BrowserType (an external user-agent) for Browser object; default to .authSession
    /// - Parameter browserType: An external user-agent type to be used for /authorize flow
    /// - Returns: BrowserBuilder object to progressively build Browser object
    @discardableResult @objc(setBrowserType:) public func set(browserType: BrowserType) -> BrowserBuilder {
        self.browserType = browserType
        return self
    }
    
    
    /// Sets presenting ViewController which will be used as ASPresentationAnchor for ASWebAuthenticationSession in iOS 13.0 or above
    /// - Parameter presentingViewController: ViewController that will act as ASPresentationAnchor for ASWebAuthenticationSession
    /// - Returns: BrowserBuilder object to progressively build Browser object
    @discardableResult @objc(setPresentingViewController:) public func set(presentingViewController: UIViewController) -> BrowserBuilder {
        self.presentingViewController = presentingViewController
        return self
    }
    
    
    /// Sets custom URL Query parameters to be added to /authorize request
    /// - Parameters:
    ///   - key: URL Query parameter key
    ///   - value: URL Query parameter value
    /// - Returns: BrowserBuilder object to progressively build Browser object
    @discardableResult @objc(setCustomKey:CustomValue:) public func setCustomParam(key: String, value: String) -> BrowserBuilder {
        customParam[key] = value
        return self
    }
    
    
    /// Completes progressive building of Browser object, and constructs Browser object based on given values
    /// - Returns: Browser object to start authentication
    @objc public func build() -> Browser {
        let browser = Browser(self.browserType, self.oAuth2Client, self.keychainManager, self.presentingViewController, customParam)
        Browser.currentBrowser = browser
        return browser
    }    
}
