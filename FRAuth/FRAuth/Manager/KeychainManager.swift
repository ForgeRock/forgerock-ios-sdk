//
//  KeychainManager.swift
//  FRAuth
//
//  Copyright (c) 2019 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRCore

/// KeychainManager is responsible to manage all Keychain Services maintained and controlled by SDK
struct KeychainManager {
    
    //  MARK: - Constants
    
    /// Keychain Service types for all storages in SDK
    enum KeychainStoreType: String {
        case local = ".local"
        case shared = ".shared"
        case cookie = ".cookie"
        case deviceIdentifier = "com.forgerock.ios.deviceIdentifierService"
    }
    
    /// Storage key for credentials
    enum StorageKey: String {
        case accessToken = "access_token"
        case ssoToken = "sso_token"
        case primaryService = "primaryService"
        case primaryServiceEncrypted = "primaryService-encrypted"
        case successUrl = "successUrl"
        case realm = "realm"
    }
    
    /// String constant for SecuredKey's application tag
    let securedKeyTag: String = "com.forgerock.ios.securedKey.identifier"
    /// String constant for default service
    let defaultService: String = "com.forgerock.ios.keychainservice"
    /// String constant for default bundle identifier
    let defaultBundleIdentifier: String = "com.forgerock.ios.sdk"
    
    
    //  MARK: - Properties
    
    /// String value of currently designated server host to create a unique storage identifier
    var currentService: String
    /// String value of Access Group for the application(s)
    var accessGroup: String?
    /// Private Keychain Service storage (local)
    var privateStore: KeychainService
    /// Shared Keychain Service storage (shared); shared across all applications with same Access Group and within same Apple Developer Program
    var sharedStore: KeychainService
    /// Cookie Keychain Service storage (shared); shared across all applications with same Access Group and within same Apple Developer Program
    var cookieStore: KeychainService
    /// Device Identifier Keychain Service storage (shared); shared across all applications with same Access Group and within same Apple Developer Program
    var deviceIdentifierStore: KeychainService
    /// Primary Service Keychain Service storage (local); to keep track of currently designated server host to identify the storage
    var primaryServiceStore: KeychainService
    /// Boolean indicator whether or not shared Keychain Service is accessible
    var isSharedKeychainAccessible: Bool = false
    /// SecuredKey object that is used for encrypting/decrypting data in Keychain Service
    var securedKey: SecuredKey?
    
    
    //  MARK: - Init
    
