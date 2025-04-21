// 
//  CustomNameCallbackCell.swift
//  FRExample
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import UIKit
import FRAuth
import FRUI

class CustomNameCallbackCell: UITableViewCell, FRUICallbackTableViewCell {
    
    static var cellIdentifier: String = "CustomNameCallbackCellId"
    static var cellHeight: CGFloat = 400.0
    
    var callback: NameCallback?
    @IBOutlet weak var nameField:FRTextField?
    
    func updateCellData(callback: Callback) {
        self.callback = callback as? NameCallback
        
        if let nameCallback = self.callback {
            self.nameField?.placeholder = nameCallback.prompt
        }
    }
}

// MARK: - UITextFieldDelegate
extension CustomNameCallbackCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        callback?.setValue(textField.text)
    }
}
