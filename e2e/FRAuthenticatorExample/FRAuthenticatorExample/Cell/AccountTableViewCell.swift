//
//  AccountTableViewCell.swift
//  FRAuthenticatorExample
//
//  Copyright (c) 2020-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuthenticator

class AccountTableViewCell: BaseTableViewCell {
    
    @IBOutlet weak var issuerLabel: UILabel?
    @IBOutlet weak var accountNameLabel: UILabel?
    @IBOutlet weak var accountLockedLabel: UILabel?
    @IBOutlet weak var logoImageView: UIImageView?
    @IBOutlet weak var tokenImageView: UIImageView?
    @IBOutlet weak var notificationImageView: UIImageView?
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint?
    @IBOutlet weak var pushIconWidthConstraint: NSLayoutConstraint?
    static var defaultCellHeight: CGFloat = 100
    static var cellIdentifier: String = "AccountTableViewCellId"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    func setAccount(account: Account) {
        
        self.pushIconWidthConstraint?.constant = 0
        for mechanism in account.mechanisms {
            if mechanism is PushMechanism {
                self.pushIconWidthConstraint?.constant = 25
            }
        }
        
        if let imageUrl = account.imageUrl, let url = URL(string: imageUrl) {
            self.logoImageView?.downloadImageFromUrl(url: url)
        }
        else {
            self.imageWidthConstraint?.constant = 0
        }
        
        self.issuerLabel?.text = account.issuer
        self.accountNameLabel?.text = account.accountName
        
        self.accountLockedLabel?.isHidden = !account.lock
        if account.lock {
            if let policyName = account.lockingPolicy {
                self.accountLockedLabel?.text = "Your account is locked due the following policy: \(policyName)"
            } else {
                self.accountLockedLabel?.text = "Your account is locked"
            }            
            self.accountNameLabel?.alpha = 0.2
            self.logoImageView?.alpha = 0.2
            self.issuerLabel?.alpha = 0.2
            self.tokenImageView?.alpha = 0.2
            self.notificationImageView?.alpha = 0.2
        }
    }
    
}