    /// Initializes KeychainManager instance
    /// - Parameter baseUrl: Base URL of designated server host to uniquely identify storage identifier
    /// - Parameter accessGroup: AccessGroup as defined in Application Project's Capabilities tab
    public init?(baseUrl: String, accessGroup: String? = nil) throws {
        
        // Define currentService based on primary server
        let service = self.defaultService
        let currentService = baseUrl + "/" + service
        self.primaryServiceStore = KeychainService(service: service)
        guard var appBundleIdentifier = Bundle.main.bundleIdentifier else {
            throw ConfigError.invalidConfiguration("Bundle Identifier is missing")
        }
        appBundleIdentifier = "-" + appBundleIdentifier
        
        if let accessGroup = accessGroup {
            // If Access Group was provided, construct KeychainService with Access Group
            
            // Validate whether given Access Group is accessible or not
            if !KeychainService.validateAccessGroup(service: currentService, accessGroup: accessGroup) {
                throw ConfigError.invalidAccessGroup(accessGroup)
            }
            
            var validatedAccessGroup = accessGroup
            if let appleTeamId = KeychainService.getAppleTeamId(), !accessGroup.hasPrefix(appleTeamId) {
                // If Apple TeamId prefix is found, and accessGroup provided doesn't contain, append it
                validatedAccessGroup = appleTeamId + "." + accessGroup
            }
            self.accessGroup = validatedAccessGroup
        }
        
        
        // Create SecuredKey if available
        if let securedKey = SecuredKey(applicationTag: self.securedKeyTag, accessGroup: self.accessGroup, accessibility: self.primaryServiceStore.options.accessibility) {
            self.securedKey = securedKey
        }
        
        if self.primaryServiceStore.getString(StorageKey.primaryService.rawValue) == nil {
            // If there is no previous primaryService, create one
            FRLog.i("Creating primary keychain service dedicated to \(baseUrl)")
            self.primaryServiceStore.set(currentService, key: StorageKey.primaryService.rawValue)
            
            // If SecuredKey exsits, stored encrypted 'currentService' string
            if let securedKey = self.securedKey, let stringData = currentService.data(using: .utf8), let encryptedData = securedKey.encrypt(data: stringData) {
                self.primaryServiceStore.set(encryptedData, key: StorageKey.primaryServiceEncrypted.rawValue)
            }
        } else if let previousService = self.primaryServiceStore.getString(StorageKey.primaryService.rawValue), currentService != previousService {
            // If primaryService currently stored is different from what's passed through parameter
            FRLog.i("Detected different primary server URL; clearing credentials for previous server")
            KeychainManager.clearAllKeychainStore(service: previousService, accessGroup: accessGroup)
            
            FRLog.i("Updating primary keychain service dedicated to \(baseUrl)")
            self.primaryServiceStore.set(currentService, key: StorageKey.primaryService.rawValue)
            // If SecuredKey exsits, stored encrypted 'currentService' string
            if let securedKey = self.securedKey, let stringData = currentService.data(using: .utf8), let encryptedData = securedKey.encrypt(data: stringData) {
                self.primaryServiceStore.set(encryptedData, key: StorageKey.primaryServiceEncrypted.rawValue)
            }
        }
        
        self.currentService = currentService
        
        if let accessGroup = accessGroup {
            self.privateStore = KeychainService(service: currentService + appBundleIdentifier + KeychainStoreType.local.rawValue, securedKey: self.securedKey)
            self.sharedStore = KeychainService(service: currentService + KeychainStoreType.shared.rawValue, accessGroup: accessGroup, securedKey: self.securedKey)
            self.cookieStore = KeychainService(service: currentService + KeychainStoreType.cookie.rawValue, accessGroup: accessGroup, securedKey: self.securedKey)
            
            // Device Identifier Migration
            var optionOld = KeychainOptions(service: KeychainStoreType.deviceIdentifier.rawValue, accessGroup: accessGroup)
            optionOld.accessibility = .alwaysThisDeviceOnly
            let previousService = KeychainService(options: optionOld, securedKey: self.securedKey)
            let oldIdentifier = previousService.getString(FRDeviceIdentifier.identifierKeychainServiceKey)
            if oldIdentifier != nil {
                previousService.deleteAll()
                // If old identifier exists, migrate it to new KeychainService
                // Constructs Device Identifier storage with specific Keychain Options
                var option = KeychainOptions(service: KeychainStoreType.deviceIdentifier.rawValue, accessGroup: accessGroup)
                option.accessibility = .afterFirstUnlockThisDeviceOnly
                self.deviceIdentifierStore = KeychainService(options: option, securedKey: self.securedKey)
                self.deviceIdentifierStore.set(oldIdentifier!, key: FRDeviceIdentifier.identifierKeychainServiceKey)
            } else {
                var option = KeychainOptions(service: KeychainStoreType.deviceIdentifier.rawValue, accessGroup: accessGroup)
                option.accessibility = .afterFirstUnlockThisDeviceOnly
                self.deviceIdentifierStore = KeychainService(options: option, securedKey: self.securedKey)
            }
            
            self.isSharedKeychainAccessible = true
        }
        else {
            // If Access Group is not provided, construct KeychainService without Access Group
            self.privateStore = KeychainService(service: currentService + appBundleIdentifier + KeychainStoreType.local.rawValue, securedKey: self.securedKey)
            self.sharedStore = KeychainService(service: currentService + appBundleIdentifier + KeychainStoreType.shared.rawValue, securedKey: self.securedKey)
            self.cookieStore = KeychainService(service: currentService + appBundleIdentifier + KeychainStoreType.cookie.rawValue, securedKey: self.securedKey)
            
            // Device Identifier Migration
            var optionOld = KeychainOptions(service: KeychainStoreType.deviceIdentifier.rawValue)
            optionOld.accessibility = .alwaysThisDeviceOnly
            let previousService = KeychainService(options: optionOld, securedKey: self.securedKey)
            let oldIdentifier = previousService.getString(FRDeviceIdentifier.identifierKeychainServiceKey)
            if oldIdentifier != nil {
                previousService.deleteAll()
                // If old identifier exists, migrate it to new KeychainService
                // Constructs Device Identifier storage with specific Keychain Options
                var option = KeychainOptions(service: KeychainStoreType.deviceIdentifier.rawValue)
                option.accessibility = .afterFirstUnlockThisDeviceOnly
                self.deviceIdentifierStore = KeychainService(options: option, securedKey: self.securedKey)
                self.deviceIdentifierStore.set(oldIdentifier!, key: FRDeviceIdentifier.identifierKeychainServiceKey)
            } else {
                var option = KeychainOptions(service: KeychainStoreType.deviceIdentifier.rawValue)
                option.accessibility = .afterFirstUnlockThisDeviceOnly
                self.deviceIdentifierStore = KeychainService(options: option, securedKey: self.securedKey)
            }
        }
    }
    
