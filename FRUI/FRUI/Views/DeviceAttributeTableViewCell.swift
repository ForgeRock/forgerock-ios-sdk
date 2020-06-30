// 
//  DeviceAttributeTableViewCell.swift
//  FRUI
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import UIKit
import FRAuth

class DeviceAttributeTableViewCell: UITableViewCell, FRUICallbackTableViewCell {
    
    public static let cellIdentifier = "TextOutputCallbackTableViewCellId"
    public static let cellHeight: CGFloat = 180.0
    var callback: DeviceProfileCallback?
    
    @IBOutlet weak var grantButton: FRButton?
    @IBOutlet weak var attributesLabel: UILabel?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        grantButton?.backgroundColor = FRUI.shared.primaryColor
        grantButton?.titleColor = UIColor.white
    }

    
    func updateCellData(callback: Callback) {
        self.callback = callback as? DeviceProfileCallback
        
        if let thisCallback = self.callback {
            var attributeValues = ""
            var attributes: [String] = []
            if thisCallback.locationRequired {
                attributes.append("Device Location")
            }
            if thisCallback.metadataRequired {
                attributes.append("Device Metadata")
            }
            
            for (index, attribute) in attributes.enumerated() {
                
                if index == 0 {
                    attributeValues += attribute
                }
                else {
                    attributeValues += ", \(attribute)"
                }
            }
            self.attributesLabel?.text = attributeValues
        }
    }
    
    
    @IBAction func grantClicked(sender: UIButton) {
        self.callback?.execute({ (json) in
            self.grantButton?.isEnabled = false
            self.grantButton?.setTitle("Collected", for: .disabled)
        })
    }
}
