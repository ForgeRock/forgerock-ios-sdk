// 
//  FRSession.swift
//  FRAuth
//
//  Copyright (c) 2020-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation


/// FRSession represents a session authenticated by AM's Authentication Tree
@objc public class FRSession: NSObject {
    
    //  MARK: - Properties
    
    /**
     Singleton instance represents currently authenticated session.
     
     ## Note ##
     If SDK has not been started using *FRAuth.start()*, *FRSession.currentSession* returns nil even if  session has previously authenticated, and valid.
     When Session Token does not exist in Keychain Service, *FRSession.currentSession* also returns nil even if SDK has properly started.
     */
    @objc
    public static var currentSession: FRSession? {
        
        get {
            if let staticSession = _staticSession {
                return staticSession
            }
            else if let frAuth = FRAuth.shared, let _ = frAuth.keychainManager.getSSOToken() {
                FRLog.v("FRSession retrieved from SessionManager")
                _staticSession = FRSession()
                
                return _staticSession
            }
            
            FRLog.w("Invalid SDK State; SDK is not initialized or Session Token does not exist")
            return nil
        }
    }
    /// Static property of current FRSession object
    static var _staticSession: FRSession? = nil
    
    /// Session Token object
    @objc
    public var sessionToken: Token? {
        get {
            if let frAuth = FRAuth.shared, let sessionToken = frAuth.keychainManager.getSSOToken() {
                return sessionToken
            }
            
            return nil
        }
    }
    
    
    //  MARK: - Authenticate
    
    /// Invokes /authenticate endpoint in AM to go through Authentication Tree flow with given PolicyAdvice information
    /// - Parameter policyAdvice: PolicyAdvice object which contains the information for authorization
    /// - Parameter completion: NodeCompletion callback which returns the result of Session Token as Token object
    @objc
    public static func authenticate(policyAdvice: PolicyAdvice, completion:@escaping NodeCompletion<Token>) {
        
        if let frAuth = FRAuth.shared {
            FRLog.v("Initiating FRSession authenticate process")
            frAuth.next(authIndexValue: policyAdvice.authIndexValue, authIndexType: policyAdvice.authIndexType) { (token: Token?, node, error) in
                completion(token, node, error)
            }
        }
        else {
            FRLog.w("Invalid SDK State")
            completion(nil, nil, ConfigError.invalidSDKState)
        }
    }
    
    
    /// Invokes /authenticate endpoint in AM to go through Authentication Tree flow with specified authIndexValue and authIndexType; authIndexType is an optional parameter defaulted to 'service' if not defined
    /// - Parameter authIndexValue: authIndexValue; Authentication Tree name value in String
    /// - Parameter authIndexType: authIndexType; Authentication Tree type value in String
    /// - Parameter completion: NodeCompletion callback which returns the result of Session Token as Token object
    @objc
    public static func authenticate(authIndexValue: String, authIndexType: String = "service", completion:@escaping NodeCompletion<Token>) {
        
        if let frAuth = FRAuth.shared {
            FRLog.v("Initiating FRSession authenticate process")
            frAuth.next(authIndexValue: authIndexValue, authIndexType: authIndexType) { (token: Token?, node, error) in
                completion(token, node, error)
            }
        }
        else {
            FRLog.w("Invalid SDK State")
            completion(nil, nil, ConfigError.invalidSDKState)
        }
    }
    
    
    /// Invokes /authenticate endpoint in AM to go through Authentication Tree flow with  `resumeURI` and `suspendedId` to resume Authentication Tree flow.
    /// - Parameters:
    ///   - resumeURI: Resume URI received in Email from Suspend Email Node; URI **must** contain `suspendedId` in URL query parameter
    ///   - completion: NodeCompletion callback which returns the result of Session Token as Token object
    @objc public static func authenticate(resumeURI: URL, completion:@escaping NodeCompletion<Token>) {
        if let frAuth = FRAuth.shared {
            FRLog.v("Initiating FRSession authenticate process with resumeURI")
            if let suspendedId = resumeURI.valueOf("suspendedId") {
                frAuth.next(suspendedId: suspendedId) { (token: Token?, node, error) in
                    completion(token, node, error)
                }
            }
            else {
                FRLog.w("Invalid resumeURI for missing suspendedId")
                completion(nil, nil, AuthError.invalidResumeURI("suspendedId"))
            }
        }
        else {
            FRLog.w("Invalid SDK State")
            completion(nil, nil, ConfigError.invalidSDKState)
        }
    }
    
    
    //  MARK: - Logout
    /// Invalidates Session Token using AM's REST API
    @objc
    public func logout() {
        
        if let frAuth = FRAuth.shared {
            
            FRLog.i("Clearing Session Token")
            
            // Revoke Session Token
            frAuth.sessionManager.revokeSSOToken()
            // Clear currentSession
            FRSession._staticSession = nil
        }
        else {
            FRLog.w("Invalid SDK State")
        }
    }
    
    
    //  MARK: - Objective-C Compatibility
    @objc(authenticateWithAuthIndexValue:authIndexType:completion:)
    @available(swift, obsoleted: 1.0)
    public func authenticate(authIndexValue: String, authIndexType: String, completion:@escaping NodeCompletion<Token>) {
        FRSession.authenticate(authIndexValue: authIndexValue, authIndexType: authIndexType) { (token: Token?, node, error) in
            completion(token, node, error)
        }
    }
}
