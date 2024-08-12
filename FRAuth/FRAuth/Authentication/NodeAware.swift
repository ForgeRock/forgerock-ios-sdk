// 
//  NodeAware.swift
//  FRAuth
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// For `Callback` which need to have awareness of the parent `Node`
protocol NodeAware {

    /// Inject the `Node` object
    func setNode(node: Node?)
}

