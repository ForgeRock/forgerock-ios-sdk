//
//  NotificationRequestViewController.swift
//  FRAuthenticatorExample
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuthenticator

class NotificationRequestViewController: BaseViewController {

    @IBOutlet weak var logoImageView: UIImageView?
    @IBOutlet weak var closeButton: UIButton?
    @IBOutlet weak var acceptButton: UIButton?
    @IBOutlet weak var denyButton: UIButton?
    @IBOutlet weak var issuerLabel: UILabel?
    @IBOutlet weak var accountNameLabel: UILabel?
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var topDescriptionLabel: UILabel?
    @IBOutlet weak var issuerLabelTopConstraint: NSLayoutConstraint?
    
    var notification: PushNotification?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Notification"
        
        guard let notification = self.notification else {
            self.dismiss(animated: true)
            return
        }
        
        if !self.isModal {
            self.closeButton?.isHidden = true
        }
        
        if !notification.isPending {
            self.acceptButton?.isHidden = true
            self.denyButton?.isHidden = true
            
            var status = ""
            
            if notification.isApproved {
                status = "had already been approved"
            }
            else if notification.isDenied {
                status = "had already been denied"
            }
            else if notification.isExpired {
                status = "was expired"
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timestamp = dateFormatter.string(from: notification.timeAdded)
            self.topDescriptionLabel?.text = "This PushNotification \(status) \(notification.isExpired ? "" : "\n @ " + timestamp)"
            self.descriptionLabel?.text = "This PushNotification \(status)."
        }
        
        self.logoImageView?.image = nil
        self.issuerLabelTopConstraint?.constant = 125
        if let mechanism = FRAClient.shared?.getMechanism(notification: notification) {
            self.issuerLabel?.text = mechanism.issuer
            self.accountNameLabel?.text = mechanism.accountName
            
            if let account = FRAClient.shared?.getAccount(mechanism: mechanism), let imgUrlStr = account.imageUrl, let url = URL(string: imgUrlStr) {
                self.logoImageView?.downloadImageFromUrl(url: url)
                self.issuerLabelTopConstraint?.constant = 145
            }
        }
        else {
            self.issuerLabel?.text = ""
            self.accountNameLabel?.text = ""
        }
    }
    
    //  MARK: - IBAction
    
    @IBAction func close(sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @IBAction func accept(sender: UIButton) {
        
        guard let notification = self.notification else {
            self.dismiss(animated: true)
            return
        }
        
        notification.accept(onSuccess: {
            DispatchQueue.main.async {
                self.dismiss(animated: true)
            }
        }) { (error) in
            self.displayAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
    @IBAction func deny(sender: UIButton) {
        
        guard let notification = self.notification else {
            self.dismiss(animated: true)
            return
        }
        
        notification.deny(onSuccess: {
            DispatchQueue.main.async {
                self.dismiss(animated: true)
            }
        }) { (error) in
            self.displayAlert(title: "Error", message: error.localizedDescription)
        }
    }
}
