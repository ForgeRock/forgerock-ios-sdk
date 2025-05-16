//
//  HOTPMechanismTableViewCell.swift
//  FRAuthenticatorExample
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuthenticator

class HOTPMechanismTableViewCell: BaseTableViewCell {
    
    @IBOutlet weak var codeLabel: UILabel?
    @IBOutlet weak var issuerLabel: UILabel?
    @IBOutlet weak var accountNameLabel: UILabel?
    @IBOutlet weak var logoImageView: UIImageView?
    @IBOutlet weak var refreshButton: UIButton?
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint?
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint?
    var mechanism: HOTPMechanism?
    static var defaultCellHeight: CGFloat = 100
    static var cellIdentifier: String = "HOTPMechanismTableViewCellId"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setMechanism(mechanism: HOTPMechanism, isAccountDetailPage: Bool = false) {
        self.mechanism = mechanism
        self.issuerLabel?.text = mechanism.issuer
        if isAccountDetailPage {
            self.imageWidthConstraint?.constant = 30
            self.imageHeightConstraint?.constant = 30
            self.logoImageView?.image = UIImage(named: "TokensIcon")
            self.accountNameLabel?.isHidden = true
            self.issuerLabel?.text = "HMAC-based One-time Password"
        }
        else {
            self.accountNameLabel?.text = mechanism.accountName + " - \(mechanism.type.uppercased())"
            if let account = FRAClient.shared?.getAccount(identifier: mechanism.issuer + "-" + mechanism.accountName), let logoImageUrl = account.imageUrl, let url = URL(string: logoImageUrl) {
                self.logoImageView?.downloadImageFromUrl(url: url)
            }
            else {
                self.imageWidthConstraint?.constant = 30
                self.imageHeightConstraint?.constant = 30
                self.logoImageView?.image = UIImage(named: "TokensIcon")
            }
        }
    }
    
    @IBAction func refresh(sender: UIButton) {
        guard let mechanism = self.mechanism, let code = try? mechanism.generateCode() else {
            return
        }
        //  Disable refreshButton right after generating the code
        self.refreshButton?.isEnabled = false
        
        //  Add spacing in the middle of the code
        self.codeLabel?.text = code.code.insertSpace(at: mechanism.digits == 6 ? 3 : 4)
        
        //  Schedule Timer to re-enable refreshButton after 5 seconds
        Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { (timer) in
            DispatchQueue.main.async {
                self.refreshButton?.isEnabled = true
            }
        }
    }
    
}
