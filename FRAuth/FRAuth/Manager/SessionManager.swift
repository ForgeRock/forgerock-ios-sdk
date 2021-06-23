//
//  SessionManager.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRCore

/// SessionManager is a representation of management class for FRAuth's managing session
class SessionManager: NSObject {
    
    //  MARK: - Properties
    
    /// KeychainManager responsible for Keychain Service activities
    var keychainManager: KeychainManager
    /// ServerConfig instance of SessionManager
    let serverConfig: ServerConfig
    /// Boolean representation of whether SSO is enabled or not; evaluated with Shared Keychain Access Group
    var isSSOEnabled: Bool {
        get {
            return self.keychainManager.isSharedKeychainAccessible
        }
    }
    
    /// Singletone object of SessionManager
    static var currentManager: SessionManager? {
        get {
            if let frAuth = FRAuth.shared {
                return frAuth.sessionManager
            }
            
            return nil
        }
    }
    
    
    //  MARK: - Init
    
    /// Initializes SessionManager object with KeychainManager, and ServerConfig instances
    /// - Parameter keychainManager: KeychainManager class responsible for Keychain Service
    /// - Parameter serverConfig: ServerConfig that contains AM server information
    init(keychainManager: KeychainManager, serverConfig: ServerConfig) {
        self.keychainManager = keychainManager
        self.serverConfig = serverConfig
    }
    
        
    //  MARK: - SSO TOken
    
    /// Revokes currently authenticated and stored SSO Token and removes it from Keychain Service
    func revokeSSOToken() -> Void {

        if let ssoToken = self.keychainManager.getSSOToken() {
            FRLog.v("Invalidating SSO Token")
            var parameter: [String: String] = [:]
            parameter[OpenAM.tokenId] = ssoToken.value
            var header: [String: String] = [:]
            header[self.serverConfig.cookieName] = ssoToken.value
            
            //  AM 6.5.2 - 7.0.0
            //
            //  Endpoint: /json/realms/sessions
            //  API Version: resource=3.1
            
            header[OpenAM.acceptAPIVersion] = OpenAM.apiResource31
            var urlParam: [String: String] = [:]
            urlParam[OpenAM.action] = OpenAM.logout

            // Deletes SSO token from Keychain Service
            self.keychainManager.setSSOToken(ssoToken: nil)
            
            // Deletes all Cookie from Cookie Store
            FRLog.i("Deleting all cookies from Cookie Store as invalidating Session Token.")
            self.keychainManager.cookieStore.deleteAll()
            
            let request = Request(url: self.serverConfig.sessionURL, method: .POST, headers: header, bodyParams: parameter, urlParams: urlParam, requestType: .json, responseType: .json, timeoutInterval: self.serverConfig.timeout)
            FRRestClient.invoke(request: request, action: Action(type: .LOGOUT)) { (result) in
                switch result {
                case .success( _, _ ):
                    FRLog.v("SSO Token was successfully revoked")
                    break
                case .failure(let error):
                    FRLog.w("SSO Token revoke request failed: \(error.localizedDescription)")
                    break
                }
            }
        }
        else {
            FRLog.w("Trying to revoke SSO Token, no SSO Token found")
        }
    }
}
