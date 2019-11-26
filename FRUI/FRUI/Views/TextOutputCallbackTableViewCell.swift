//
//  TextOutputCallbackTableViewCell.swift
//  FRUI
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuth

class TextOutputCallbackTableViewCell: UITableViewCell {
    
    public static let cellIdentifier = "TextOutputCallbackTableViewCellId"
    public static let cellHeight: CGFloat = 100.0
    @IBOutlet weak var textField:FRTextField?
    var callback: TextOutputCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.textField?.tintColor = FRUI.shared.primaryColor
        self.textField?.textColor = FRUI.shared.primaryColor
        self.textField?.isUserInteractionEnabled = false
    }

    
    // MARK: - Public
    public func updateCellData(authCallback: TextOutputCallback) {
        self.callback = authCallback
        self.textField?.textAlignment = .center
        self.textField?.text = self.callback?.message
        
        var textColor = FRUI.shared.primaryTextColor
        
        if #available(iOS 13.0, *) {
            textColor = UIColor.label
        }
        
        switch authCallback.messageType {
        case .error:
            textColor = FRUI.shared.errorColor
            break
        case .warning:
            textColor = FRUI.shared.warningColor
            break
        default:
            break
        }
        
        self.textField?.tintColor = textColor
        self.textField?.textColor = textColor
    }
}
