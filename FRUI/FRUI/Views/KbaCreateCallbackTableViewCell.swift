//
//  KbaCreateCallbackTableViewCell.swift
//  FRUI
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuth

class KbaCreateCallbackTableViewCell: UITableViewCell, FRUICallbackTableViewCell {

    // MARK: - Properties
    public static let cellIdentifier = "KbaCreateCallbackTableViewCellId"
    public static let cellHeight: CGFloat = 140.0
    @IBOutlet weak var dropDown: FRDropDownButton?
    
    @IBOutlet weak var answerField: FRTextField?
    @IBOutlet weak var questionField: UIButton?
    
    var callback: KbaCreateCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        dropDown?.themeColor = FRUI.shared.primaryColor
        dropDown?.delegate = self
        answerField?.normalColor = FRUI.shared.primaryColor
//        dropDown?.shouldCoverButton = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK: - Public
    public func updateCellData(callback: Callback) {
        self.callback = callback as? KbaCreateCallback
        
        if let cb = self.callback {
            self.dropDown?.setTitle(cb.prompt, for: .normal)
            self.dropDown?.setTitle(cb.prompt, for: .focused)
            self.dropDown?.setTitle(cb.prompt, for: .highlighted)
            self.dropDown?.setTitle(cb.prompt, for: .selected)
            dropDown?.dataSource = cb.predefinedQuestions
        }
    }
}


extension KbaCreateCallbackTableViewCell: FRDropDownViewProtocol {
    func selectedItem(index: Int, item: String) {
        callback?.setQuestion(item)
    }
}

// MARK: - UITextFieldDelegate
extension KbaCreateCallbackTableViewCell: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if answerField?.errorMessage != nil {
            answerField?.errorMessage = nil
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let answerText = textField.text, answerText.count > 0 {
            self.callback?.setAnswer(answerText)
        }
        else {
            answerField?.errorMessage = "Value must not be empty"
        }
    }
}
