//
//  CredentialStore.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Original work Copyright © 2018 Lyo Kato. All rights reserved.
//  Modified work Copyright © 2021 ForgeRock, Inc.
//

import Foundation
import FRCore

protocol CredentialStore {
    func lookupCredentialSource(rpId: String, credentialId: [UInt8]) -> Optional<PublicKeyCredentialSource>
    func saveCredentialSource(_ cred: PublicKeyCredentialSource) -> Bool
    func loadAllCredentialSources(rpId: String) -> [PublicKeyCredentialSource]
    func deleteCredentialSource(_ cred: PublicKeyCredentialSource) -> Bool
    func deleteAllCredentialSources(rpId: String, userHandle: [UInt8])
}


/// WebAuthnKeychainStore is a representation of KeychainService class which is responsible to store and retrieve data with Secure Enclave encryption
struct WebAuthnKeychainStore {
    let keychainValidationString: String = "com.forgerock.ios.webauthn.keychain.validation"
    let keychainValidationKey: String = "validation-key"
    let securedKeyLabel: String = "com.forgerock.ios.webauthn.securedKey"
    var keychainStore: KeychainService
    var service: String
    
    init(service: String) {
        self.service = service
        //  Retrieve accessGroup from configuration, if SDK is initialized
        var accessGroup: String? = nil
        if let frAuth = FRAuth.shared, let accessGroupConfig = frAuth.keychainManager.accessGroup {
            accessGroup = accessGroupConfig
        }
        //  Create SecuredKey if possible
        var securedKey: SecuredKey? = nil
        if let thisSecuredKey = SecuredKey(applicationTag: self.securedKeyLabel, accessGroup: accessGroup) {
            securedKey = thisSecuredKey
        }
        
        if let thisAccessGroup = accessGroup {
            self.keychainStore = KeychainService(service: service, accessGroup: thisAccessGroup, securedKey: securedKey)
        }
        else {
            self.keychainStore = KeychainService(service: service, securedKey: securedKey)
        }
        
        //  If the store already has encryption string
        if let result = self.keychainStore.allItems()?.keys.contains(self.keychainValidationKey), result {
            //  Try to validate the decrypted string
            if let decryptedString = self.keychainStore.getString(self.keychainValidationKey), decryptedString == self.keychainValidationString {
                FRLog.v("WebAuthnKeychainStore encryption validation was successful")
            }
            else {
                //  If decrypted string doesn't match, remove all items, and re-add newly encrypted string
                FRLog.w("WebAuthnKeychainStore encrpytion validation failed; removing all credentials from store")
                self.keychainStore.deleteAll()
                FRLog.v("Storing new encryption validation string")
                self.keychainStore.set(self.keychainValidationString, key: self.keychainValidationKey)
            }
        }
        else {
            //  If the store doesn't have the encrypted string yet, add it
            self.keychainStore.set(self.keychainValidationString, key: self.keychainValidationKey)
            FRLog.v("WebAuthnKeychainStore; detected first initialization, stored encryption validation string.")
        }
    }
}

class KeychainCredentialStore : CredentialStore {

    let servicePrefix: String = "com.forgerock.ios.webauthn.credentialstore" + "::"
    var keychainStore: WebAuthnKeychainStore?
    
    init() {}
    
    func getKeychainStore(service: String) -> WebAuthnKeychainStore {
        if let store = self.keychainStore {
            return store
        }
        else {
            let store = WebAuthnKeychainStore(service: service)
            self.keychainStore = store
            return store
        }
    }
    
    func loadAllCredentialSources(rpId: String) -> [PublicKeyCredentialSource] {
        WAKLogger.debug("[CredentialStore] loadAllCredentialSources")
        let keychainService = self.getKeychainStore(service: self.servicePrefix + rpId).keychainStore
        
        if let items = keychainService.allItems() {
            return items.compactMap { (key, item) -> PublicKeyCredentialSource? in
                if let itemData = item as? Data {
                    let credentialSource = PublicKeyCredentialSource.fromCBOR(itemData.bytes)
                    //  If PublicKeyCredentialSource has userHandle meaning that it's client-side discoverable PublicKeyCredentialSource
                    //  Only return the client-side discoverable PublicKeyCredentialSource
                    if credentialSource?.userHandle != nil {
                        return credentialSource
                    }
                    else {
                        return nil
                    }
                } else {
                    WAKLogger.debug("[CredentialStore] failed to load data for key:\(key)")
                    return nil
                }
            }
        }
        else {
            return []
        }
    }
    
    func deleteAllCredentialSources(rpId: String, userHandle: [UInt8]) {
        self.loadAllCredentialSources(rpId: rpId, userHandle: userHandle).forEach {
            _ = self.deleteCredentialSource($0)
        }
    }
    
    func loadAllCredentialSources(rpId: String, userHandle: [UInt8]) -> [PublicKeyCredentialSource] {
        WAKLogger.debug("[CredentialStore] loadAllCredentialSources with userHandle")
        let credentials = self.loadAllCredentialSources(rpId: rpId)
        var userCredentials: [PublicKeyCredentialSource] = []
        
        for credential in credentials {
            if let credUserHandle = credential.userHandle, credUserHandle.elementsEqual(userHandle) {
                userCredentials.append(credential)
            }
        }
        return userCredentials
    }

    func lookupCredentialSource(rpId: String, credentialId: [UInt8])
        -> Optional<PublicKeyCredentialSource> {
            WAKLogger.debug("[CredentialStore] lookupCredentialSource")

        let handle = credentialId.toHexString()
        let keychain = self.getKeychainStore(service: self.servicePrefix + rpId).keychainStore
        if let result = keychain.getData(handle) {
            return PublicKeyCredentialSource.fromCBOR(result.bytes)
        }
        else {
            WAKLogger.debug("[CredentialStore] failed to load data for key:\(handle)")
            return nil
        }
    }
    
    func deleteCredentialSource(_ cred: PublicKeyCredentialSource) -> Bool {
        
        WAKLogger.debug("[CredentialStore] deleteCredentialSource")
        
        let handle = cred.id.toHexString()
        let keychain = self.getKeychainStore(service: self.servicePrefix + cred.rpId).keychainStore
        return keychain.delete(handle)
    }

    func saveCredentialSource(_ cred: PublicKeyCredentialSource) -> Bool {
        WAKLogger.debug("[CredentialStore] saveCredentialSource")

        let handle = cred.id.toHexString()
        let keychain = self.getKeychainStore(service: self.servicePrefix + cred.rpId).keychainStore
        if let bytes = cred.toCBOR() {
            return keychain.set(Data(bytes), key: handle)
        }
        else {
            return false
        }
    }
}

