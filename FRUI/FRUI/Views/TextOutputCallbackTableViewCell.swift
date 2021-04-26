//
//  TextOutputCallbackTableViewCell.swift
//  FRUI
//
//  Copyright (c) 2019-2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuth

class TextOutputCallbackTableViewCell: UITableViewCell, FRUICallbackTableViewCell {
    
    public static let cellIdentifier = "TextOutputCallbackTableViewCellId"
    public static let cellHeight: CGFloat = 200.0
    @IBOutlet weak var textField:FRTextField?
    @IBOutlet weak var textView: UITextView?
    var callback: TextOutputCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.textView?.tintColor = FRUI.shared.primaryColor
        self.textView?.textColor = FRUI.shared.primaryColor
    }

    
    // MARK: - Public
    public func updateCellData(callback: Callback) {
        self.callback = callback as? TextOutputCallback
        self.textView?.text = self.callback?.message
                
        var textColor = FRUI.shared.primaryTextColor
        
        if #available(iOS 13.0, *) {
            textColor = UIColor.label
        }
        
        switch self.callback?.messageType {
        case .error:
            textColor = FRUI.shared.errorColor
            break
        case .warning:
            textColor = FRUI.shared.warningColor
            break
        default:
            break
        }
        
        self.textView?.tintColor = textColor
        self.textView?.textColor = textColor
    }
}
