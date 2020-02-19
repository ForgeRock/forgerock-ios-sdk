//
//  ActionCallback.swift
//  FRAuth
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

public protocol ActionCallback {
    func execute(_ completion: @escaping JSONCompletionCallback)
}
