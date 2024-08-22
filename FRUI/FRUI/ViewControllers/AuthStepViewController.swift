//
//  AuthStepViewController.swift
//  FRUI
//
//  Copyright (c) 2019-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuth
import FRCore
import FRDeviceBinding
import FRCaptchaEnterprise

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
    var listItem: [Any] = []
    var selectIdPCallback: SelectIdPCallback?

    
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var headerLabel: UILabel?
    @IBOutlet weak var descriptionTextView: UITextView?
    @IBOutlet weak var descriptionTextViewHeight: NSLayoutConstraint?
    @IBOutlet weak var cancelButton: FRButton?
    @IBOutlet weak var nextButton: FRButton?
    @IBOutlet weak var extraButton: FRButton?
    @IBOutlet weak var extraButtonHeight: NSLayoutConstraint?
    @IBOutlet weak var logoImageView: UIImageView?
    
    var loadingView: FRLoadingView = FRLoadingView(size: CGSize(width: 120.0, height: 120.0), showDropShadow: true, showDimmedBackground: true, loadingText: "Loading...")
    
    // MARK: - Init
    
    init<T>(node: Node, uiCompletion: @escaping NodeUICompletion<T>, nibName: String) {
        
        currentNode = node
        
        // Super init
        #if SWIFT_PACKAGE
        super.init(nibName: nibName, bundle: Bundle.module)
        #else
        super.init(nibName: nibName, bundle: Bundle(for: AuthStepViewController.self))
        #endif
        
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
            
            #if SWIFT_PACKAGE
            self.tableView?.register(UINib(nibName: callbackTableViewCellNib, bundle: Bundle.module), forCellReuseIdentifier: callbackTableViewCell.cellIdentifier)
            #else
            self.tableView?.register(UINib(nibName: callbackTableViewCellNib, bundle: Bundle(for: callbackTableViewCell.self)), forCellReuseIdentifier: callbackTableViewCell.cellIdentifier)
            #endif
        }
        #if SWIFT_PACKAGE
        self.tableView?.register(UINib(nibName: "IdPValueTableViewCell", bundle: Bundle.module), forCellReuseIdentifier: IdPValueTableViewCell.cellIdentifier)
        #else
        self.tableView?.register(UINib(nibName: "IdPValueTableViewCell", bundle: Bundle(for: IdPValueTableViewCell.self)), forCellReuseIdentifier: IdPValueTableViewCell.cellIdentifier)
        #endif

        
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
        self.extraButton?.backgroundColor = FRUI.shared.primaryColor
        self.extraButton?.titleColor = UIColor.white
        
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
                }
                //  If DeviceProfileCallback is found as one of Callbacks, collect data first
                if let deviceProfileCallback = deviceProfileCallback, self.authCallbacks.count > 1 {
                    self.startLoading()
                    deviceProfileCallback.execute { (profile) in
                        self.stopLoading()
                        self.renderAuthStep()
                    }
                }
                
              
              var captcha: ReCaptchaEnterpriseCallback?
              for (_, callback) in self.authCallbacks.enumerated() {
                  //  DeviceBindingCallback handling
                  if let thisCallback = callback as? ReCaptchaEnterpriseCallback {
                    captcha = thisCallback
                  }
              }
              
              if let captcha = captcha {
                let alert = UIAlertController(title: "Captcha Result", message: nil, preferredStyle: .alert)
                let action = UIAlertAction(title: "Ok", style: .cancel, handler: { _ in })
                alert.addAction(action)
                self.startLoading()
                if #available(iOS 13.0, *) {
                    Task {
                        do {
                          try await captcha.execute(action: "login")
                          alert.message = "Success"
                          self.present(alert, animated: true)
                        }
                        catch let error as RecaptchaError {
                          alert.message = error.localizedDescription
                          self.present(alert, animated: true)
                        }
                        self.stopLoading()
                    }
                }
              }
                
                var appIntegrity: FRAppIntegrityCallback?
                for (_, callback) in self.authCallbacks.enumerated() {
                    //  DeviceBindingCallback handling
                    if let thisCallback = callback as? FRAppIntegrityCallback {
                        appIntegrity = thisCallback
                    }
                }
                
                if let appIntegrity = appIntegrity {
                    let alert = UIAlertController(title: "App Attestation Result", message: nil, preferredStyle: .alert)
                    let action = UIAlertAction(title: "Ok", style: .cancel, handler: { _ in })
                    alert.addAction(action)
                    self.startLoading()
                    if #available(iOS 14.0, *) {
                        Task {
                            do {
                                try await appIntegrity.requestIntegrityToken()
                                alert.message = "Success"
                            }
                            catch let error {
                                alert.message = (error as? FRDeviceCheckAPIFailure)?.rawValue
                            }
                            self.stopLoading()
                            await MainActor.run {
                                if appIntegrity.isAttestationCompleted() {
                                    self.present(alert, animated: true)
                                } else {
                                    self.submitCurrentNode()
                                }
                            }
                        }
                    } else {
                        alert.message = "Unsupported"
                        appIntegrity.setClientError(FRAppIntegrityClientError.unSupported.rawValue)
                        self.stopLoading()
                        self.present(alert, animated: true)
                    }
                }
                
                //
                var deviceBindingCallback: DeviceBindingCallback?
                for (index, callback) in self.authCallbacks.enumerated() {
                    //  DeviceBindingCallback handling
                    if let thisCallback = callback as? DeviceBindingCallback {
                        deviceBindingCallback = thisCallback
                    }
                }
                
                //  If DeviceBindingCallback is found as one of Callbacks, bind the device and show the authentication result
                if let deviceBindingCallback = deviceBindingCallback {
                    self.startLoading()
                    deviceBindingCallback.bind() { result in
                        DispatchQueue.main.async {
                            self.stopLoading()
                            var bindingResult = ""
                            switch result {
                            case .success:
                                bindingResult = "Success"
                            case .failure(let error):
                                bindingResult = error.errorMessage
                            }
                            
                            let alert = UIAlertController(title: "Binding Result", message: bindingResult, preferredStyle: .alert)
                            let action = UIAlertAction(title: "Ok", style: .cancel, handler: { _ in
                                self.submitCurrentNode()
                                
                            })
                            alert.addAction(action)
                            self.present(alert, animated: true)
                        }
                    }
                }
                
                var deviceSigningVerifierCallback: DeviceSigningVerifierCallback?
                for (index, callback) in self.authCallbacks.enumerated() {
                    //  DeviceBindingCallback handling
                    if let thisCallback = callback as? DeviceSigningVerifierCallback {
                        deviceSigningVerifierCallback = thisCallback
                    }
                }
                
                //  If DeviceSigningVerifierCallback is found as one of Callbacks, verify signature and show the result
                if let deviceSigningVerifierCallback = deviceSigningVerifierCallback {
                    self.startLoading()
                    deviceSigningVerifierCallback.sign() { result in
                        DispatchQueue.main.async {
                            self.stopLoading()
                            var bindingResult = ""
                            switch result {
                            case .success:
                                bindingResult = "Success"
                            case .failure(let error):
                                bindingResult = error.errorMessage
                            }
                            
                            let alert = UIAlertController(title: "Signing Verifier Result", message: bindingResult, preferredStyle: .alert)
                            let action = UIAlertAction(title: "Ok", style: .cancel, handler: { _ in
                                self.submitCurrentNode()
                                
                            })
                            alert.addAction(action)
                            self.present(alert, animated: true)
                        }
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
                var title = "Error"
                var dismissAfter = false
                //  Handle error
                if let authApiError: AuthApiError = error as? AuthApiError {
                    
                    switch authApiError {
                    case .authenticationTimout:
                        message = "Process timed out; please try again"
                        dismissAfter = true
                        break
                    case .apiFailureWithMessage(let reason, let errorMessage, _, _):
                        title = reason
                        message = errorMessage
                        break
                    default:
                        message = "Something went wrong; please try again"
                        break
                    }
                }
                else {
                    message = error.localizedDescription
                }
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
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
        
        //  Set all button states to normal
        self.extraButtonHeight?.constant = 0
        self.cancelButton?.isHidden = false
        self.nextButton?.isHidden = false
        self.extraButton?.isHidden = true
        
        //  Make sure auth step is properly set, and callback(s) is returned
        guard self.currentNode == self.currentNode && self.authCallbacks.count > 0 else {
            self.stopLoading()
            return
        }
        
        var listItems: [Any] = []
        var containsLA: Bool = false
        for callback in self.authCallbacks {
            if let idpCallback = callback as? SelectIdPCallback {
                for provider in idpCallback.providers {
                    if provider.provider == "localAuthentication" {
                        containsLA = true
                    }
                    else {
                        listItems.append(provider)
                    }
                }
                self.selectIdPCallback = idpCallback
            }
            else {
                listItems.append(callback)
            }
        }
        self.listItem = listItems
        
        let containsIdP = self.listItem.contains(where: { $0 is IdPValue })
        let containsCallback = self.listItem.contains(where: { $0 is Callback })
        
        //  If the array only contains IdPValue, hide Next button
        if containsIdP && !containsCallback {
            self.nextButton?.isHidden = true
        }
        
        //  If the array only contains IdPValue, and Local Authentication is allowed, display Sign-in with Username button
        if containsLA && !containsCallback {
            self.extraButtonHeight?.constant = 45
            self.extraButton?.isHidden = false
            self.extraButton?.setTitle("Sign-in with Username", for: .normal)
        }
        
        //  If an array of Callbacks contains SuspendedTextOutputCallback, display Close button
        if self.authCallbacks.contains(where: { $0 is SuspendedTextOutputCallback }) {
            self.cancelButton?.isHidden = true
            self.nextButton?.isHidden = true
            self.extraButton?.setTitle("Close", for: .normal)
            self.extraButtonHeight?.constant = 45.0
            self.extraButton?.isHidden = false
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
    
    
    func submitCurrentNode() {
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
    
    
    // MARK: - IBOutlet
    @IBAction func nextButtonClicked(sender: UIButton?) {
        //  Force to end editing
        self.view.endEditing(true)
        self.startLoading()
        
        self.submitCurrentNode()
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
    
    
    @IBAction func extraButtonClicked(sender: UIButton) {
        
        var laProvider: IdPValue?
        if let selectIdPCallback = self.selectIdPCallback {
            for provider in selectIdPCallback.providers {
                if provider.provider == "localAuthentication" {
                    laProvider = provider
                }
            }
        }
        let containsCallback = self.listItem.contains(where: { $0 is Callback })
        
        //  If Local Authentication provider exists, and there is no Callback, then submit the Node with Local Authentication provider
        if let provider = laProvider, !containsCallback {
            self.selectIdPCallback?.setProvider(provider: provider)
            self.submitCurrentNode()
        }
        else {
            //  If not, it's Close button action for SuspendedTextOutputcallback
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
}


// MARK: - UITableViewDataSource
extension AuthStepViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //  deque reusable cell with the custom cell's identifier
        
        if indexPath.row == self.listItem.count - 1 {
            self.stopLoading()
        }
        
        if let callback = self.listItem[indexPath.row] as? Callback,
           let callbackTableViewCell: FRUICallbackTableViewCell.Type = CallbackTableViewCellFactory.shared.talbeViewCellForCallbacks[callback.type],
           let callbackTableViewCellNib = CallbackTableViewCellFactory.shared.tableViewCellNibForCallbacks[callback.type] {

            #if SWIFT_PACKAGE
            let cell = Bundle.module.loadNibNamed(callbackTableViewCellNib, owner: self, options: nil)?.first as! FRUICallbackTableViewCell
            #else
            let cell = Bundle(for: callbackTableViewCell.self).loadNibNamed(callbackTableViewCellNib, owner: self, options: nil)?.first as! FRUICallbackTableViewCell
            #endif
            
            if let confirmationCallbackCell = cell as? ConfirmationCallbackTableViewCell {
                confirmationCallbackCell.delegate = self
            }
            else if let pollingWaitCallbackCell = cell as? PollingWaitCallbackTableViewCell {
                pollingWaitCallbackCell.delegate = self
            }
            else if let deviceProfileCallbackCell = cell as? DeviceAttributeTableViewCell {
                deviceProfileCallbackCell.delegate = self
            }
            else if let idpCallbackCell = cell as? IdPCallbackTableViewCell {
                idpCallbackCell.delegate = self
                idpCallbackCell.presentingViewController = self
            }
            else if let webAuthnCallback = cell as? WebAuthnCallbackTableViewCell {
                webAuthnCallback.delegate = self
                webAuthnCallback.viewController = self
                webAuthnCallback.updateCellWithViewController(callback: callback, node: self.currentNode)
            }
            
            cell.selectionStyle = .none
            cell.updateCellData(callback: callback)
            return cell
        }
        else if let provider = self.listItem[indexPath.row] as? IdPValue, let callback = self.selectIdPCallback {
            #if SWIFT_PACKAGE
            let cell = Bundle.module.loadNibNamed("IdPValueTableViewCell", owner: self, options: nil)?.first as! IdPValueTableViewCell
            #else
            let cell = Bundle(for: IdPValueTableViewCell.self).loadNibNamed("IdPValueTableViewCell", owner: self, options: nil)?.first as! IdPValueTableViewCell
            #endif
            
            cell.updateCellData(callback: callback)
            cell.updateCellWithProvider(provider: provider)
            cell.delegate = self
            cell.selectionStyle = .none
            return cell
        }
        else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.listItem.count
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
        if let provider = self.listItem[indexPath.row] as? IdPValue, let callback = self.selectIdPCallback {
            callback.setProvider(provider: provider)
            self.submitNode()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        var cellHeight: CGFloat = 0.0
        if let thisCell = self.listItem[indexPath.row] as? Callback {
            if let callbackTableViewCell: FRUICallbackTableViewCell.Type = CallbackTableViewCellFactory.shared.talbeViewCellForCallbacks[thisCell.type] {
                cellHeight = callbackTableViewCell.cellHeight
            }
        }
        else if let _ = self.listItem[indexPath.row] as? IdPValue {
            cellHeight = IdPValueTableViewCell.cellHeight
        }
        
        return cellHeight
    }
}
