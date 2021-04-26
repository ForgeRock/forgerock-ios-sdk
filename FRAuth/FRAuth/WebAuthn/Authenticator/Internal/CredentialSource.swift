//
//  CredentialSource.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/23.
//  Original work Copyright © 2018 Lyo Kato. All rights reserved.
//  Modified work Copyright © 2021 ForgeRock, Inc.
//

import Foundation
import FRCore

struct PublicKeyCredentialSource {
    
    var keyLabel: String {
        get {
            let idHex = self.id.toHexString()
            return "\(self.rpId)/\(idHex)"
        }
    }
    
    var type:       PublicKeyCredentialType = .publicKey
    var signCount:  UInt32 = 0
    var id:         [UInt8] // credential id
    var rpId:       String
    var userHandle: [UInt8]?
    var alg:        Int = COSEAlgorithmIdentifier.rs256.rawValue
    var otherUI:    String
    
    init(
        id:         [UInt8],
        rpId:       String,
        userHandle: [UInt8]?,
        signCount:  UInt32,
        alg:        Int,
        otherUI:    String
        ) {
        
        self.id         = id
        self.rpId       = rpId
        self.userHandle = userHandle
        self.signCount  = signCount
        self.alg        = alg
        self.otherUI    = otherUI
    }
    
    func toCBOR() -> Optional<[UInt8]> {
        WAKLogger.debug("<PublicKeyCredentialSource> toCBOR")
        
        let builder = CBORWriter()
        
        let dict = SimpleOrderedDictionary<String>()
        
        dict.addBytes("id", self.id)
        dict.addString("rpId", self.rpId)
        if let userHandle = self.userHandle {
            dict.addBytes("userHandle", userHandle)
        }
        dict.addInt("alg", Int64(self.alg))
        dict.addInt("signCount", Int64(self.signCount))
        dict.addString("otherUI", self.otherUI)
        return builder.putStringKeyMap(dict).getResult()
    }
    
    static func fromCBOR(_ bytes: [UInt8]) -> Optional<PublicKeyCredentialSource> {
        WAKLogger.debug("<PublicKeyCredentialSource> fromCBOR")
        
        var id:         [UInt8]
        var rpId:       String = ""
        var userHandle: [UInt8]? = nil
        var algId:      Int = 0
        var otherUI:    String = ""
        var signCount:  UInt32 = 0
        
        guard let dict = CBORReader(bytes: bytes).readStringKeyMap()  else {
            return nil
        }
        
        if let foundId = dict["id"] as? [UInt8] {
            id = foundId
        } else {
            WAKLogger.debug("<PublicKeyCredentialSource> id not found")
            return nil
        }
        
        if let foundSignCount = dict["signCount"] as? Int64 {
            signCount = UInt32(foundSignCount)
        } else {
            WAKLogger.debug("<PublicKeyCredentialSource> signCount not found")
            return nil
        }
        
        if let foundOtherUI = dict["otherUI"] as? String {
            otherUI = foundOtherUI
        } else {
            WAKLogger.debug("<PublicKeyCredentialSource> otherUI not found")
            return nil
        }
        
        if let foundRpId = dict["rpId"] as? String {
            rpId = foundRpId
        } else {
            WAKLogger.debug("<PublicKeyCredentialSource> rpId not found")
            return nil
        }
        
        if let handle = dict["userHandle"] as? [UInt8] {
            userHandle = handle
        }
        
        if let alg = dict["alg"] as? Int64 {
            algId = Int(alg)
        } else {
            WAKLogger.debug("<PublicKeyCredentialSource> alg not found")
            return nil
        }
        
        let src = PublicKeyCredentialSource(
            id:         id,
            rpId:       rpId,
            userHandle: userHandle,
            signCount:  signCount,
            alg:        algId,
            otherUI:    otherUI
        )
        return src
    }
}
