//
//  NotificationListTableViewController.swift
//  FRAuthenticatorExample
//
//  Copyright (c) 2020-2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuthenticator

class NotificationListTableViewController: BaseTableViewController {

    var mechanism: PushMechanism?
    var pendingNotifications: [PushNotification] = []
    var notifications: [PushNotification] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Notifications"
        self.registerCells()
        self.reload()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.reload()
    }
    
    
    func reload() {
        guard let pushMechanism = self.mechanism else {
            fatalError("Error while retrieving PushMechanism")
        }
        self.pendingNotifications = []
        self.notifications = []
        self.startLoading()
        let notifications = FRAClient.shared?.getAllNotifications(mechanism: pushMechanism).sorted(by: {$0.timeAdded > $1.timeAdded}) ?? []
        for notification in notifications {
            if notification.isPending {
                self.pendingNotifications.append(notification)
            }
            else {
                self.notifications.append(notification)
            }
        }
        self.stopLoading()
        if self.notifications.count == 0  && self.pendingNotifications.count == 0{
            self.showNoData()
        }
        else {
            self.hideNoData()
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    func registerCells() {
        self.tableView.register(UINib(nibName: "NotificationTableViewCell", bundle: nil), forCellReuseIdentifier: NotificationTableViewCell.cellIdentifier)
    }
    
    
    // MARK: - TableView DataSource / Delegate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.pendingNotifications.count > 0 ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.pendingNotifications.count > 0 {
            return section == 0 ? "Pending" : "Notifications"
        }
        else {
            return "Notifications"
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.pendingNotifications.count > 0 {
            return section == 0 ? self.pendingNotifications.count : self.notifications.count
        }
        else {
            return self.notifications.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return NotificationTableViewCell.defaultCellHeight
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let list = self.pendingNotifications.count > 0 ? (indexPath.section == 0 ? self.pendingNotifications : self.notifications) : self.notifications
        let notification = list[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NotificationTableViewCell.cellIdentifier, for: indexPath) as! NotificationTableViewCell
        cell.setNotification(notification: notification)
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let list = self.pendingNotifications.count > 0 ? (indexPath.section == 0 ? self.pendingNotifications : self.notifications) : self.notifications
        let notification = list[indexPath.row]
        performSegue(withIdentifier: "showNotificationDetail", sender: notification)
    }
    
    
    //  MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let notification = sender as? PushNotification, segue.identifier == "showNotificationDetail", let viewController = segue.destination as? NotificationRequestViewController {
            viewController.notification = notification
        }
    }
}
