// 
//  IdPCallback.swift
//  FRAuth
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import UIKit


/**
 IdPCallback is a representation of `Social Provider Handler Node` in AM when `Client Type` option specified as `NATIVE` (only available in AM 7.1 and above)
 */
public class IdPCallback: MultipleValuesCallback {
    
    //  MARK: - Properties
    
    /// Selected identity provider client information
    public var idpClient: IdPClient
    /// Token type input key in callback response
    var tokenTypeKey: String
    /// Token input key in callback response
    var tokenKey: String
    /// IdPHandler to handle authorization flow against the identity provider
    var idpHandler: IdPHandler?

    
    //  MARK: - Init
    
    /// Designated initialization method for IdPCallback
    /// - Parameter json: JSON object of SelectIdPCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    public required init(json: [String : Any]) throws {
        
        guard let callbackType = json["type"] as? String else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        guard let outputs = json["output"] as? [[String: Any]], let inputs = json["input"] as? [[String: Any]] else {
                throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        var providerValue: String?
        var clientIdValue: String?
        var redirectUriValue: String?
        var scopeValues: [String]?
        var nonceValue: String?
        var acrValues: [String]?
        var requestValue: String?
        var requestUriValue: String?
        
        for output in outputs {
            if let outputName = output["name"] as? String, outputName == "provider", let outputValue = output["value"] as? String {
                providerValue = outputValue
            }
            else if let outputName = output["name"] as? String, outputName == "clientId", let outputValue = output["value"] as? String {
                clientIdValue = outputValue
            }
            else if let outputName = output["name"] as? String, outputName == "redirectUri", let outputValue = output["value"] as? String {
                redirectUriValue = outputValue
            }
            else if let outputName = output["name"] as? String, outputName == "nonce", let outputValue = output["value"] as? String {
                nonceValue = outputValue
            }
            else if let outputName = output["name"] as? String, outputName == "scopes", let outputValue = output["value"] as? [String] {
                scopeValues = outputValue
            }
            else if let outputName = output["name"] as? String, outputName == "acrValues", let outputValue = output["value"] as? [String] {
                acrValues = outputValue
            }
            else if let outputName = output["name"] as? String, outputName == "request", let outputValue = output["value"] as? String {
                requestValue = outputValue
            }
            else if let outputName = output["name"] as? String, outputName == "requestUri", let outputValue = output["value"] as? String {
                requestUriValue = outputValue
            }
        }

        guard let provider = providerValue else {
            throw AuthError.invalidCallbackResponse("Missing provider value")
        }
        guard let clientId = clientIdValue else {
            throw AuthError.invalidCallbackResponse("Missing client_id value")
        }
        guard let redirect_uri = redirectUriValue else {
            throw AuthError.invalidCallbackResponse("Missing redirect_uri value")
        }


        self.tokenKey = ""
        self.tokenTypeKey = ""
        for input in inputs {
            if let name = input["name"] as? String, name.hasSuffix("token") {
                self.tokenKey = name
            } else if let name = input["name"] as? String, name.hasSuffix("token_type") {
                self.tokenTypeKey = name
            }
        }

        self.idpClient = IdPClient(provider: provider, clientId: clientId, redirectUri: redirect_uri, scopes: scopeValues, nonce: nonceValue, acrValues: acrValues, request: requestValue, requestUri: requestUriValue)
        
        try super.init(json: json)
        self.type = callbackType
        self.response = json
    }
    
    
    //  MARK: - Public
    
    /// Builds input response for callback
    /// - Returns: JSON value for callback
    open override func buildResponse() -> [String : Any] {
        var responsePayload = self.response
        
        var input: [[String: Any]] = []
        for (key, val) in self.inputValues {
            input.append(["name": key, "value": val])
        }
        responsePayload["input"] = input
        return responsePayload
    }
    
    
    //  MARK: - Sign-in
    
    /// Signs-in with selected Identity Provider using `IdPHandler` protocol; if `IdPHandler` is not provided, SDK will use default implementation of `IdPHandler` for `google`, `facebook`, and `apple` based on `IdPClient`'s `provider` value.
    ///
    /// Note: `signIn()` method automatically sets `token` and `tokenType` values if provided using `.setToken()`, and `.setTokenType()` methods.
    ///
    /// - Parameters:
    ///   - handler: Optional `IdPHandler` instance to perform social login; if not provided, SDK automatically selects the default `IdPHandler` implementation based on `IdPClient.provider` value (`google`, `facebook`, and `apple`; case insensitive)
    ///   - presentingViewController: Currently presenting `UIViewController` to present modal view for authorization using provider's SDK. For certain providers, `UIViewController` **must be** presented.
    ///   - completion: Completion callback to notify the result
    public func signIn(handler: IdPHandler? = nil, presentingViewController: UIViewController? = nil, completion: @escaping SocialLoginCompletionCallback) {
        
        //  Keep the handler
        self.idpHandler = handler
        
        //  If IdPHandler is not passed in as parameter, try to get default implementation
        if self.idpHandler == nil, let defaultHandler = self.getDefaultIdPHandler(provider: self.idpClient.provider) {
            self.idpHandler = defaultHandler
        }
        
        //  If no handler is passed in as parameter, and no default handler implementation found, throw an exception
        guard var handler = self.idpHandler else {
            FRLog.e("Missing handler; given provider (\(self.idpClient.provider)) does not match with any of default IdPHandler implementation, and no IdPHandler is passed into IdPCallback.signIn.")
            completion(nil, nil, SocialLoginError.missingIdPHandler)
            return
        }
        
        handler.presentingViewController = presentingViewController
        handler.signIn(idpClient: self.idpClient) { (token, tokenType, error) in
            
            if let token = token, let tokenType = tokenType {
                self.setToken(token)
                self.setTokenType(tokenType)
                FRLog.v("Credentials received - Token Type: \(tokenType) from \(self.idpClient.provider)")
            }
            
            completion(token, tokenType, error)
        }
    }
    
    
    //  MARK: - Private
    
    /// Retrieves default `IdPHandler` implementation based on the `IdPClient.provider` value
    /// - Parameter provider: String value of `IdPClient.provider`
    /// - Returns: `IdPHandler` implementation for the given provider
    func getDefaultIdPHandler(provider: String) -> IdPHandler? {
        var idpHandler: IdPHandler?
        if provider.lowercased().contains("apple") {
            idpHandler = AppleSignInHandler()
        }
        else if provider.lowercased().contains("google") {
            if let c: NSObject.Type = NSClassFromString("FRGoogleSignIn.GoogleSignInHandler") as? NSObject.Type, let thisHandler = c.init() as? IdPHandler {
                idpHandler = thisHandler
            }
        }
        else if provider.lowercased().contains("facebook") {
            if let c: NSObject.Type = NSClassFromString("FRFacebookSignIn.FacebookSignInHandler") as? NSObject.Type, let thisHandler = c.init() as? IdPHandler {
                idpHandler = thisHandler
            }
        }
        return idpHandler
    }
    
    
    //  MARK: - Set values
    
    /// Sets `token_type` value in callback response
    /// - Parameter tokenType: String value of `token_type`; can be either one of `id_token`, `access_token`, or `authorization_code`
    public func setTokenType(_ tokenType: String) {
        self.inputValues[self.tokenTypeKey] = tokenType
    }
    
    
    /// Sets `token` value in callback response
    /// - Parameter token: String value of obtained credentials from the provider
    public func setToken(_ token: String) {
        self.inputValues[self.tokenKey] = token
    }
}
