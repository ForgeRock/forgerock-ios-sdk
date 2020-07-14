//
//  PasswordCallbackTableViewCell.swift
//  FRUI
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuth

class PasswordCallbackTableViewCell: UITableViewCell, FRUICallbackTableViewCell {

    // MARK: - Properties
    public static let cellIdentifier = "PasswordCallbackTableViewCellId"
    public static let cellHeight:CGFloat = 100.0
    @IBOutlet weak var passwordField:FRTextField?
    
    var callback: SingleValueCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.passwordField?.tintColor = FRUI.shared.primaryColor
        self.passwordField?.normalColor = FRUI.shared.primaryColor
        self.passwordField?.isSecureTextEntry = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK: - Public
    public func updateCellData(callback: Callback) {
        
        self.callback = callback as? SingleValueCallback
        self.passwordField?.placeholder = self.callback?.prompt
        
        if callback is AbstractValidatedCallback, let validatedCallback = callback as? ValidatedCreatePasswordCallback {
            if let failedPolicies = validatedCallback.failedPolicies {
                var failedMessage = ""
                for (index, failedPolicy) in failedPolicies.enumerated() {
                    if index >= 1 {
                        failedMessage += ", "
                    }
                    failedMessage += failedPolicy.failedDescription()
                }
                passwordField?.errorMessage = failedMessage
            }
            self.passwordField?.isSecureTextEntry = !validatedCallback.echoOn
        }
    }
}

// MARK: - UITextFieldDelegate
extension PasswordCallbackTableViewCell: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if passwordField?.errorMessage != nil {
            passwordField?.errorMessage = nil
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        callback?.setValue(textField.text)
        if callback is AttributeInputCallback,
            let inputCallback = callback as? AttributeInputCallback,
            inputCallback.required {
            if textField.text == nil || textField.text?.count == 0 {
                passwordField?.errorMessage = "Value must not be empty"
            }
        }
    }
}
