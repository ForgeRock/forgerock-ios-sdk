//
//  PushMechanismTableViewCell.swift
//  FRAuthenticatorExample
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuthenticator

class PushMechanismTableViewCell: BaseTableViewCell {
    
    @IBOutlet weak var issuerLabel: UILabel?
    @IBOutlet weak var accountNameLabel: UILabel?
    @IBOutlet weak var logoImageView: UIImageView?
    @IBOutlet weak var notificationIconImageView: UIImageView?
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint?
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint?
    @IBOutlet weak var issuerTopConstraint: NSLayoutConstraint?
    static var defaultCellHeight: CGFloat = 100
    static var cellIdentifier: String = "PushMechanismTableViewCellId"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    func setMechanism(mechanism: PushMechanism, isAccountDetailPage: Bool = false) {
        
        if isAccountDetailPage {
            self.issuerTopConstraint?.constant = 40
            self.imageWidthConstraint?.constant = 30
            self.imageHeightConstraint?.constant = 30
            self.logoImageView?.image = UIImage(named: "NotificationIcon")
            self.notificationIconImageView?.isHidden = true
        }
        else if let account = FRAClient.shared?.getAccount(identifier: mechanism.issuer + "-" + mechanism.accountName), let logoImageUrl = account.imageUrl, let url = URL(string: logoImageUrl) {
            self.logoImageView?.downloadImageFromUrl(url: url)
        }
        else {
            self.imageWidthConstraint?.constant = 30
            self.imageHeightConstraint?.constant = 30
            self.logoImageView?.image = UIImage(named: "NotificationIcon")
            self.notificationIconImageView?.isHidden = true
        }
        
        self.issuerLabel?.text = mechanism.issuer
        self.accountNameLabel?.text = mechanism.accountName
    }
    
}