    //  MARK: - SSO Token
    
    /// Returns current session's Token object that represents SSO Token
    func getSSOToken() -> Token? {
        if let ssoTokenString = self.sharedStore.getString(StorageKey.ssoToken.rawValue) {
            let successUrl = self.sharedStore.getString(StorageKey.successUrl.rawValue) ?? ""
            let realm = self.sharedStore.getString(StorageKey.realm.rawValue) ?? ""
            return Token(ssoTokenString, successUrl: successUrl, realm: realm)
        }
        else {
            return nil
        }
    }
    
    
    /// Stores SSOToken into designated Keychain Service, or removes SSOToken when nil
    /// - Parameter ssoToken: Token object
    /// - Returns: Boolean result of operation
    @discardableResult func setSSOToken(ssoToken: Token?) -> Bool {
        if let token = ssoToken {
            return self.sharedStore.set(token.value, key: StorageKey.ssoToken.rawValue)
            && self.sharedStore.set(token.successUrl, key: StorageKey.successUrl.rawValue)
            && self.sharedStore.set(token.realm, key: StorageKey.realm.rawValue)
        }
        else {
            return self.sharedStore.delete(StorageKey.ssoToken.rawValue)
            && self.sharedStore.delete(StorageKey.successUrl.rawValue)
            && self.sharedStore.delete(StorageKey.realm.rawValue)
        }
    }
    
    
    //  MARK: - AccessToken
    
