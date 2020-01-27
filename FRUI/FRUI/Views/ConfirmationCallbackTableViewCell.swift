//
//  ConfirmationCallbackTableViewCell.swift
//  FRUI
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuth

class ConfirmationCallbackTableViewCell: UITableViewCell, FRUICallbackTableViewCell {

    // MARK: - Properties
    public static let cellIdentifier = "ConfirmationCallbackTableViewCellId"
    public static let cellHeight: CGFloat = 100.0
    public var delegate: AuthStepProtocol?
    
    var callback: ConfirmationCallback?
    var buttons: [FRButton] = []
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let xOrigin = 35
        let yOrigin = 10
        let spacing = 20
        
        let buttonWidth = (Int(self.contentView.bounds.width) - 70  - (spacing * (buttons.count - 1))) / buttons.count
        let buttonHeight = 40
        for (index, button) in buttons.enumerated() {
            let buttonXOrigin = xOrigin + ((buttonWidth + spacing) * index)
            button.frame = CGRect(x: buttonXOrigin, y: yOrigin, width: buttonWidth, height: buttonHeight)
        }
    }
    
    
    @objc func buttonClicked(sender: UIButton) {
        callback?.value = sender.tag
        delegate?.submitNode()
    }
    
    
    // MARK: - Public
    public func updateCellData(callback: Callback) {
    
        self.callback = callback as? ConfirmationCallback
        
        if let options = self.callback?.options {
            for (index, option) in options.enumerated() {
                let button = FRButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
                button.setTitle(option, for: .normal)
                button.backgroundColor = FRUI.shared.primaryColor
                button.titleColor = UIColor.white
                button.tag = index
                button.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
                self.contentView.addSubview(button)
                buttons.append(button)
            }
        }
    }
}
