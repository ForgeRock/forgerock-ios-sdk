// 
//  CryptoAware.swift
//  FRDeviceBinding
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore


/// Protocol to be implemented by objects that want to be aware of CryptoKey
internal protocol CryptoAware {
    func setKey(cryptoKey: CryptoKey)
}
