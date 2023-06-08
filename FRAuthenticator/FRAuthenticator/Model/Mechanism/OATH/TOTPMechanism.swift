// 
//  TOTPMechanism.swift
//  FRAuthenticator
//
//  Copyright (c) 2020-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// TOTPMechanism represents Time-based OTP Auth and is responsible for its related operation
public class TOTPMechanism: OathMechanism {
    
    //  MARK: - Properties
    
    /// Time valid period for generated OTP credentials
    public var period: Int
    
    
    //  MARK: - Init
        
    /// Initializes TOTPMechanism with given data
    /// - Parameters:
    ///   - issuer: issuer of OATH
    ///   - accountName: accountName of current OATH Mechanism
    ///   - secret: shared secret in string of OATH Mechanism
    ///   - algorithm: algorithm in string for OATH Mechanism
    ///   - period: period of TOTP
    ///   - digits: number of digits for TOTP code
    init(issuer: String, accountName: String, secret: String, algorithm: String?, period: Int? = 30, digits: Int? = 6) {
        self.period = period ?? 30
        super.init(type: FRAConstants.totp, issuer: issuer, accountName: accountName, secret: secret, algorithm: algorithm, digits: digits)
    }
    
    
    /// Initializes HOTPMechanism with given data
    ///
    /// - Parameter mechanismUUID: Mechanism UUID
    /// - Parameter type: type of OATH
    /// - Parameter version: version of HOTPMechanism
    /// - Parameter issuer: issuer of OATH
    /// - Parameter secret: shared secret of OATH
    /// - Parameter accountName: accountName of OATH
    /// - Parameter algorithm: algorithm used for OATH
    /// - Parameter digits: length of OTP credentials
    /// - Parameter period: valid time period for OTP credentials
    /// - Parameter timeAdded: Date timestamp for creation of Mechanism object
    init?(mechanismUUID: String?, type: String?, version: Int?, issuer: String?, secret: String?, accountName: String?, algorithm: String?, digits: Int, period: Int, timeAdded: Double) {
        self.period = period
        super.init(mechanismUUID: mechanismUUID, type: type, version: version, issuer: issuer, secret: secret, accountName: accountName, algorithm: algorithm, digits: digits, timeAdded: timeAdded)
    }
    
    
    //  MARK: - NSCoder
    
    override public class var supportsSecureCoding: Bool { return true }
    
    
    override public func encode(with coder: NSCoder) {
        coder.encode(self.period, forKey: "period")
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
        let period = coder.decodeInteger(forKey: "period")
        let timeAdded = coder.decodeDouble(forKey: "timeAdded")
        
        self.init(mechanismUUID: mechanismUUID, type: type, version: version, issuer: issuer, secret: secret, accountName: accountName, algorithm: algorithm, digits: digits, period: period, timeAdded: timeAdded)
    }
    
    
    //  MARK: - Codable
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        period = try container.decode(Int.self, forKey: .period)
        try super.init(from: decoder)
    }

    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(period, forKey: .period)
        try super.encode(to: encoder)
    }
    
    
    //  MARK: - Oath Code
    
    /// Generates OathTokenCode object based on current time, and given secret for Mechanism
    /// - Throws: AccountError, CryptoError, MechanismError
    /// - Returns: OathTokenCode which represents Oath code for TOTP
    public func generateCode() throws -> OathTokenCode{
        
        if let account = FRAClient.storage.getAccount(accountIdentifier: self.accountIdentifier), let policyName = account.lockingPolicy, account.lock {
            FRALog.e("Error generating next OTP code: Account is locked.")
            throw AccountError.accountLocked(policyName)
        }
        
        let timeInterval = Date().timeIntervalSince1970
        let counter = UInt64(Int(timeInterval) / self.period)
        
        let startTimeInSeconds = (Int(timeInterval) / self.period * self.period)
        let endTimeInSeconds = (startTimeInSeconds + self.period) 
        
        let currentCode = try OathCodeGenerator.generateOTP(secret: self.secret, algorithm: self.algorithm, counter: counter, digits: self.digits)
        
        return OathTokenCode(tokenType: self.type, code: currentCode, start: TimeInterval(startTimeInSeconds), until: TimeInterval(endTimeInSeconds))
    }
    
    
    //  MARK: - Public
    
    /// Serializes `TOTPMechanism` object into JSON String.
    /// - Returns: JSON String value of `TOTPMechanism` object
    public func toJson() -> String? {
        if let objData = try? JSONEncoder().encode(self), let serializedStr = String(data: objData, encoding: .utf8) {
            return serializedStr
        }
        else {
            return nil
        }
    }
}

extension TOTPMechanism {
    enum CodingKeys: String, CodingKey {
        case period = "period"
    }
}

