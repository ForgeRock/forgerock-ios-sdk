//
//  CBConstants.swift
//  FRCaptchaEnterprise
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRAuth

//  MARK: - CaptchaEnterpriseCallback

public class CaptchaConstant {
  static let type: String = "type"
  static let input: String = "input"
  static let output: String = "output"
  static let name: String = "name"
  static let value: String = "value"
  
  static let action: String = "action"
  static let token: String = "token"
  static let captchaApiUri: String = "captchaApiUri"
  static let captchaDivClass: String = "captchaDivClass"
  static let recaptchaSiteKey: String = "recaptchaSiteKey"
  static let clientError: String = "clientError"
  static let payload: String = "payload"
  
  static let domain = "com.google.recaptcha"
  static let invalidToken = "INVALID_CAPTCHA_TOKEN"
}