    /// Stores AccessToken into designated Keychain Service, or removes AccessToken when nil
    /// - Parameter token: AccessToken object
    /// - Throws: `TokenError`
    /// - Returns: Boolean result of operation
    @discardableResult func setAccessToken(token: AccessToken?) throws -> Bool {
        if let thisToken = token {
            do {
                let tokenData = try NSKeyedArchiver.archivedData(withRootObject: thisToken, requiringSecureCoding: true)
                return self.privateStore.set(tokenData, key: StorageKey.accessToken.rawValue)
            }
            catch {
                throw TokenError.failToParseToken(error.localizedDescription)
            }
        }
        else {
            return self.privateStore.delete(StorageKey.accessToken.rawValue)
        }
    }
    
    
    /// Retrieves AccessToken object from the Keychain Service
    /// - Throws: `TokenError`
    /// - Returns: AccessToken object if exists
    func getAccessToken() throws -> AccessToken? {
        if let tokenData = self.privateStore.getData(StorageKey.accessToken.rawValue) {
            do {
                let token = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [AccessToken.self, Token.self], from: tokenData) as? AccessToken
                return token
            }
            catch {
                throw TokenError.failToParseToken(error.localizedDescription)
            }
        }
        return nil
    }
    
    //  MARK: - Session Token Handling
    
    /// Handles a newly received SSO token from an authentication journey, managing token mismatch scenarios.
    ///
    /// When a new SSO token is received via a journey, the behavior depends on the current state:
    /// - **Empty `newToken.value`** (e.g. a passthrough or `NoSession`-flagged journey that returns no
    ///   session token): treated as a no-op. Existing stored credentials (SSO token + OAuth2 tokens)
    ///   are preserved; the empty token is forwarded to the completion so the journey result is still
    ///   surfaced to the caller.
    /// - **No existing SSO token AND no access token** (fresh state): stores the new SSO token.
    /// - **No existing SSO token but an access token exists** (e.g. user previously authenticated via
    ///   Centralized Login / OIDC browser flow): treats this as a session change. Revokes the existing
    ///   OAuth2 token set on the server, stores the new SSO token, then calls completion. This prevents
    ///   the SDK from holding stale OAuth2 tokens for a different user/session than the cookies the SDK
    ///   will subsequently send to AM.
    /// - **Existing SSO token matches the new one**: stores the new token (no-op effectively).
    /// - **Existing SSO token mismatches the new one** (with access token present): revokes the old SSO
    ///   token on the server, revokes OAuth2 tokens, stores the new SSO token, then calls completion.
    ///
    /// - Important: A consumer who deliberately uses `FRSession.authenticate` for a step-up of the
    ///   *same* user after Centralized Login will lose their existing access token as a side-effect of
    ///   this safety behavior. To obtain a new OAuth2 token set after the journey completes, call
    ///   `FRUser.currentUser?.getAccessToken(...)`, which exchanges the newly stored SSO token for a
    ///   fresh OAuth2 token set.
    ///
    /// - Parameters:
    ///   - newToken: The newly received SSO `Token` from the journey.
    ///   - tokenManager: Optional `TokenManager` for revoking OAuth2 tokens.
    ///   - completion: Callback invoked with the new token once all cleanup is done.
    func handleSessionToken(_ newToken: Token, tokenManager: TokenManager?, completion: @escaping NodeCompletion<Token>) {
        // Case 0: The journey returned an empty token (e.g. passthrough / NoSession journey).
        // Preserve any existing stored credentials and surface the empty token to the caller.
        guard !newToken.value.isEmpty else {
            FRLog.i("Received an empty SSO Token from the journey (e.g. passthrough or NoSession); preserving existing stored credentials.")
            completion(newToken, nil, nil)
            return
        }
        
        let currentSessionToken = self.getSSOToken()
        let existingAccessToken = try? self.getAccessToken()
        
        // Case 1: No existing SSO token.
        if currentSessionToken == nil {
            guard existingAccessToken != nil else {
                // Fresh state — nothing to protect, just store the new SSO token.
                self.setSSOToken(ssoToken: newToken)
                completion(newToken, nil, nil)
                return
            }
            
            // Centralized Login state: an access token exists but no SSO token. The journey has
            // produced a new SSO token (possibly for a different user). Revoke the stale OAuth2
            // token set so the SDK does not return tokens that disagree with the SSO cookies AM
            // will now associate with the SDK.
            FRLog.w("SDK identified a new Session Token from a journey while an access token from a previous (non-journey) authentication exists; revoking old OAuth2 token set to avoid stale credentials.")
            self.revokeOAuth2AndStore(newToken: newToken, tokenManager: tokenManager, completion: completion)
            return
        }
        
        // Case 2: Existing SSO token mismatches and an access token exists — revoke old SSO + OAuth2.
        if let _ = existingAccessToken, newToken.value != currentSessionToken!.value {
            FRLog.w("SDK identified existing Session Token (\(currentSessionToken!.value)) and received Session Token (\(newToken.value))'s mismatch; revoking old OAuth2 token set.")
            
            // Revoke the old SSO token on the server (fire-and-forget; local cleanup is immediate)
            SessionManager.currentManager?.revokeSSOToken()
            self.revokeOAuth2AndStore(newToken: newToken, tokenManager: tokenManager, completion: completion)
            return
        }
        
        // Case 3: Existing SSO token mismatches and no access token exists — revoke old SSO and fall through to Case 4.
        if newToken.value != currentSessionToken!.value {
            FRLog.w("SDK identified existing Session Token (\(currentSessionToken!.value)) and received Session Token (\(newToken.value))'s mismatch; ending old session")
            
            // Revoke the old SSO token on the server (fire-and-forget; local cleanup is immediate)
            SessionManager.currentManager?.revokeSSOToken()
        }
        
        // Case 4: Existing SSO token matches OR no access token to invalidate — just store the new SSO.
        self.setSSOToken(ssoToken: newToken)
        completion(newToken, nil, nil)
    }
    
    
    /// Revokes the currently stored OAuth2 token set (if a `TokenManager` is supplied) and then stores
    /// the supplied new SSO token. Falls back to a synchronous local clear of the access token when no
    /// `TokenManager` is available. The completion is invoked once the new SSO token has been stored.
    private func revokeOAuth2AndStore(newToken: Token, tokenManager: TokenManager?, completion: @escaping NodeCompletion<Token>) {
        if let tokenManager = tokenManager {
            tokenManager.revoke { error in
                if let error = error {
                    FRLog.e("OAuth2 token revocation failed: \(error.localizedDescription)")
                }
                self.setSSOToken(ssoToken: newToken)
                completion(newToken, nil, nil)
            }
            return
        }
        
        FRLog.i("TokenManager is not found; removing OAuth2 token set from storage")
        do {
            try self.setAccessToken(token: nil)
        } catch {
            FRLog.e("Unexpected error while removing AccessToken: \(error.localizedDescription)")
        }
        self.setSSOToken(ssoToken: newToken)
        completion(newToken, nil, nil)
    }
    
    
    //  MARK: - Instance helper methods
    
    /// Validates with current SecuredKey whether or not data can be decrypted as SecuredKey may change by numerous factors
    func validateEncryption() {
        // If SecuredKey is not found, but encrypted data is found, clear all Keychain Service
        if self.securedKey == nil, self.primaryServiceStore.getData(StorageKey.primaryServiceEncrypted.rawValue) != nil {
            FRLog.w("Secured key was not found with encrypted data; clearing credentials from KeychainServices")
            self.primaryServiceStore.delete(StorageKey.primaryServiceEncrypted.rawValue)
            KeychainManager.clearAllKeychainStore(service: currentService, accessGroup: accessGroup)
        }
        // If SecuredKey is found, but no encrypted data is found, clear all Keychain Service
        else if let securedKey = self.securedKey, self.primaryServiceStore.getData(StorageKey.primaryServiceEncrypted.rawValue) == nil {
            FRLog.w("Secured key was found without encrypted data; clearing credentials from KeychainServices")
            KeychainManager.clearAllKeychainStore(service: currentService, accessGroup: accessGroup)
            let encryptedData = securedKey.encrypt(data: currentService.data(using: .utf8)!)
            self.primaryServiceStore.set(encryptedData!, key: StorageKey.primaryServiceEncrypted.rawValue)
        }
        // If SecuredKey is found, and encrypted data is found, validate the data with decryption
        else if let securedKey = self.securedKey, let encryptedData = self.primaryServiceStore.getData(StorageKey.primaryServiceEncrypted.rawValue) {
            
            if let decryptedData = securedKey.decrypt(data: encryptedData) {
                let decryptedString = String(decoding: decryptedData, as: UTF8.self)
                if decryptedString != currentService {
                    FRLog.w("Failed to decrypt data using current SecuredKey; clearing credentials from KeychainServices")
                    KeychainManager.clearAllKeychainStore(service: currentService, accessGroup: accessGroup)
                    let encryptedData = securedKey.encrypt(data: currentService.data(using: .utf8)!)
                    self.primaryServiceStore.set(encryptedData!, key: StorageKey.primaryServiceEncrypted.rawValue)
                }
            }
            else {
                FRLog.w("Failed to decrypt data using current SecuredKey; clearing credentials from KeychainServices")
                KeychainManager.clearAllKeychainStore(service: currentService, accessGroup: accessGroup)
                let encryptedData = securedKey.encrypt(data: currentService.data(using: .utf8)!)
                self.primaryServiceStore.set(encryptedData!, key: StorageKey.primaryServiceEncrypted.rawValue)
            }
        }
    }
    
    
    //  MARK: - static helper methods
    
    /// Clears All (PrivateStore, SharedStore, and CookieStore) Keychain Services with given service identifier and AccessGroup; PrimaryService, and DeviceIdentifier Stores will never be cleared and will always be persisted within the device.
    /// - Parameter service: Service identifier
    /// - Parameter accessGroup: AcessGroup identifier
    static func clearAllKeychainStore(service: String, accessGroup: String?) {
        guard var appBundleIdentifier = Bundle.main.bundleIdentifier else {
            FRLog.e("Bundle Identifier is missing")
            return
        }
        appBundleIdentifier = "-" + appBundleIdentifier
        // Initiate old stores, and delete all items
        let oldPrivateStore = KeychainService(service: service + appBundleIdentifier + KeychainStoreType.local.rawValue)
        oldPrivateStore.deleteAll()
        if let accessGroup = accessGroup, KeychainService.validateAccessGroup(service: service, accessGroup: accessGroup) {
          let oldSharedStore = KeychainService(service: service + KeychainStoreType.shared.rawValue, accessGroup: accessGroup)
          oldSharedStore.deleteAll()
          let oldCookieStore = KeychainService(service: service + KeychainStoreType.cookie.rawValue, accessGroup: accessGroup)
          oldCookieStore.deleteAll()
        }
        else {
          let oldSharedStore = KeychainService(service: service + appBundleIdentifier + KeychainStoreType.shared.rawValue)
          oldSharedStore.deleteAll()
          let oldCookieStore = KeychainService(service: service + appBundleIdentifier + KeychainStoreType.cookie.rawValue)
          oldCookieStore.deleteAll()
        }
    }
}
