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

protocol AuthStepProtocol {
    func submitNode()
}

class AuthStepViewController: UIViewController {

    // MARK: - Properties
    var tokenCompletion: NodeUICompletion<Token>?
    var atCompletion: NodeUICompletion<AccessToken>?
    var userCompletion: NodeUICompletion<FRUser>?
    var currentNode: Node?
    var authService: AuthService?
    var type: Any?
    var flowType: FRAuthFlowType?
    var isKeyboardVisible: Bool = false
    var authCallbacks: [Callback] = []
    var authCallbackValues: [String:String] = [:]
    var authIndexValue: String?
    var authIndexType: String?
    
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var authStepLabel: UILabel?
    @IBOutlet weak var cancelButton: FRButton?
    @IBOutlet weak var nextButton: FRButton?
    @IBOutlet weak var logoImageView: UIImageView?
    
    var loadingView: FRLoadingView = FRLoadingView(size: CGSize(width: 120.0, height: 120.0), showDropShadow: true, showDimmedBackground: true, loadingText: "Loading...")
    
    // MARK: - Init
    
    init<T>(authIndexValue: String, authIndexType: String, uiCompletion: @escaping NodeUICompletion<T>, nibName: String) {
        self.authIndexValue = authIndexValue
        self.authIndexType = authIndexType
        
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
        
        // Super init
        super.init(nibName: nibName, bundle: Bundle(for: AuthStepViewController.self))
        
        self.initPrivate()
    }
    
    init<T>(flowType: FRAuthFlowType?, uiCompletion: @escaping NodeUICompletion<T>, nibName: String) {
        
        // set completion block
        if T.self as AnyObject? === AccessToken.self {
            self.atCompletion = (uiCompletion as! NodeUICompletion<AccessToken>)
            self.type = AccessToken.self
        }
        else if T.self as AnyObject? === FRUser.self {
            self.userCompletion = (uiCompletion as! NodeUICompletion<FRUser>)
            self.type = FRUser.self
        }
        
        self.flowType = flowType
        
        // Super init
        super.init(nibName: nibName, bundle: Bundle(for: AuthStepViewController.self))
        
        self.initPrivate()
    }
    
    
    init<T>(authService: AuthService, uiCompletion: @escaping NodeUICompletion<T>, nibName: String) {
        // set AuthService
        self.authService = authService
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
        
        // Super init
        super.init(nibName: nibName, bundle: Bundle(for: AuthStepViewController.self))
        
        self.initPrivate()
    }
    
