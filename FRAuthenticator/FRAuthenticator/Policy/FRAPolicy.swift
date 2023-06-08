// 
//  FRAPolicy.swift
//  FRAuthenticator
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// The FRAPolicy is an abstract Policy that provides general guidance on implementing policies to enforce the security of an Authenticator app.
/// A policy must contain an unique name and instructions to determinate whether a condition is valid at a particular time. The policy may optionally contain some data to be used in the validation procedure.
///
/// JSON representation of a policy:
/// {"policyName" : { policyData }}
@objc
public protocol FRAPolicy {
    
    /// The attributes used for policy validation.
    var data : Any? { get set }
    
    /// The name of the Policy.
    var name: String { get }
    
    /// Evaluate the policy compliance.
    /// - Returns: true if the policy comply, false otherwise
    func evaluate() -> Bool
    
}
