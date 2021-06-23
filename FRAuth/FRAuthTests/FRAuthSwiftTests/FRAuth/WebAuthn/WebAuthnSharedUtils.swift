// 
//  WebAuthnSharedUtils.swift
//  FRAuthTests
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

class WebAuthnSharedUtils: FRAuthBaseTest {
    
    //  MARK: - Helper
    
    func parseAttestationObjectFromRegistrationResult(str: String) -> AttestationObject? {
        let components = str.components(separatedBy: "::")
        if components.count >= 3 {
            let attestationData = components[components.count - 2]
            if let attestationDataArr = self.convertInt8StrToUInt8Arr(str: attestationData) {
                if let cborMap = CBORReader(bytes: attestationDataArr).readStringKeyMap(),
                   let authData = cborMap["authData"] as? [UInt8],
                   let authObj = AuthenticatorData.fromBytes(authData),
                   let fmt = cborMap["fmt"] as? String {
                    return AttestationObject(fmt: fmt, authData: authObj, attStmt: SimpleOrderedDictionary<String>())
                }
            }
        }
        return nil
    }
    
    
    func convertInt8StrToUInt8Arr(str: String) -> [UInt8]? {
        
        var int8Arr: [Int8] = []
        let ints = str.split(separator: ",")
        for int8 in ints {
            let thisVal = int8.replacingOccurrences(of: " ", with: "")
            if let int8Val = Int8(thisVal) {
                int8Arr.append(int8Val)
            }
            else {
                return nil
            }
        }
        return int8Arr.map { UInt8(bitPattern: $0) }
    }
    
    
    func createAuthenticationCallback() throws -> WebAuthnAuthenticationCallback {
        let jsonStr = """
        {
            "type": "MetadataCallback",
            "output": [
                {
                    "name": "data",
                    "value": {
                        "_action": "webauthn_authentication",
                        "challenge": "G5MMUCfoB2TGpdqmXNmPqkf3YxKL5uGURyOVvW8jjFQ=",
                        "_allowCredentials": [
                            {
                                "type": "public-key",
                                "id": [-87, 55, -118, -125, -94, 76, 75, -30, -68, 20, -108, 53, -80, -17, 89, 33]
                            }
                        ],
                        "timeout": "60000",
                        "userVerification": "preferred",
                        "_relyingPartyId": "com.forgerock.ios",
                        "_type": "WebAuthn"
                    }
                }
            ]
        }
        """
        
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        return try WebAuthnAuthenticationCallback(json: callbackResponse)
    }
    
    func createRegistrationCallback(userName: String = "527490d2-0d91-483e-bf0b-853ff3bb2447", displayName: String = "527490d2-0d91-483e-bf0b-853ff3bb2447", userId: String = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3", attestationPreference: String = "indirect") throws -> WebAuthnRegistrationCallback {
        let jsonStr = """
        {
            "type": "MetadataCallback",
            "output": [
                {
                    "name": "data",
                    "value": {
                        "_action": "webauthn_registration",
                        "challenge": "fJ4kdpPiHmBXHe1l1q6sB+GUC35husrw1w6vWBHiSJg=",
                        "attestationPreference": "\(attestationPreference)",
                        "userName": "\(userName)",
                        "userId": "\(userId)",
                        "relyingPartyName": "ForgeRock",
                        "_authenticatorSelection": {
                            "userVerification": "preferred"
                        },
                        "_pubKeyCredParams": [
                            {
                                "type": "public-key",
                                "alg": -257
                            },
                            {
                                "type": "public-key",
                                "alg": -7
                            }
                        ],
                        "timeout": "60000",
                        "_excludeCredentials": [],
                        "displayName": "\(displayName)",
                        "_relyingPartyId": "com.forgerock.ios",
                        "_type": "WebAuthn"
                    }
                }
            ]
        }
        """
        
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        return try WebAuthnRegistrationCallback(json: callbackResponse)
    }
}
