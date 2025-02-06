//
//  BaseTableViewController.swift
//  FRAuthenticatorExample
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit

class BaseTableViewController: UITableViewController {

    var loadingView: LoadingView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        let loading = LoadingView(frame: self.view.bounds)
        view.addSubview(loading)
        loading.translatesAutoresizingMaskIntoConstraints = true
        loading.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        loading.autoresizingMask = [UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleRightMargin, UIView.AutoresizingMask.flexibleTopMargin, UIView.AutoresizingMask.flexibleBottomMargin]
        self.loadingView = loading
        loadingView?.alpha = 0.0
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
 
    func displayAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    
    func showNoData() {
        
        self.tableView.separatorStyle = .none
        self.loadingView?.label?.text = "No data found"
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5) {
                self.loadingView?.alpha = 1.0
            }
        }
    }
    
    
    func hideNoData() {
        self.tableView.separatorStyle = .singleLineEtched
    }
    
    
    func startLoading() {
        self.tableView.separatorStyle = .none
        self.loadingView?.label?.text = "Loading..."
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5) {
                self.loadingView?.alpha = 1.0
            }
        }
    }
    
    
    func stopLoading() {
        self.tableView.separatorStyle = .singleLineEtched
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5) {
                self.loadingView?.alpha = 0.0
            }
        }
    }
}
