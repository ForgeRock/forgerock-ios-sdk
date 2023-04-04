// 
//  HOTPMechanism.swift
//  FRAuthenticator
//
//  Copyright (c) 2020-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// HOTPMechanism represents HMAC-based OTP Auth and is responsible for its related operation
public class HOTPMechanism: OathMechanism {
    
    //  MARK: - Properties
    
    /// Counter as in Int for number of OTP credentials generated
    var counter: Int
    
    
    //  MARK: - Init    
    
    /// Initializes HOTPMechanism with given data
    /// - Parameters:
    ///   - issuer: issuer of OATH
    ///   - accountName: accountName of current OATH Mechanism
    ///   - secret: shared secret in string of OATH Mechanism
    ///   - algorithm: algorithm in string for OATH Mechanism
    ///   - counter: counter of HOTP
    ///   - digits: number of digits for TOTP code
    init(issuer: String, accountName: String, secret: String, algorithm: String?, counter: Int? = 0, digits: Int? = 6) {
        self.counter = counter ?? 0
        super.init(type: FRAConstants.hotp, issuer: issuer, accountName: accountName, secret: secret, algorithm: algorithm, digits: digits)
    }
    
    
    /// Initializes HOTPMechanism with given data
    /// - Parameter mechanismUUID: Mechanism UUID
    /// - Parameter type: type of OATH
    /// - Parameter version: version of HOTPMechanism
    /// - Parameter issuer: issuer of OATH
    /// - Parameter secret: shared secret of OATH
    /// - Parameter accountName: accountName of OATH
    /// - Parameter algorithm: algorithm used for OATH
    /// - Parameter digits: length of OTP Credentials
    /// - Parameter counter: counter for number of OTP credentials generated
    /// - Parameter timeAdded: Date timestamp for creation of Mechanism object 
    init?(mechanismUUID: String?, type: String?, version: Int?, issuer: String?, secret: String?, accountName: String?, algorithm: String?, digits: Int, counter: Int, timeAdded: Double) {
        self.counter = counter
        super.init(mechanismUUID: mechanismUUID, type: type, version: version, issuer: issuer, secret: secret, accountName: accountName, algorithm: algorithm, digits: digits, timeAdded: timeAdded)
    }

    
    //  MARK: - NSCoder
    
    override public class var supportsSecureCoding: Bool { return true }
    
    
    override public func encode(with coder: NSCoder) {
        coder.encode(self.counter, forKey: "counter")
        super.encode(with: coder)
    }
    

    public required convenience init?(coder: NSCoder) {
        let mechanismUUID = coder.decodeObject(of: NSString.self, forKey: "mechanismUUID") as String?
        let type = coder.decodeObject(of: NSString.self, forKey: "type") as String?
        let version = coder.decodeInteger(forKey: "version")
        let issuer = coder.decodeObject(of: NSString.self, forKey: "issuer") as String?
        let secret = coder.decodeObject(of: NSString.self, forKey: "secret") as String?
        let accountName = coder.decodeObject(of: NSString.self, forKey: "accountName") as String?
        let algorithm = coder.decodeObject(of: NSString.self, forKey: "algorithm") as String?
        let digits = coder.decodeInteger(forKey: "digits")
        let counter = coder.decodeInteger(forKey: "counter")
        let timeAdded = coder.decodeDouble(forKey: "timeAdded")
        self.init(mechanismUUID: mechanismUUID, type: type, version: version, issuer: issuer, secret: secret, accountName: accountName, algorithm: algorithm, digits: digits, counter: counter, timeAdded: timeAdded)
    }
    
    
    //  MARK: - Codable
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        counter = try container.decode(Int.self, forKey: .counter)
        try super.init(from: decoder)
    }
    

    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(counter, forKey: .counter)
    }
    
    
    //  MARK: - Oath Code
        
    /// Generates OathTokenCode object based on current counter, and given secret for Mechanism
    /// - Throws: AccountError, CryptoError, MechanismError
    /// - Returns: OathTokenCode which represents Oath code for HOTP
    public func generateCode() throws -> OathTokenCode {
        
        if let account = FRAClient.storage.getAccount(accountIdentifier: self.accountIdentifier), let policyName = account.lockingPolicy, account.lock {
            FRALog.e("Error generating next OTP code: Account is locked.")
            throw AccountError.accountLocked(policyName)
        }
        
        let startTimeInSeconds = Date().timeIntervalSince1970
        let currentCode = try OathCodeGenerator.generateOTP(secret: self.secret.base64Pad(), algorithm: self.algorithm, counter: UInt64(self.counter), digits: self.digits)
        self.counter += 1
        
        if FRAClient.storage.setMechanism(mechanism: self) {
            FRALog.v("HOTP was generated, and updated through StorageClient")
            return OathTokenCode(tokenType: self.type, code: currentCode, start: startTimeInSeconds, until: nil)
        }
        else {
            FRALog.v("HOTP was generated, but failed to update HOTPMechanism object in StorageClient; reverting changes for counter, and currentCode.")
            self.counter -= 1
            throw MechanismError.failedToUpdateInformation(self.identifier)
        }
    }
    
    
    //  MARK: - Public
    
    /// Serializes `HOTPMechanism` object into JSON String
    /// - Returns: JSON String value of `HOTPMechanism` object
    public func toJson() -> String? {
        if let objData = try? JSONEncoder().encode(self), let serializedStr = String(data: objData, encoding: .utf8) {
            return serializedStr
        }
        else {
            return nil
        }
    }
}


extension HOTPMechanism {
    enum CodingKeys: String, CodingKey {
        case counter = "counter"
    }
}
