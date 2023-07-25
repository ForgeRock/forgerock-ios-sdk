//
//  NotificationRequestViewController.swift
//  FRAuthenticatorExample
//
//  Copyright (c) 2020-2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRCore
import FRAuthenticator
import CoreLocation

class NotificationRequestViewController: BaseViewController {
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var denyButton: UIButton!
    @IBOutlet weak var issuerLabel: UILabel!
    @IBOutlet weak var accountNameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var topDescriptionLabel: UILabel!
    @IBOutlet weak var issuerLabelTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationView: UIView!
    @IBOutlet weak var numbersChallengeStackView: UIStackView!
    
    var notification: PushNotification?
    static var intercepted: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Notification"
        
        acceptButton.setImage(UIImage(named: "ApprovedIcon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        denyButton.setImage(UIImage(named: "DeniedIcon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        
        
        guard let notification = self.notification else {
            self.dismiss(animated: true)
            return
        }
        
        if !self.isModal {
            self.closeButton.isHidden = true
        }
        
        if !notification.isPending {
            self.acceptButton.isHidden = true
            self.denyButton.isHidden = true
            self.locationView.isHidden = true
            self.numbersChallengeStackView.isHidden = true
            
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
            self.topDescriptionLabel.text = "This PushNotification \(status) \(notification.isExpired ? "" : "\n @ " + timestamp)"
            self.descriptionLabel.text = "This PushNotification \(status)."
        } else {
            
            let pushType = notification.pushType
            switch pushType {
            case .default:
                acceptButton.isHidden = false
                denyButton.isHidden = false
                numbersChallengeStackView.isHidden = true
                descriptionLabel.text = "Tap Accept or Deny button to allow or reject this login request."
            case .challenge:
                acceptButton.isHidden = true
                denyButton.isHidden = false
                numbersChallengeStackView.isHidden = false
                descriptionLabel.text = "Please choose the right number to allow this login request or tap Deny button to reject."
                if let numbers = notification.numbersChallengeArray,
                   let buttons = numbersChallengeStackView.arrangedSubviews as? [UIButton],
                   numbers.count == buttons.count {
                    for (index, button) in buttons.enumerated() {
                        button.setTitle("\(numbers[index])", for: .normal)
                        button.addTarget(self, action: #selector(self.numberButtonTapped), for: .touchUpInside)
                    }
                }
                break
            case .biometric:
                acceptButton.isHidden = false
                denyButton.isHidden = false
                numbersChallengeStackView.isHidden = true
                acceptButton.setTitle("Accept with Biometric", for: .normal)
                descriptionLabel.text = "Tap Accept with Biometric to allow this login request or tap Deny button to reject it."
                
            }
            
            //location
            if let contextInfoData = notification.contextInfo?.data(using: .utf8),
               let contextinfo = try? JSONSerialization.jsonObject(with: contextInfoData, options: []) as? [String : Any],
               let location = contextinfo["location"] as? [String: Any],
               let latitude = location["latitude"] as? Double,
               let longitude = location["longitude"] as? Double{
                getAddressFrom(latitude: latitude, longitude: longitude) { address in
                    self.locationLabel.text = address
                }
                
            } else {
                locationView.isHidden = true
            }
            
        }
        
        self.logoImageView.image = nil
        self.issuerLabelTopConstraint.constant = 125
        if let mechanism = FRAClient.shared?.getMechanism(notification: notification) {
            self.issuerLabel.text = mechanism.issuer
            self.accountNameLabel.text = mechanism.accountName
            
            if let account = FRAClient.shared?.getAccount(mechanism: mechanism), let imgUrlStr = account.imageUrl, let url = URL(string: imgUrlStr) {
                self.logoImageView.downloadImageFromUrl(url: url)
                self.issuerLabelTopConstraint.constant = 145
            }
        }
        else {
            self.issuerLabel.text = ""
            self.accountNameLabel.text = ""
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
        if notification.pushType == .default {
            notification.accept(onSuccess: {
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }
            }) { (error) in
                self.displayAlert(title: "Error", message: error.localizedDescription)
            }
        } else if notification.pushType == .biometric {
            notification.accept(title: "Please authenticate", allowDeviceCredentials: true) {
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }
            } onError: { error in
                self.displayAlert(title: "Error", message: error.localizedDescription)
            }
        } else {
            self.displayAlert(title: "Error", message: "Push Type not supported")
        }
    }
    
    @objc func numberButtonTapped(sender : UIButton) {
        guard let notification = self.notification,
              let selectedNumber = sender.title(for: .normal) else {
            self.dismiss(animated: true)
            return
        }
        if notification.pushType == .challenge {
            notification.accept(challengeResponse: selectedNumber, onSuccess: {
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }
            }) { (error) in
                self.displayAlert(title: "Error", message: error.localizedDescription)
            }
        } else {
            self.displayAlert(title: "Error", message: "Push Type not supported")
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

extension NotificationRequestViewController {
    func getAddressFrom(latitude: Double, longitude: Double, handler: @escaping (String?) -> Void) {
        let location: CLLocation = CLLocation(latitude: latitude, longitude: longitude)
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error ) in
            if error == nil, let placemark = placemarks?.first {
                handler("\(placemark.locality ?? ""), \(placemark.country ?? "")")
            } else {
                handler(nil)
            }
        }
    }
    
}
