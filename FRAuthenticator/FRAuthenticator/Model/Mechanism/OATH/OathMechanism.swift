// 
//  OathMechanism.swift
//  FRAuthenticator
//
//  Copyright (c) 2020-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

public class OathMechanism: Mechanism {
    
    //  MARK: - Properties
    
    /// Algorithm of OATH OTP
    var algorithm: OathAlgorithm
    /// Length of OATH Code
    public var digits: Int

    
    // MARK: - Coding Keys

    /// CodingKeys customize the keys when this object is encoded and decoded
    enum CodingKeys: String, CodingKey {
        case algorithm
        case digits
    }
    
    
    //  MARK: - Init
    
    /// Initializes OathMechanism with given data
    /// - Parameters:
    ///   - type: type of OATH
    ///   - issuer: issuer of OATH
    ///   - accountName: accountName of current OATH Mechanism
    ///   - secret: shared secret in string of OATH Mechanism
    ///   - algorithm: algorithm in string for OATH Mechanism
    ///   - digits: number of digits for TOTP code
    init(type: String, issuer: String, accountName: String, secret: String, algorithm: String?, digits: Int? = 6) {
        if let algorithmStr = algorithm, let oathAlgorithm = OathAlgorithm(algorithm: algorithmStr) {
            self.algorithm = oathAlgorithm
        }
        else {
            self.algorithm = .sha1
        }
        self.digits = digits ?? 6
        super.init(type: type, issuer: issuer, accountName: accountName, secret: secret)
    }
    
    
    /// Initializes OathMechanism with given data
    /// - Parameter mechanismUUID: Mechanism UUID
    /// - Parameter type: type of OATH
    /// - Parameter version: version of HOTPMechanism
    /// - Parameter issuer: issuer of OATH
    /// - Parameter secret: shared secret of OATH
    /// - Parameter accountName: accountName of OATH
    /// - Parameter algorithm: algorithm used for OATH
    /// - Parameter digits: length of OTP Credentials
    /// - Parameter timeAdded: Date timestamp for creation of Mechanism object 
    init?(mechanismUUID: String?, type: String?, version: Int?, issuer: String?, secret: String?, accountName: String?, algorithm: String?, digits: Int, timeAdded: Double) {
        guard let algorithm = algorithm, let oathAlgorithm = OathAlgorithm(algorithm: algorithm) else {
            return nil
        }
        self.algorithm = oathAlgorithm
        self.digits = digits
        super.init(mechanismUUID: mechanismUUID, type: type, version: version, issuer: issuer, secret: secret, accountName: accountName, timeAdded: timeAdded)
    }

    
    //  MARK: - NSCoder
    
    override public class var supportsSecureCoding: Bool { return true }
    
    
    override public func encode(with coder: NSCoder) {
        coder.encode(self.algorithm.rawValue, forKey: "algorithm")
        coder.encode(self.digits, forKey: "digits")
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
        let timeAdded = coder.decodeDouble(forKey: "timeAdded")
        self.init(mechanismUUID: mechanismUUID, type: type, version: version, issuer: issuer, secret: secret, accountName: accountName, algorithm: algorithm, digits: digits, timeAdded: timeAdded)
    }
    
    
    //  MARK: - Codable
    
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(algorithm, forKey: .algorithm)
        try container.encode(digits, forKey: .digits)
        try super.encode(to: encoder)
    }
    
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        algorithm = try container.decode(OathAlgorithm.self, forKey: .algorithm)
        digits = try container.decode(Int.self, forKey: .digits)
        try super.init(from: decoder)
    }
    
}

