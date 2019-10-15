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

class NameCallbackTableViewCell: UITableViewCell {

    // MARK: - Properties
    public static let cellIdentifier = "NameCallbackTableViewCellId"
    public static let cellHeight:CGFloat = 100.0
    @IBOutlet weak var textField:FRTextField?
    
    var callback:SingleValueCallback?
    
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
    public func updateCellData(authCallback: SingleValueCallback) {
        self.callback = authCallback
        self.textField?.placeholder = authCallback.prompt
        
        if authCallback is AbstractValidatedCallback, let validatedCallback = authCallback as? AbstractValidatedCallback {
            self.textField?.text = validatedCallback.value as? String
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
        callback?.value = textField.text
        if callback is AttributeInputCallback,
            let inputCallback = callback as? AttributeInputCallback,
            inputCallback.required {
            if textField.text == nil || textField.text?.count == 0 {
                self.textField?.errorMessage = "Value must not be empty"
            }
        }
    }
}
