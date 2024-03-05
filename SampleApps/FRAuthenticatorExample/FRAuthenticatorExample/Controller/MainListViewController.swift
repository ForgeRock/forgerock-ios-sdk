//
//  MainListViewController.swift
//  FRAuthenticatorExample
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRCore
import FRAuthenticator

class MainListViewController: BaseTableViewController {

    var listData: [AnyObject] = []
    
    //  MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  Register Cells
        self.registerCells()
        
        //  Init FRAuthenticator SDK
        FRAClient.start()
        //  Set LogLevel
        FRALog.setLogLevel(.all)
        //  Reload tableView
        DispatchQueue.main.async {
            self.reload()
        }
        
        // - MARK: PushRequestInterceptor example
        /// Uncomment the next line to test the http request interceptor...
        //RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [PushRequestInterceptor()])
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    //  MARK: - Private
    
    /// Reloads all Accounts from StorageClient, and refresh tableView
    func reload() {
        self.startLoading()
        let accounts = FRAClient.shared?.getAllAccounts() ?? []
        self.listData = []
        var tmpAccounts: [Account] = []
        var tmpMechanisms: [Mechanism] = []
        for account in accounts {
            if account.mechanisms.count > 1 {
                tmpAccounts.append(account)
            }
            else {
                for mechanism in account.mechanisms {
                    tmpMechanisms.append(mechanism)
                }
            }
        }
        self.listData.append(contentsOf: tmpAccounts)
        self.listData.append(contentsOf: tmpMechanisms)
        self.stopLoading()
        
        if listData.count == 0 {
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
        self.tableView.register(UINib(nibName: "TOTPMechanismTableViewCell", bundle: nil), forCellReuseIdentifier: TOTPMechanismTableViewCell.cellIdentifier)
        self.tableView.register(UINib(nibName: "HOTPMechanismTableViewCell", bundle: nil), forCellReuseIdentifier: HOTPMechanismTableViewCell.cellIdentifier)
        self.tableView.register(UINib(nibName: "PushMechanismTableViewCell", bundle: nil), forCellReuseIdentifier: PushMechanismTableViewCell.cellIdentifier)
        self.tableView.register(UINib(nibName: "AccountTableViewCell", bundle: nil), forCellReuseIdentifier: AccountTableViewCell.cellIdentifier)
    }
    

    //  MARK: - IBAction
    
    @IBAction func scanCode(sender: UIBarButtonItem) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let viewController = sb.instantiateViewController(withIdentifier: "qrCodeScannerViewController")
        //  Assign delegate
        if let scannerViewController = viewController as? QRCodeScannerViewController {
            scannerViewController.delegate = self
        }
        self.present(viewController, animated: true, completion: nil)
    }
    
    
    // MARK: - TableView DataSource / Delegate
    
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
        else if item is Account {
            return AccountTableViewCell.defaultCellHeight
        }
        else {
            fatalError("Invalid Mechanism type")
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let item = self.listData[indexPath.row]
        
        if item is TOTPMechanism, let mechanism = item as? TOTPMechanism {
            let cell = tableView.dequeueReusableCell(withIdentifier: TOTPMechanismTableViewCell.cellIdentifier, for: indexPath) as! TOTPMechanismTableViewCell
            cell.setMechanism(mechanism: mechanism)
            return cell
        }
        else if item is HOTPMechanism, let mechanism = item as? HOTPMechanism {
            let cell = tableView.dequeueReusableCell(withIdentifier: HOTPMechanismTableViewCell.cellIdentifier, for: indexPath) as! HOTPMechanismTableViewCell
            cell.setMechanism(mechanism: mechanism)
            return cell
        }
        else if item is PushMechanism, let mechanism = item as? PushMechanism {
            let cell = tableView.dequeueReusableCell(withIdentifier: PushMechanismTableViewCell.cellIdentifier, for: indexPath) as! PushMechanismTableViewCell
            cell.setMechanism(mechanism: mechanism)
            return cell
        }
        else if item is Account, let account = item as? Account {
            let cell = tableView.dequeueReusableCell(withIdentifier: AccountTableViewCell.cellIdentifier, for: indexPath) as! AccountTableViewCell
            cell.setAccount(account: account)
            return cell
        }
        else {
            fatalError("Invalid Mechanism type")
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        let item = self.listData[indexPath.row]
        
        if item is Account, let account = item as? Account {
            performSegue(withIdentifier: "showAccountDetail", sender: account)
        }
        else if item is PushMechanism, let mechanism = item as? PushMechanism {
            performSegue(withIdentifier: "listNotification", sender: mechanism)
        }
    }
    
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alert = UIAlertController(title: "Warning", message: "Deleting this account/mechanism will NOT automatically remove 2-step authentication in this provider. You need to ensure that you disable 2-step authentication from the provider prior to deleting this information.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { (action) in
                
                let item = self.listData[indexPath.row]
                
                if item is Mechanism, let mechanism = item as? Mechanism {
                    if let fraClient = FRAClient.shared, fraClient.removeMechanism(mechanism: mechanism) {
                        self.reload()
                    }
                    else {
                        self.displayAlert(title: "Error", message: "An unknown error encountered while deleting the Mechanism (\(mechanism.identifier).")
                    }
                }
                else if item is Account, let account = item as? Account {
                    if let fraClient = FRAClient.shared, fraClient.removeAccount(account: account) {
                        self.reload()
                    }
                    else {
                        self.displayAlert(title: "Error", message: "An unknown error encountered while deleting the Account (\(account.identifier).")
                    }
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
        else if let account = sender as? Account, segue.identifier == "showAccountDetail", let viewController = segue.destination as? AccountDetailTableViewController {
            viewController.account = account
        }
    }
}


extension MainListViewController: QRCodeScannerDelegate {
    func onSuccess(qrCode: String) {
        //  Validate if QR Code is in URL format
        guard let url = URL(string: qrCode) else {
            self.displayAlert(title: "Error", message: "Invalid QR Code: QR Code data is not in URL format.")
            return
        }
    
        //  Create and store Mechanism object from QR Code URL
        FRAClient.shared?.createMechanismFromUri(uri: url, onSuccess: { (mechanism) in
            // Reload tableView
            DispatchQueue.main.async {
                self.reload()
            }
        }, onError: { (error) in
            self.displayAlert(title: "Error", message: error.localizedDescription)
        })
    }
    
    func onFailure(error: Error) {
        self.displayAlert(title: "Error", message: error.localizedDescription)
    }
}


/// This is an example http interceptor for testing purposes (SDKS-2545)
class PushRequestInterceptor: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        var headers = request.headers

        if action.type == "PUSH_REGISTER" {
            NotificationRequestViewController.intercepted.append("PUSH_REGISTER")
            headers["testHeader"] = "PUSH_REGISTER"
                    }
        else if action.type == "PUSH_AUTHENTICATE" {
            NotificationRequestViewController.intercepted.append("PUSH_AUTHENTICATE")
            headers["testHeader"] = "PUSH_AUTHENTICATE"
        }

        let newRequest = Request(url: request.url, method: request.method, headers: headers, bodyParams: request.bodyParams, urlParams: request.urlParams, requestType: request.requestType, responseType: request.responseType, timeoutInterval: request.timeoutInterval)

        return newRequest
    }
}

