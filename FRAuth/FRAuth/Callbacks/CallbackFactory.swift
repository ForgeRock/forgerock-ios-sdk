//
//  CallbackFactory.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/**
 CallbackFactory is a representation of class responsible for managing and maintaining supported OpenAM callback in FRAuth SDK.
 
 ## Notes ##
     * Any Callback type returned from OpenAM **must** be supported within CallbackFactory.shared.supportedCallbacks.
     * Any custom Callback must be implemented custom Callback class, and be registered through CallbackFactory.shared.registerCallback(callbackType:callbackClass:).
     * FRAuth SDK currently supports following Callback types:
         1. NameCallback
         2. PasswordCallback
         3. ChoiceCallback
         4. ValidatedCreateUsernameCallback
         5. ValidatedCreatePasswordCallback
         6. StringAttributeInputCallback
         7. TermsAndConditionsCallback
         8. KbaCreateCallback
         9. PollingWaitCallback
         10. ConfirmationCallback
         11. TextOutputCallback
         12. ReCaptchaCallback
         13. MetadataCallback
         14. DeviceProfileCallback
         15. BooleanAttributeInputCallback
         16. NumberAttributeInputCallback
         17. SuspendedTextOutputCallback
         18. WebAuthnRegistrationCallback
         19. WebAuthnAuthenticationCallback
         20. IdPCallback
         21. SelectIdPCallback
 */
@objc(FRCallbackFactory)
public class CallbackFactory: NSObject {
    
    //  MARK: - Property
    /// Shared instance of CallbackFactory
    @objc
    public static let shared = CallbackFactory()
    /// An array of supported Callback types; additional Callback type can be registered through Node.registerCallback
    @objc
    public var supportedCallbacks: [String: Callback.Type]
    
    
    //  MARK: - Init
    
    /// Initializes CallbackFactory instance
    override init() {
        
        self.supportedCallbacks = [
            CallbackType.ChoiceCallback.rawValue: ChoiceCallback.self,
            CallbackType.NameCallback.rawValue: NameCallback.self,
            CallbackType.PasswordCallback.rawValue: PasswordCallback.self,
            CallbackType.ValidatedCreateUsernameCallback.rawValue: ValidatedCreateUsernameCallback.self,
            CallbackType.ValidatedCreatePasswordCallback.rawValue: ValidatedCreatePasswordCallback.self,
            CallbackType.StringAttributeInputCallback.rawValue: StringAttributeInputCallback.self,
            CallbackType.TermsAndConditionsCallback.rawValue: TermsAndConditionsCallback.self,
            CallbackType.KbaCreateCallback.rawValue: KbaCreateCallback.self,
            CallbackType.PollingWaitCallback.rawValue: PollingWaitCallback.self,
            CallbackType.ConfirmationCallback.rawValue: ConfirmationCallback.self,
            CallbackType.TextOutputCallback.rawValue: TextOutputCallback.self,
            CallbackType.ReCaptchaCallback.rawValue: ReCaptchaCallback.self,
            CallbackType.HiddenValueCallback.rawValue: HiddenValueCallback.self,
            CallbackType.DeviceProfileCallback.rawValue: DeviceProfileCallback.self,
            CallbackType.MetadataCallback.rawValue: MetadataCallback.self,
            CallbackType.BooleanAttributeInputCallback.rawValue: BooleanAttributeInputCallback.self,
            CallbackType.NumberAttributeInputCallback.rawValue: NumberAttributeInputCallback.self,
            CallbackType.SuspendedTextOutputCallback.rawValue: SuspendedTextOutputCallback.self,
            CallbackType.WebAuthnAuthenticationCallback.rawValue: WebAuthnAuthenticationCallback.self,
            CallbackType.WebAuthnRegistrationCallback.rawValue: WebAuthnRegistrationCallback.self,
            CallbackType.IdPCallback.rawValue: IdPCallback.self,
            CallbackType.SelectIdPCallback.rawValue: SelectIdPCallback.self
        ]
    }
    
    
    
    // - MARK: Supported Callbacks
    
    /// Registers a Callback class to the supported Callback list
    ///
    /// - NOTE: Any custom Callback class should be registered with this method; if unknown / unsupported Callback type is returned from OpenAM, SDK throws an error
    ///
    /// - Parameters:
    ///   - callbackType: String value of Callback type
    ///   - callbackClass: Class type of the callback
    @objc
    public func registerCallback(callbackType: String, callbackClass: Callback.Type) {
        FRLog.i("Registering custom Callback: \(callbackType) | \(callbackClass)")
        self.supportedCallbacks[callbackType] = callbackClass
    }
}
