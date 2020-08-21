//
//  TermsAndConditionsTableViewCell.swift
//  FRUI
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuth

class TermsAndConditionsTableViewCell: UITableViewCell, FRUICallbackTableViewCell {

    // MARK: - Properties
    public static let cellIdentifier = "TermsAndConditionsTableViewCellId"
    public static let cellHeight: CGFloat = 250.0
    @IBOutlet weak var terms: UITextView?
    @IBOutlet weak var acceptSwitch: UISwitch?
    
    var callback: TermsAndConditionsCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK: - Public
    public func updateCellData(callback: Callback) {
        self.callback = callback as? TermsAndConditionsCallback
        
        if let cb = self.callback, let terms = cb.terms {
            self.terms?.text = terms
        }
    }
    
    // MARK: - IBOutlet
    @IBAction func termsAcceptedChanged(sender: UISwitch) {
        self.callback?.setValue(sender.isOn)
    }
}
