//
//  AppleSignInHandler.swift
//  FRAuth
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import AuthenticationServices

/*
 Apple Sign in example JSON response for 3rd party applications.
 This format is expected to be passed to AM's IdPCallback
 {
     "code": "1234781237213123...",
     "id_token": "PEHANCKakenAKDNFAhekqoioenakdfnn53i2kKK23k2k2nn3...",
     "state": "..."
     "user": {
         "name": {
             "firstName": "Kurt",
             "lastName": "Cobain"
         },
         "email": "kurt@example.com"
     }
 }
         
 */
@available(iOS 13.0, *)
struct AppleSignInResponse: Codable {
    var code: String?
    var id_token: String?
    var state: String?
    var user: AppleSignInUser
    
    init(_ appleIDCredential: ASAuthorizationAppleIDCredential) {
        if let code = appleIDCredential.authorizationCode {
            self.code = String(data: code, encoding: .utf8)
        } else {
            self.code = nil
        }
        if let id_token = appleIDCredential.identityToken {
            self.id_token = String(data: id_token, encoding: .utf8)
        } else {
            self.id_token = nil
        }
        self.state = appleIDCredential.state
        self.user = AppleSignInUser(nameComponents: appleIDCredential.fullName, email: appleIDCredential.email)
    }
}

struct AppleSignInUser: Codable {
    var name: FullName?
    var email: String
    
    init(nameComponents: PersonNameComponents?, email: String?) {
        if let nameComponents = nameComponents {
            self.name = FullName(nameComponents)
        } else {
            self.name = nil
        }
        self.email = email ?? ""
    }
}

struct FullName: Codable {
    var firstName: String?
    var lastName: String?
}

extension FullName {
    init(_ nameComponents: PersonNameComponents) {
        firstName = nameComponents.givenName
        lastName = nameComponents.familyName
    }
}
