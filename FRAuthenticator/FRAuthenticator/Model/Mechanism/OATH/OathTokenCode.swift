// 
//  OathTokenCode.swift
//  FRAuthenticator
//
//  Copyright (c) 2020-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// OathTokenCode represents OTP credentials as an object generated with HOTPMechnism, and/or TOTPMechanism
public class OathTokenCode: NSObject, Codable {
    
    //  MARK: - Property
    
    /// OathTokenType as in String; either 'hotp', or 'totp'
    public let tokenType: String
    /// Oath code
    public let code: String
    /// Started timestamp of current Oath token; timestamp in seconds since 
    public let start: TimeInterval
    /// Expiration timestamp of current Oath token; for HOTP, 'until' property returns nil as it does not expires
    public let until: TimeInterval?
    /// Boolean property indicating whether or not current OathTokenCode is valid; for HOTP, isValid always returns 'true' and for TOTP. This property computes, start and until timestamps of OathTokenCode and determines its validity
    public var isValid: Bool {
        get {
            if let untilTimestamp = self.until, self.tokenType == FRAConstants.totp {
                let currentTime = Date().timeIntervalSince1970
                return ((untilTimestamp - currentTime) > 0 && (currentTime - self.start) > 0)
            }

            return true
        }
    }
    
    /**
        Float value that represents percentage until current Oath code expires; ranging from 0.0 to 1.0
        **Warning:** For `HOTPMechanism`, progress always returns 0.0; actual progress value is only returned for `TOTPMechanism`
     */
    public var progress: Float {
        get {
            guard self.tokenType == "totp" else {
                return 0.0
            }
            
            var time: timeval = timeval(tv_sec: 0, tv_usec: 0)
            gettimeofday(&time, nil)
            
            let now = Double(time.tv_sec * 1000) + Double(time.tv_usec / 1000)
            
            if now < self.start * 1000 {
                return 0.0
            }
            if let until = self.until, now < (until * 1000) {
                let duration = (until * 1000) - (self.start * 1000)
                return Float((now - (self.start * 1000)) / duration)
            }
            
            return 1.0
        }
    }
    
    
    //  MARK: - Init
    
    /// Prevents init
    private override init() { fatalError("OathTokenCode() is prohibited. Use OathMechanism.getOathTokenCode() to retrieve OathTokenCode") }
    
    
    /// Initializes OathTokenCode object with given data
    /// - Parameters:
    ///   - tokenType: Oath token type; HOTP or TOTP
    ///   - code: Oath token code; 6 or 8 digits
    ///   - start: start timestamp for current Oath code
    ///   - until: expiration timestamp for current Oath code
    init(tokenType: String, code: String, start: TimeInterval, until: TimeInterval?) {
        self.tokenType = tokenType
        self.code = code
        self.start = start
        self.until = until
    }
    
    
    //  MARK: - Public
    
    /// Serializes `OathTokenCode` object into JSON String
    /// - Returns: JSON String value of `OathTokenCode` object
    public func toJson() -> String? {
        if let objData = try? JSONEncoder().encode(self), let serializedStr = String(data: objData, encoding: .utf8) {
            return serializedStr
        }
        else {
            return nil
        }
    }
}
