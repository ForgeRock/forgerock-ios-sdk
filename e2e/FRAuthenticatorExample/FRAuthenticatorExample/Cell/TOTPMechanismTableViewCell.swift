//
//  TOTPMechanismTableViewCell.swift
//  FRAuthenticatorExample
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuthenticator

class TOTPMechanismTableViewCell: BaseTableViewCell {
    
    @IBOutlet weak var codeLabel: UILabel?
    @IBOutlet weak var issuerLabel: UILabel?
    @IBOutlet weak var accountNameLabel: UILabel?
    @IBOutlet weak var logoImageView: UIImageView?
    @IBOutlet weak var progressView: UIProgressView?
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint?
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint?
    @IBOutlet weak var progressiveBarMarginConstraint: NSLayoutConstraint?
    static var defaultCellHeight: CGFloat = 100
    static var cellIdentifier: String = "TOTPMechanismTableViewCellId"
    var mechanism: TOTPMechanism?
    var currentCode: OathTokenCode?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setMechanism(mechanism: TOTPMechanism, isAccountDetailPage: Bool = false) {
        
        self.mechanism = mechanism
        self.issuerLabel?.text = mechanism.issuer
        if isAccountDetailPage {
            self.imageWidthConstraint?.constant = 30
            self.imageHeightConstraint?.constant = 30
            self.progressiveBarMarginConstraint?.constant = 50
            self.logoImageView?.image = UIImage(named: "TokensIcon")
            self.accountNameLabel?.isHidden = true
            self.issuerLabel?.text = "Time-based One-time Password"
        }
        else {
            self.accountNameLabel?.text = mechanism.accountName + " - \(mechanism.type.uppercased())"
            if let account = FRAClient.shared?.getAccount(identifier: mechanism.issuer + "-" + mechanism.accountName), let logoImageUrl = account.imageUrl, let url = URL(string: logoImageUrl) {
                self.logoImageView?.downloadImageFromUrl(url: url)
            }
            else {
                self.imageWidthConstraint?.constant = 30
                self.imageHeightConstraint?.constant = 30
                self.progressiveBarMarginConstraint?.constant = 50
                self.logoImageView?.image = UIImage(named: "TokensIcon")
            }
        }
        self.progressView?.setProgress(0.0, animated: false)
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (timer) in
            if let code = self.currentCode {
                if code.progress >= 1.0 {
                    self.currentCode = nil
                    DispatchQueue.main.async {
                        self.progressView?.setProgress(0.0, animated: false)
                    }
                }
                else {
                    DispatchQueue.main.async {
                        self.progressView?.setProgress(code.progress, animated: true)
                    }
                }
            }
            else if let mechanism = self.mechanism, let code = try? self.mechanism?.generateCode(){
                self.currentCode = code
                self.codeLabel?.text = code.code.insertSpace(at: mechanism.digits == 6 ? 3 : 4)
                DispatchQueue.main.async {
                    self.progressView?.setProgress(code.progress, animated: false)
                }
            }
            else {
                timer.invalidate()
            }
        }
    }
}
