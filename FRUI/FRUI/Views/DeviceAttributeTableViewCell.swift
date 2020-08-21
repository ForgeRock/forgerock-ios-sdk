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
    
    public static let cellIdentifier = "DeviceAttributeTableViewCellId"
    public static let cellHeight: CGFloat = 180.0
    var callback: DeviceProfileCallback?
    
    @IBOutlet weak var loadingView: FRLoadingView?
    public var delegate: AuthStepProtocol?
    @IBOutlet weak var messageLabel: UILabel?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        messageLabel?.textColor = FRUI.shared.primaryColor
    }
    
    
    func updateCellData(callback: Callback) {
        self.callback = callback as? DeviceProfileCallback
        self.loadingView?.startLoading()
        self.messageLabel?.text = self.callback?.message
        
        self.callback?.execute({ (_) in
            DispatchQueue.main.async {
                self.delegate?.submitNode()
            }
        })
    }
}
