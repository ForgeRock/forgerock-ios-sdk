//
//  AuthStepViewController.swift
//  FRUI
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuth
import FRCore

protocol AuthStepProtocol {
    func submitNode()
}

class AuthStepViewController: UIViewController {

    // MARK: - Properties
    var tokenCompletion: NodeUICompletion<Token>?
    var atCompletion: NodeUICompletion<AccessToken>?
    var userCompletion: NodeUICompletion<FRUser>?
    var currentNode: Node
    var type: Any?
    var isKeyboardVisible: Bool = false
    var authCallbacks: [Callback] = []
    var authCallbackValues: [String:String] = [:]
    
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var headerLabel: UILabel?
    @IBOutlet weak var descriptionTextView: UITextView?
    @IBOutlet weak var descriptionTextViewHeight: NSLayoutConstraint?
    @IBOutlet weak var cancelButton: FRButton?
    @IBOutlet weak var nextButton: FRButton?
    @IBOutlet weak var closeButton: FRButton?
    @IBOutlet weak var logoImageView: UIImageView?
    
    var loadingView: FRLoadingView = FRLoadingView(size: CGSize(width: 120.0, height: 120.0), showDropShadow: true, showDimmedBackground: true, loadingText: "Loading...")
    
    // MARK: - Init
    
