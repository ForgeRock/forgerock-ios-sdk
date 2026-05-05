//
//  PebbleBankUtilities.swift
//  UnsummitAuthentication
//
//  Created by George Bafaloukas on 24/07/2023.
//

import UIKit
import FRAuth
import FRCore

class PebbleBankUtilities: NSObject {
    static let usePasskeysIfAvailable = true
    static let biometricsEnabledKey = "BiometricsEnabled"
    static let mainAuthenticationJourney = "Login"
    static let biometricsRegistrationJourney = "BlogWebAuthnRegistration"
    static let biometricsAuthenticationJourney = "BlogWebAuthnAuthentication"
    static let amURL = [AM URL]
    static let cookieName = [COOKIE NAME]
    static let realm = "alpha"
    static let oauthClientId = [CLIENT ID]
    static let oauthRedirectURI = "frauth://com.forgerock.ios.frexample"
    static let oauthScopes = "openid profile email address"
    
    static func frCongiguration() -> FROptions {
        return FROptions(url: self.amURL, realm: self.realm, cookieName: self.cookieName, authServiceName: self.mainAuthenticationJourney, oauthClientId: self.oauthClientId, oauthRedirectUri: self.oauthRedirectURI, oauthScope: self.oauthScopes)
    }
    
    static func registerRequestInterceptors() {
        FRRequestInterceptorRegistry.shared.registerInterceptors(
            interceptors: [
                ForceAuthInterceptorBiometricRegistration()
            ]
        )
    }
}


// MARK: - Extensions

extension UIStackView {
    
    func removeAllArrangedSubviews() {
        
        let removedSubviews = arrangedSubviews.reduce([]) { (allSubviews, subview) -> [UIView] in
            self.removeArrangedSubview(subview)
            return allSubviews + [subview]
        }
        
        // Deactivate all constraints
        NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))
        
        // Remove the views from self
        removedSubviews.forEach({ $0.removeFromSuperview() })
    }
}

// MARK: - Request Interceptors
class ForceAuthInterceptorBiometricRegistration: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        if (action.type == "START_AUTHENTICATE" || action.type == "AUTHENTICATE"),
           let payload = action.payload,
           let treeName = payload["tree"] as? String,
           treeName == PebbleBankUtilities.biometricsRegistrationJourney,
           let sessionToken = FRSession.currentSession?.sessionToken?.value
        {
            var headers = request.headers
            headers["Cookie"] = "\(PebbleBankUtilities.cookieName)=\(sessionToken)"
            var urlParams = request.urlParams
            urlParams["ForceAuth"] = "true"
            let newRequest = Request(url: request.url, method: request.method, headers: headers, bodyParams: request.bodyParams, urlParams: urlParams, requestType: request.requestType, responseType: request.responseType, timeoutInterval: request.timeoutInterval)
            return newRequest
        }
        else {
            return request
        }
    }
}
