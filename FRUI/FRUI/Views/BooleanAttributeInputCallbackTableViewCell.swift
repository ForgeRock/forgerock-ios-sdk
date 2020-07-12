// 
//  BooleanAttributeInputCallbackTableViewCell.swift
//  FRUI
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import UIKit
import FRAuth

class BooleanAttributeInputCallbackTableViewCell: UITableViewCell, FRUICallbackTableViewCell {
    
    // MARK: - Properties
    public static let cellIdentifier = "BooleanAttributeInputCallbackTableViewCellId"
    public static let cellHeight: CGFloat = 80.0
    
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var toggleSwitch: UISwitch?
    
    var callback: BooleanAttributeInputCallback?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    
    func updateCellData(callback: Callback) {
        if let callback = callback as? BooleanAttributeInputCallback {
            self.callback = callback
            
            descriptionLabel?.text = callback.prompt
            toggleSwitch?.isOn = callback.getValue() as? Bool ?? false
        }
    }
    
    // MARK: - IBOutlet
    @IBAction func valueChanged(sender: UISwitch) {
        self.callback?.setValue(sender.isOn)
    }
}