    init<T>(node: Node, uiCompletion: @escaping NodeUICompletion<T>, nibName: String) {
        
        currentNode = node
        
        // Super init
        super.init(nibName: nibName, bundle: Bundle(for: AuthStepViewController.self))
        
        // set completion block
        if T.self as AnyObject? === AccessToken.self {
            self.atCompletion = (uiCompletion as! NodeUICompletion<AccessToken>)
            self.type = AccessToken.self
        }
        else if T.self as AnyObject? === Token.self {
            self.tokenCompletion = (uiCompletion as! NodeUICompletion<Token>)
            self.type = Token.self
        }
        else if T.self as AnyObject? === FRUser.self {
            self.userCompletion = (uiCompletion as! NodeUICompletion<FRUser>)
            self.type = FRUser.self
        }
        
        self.initPrivate()
    }
    
    
    fileprivate func initPrivate() {
        
        // Add loading view
        loadingView.add(inView: self.view)
        
        // Register tableViewCell
        for callbackType in CallbackTableViewCellFactory.shared.tableViewCellNibForCallbacks.keys {
            guard let callbackTableViewCell = CallbackTableViewCellFactory.shared.talbeViewCellForCallbacks[callbackType],
                let callbackTableViewCellNib = CallbackTableViewCellFactory.shared.tableViewCellNibForCallbacks[callbackType] else {
                    return
            }
            
            self.tableView?.register(UINib(nibName: callbackTableViewCellNib, bundle: Bundle(for: callbackTableViewCell.self)), forCellReuseIdentifier: callbackTableViewCell.cellIdentifier)
        }
        
        self.title = "FRUI"
        
        // Notification for Keyboard appearance
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
        self.tableView?.alwaysBounceVertical = false
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.logoImageView?.image = FRUI.shared.logoImage
        self.headerLabel?.textColor = FRUI.shared.primaryTextColor
        self.descriptionTextView?.textColor = FRUI.shared.primaryTextColor
        self.descriptionTextView?.translatesAutoresizingMaskIntoConstraints = true
        self.descriptionTextView?.isScrollEnabled = false
                
        //  Styling buttons
        self.nextButton?.backgroundColor = FRUI.shared.primaryColor
        self.nextButton?.titleColor = UIColor.white
        self.cancelButton?.backgroundColor = FRUI.shared.secondaryColor
        self.cancelButton?.titleColor = UIColor.white
        self.closeButton?.backgroundColor = FRUI.shared.secondaryColor
        self.closeButton?.titleColor = UIColor.white
        
        self.handleNode(nil, self.currentNode, nil)
    }
    
    
    // MARK: - Authentication handling methods
    func handleNode(_ result: Any?, _ node: Node?, _ error: Error?) {
        
        //  Perform UI work in the main thread
        DispatchQueue.main.async {
            
            if let node = node {
                
                //  Set auth callbacks in list for rendering
                self.currentNode = node
                self.authCallbacks = node.callbacks
        
                self.headerLabel?.text = node.pageHeader != nil ? node.pageHeader : node.stage != nil ? node.stage : ""
                if let descriptionText = node.pageDescription {
                    self.descriptionTextView?.setHTMLString(descriptionText)
                }
                else {
                    self.descriptionTextView?.text = ""
                }
                self.descriptionTextView?.sizeToFit()
                let descriptionTextViewHeightConstant = self.descriptionTextView?.frame.size.height ?? 0.0
                self.descriptionTextViewHeight?.constant = descriptionTextViewHeightConstant
                let headerFrame = self.tableView?.tableHeaderView?.bounds ?? CGRect(x: 0, y: 0, width: 0, height: 0)
                self.tableView?.tableHeaderView?.frame = CGRect(x: headerFrame.origin.x, y: headerFrame.origin.y, width: headerFrame.size.width, height: 225 + descriptionTextViewHeightConstant)
                
                var deviceProfileCallback: DeviceProfileCallback?
                for (index, callback) in self.authCallbacks.enumerated() {
                    //  DeviceProfileCallback handling
                    if let thisCallback = callback as? DeviceProfileCallback {
                        deviceProfileCallback = thisCallback
                        if self.authCallbacks.count > 1 {
                            self.authCallbacks.remove(at: index)
                        }
                    }
                    //  SuspendedTextOutputCallback handling
                    else if let _ = callback as? SuspendedTextOutputCallback {
                        self.cancelButton?.isHidden = true
                        self.nextButton?.isHidden = true
                        self.closeButton?.isHidden = false
                    }
                }
                //  If DeviceProfileCallback is found as one of Callbacks, collect data first
                if let deviceProfileCallback = deviceProfileCallback, self.authCallbacks.count > 1 {
                    self.startLoading()
                    deviceProfileCallback.execute { (profile) in
                        self.stopLoading()
                        self.renderAuthStep()
                    }
                }
                else {
                    //  Otherwise, just render as usual
                    self.renderAuthStep()
                }
            }
            else if let result = result {
                
                if result is AccessToken, let completion = self.atCompletion {
                    completion(result as? AccessToken, nil)
                } else if result is Token, let completion = self.tokenCompletion {
                    completion(result as? Token, nil)
                } else if result is FRUser, let completion = self.userCompletion {
                    completion(result as? FRUser, nil)
                }
                //  Close viewController
                self.dismiss(animated: true, completion: nil)
            }
            else if let error = error {
                
                var message = ""
                var dismissAfter = false
                //  Handle error
                if let networkError: NetworkError = error as? NetworkError {
                    
                    switch networkError {
                    case .invalidCredentials(_, _, _):
                        message = "Invalid credentials"
                        break
                    case .authenticationTimeout(_, _, _):
                        message = "Process timed out; please try again"
                        dismissAfter = true
                        break
                    case .apiFailedWithError(_, _, _):
                        message = "Something went wrong; please try again"
                        dismissAfter = false
                        break
                    default:
                        message = error.localizedDescription
                        break
                    }
                }
                else {
                    message = error.localizedDescription
                }
                
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                let action = UIAlertAction(title: "Ok", style: .cancel, handler: { _ in
                    if dismissAfter {
                        self.dismiss(animated: true, completion: nil)
                    }
                })
                alert.addAction(action)
                self.present(alert, animated: true)
            }
            else {
                if let completion = self.atCompletion {
                    completion(nil, nil)
                } else if let completion = self.tokenCompletion {
                    completion(nil, nil)
                } else if let completion = self.userCompletion {
                    completion(nil, nil)
                }
                //  Close viewController
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    
    func renderAuthStep() {
        
        //  Make sure auth step is properly set, and callback(s) is returned
        guard self.currentNode == self.currentNode && self.authCallbacks.count > 0 else {
            self.stopLoading()
            return
        }
        
        //  Reload tableView for rendering with callbacks
        self.tableView?.reloadData()
    }
    
    
    // MARK: - Helper
    func startLoading() {
        loadingView.startLoading()
    }
    
    
    func stopLoading() {
        loadingView.stopLoading()
    }
    
    
    @objc func dismissKeyboard() {
        if isKeyboardVisible {
            self.view.endEditing(true)
        }
    }
    
    
    @objc func keyboardDidShow(_ notification: Notification) {
        if !isKeyboardVisible,
            let info = notification.userInfo,
            let keyboardFrameInfo = info[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue {
            
            let keyboardSize = keyboardFrameInfo.cgRectValue
            self.tableView?.isScrollEnabled = true
            tableView?.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: keyboardSize.size.height, right: 0)
        }
        isKeyboardVisible = true
    }
    
    
    @objc func keyboardDidHide(_ notification: Notification) {
        if isKeyboardVisible {
            self.tableView?.isScrollEnabled = false
            tableView?.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        }
        isKeyboardVisible = false
    }
    
    
    // MARK: - IBOutlet
    @IBAction func nextButtonClicked(sender: UIButton?) {
        //  Force to end editing
        self.view.endEditing(true)
        self.startLoading()
                
        for (identifier, value) in self.authCallbackValues {
            
            for authCallback: Callback in self.authCallbacks
            {
                if authCallback is SingleValueCallback, let callback = authCallback as? SingleValueCallback, callback.inputName == identifier {                    
                    callback.setValue(value)
                }
            }
        }
        
        self.startLoading()
        
        if self.type as AnyObject? === AccessToken.self {
            
            currentNode.next(completion: { (token: AccessToken?, node, error) in
                
                //  Perform UI work in the main thread
                DispatchQueue.main.async {
                    self.stopLoading()
                    self.handleNode(token, node, error)
                }
            })
        } else if self.type as AnyObject? === Token.self {
            
            currentNode.next(completion: { (token: Token?, node, error) in
                
                //  Perform UI work in the main thread
                DispatchQueue.main.async {
                    self.stopLoading()
                    self.handleNode(token, node, error)
                }
            })
        } else if self.type as AnyObject? === FRUser.self {
            currentNode.next { (user: FRUser?, node, error) in
                
                //  Perform UI work in the main thread
                DispatchQueue.main.async {
                    self.stopLoading()
                    self.handleNode(user, node, error)
                }
            }
        }
    }
    
    @IBAction func cancelButtonClicked(sender: UIButton) {
        
        if let completion = self.atCompletion {
            completion(nil, AuthError.authenticationCancelled)
        } else if let completion = self.tokenCompletion {
            completion(nil, AuthError.authenticationCancelled)
        } else if let completion = self.userCompletion {
            completion(nil, AuthError.authenticationCancelled)
        }
        
        //  Force to end editing
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeButtonClicked(sender: UIButton) {
        if let completion = self.atCompletion {
            completion(nil, nil)
        } else if let completion = self.tokenCompletion {
            completion(nil, nil)
        } else if let completion = self.userCompletion {
            completion(nil, nil)
        }
        
        //  Force to end editing
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }
}


// MARK: - UITableViewDataSource
extension AuthStepViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //  deque reusable cell with the custom cell's identifier
        
        if indexPath.row == self.authCallbacks.count - 1 {
            self.stopLoading()
        }
        
        let callback = self.authCallbacks[indexPath.row]
        
        
        if let callbackTableViewCell: FRUICallbackTableViewCell.Type = CallbackTableViewCellFactory.shared.talbeViewCellForCallbacks[callback.type],
            let callbackTableViewCellNib = CallbackTableViewCellFactory.shared.tableViewCellNibForCallbacks[callback.type] {
            let cell = Bundle(for: callbackTableViewCell.self).loadNibNamed(callbackTableViewCellNib, owner: self, options: nil)?.first as! FRUICallbackTableViewCell
            cell.updateCellData(callback: callback)
            
            if let confirmationCallbackCell = cell as? ConfirmationCallbackTableViewCell {
                confirmationCallbackCell.delegate = self
            }
            else if let pollingWaitCallbackCell = cell as? PollingWaitCallbackTableViewCell {
                pollingWaitCallbackCell.delegate = self
            }
            else if let deviceProfileCallbackCell = cell as? DeviceAttributeTableViewCell {
                deviceProfileCallbackCell.delegate = self
            }
            
            return cell
        }
        else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.authCallbacks.count
    }
}


// MARK: - AuthStepProtocol
extension AuthStepViewController: AuthStepProtocol {
    
    func submitNode() {
        nextButtonClicked(sender: nil)
    }
}


// MARK: - UITableViewDelegate
extension AuthStepViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let callback = self.authCallbacks[indexPath.row]
        
        var cellHeight: CGFloat = 0.0
        
        if let callbackTableViewCell: FRUICallbackTableViewCell.Type = CallbackTableViewCellFactory.shared.talbeViewCellForCallbacks[callback.type] {
            cellHeight = callbackTableViewCell.cellHeight
        }
        
        return cellHeight
    }
}
