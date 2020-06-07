// 
//  Typealias.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

//  Success void callback
public typealias SuccessCallback = () -> Void
//  Error void callback
public typealias ErrorCallback = (_ error: Error) -> Void
//  Array of Account objects return callback
public typealias AccountsCallback = (_ accounts: [Account]) -> Void
//  Account object return callback
public typealias AccountCallback = (_ account: Account) -> Void
//  Mechanism object return callback
public typealias MechanismCallback = (_ mechanism: Mechanism) -> Void


