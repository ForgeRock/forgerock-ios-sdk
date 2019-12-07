//
//  ChoiceCallbackTableViewCell.swift
//  FRUI
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuth

class ChoiceCallbackTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    @IBOutlet weak var dropDown: FRActionSheetButton?
    public static let cellIdentifier = "ChoiceCallbackTableViewCellId"
    public static let cellHeight:CGFloat = 120.0
    
    var callback:ChoiceCallback?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.dropDown?.themeColor = FRUI.shared.primaryColor
        self.dropDown?.delegate = self
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    public func updateCellData(authCallback: ChoiceCallback) {
     
        self.callback = authCallback
        self.dropDown?.setTitle(authCallback.prompt, for: .normal)
        self.dropDown?.setTitle(authCallback.prompt, for: .focused)
        self.dropDown?.setTitle(authCallback.prompt, for: .highlighted)
        self.dropDown?.setTitle(authCallback.prompt, for: .selected)        
        self.dropDown?.dataSource = authCallback.choices
    }
}

extension ChoiceCallbackTableViewCell: FRActionSheetProtocol {
    func selectedItem(index: Int, item: String) {
        self.callback?.value = index
    }
}
