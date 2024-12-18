//
//  ClientDevicesTableViewController.swift
//  FRExample
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRAuth

@available(iOS 13.0.0, *)
class ClientDevicesTableViewController: UITableViewController, AlertShowing {
    let identifier = "cell123"
    let deviceRepo = DeviceClient()
    var devices: [DeviceType: [Device]] = [.oath : [],
                                           .push : [],
                                           .binding : [],
                                           .webAuthn : [],
                                           .profile : []]
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Client Devices"
        self.reloadAllDevices()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices[DeviceType(rawValue: section)!]?.count ?? 0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return DeviceType.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.identifier)
        ?? UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: self.identifier)
        
        cell.textLabel?.text = "\(devices[DeviceType(rawValue: indexPath.section)!]?[indexPath.row].deviceName ?? "")"
        cell.detailTextLabel?.text = "\(devices[DeviceType(rawValue: indexPath.section)!]?[indexPath.row].id ?? "")"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return DeviceType(rawValue: section)?.description
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as! UITableViewHeaderFooterView).contentView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor.white
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let device = devices[DeviceType(rawValue: indexPath.section)!]![indexPath.row]
        showAlert(title: device.deviceName, message: String(describing: device))
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var actions = [UIContextualAction]()
        let deviceType = DeviceType(rawValue: indexPath.section)!
        let device = self.devices[deviceType]![indexPath.row]
        
        // Delete action
        let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completion) in
            let alert = UIAlertController(title: "Delete Device", message: "Are you sure you want to delete device \"\(device.deviceName)\"?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (alert: UIAlertAction!) in
                Task {
                    do {
                      if let device = device as? BoundDevice {
                          try await self.deviceRepo.bound.delete(device)
                      } else if let device = device as? ProfileDevice {
                          try await self.deviceRepo.profile.delete(device)
                      } else if let device = device as? WebAuthnDevice {
                          try await self.deviceRepo.webAuthn.delete(device)
                      }else if let device = device as? OathDevice {
                          try await self.deviceRepo.oath.delete(device)
                      }else if let device = device as? PushDevice {
                        try await self.deviceRepo.push.delete(device)
                      }
                    } catch AuthApiError.apiFailureWithMessage(let reason, let message, let code, _) {
                        self.showAlert(title: reason, message: message + " -  \(String(describing: code ?? 0))")
                    }
                    self.reloadAllDevices()
                }
                completion(true)
            }))
            
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (alert: UIAlertAction!) in
                completion(true)
            }))
            
            self.present(alert, animated: true, completion: nil)
            
        }
        actions.append(delete)
        
        // Edit Action
        if deviceType.isEditable {
            let edit = UIContextualAction(style: .normal, title: "Edit") { (action, view, completion) in
                
                let alert =  UIAlertController(title: "Edit Device Name", message: device.id, preferredStyle: .alert)
                alert.addTextField { textField in
                    textField.text = device.deviceName
                }
                
                let okAction = UIAlertAction(title: "Submit", style: .default) {  [unowned alert] _ in
                    let updateDeviceName = alert.textFields![0].text!
                    Task {
                        do {
                            if var device = device as? BoundDevice {
                                device.deviceName = updateDeviceName
                                try await self.deviceRepo.bound.update(device)
                            } else if var device = device as? ProfileDevice {
                                device.deviceName = updateDeviceName
                                try await self.deviceRepo.profile.update(device)
                            } else if var device = device as? WebAuthnDevice {
                                device.deviceName = updateDeviceName
                                try await self.deviceRepo.webAuthn.update(device)
                            }
                        } catch AuthApiError.apiFailureWithMessage(let reason, let message, let code, _) {
                            self.showAlert(title: reason, message: message + " -  \(String(describing: code ?? 0))")
                        }
                        self.reloadAllDevices()
                    }
                }
                alert.addAction(okAction)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                    completion(true)
                })
                alert.addAction(cancelAction)
                
                self.present(alert, animated: true, completion: nil)
                
                completion(true)
            }
            edit.backgroundColor = UIColor(red: 255/255.0, green: 128.0/255.0, blue: 0.0, alpha: 1.0)
            actions.append(edit)
        }
        
        let swipeConfiguration = UISwipeActionsConfiguration(actions: actions)
        swipeConfiguration.performsFirstActionWithFullSwipe = false
        return swipeConfiguration
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    private func reloadAllDevices() {
        Task {
            do {
              let oathDevices = try await deviceRepo.oath.get()
                devices[.oath] = oathDevices
                self.tableView.reloadData()
            } catch AuthApiError.apiFailureWithMessage(let reason, let message, let code, _) {
                self.showAlert(title: "Oath Devices - " + reason, message: message + " -  \(String(describing: code ?? 0))")
            }
            
            do {
                let pushDevices = try await deviceRepo.push.get()
                devices[.push] = pushDevices
                self.tableView.reloadData()
            } catch AuthApiError.apiFailureWithMessage(let reason, let message, let code, _) {
                self.showAlert(title: "Push Devices - " + reason, message: message + " -  \(String(describing: code ?? 0))")
            }
            
            do {
                let webAuthnDevices = try await deviceRepo.webAuthn.get()
                devices[.webAuthn] = webAuthnDevices
                self.tableView.reloadData()
            } catch AuthApiError.apiFailureWithMessage(let reason, let message, let code, _) {
                self.showAlert(title: "WebAuthn Devices - " + reason, message: message + " -  \(String(describing: code ?? 0))")
            }
            
            do {
              let bindingDevices = try await deviceRepo.bound.get()
                devices[.binding] = bindingDevices
                self.tableView.reloadData()
            } catch AuthApiError.apiFailureWithMessage(let reason, let message, let code, _) {
                self.showAlert(title: "Binding Devices - " + reason, message: message + " -  \(String(describing: code ?? 0))")
            }
            
            do {
                let profileDevices = try await deviceRepo.profile.get()
                devices[.profile] = profileDevices
                self.tableView.reloadData()
            } catch AuthApiError.apiFailureWithMessage(let reason, let message, let code, _) {
                self.showAlert(title: "Profile Devices - " + reason, message: message + " -  \(String(describing: code ?? 0))")
            }
        }
    }
    
    enum DeviceType: Int {
        case oath = 0
        case binding
        case push
        case webAuthn
        case profile
        
        static var allCases: [DeviceType] { return [.oath, .binding, .push, .webAuthn, .profile] }
        
        var description: String {
            switch self {
            case .binding:
                return "Binding Devices"
            case .oath:
                return "Oath Devices"
            case .profile:
                return "Profile Devices"
            case .push:
                return "Push Devices"
            case .webAuthn:
                return "WebAuthn Devices"
            }
        }
        
        var isEditable: Bool {
            switch self {
            case .binding, .profile, .webAuthn:
                return true
            case .oath, .push:
                return false
            }
        }
    }
}
