//
//  KeySupport.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Original work Copyright © 2018 Lyo Kato. All rights reserved.
//  Modified work Copyright © 2021 ForgeRock, Inc.
//

import Foundation
import LocalAuthentication
import FRCore

protocol KeySupport {
    var selectedAlg: COSEAlgorithmIdentifier { get }
    func createKeyPair(label: String) -> Optional<COSEKey>
    func sign(data: [UInt8], label: String) -> Optional<[UInt8]>
}

class KeySupportChooser {
    
    init() {}

    func choose(_ requestedAlgorithms: [COSEAlgorithmIdentifier])
        -> Optional<KeySupport> {
        WAKLogger.debug("<KeySupportChooser> choose")

        for alg in requestedAlgorithms {
            switch alg {
            case COSEAlgorithmIdentifier.es256:
                return ECDSAKeySupport(alg: .es256)
            default:
                WAKLogger.debug("<KeySupportChooser> currently this algorithm not supported")
                break
            }
        }
        return nil
    }
}

class ECDSAKeySupport : KeySupport {
    
    let selectedAlg: COSEAlgorithmIdentifier
    var accessGroup: String? = nil
    
    init(alg: COSEAlgorithmIdentifier) {
        self.selectedAlg = alg
        if let frAuth = FRAuth.shared, let accessGroupConfig = frAuth.keychainManager.accessGroup {
            self.accessGroup = accessGroupConfig
        }
        //  Add Apple Team Identifier if the accessGroup doesn't already have one
        if let currentAccessGroup = accessGroup, let appleTeamId = KeychainService.getAppleTeamId(), !currentAccessGroup.hasPrefix(appleTeamId) {
            self.accessGroup = appleTeamId + "." + currentAccessGroup
        }
        //  Validate the accessGroup, if it fails to validate, invalidate accessGroup
        if let currentAccessGroup = self.accessGroup, !KeychainService.validateAccessGroup(service: "com.forgerock.ios.webauthn.securekey.keychain.validation", accessGroup: currentAccessGroup) {
            FRLog.w("Given access group retrieved from configuration (\(currentAccessGroup)) is not valid configuration; WebAuthnKeychainStore will be configured without Access Group.")
            self.accessGroup = nil
        }
    }
    
    private func createPair(label: String) -> ECPrimeRandomKey? {
        ECPrimeRandomKey.getKeypair(label: label, accessGroup: self.accessGroup, context: LAContext())
    }
    
    func sign(data: [UInt8], label: String) -> Optional<[UInt8]> {
        
        if let pair = self.createPair(label: label), let signature = pair.sign(data: Data(data)) {
            return signature.bytes
        }
        else {
            WAKLogger.debug("<ECDSAKeySupport> failed to sign:")
            return nil
        }
    }
    
    func createKeyPair(label: String) -> Optional<COSEKey> {
        WAKLogger.debug("<ECDSAKeySupport> createKeyPair")
        
        if let pair = self.createPair(label: label) {
            do {
                let publicKey = try pair.getPublicKeyDERData().bytes
                if publicKey.count != 91 {
                    WAKLogger.debug("<ECDSAKeySupport> length of pubKey should be 91: \(publicKey.count)")
                    return nil
                }
                
                let x = Array(publicKey[27..<59])
                let y = Array(publicKey[59..<91])
                
                let key: COSEKey = COSEKeyEC2(
                    alg: self.selectedAlg.rawValue,
                    crv: COSEKeyCurveType.p256,
                    xCoord: x,
                    yCoord: y
                )
                return key
            }
            catch {
                WAKLogger.debug("<ECDSAKeySupport> failed to create key-pair: \(error)")
                return nil
            }
        }
        return nil
    }
}
