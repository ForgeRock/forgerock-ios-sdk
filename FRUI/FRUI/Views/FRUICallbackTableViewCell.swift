// 
//  FRUICallbackTableViewCell.swift
//  FRUI
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import UIKit
import FRAuth

/// UITableViewCell protocol for FRUI's Authentication View Controller customization
public protocol FRUICallbackTableViewCell: UITableViewCell {
    
    /// Unique cell identifier string; should also be registered with same value in Nib file as well.
    static var cellIdentifier: String { get }
    /// Float value of cell height
    static var cellHeight: CGFloat { get }
    /// A callback method that will be invoked whenever the cell needs to be rendered with Callback object. Callback object is recommended to persist in the class to update the value or render UI.
    func updateCellData(callback: Callback)
    
    func updateCellWithViewController(viewController: UIViewController, callback: Callback, node: Node)
}


extension FRUICallbackTableViewCell {
    public func updateCellWithViewController(viewController: UIViewController, callback: Callback, node: Node) {
        //  Dummy implementation to make the protocol method optional
    }
}
