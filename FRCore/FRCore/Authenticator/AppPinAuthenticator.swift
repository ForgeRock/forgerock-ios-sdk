// 
//  AppPinAuthenticator.swift
//  FRCore
//
//  Copyright (c) 2022-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import LocalAuthentication


///An authenticator to authenticate the user with Application Pin
public class AppPinAuthenticator {
    private var cryptoKey: CryptoKey
    
    
    public init(cryptoKey: CryptoKey) {
        self.cryptoKey = cryptoKey
    }
    
    
    /// Generate public and private key pair
    open func generateKeys(description: String, pin: String) throws -> KeyPair {
        var keyBuilderQuery = cryptoKey.keyBuilderQuery()
        keyBuilderQuery[String(kSecAttrAccessControl)] = accessControl()
        
#if !targetEnvironment(simulator)
        let context = LAContext()
        context.localizedReason = description
        let credentialIsSet = context.setCredential(pin.data(using: .utf8), type: .applicationPassword)
        guard credentialIsSet == true else { throw NSError() }
        keyBuilderQuery[String(kSecUseAuthenticationContext)] = context
#endif
        
        return try cryptoKey.createKeyPair(builderQuery: keyBuilderQuery)
    }
    
    
    /// Access Control for the authetication type
    open func accessControl() -> SecAccessControl? {
#if !targetEnvironment(simulator)
        return SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, [.applicationPassword, .privateKeyUsage], nil)
#else
        return SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, [.applicationPassword], nil)
#endif
    }
    
    
    func getPrivateKey(pin: String) -> SecKey? {
        return cryptoKey.getSecureKey(pin: pin)
    }
    
    
    func getKeyAlias() -> String {
        return cryptoKey.keyAlias
    }
}
