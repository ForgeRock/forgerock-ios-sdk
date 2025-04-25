//
//  NotificationTableViewCell.swift
//  FRAuthenticatorExample
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuthenticator

class NotificationTableViewCell: BaseTableViewCell {

    @IBOutlet weak var iconImageView: UIImageView?
    @IBOutlet weak var timestampLabel: UILabel?
    static var defaultCellHeight: CGFloat = 80
    static var cellIdentifier: String = "NotificationTableViewCellId"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    func setNotification(notification: PushNotification) {
        if notification.isPending {
            self.iconImageView?.image = UIImage(named: "PendingIcon")
        }
        else if notification.isApproved {
            self.iconImageView?.image = UIImage(named: "ApprovedIcon")
        }
        else if notification.isExpired {
            self.iconImageView?.image = UIImage(named: "DeniedIcon")
        }
        else if notification.isDenied {
            self.iconImageView?.image = UIImage(named: "DeniedIcon")
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.timestampLabel?.text = dateFormatter.string(from: notification.timeAdded)
    }
}
