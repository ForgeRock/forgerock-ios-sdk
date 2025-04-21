//
//  AccountDetailTableViewController.swift
//  FRAuthenticatorExample
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuthenticator

class AccountDetailTableViewController: BaseTableViewController {
    
    @IBOutlet weak var issuerLabel: UILabel?
    @IBOutlet weak var accountNameLabel: UILabel?
    @IBOutlet weak var logoImageView: UIImageView?
    @IBOutlet weak var issuerLabelTopConstraint: NSLayoutConstraint?
    
    var account: Account?
    var listData: [Mechanism] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerCells()
        
        let account = self.getAccount()
        self.title = account.issuer
        self.issuerLabel?.text = account.issuer
        self.accountNameLabel?.text = account.accountName
        
        if let imgUrlStr = account.imageUrl, let url = URL(string: imgUrlStr) {
            self.logoImageView?.downloadImageFromUrl(url: url)
        }
        else {
            self.logoImageView?.isHidden = true
            self.issuerLabelTopConstraint?.constant = 95
        }
        self.reload()
    }
    
    
    func reload() {
        self.listData = []
        for mechanism in self.getAccount().mechanisms {
            self.listData.append(mechanism)
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    func registerCells() {
        self.tableView.register(UINib(nibName: "TOTPMechanismTableViewCell", bundle: nil), forCellReuseIdentifier: TOTPMechanismTableViewCell.cellIdentifier)
        self.tableView.register(UINib(nibName: "HOTPMechanismTableViewCell", bundle: nil), forCellReuseIdentifier: HOTPMechanismTableViewCell.cellIdentifier)
        self.tableView.register(UINib(nibName: "PushMechanismTableViewCell", bundle: nil), forCellReuseIdentifier: PushMechanismTableViewCell.cellIdentifier)
    }
    
    func getAccount() -> Account {
        guard let account = self.account else {
            fatalError("Failed to retrieve Account object")
        }
        return account
    }
    
    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.listData.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let item = self.listData[indexPath.row]
        
        if item is TOTPMechanism {
            return TOTPMechanismTableViewCell.defaultCellHeight
        }
        else if item is HOTPMechanism {
            return HOTPMechanismTableViewCell.defaultCellHeight
        }
        else if item is PushMechanism {
            return PushMechanismTableViewCell.defaultCellHeight
        }
        else {
            fatalError("Invalid Mechanism type")
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.listData[indexPath.row]
        if item is TOTPMechanism, let mechanism = item as? TOTPMechanism {
            let cell = tableView.dequeueReusableCell(withIdentifier: TOTPMechanismTableViewCell.cellIdentifier, for: indexPath) as! TOTPMechanismTableViewCell
            cell.setMechanism(mechanism: mechanism, isAccountDetailPage: true)
            return cell
        }
        else if item is HOTPMechanism, let mechanism = item as? HOTPMechanism {
            let cell = tableView.dequeueReusableCell(withIdentifier: HOTPMechanismTableViewCell.cellIdentifier, for: indexPath) as! HOTPMechanismTableViewCell
            cell.setMechanism(mechanism: mechanism, isAccountDetailPage: true)
            return cell
        }
        else if item is PushMechanism, let mechanism = item as? PushMechanism {
            let cell = tableView.dequeueReusableCell(withIdentifier: PushMechanismTableViewCell.cellIdentifier, for: indexPath) as! PushMechanismTableViewCell
            cell.setMechanism(mechanism: mechanism, isAccountDetailPage: true)
            return cell
        }
        else {
            fatalError("Invalid Mechanism type")
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.listData[indexPath.row]
        if item is PushMechanism, let mechanism = item as? PushMechanism {
            performSegue(withIdentifier: "listNotification", sender: mechanism)
        }
    }
    
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alert = UIAlertController(title: "Warning", message: "Deleting this account/mechanism will NOT automatically remove 2-step authentication in this provider. You need to ensure that you disable 2-step authentication from the provider prior to deleting this information.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { (action) in
                let mechanism = self.listData[indexPath.row]
                if let fraClient = FRAClient.shared, fraClient.removeMechanism(mechanism: mechanism) {
                    self.navigationController?.popViewController(animated: true)
                }
                else {
                    self.displayAlert(title: "Error", message: "An unknown error encountered while deleting the Mechanism (\(mechanism.identifier).")
                }
            }))
            self.present(alert, animated: true)
        }
    }
    
    
    //  MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let mechanism = sender as? PushMechanism, segue.identifier == "listNotification", let viewController = segue.destination as? NotificationListTableViewController {
            viewController.mechanism = mechanism
        }
    }
}