    fileprivate func initPrivate() {
        
        // Add loading view
        loadingView.add(inView: self.view)
        
        // Register tableViewCell
        self.tableView?.register(UINib(nibName: "NameCallbackTableViewCell", bundle: Bundle(for: AuthStepViewController.self)), forCellReuseIdentifier: NameCallbackTableViewCell.cellIdentifier)
        self.tableView?.register(UINib(nibName: "PasswordCallbackTableViewCell", bundle: Bundle(for: AuthStepViewController.self)), forCellReuseIdentifier: PasswordCallbackTableViewCell.cellIdentifier)
        self.tableView?.register(UINib(nibName: "ChoiceCallbackTableViewCell", bundle: Bundle(for: AuthStepViewController.self)), forCellReuseIdentifier: ChoiceCallbackTableViewCell.cellIdentifier)
        self.tableView?.register(UINib(nibName: "TermsAndConditionsTableViewCell", bundle: Bundle(for: AuthStepViewController.self)), forCellReuseIdentifier: TermsAndConditionsTableViewCell.cellIdentifier)
        self.tableView?.register(UINib(nibName: "KbaCreateCallbackTableViewCell", bundle: Bundle(for: AuthStepViewController.self)), forCellReuseIdentifier: KbaCreateCallbackTableViewCell.cellIdentifier)
        self.tableView?.register(UINib(nibName: "PollingWaitCallbackTableViewCell", bundle: Bundle(for: AuthStepViewController.self)), forCellReuseIdentifier: PollingWaitCallbackTableViewCell.cellIdentifier)
        self.tableView?.register(UINib(nibName: "ConfirmationCallbackTableViewCell", bundle: Bundle(for: AuthStepViewController.self)), forCellReuseIdentifier: ConfirmationCallbackTableViewCell.cellIdentifier)
        self.tableView?.register(UINib(nibName: "TextOutputCallbackTableViewCell", bundle: Bundle(for: AuthStepViewController.self)), forCellReuseIdentifier: TextOutputCallbackTableViewCell.cellIdentifier)
        
        if self.flowType == FRAuthFlowType.authentication {
            self.title = "User Login"
        }
        else {
            self.title = "User Registration"
        }
        
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
        self.authStepLabel?.textColor = FRUI.shared.primaryTextColor
        
        self.startLoading()
        
        //  Start authentication
        if let authService = self.authService {
            
            self.title = authService.serviceName + " Flow"
            
            if self.type as AnyObject? === AccessToken.self {
                authService.next { (token: AccessToken?, node, error) in
                    
                    //  Perform UI work in the main thread
                    DispatchQueue.main.async {
                        self.stopLoading()
                        self.handleNode(token, node, error)
                    }
                }
            } else if self.type as AnyObject? === Token.self {
                authService.next { (token: Token?, node, error) in
                    
                    //  Perform UI work in the main thread
                    DispatchQueue.main.async {
                        self.stopLoading()
                        self.handleNode(token, node, error)
                    }
                }
            } else if self.type as AnyObject? === FRUser.self {
                authService.next { (user: FRUser?, node, error) in
                    
                    //  Perform UI work in the main thread
                    DispatchQueue.main.async {
                        self.stopLoading()
                        self.handleNode(user, node, error)
                    }
                }
            }
        }
        else if let authIndexValue = self.authIndexValue, let authIndexType = self.authIndexType {
            FRSession.authenticate(authIndexValue: authIndexValue, authIndexType: authIndexType) { (token: Token?, node, error) in
                DispatchQueue.main.async {
                    self.stopLoading()
                    self.handleNode(token, node, error)
                }
            }
        }
        else if let flowType = self.flowType {
            self.title = "FRAuth Authentication"
            
            if self.type as AnyObject? === AccessToken.self {
                
                let completionBlock: NodeCompletion = {(user: FRUser?, node, error) in
                    DispatchQueue.main.async {
                        self.stopLoading()
                        if let user = user {
                            self.handleNode(user.token, node, error)
                        }
                        else {
                            self.handleNode(nil, node, error)
                        }
                    }
                }
                
                if flowType == .registration {
                    FRUser.register(completion: completionBlock)
                }
                else {
                    FRUser.login(completion: completionBlock)
                }
            } else if self.type as AnyObject? === FRUser.self {
                
                let completionBlock: NodeCompletion = {(user: FRUser?, node, error) in
                    
                    DispatchQueue.main.async {
                        self.stopLoading()
                        self.handleNode(user, node, error)
                    }
                }
                
                if flowType == .registration {
                    FRUser.register(completion: completionBlock)
                }
                else {
                    FRUser.login(completion: completionBlock)
                }
            } 
        }
        
        //  Start loading indicator
        self.startLoading()
        
        //  Styling buttons
        self.nextButton?.backgroundColor = FRUI.shared.primaryColor
        self.nextButton?.titleColor = UIColor.white
        self.cancelButton?.backgroundColor = FRUI.shared.secondaryColor
        self.cancelButton?.titleColor = UIColor.white
    }
    
    
    // MARK: - Authentication handling methods
    func handleNode(_ result: Any?, _ node: Node?, _ error: Error?) {
    
        //  Perform UI work in the main thread
        DispatchQueue.main.async {
            
            if let node = node {
                
                //  Set auth callbacks in list for rendering
                self.currentNode = node
                self.authCallbacks = node.callbacks
                self.renderAuthStep()
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
                if let authError: AuthError = error as? AuthError {
                    
                    switch authError {
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
        
        guard let currentNode = self.currentNode else {
            return
        }
        
        for (identifier, value) in self.authCallbackValues {
            
            for authCallback: Callback in self.authCallbacks
            {
                if authCallback is SingleValueCallback, let callback = authCallback as? SingleValueCallback, callback.inputName == identifier {                    
                    callback.value = value
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
        
        if (callback is NameCallback || callback is StringAttributeInputCallback || callback is ValidatedCreateUsernameCallback) {
            let cell = Bundle(for: AuthStepViewController.self).loadNibNamed("NameCallbackTableViewCell", owner: self, options: nil)?.first as! NameCallbackTableViewCell
            cell.updateCellData(authCallback: callback as! SingleValueCallback)
            return cell
        }
        else if (callback is PasswordCallback || callback is ValidatedCreatePasswordCallback) {
            let cell = Bundle(for: AuthStepViewController.self).loadNibNamed("PasswordCallbackTableViewCell", owner: self, options: nil)?.first as! PasswordCallbackTableViewCell
            cell.updateCellData(authCallback: callback as! SingleValueCallback)
            return cell
        }
        else if (callback is ChoiceCallback) {
            let cell = Bundle(for: AuthStepViewController.self).loadNibNamed("ChoiceCallbackTableViewCell", owner: self, options: nil)?.first as! ChoiceCallbackTableViewCell
            cell.updateCellData(authCallback: callback as! ChoiceCallback)
            return cell
        } else if (callback is TermsAndConditionsCallback) {
            let cell = Bundle(for: AuthStepViewController.self).loadNibNamed("TermsAndConditionsTableViewCell", owner: self, options: nil)?.first as! TermsAndConditionsTableViewCell
            cell.updateCellData(authCallback: callback as! TermsAndConditionsCallback)
            return cell
        } else if (callback is KbaCreateCallback) {
            let cell = Bundle(for: AuthStepViewController.self).loadNibNamed("KbaCreateCallbackTableViewCell", owner: self, options: nil)?.first as! KbaCreateCallbackTableViewCell
            cell.updateCellData(authCallback: callback as! KbaCreateCallback)
            return cell
        } else if (callback is PollingWaitCallback) {
            let cell = Bundle(for: AuthStepViewController.self).loadNibNamed("PollingWaitCallbackTableViewCell", owner: self, options: nil)?.first as! PollingWaitCallbackTableViewCell
            cell.updateCellData(authCallback: callback as! PollingWaitCallback)
            return cell
        } else if (callback is ConfirmationCallback) {
            let cell = Bundle(for: AuthStepViewController.self).loadNibNamed("ConfirmationCallbackTableViewCell", owner: self, options: nil)?.first as! ConfirmationCallbackTableViewCell
            cell.updateCellData(authCallback: callback as! ConfirmationCallback)
            cell.delegate = self
            return cell
        } else if (callback is TextOutputCallback) {
            let cell = Bundle(for: AuthStepViewController.self).loadNibNamed("TextOutputCallbackTableViewCell", owner: self, options: nil)?.first as! TextOutputCallbackTableViewCell
            cell.updateCellData(authCallback: callback as! TextOutputCallback)
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
        
        var cellHeight:CGFloat = 0.0
        
        if (callback is NameCallback || callback is StringAttributeInputCallback || callback is ValidatedCreateUsernameCallback) {
            cellHeight = NameCallbackTableViewCell.cellHeight
        }
        else if (callback is PasswordCallback || callback is ValidatedCreatePasswordCallback) {
            cellHeight = PasswordCallbackTableViewCell.cellHeight
        }
        else if (callback is ChoiceCallback) {
            cellHeight = ChoiceCallbackTableViewCell.cellHeight
        }
        else if (callback is TermsAndConditionsCallback) {
            cellHeight = TermsAndConditionsTableViewCell.cellHeight
        }
        else if (callback is KbaCreateCallback) {
            cellHeight = KbaCreateCallbackTableViewCell.cellHeight
        }
        else if (callback is PollingWaitCallback) {
            cellHeight = PollingWaitCallbackTableViewCell.cellHeight
        }
        else if (callback is ConfirmationCallback) {
            cellHeight = ConfirmationCallbackTableViewCell.cellHeight
        }
        else if (callback is TextOutputCallback) {
            cellHeight = TextOutputCallbackTableViewCell.cellHeight
        }
        
        return cellHeight
    }
}
