//
//  NameCallbackTableViewCell.swift
//  FRUI
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuth

class NameCallbackTableViewCell: UITableViewCell, FRUICallbackTableViewCell {

    // MARK: - Properties
    public static let cellIdentifier = "NameCallbackTableViewCellId"
    public static let cellHeight: CGFloat = 100.0
    @IBOutlet weak var textField: FRTextField?
    
    var callback: SingleValueCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.textField?.tintColor = FRUI.shared.primaryColor
        self.textField?.normalColor = FRUI.shared.primaryColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK: - Public
    public func updateCellData(callback: Callback) {
        self.callback = callback as? SingleValueCallback
        self.textField?.placeholder = self.callback?.prompt
        
        if callback is TextInputCallback, let textInputCallback = callback as? TextInputCallback {
            self.textField?.text = textInputCallback.getDefaultText()
        }
        
        if callback is AbstractValidatedCallback, let validatedCallback = callback as? AbstractValidatedCallback {
            self.textField?.text = validatedCallback.getValue() as? String
            if let failedPolicies = validatedCallback.failedPolicies {
                var failedMessage = ""
                for (index, failedPolicy) in failedPolicies.enumerated() {
                    if index >= 1 {
                        failedMessage = ", "
                    }
                    failedMessage = failedPolicy.failedDescription()
                }
                textField?.errorMessage = failedMessage
            }
        }
        
        if callback is NumberAttributeInputCallback {
            textField?.keyboardType = .decimalPad
        }
    }
}

// MARK: - UITextFieldDelegate
extension NameCallbackTableViewCell: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if self.textField?.errorMessage != nil {
            self.textField?.errorMessage = nil
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if callback is AttributeInputCallback,
            let inputCallback = callback as? AttributeInputCallback,
            inputCallback.required {
            if textField.text == nil || textField.text?.count == 0 {
                self.textField?.errorMessage = "Value must not be empty"
                return
            }
        }
        if let numberCallback = callback as? NumberAttributeInputCallback, let stringValue = textField.text {
            numberCallback.setValue(Double(stringValue))
        }
        else {
            callback?.setValue(textField.text)
        }
    }
}
