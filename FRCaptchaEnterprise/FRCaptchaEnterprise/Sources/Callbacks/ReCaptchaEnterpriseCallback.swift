//
//  CaptchaEnterpriseCallback.swift
//  FRCaptchaEnterprise
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRAuth
@_exported import RecaptchaEnterprise

/**
 * Callback designed for usage with the Captcha Enterprise Node.
 */
public class ReCaptchaEnterpriseCallback: MultipleValuesCallback {
  
  //  MARK: - Property
  
  /// The ReCaptcha SiteKey
  public private(set) var recaptchaSiteKey: String = String()
  /// Token input key in callback response
  public private(set) var tokenKey: String = String()
  /// Token result
  public private(set) var tokenResult: String = String()
  /// Action input key in callback response
  public private(set) var actionKey: String = String()
  /// Client Error input key in callback response
  public private(set) var clientErrorKey: String = String()
  /// Payload key in callback response
  public private(set) var payloadKey: String = String()
  
  /// An array of outputName values
  private var outputNames: [String] = []
  /// An array of output values
  private var outputValues: [String: Any] = [:]
  
  
  
  //  MARK: - Init
  
  /// Designated initialization method for CaptchaEnterpriseCallback
  ///
  /// - Parameter json: JSON object of ReCaptchaCallback
  /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
  required init(json: [String: Any]) throws {
    
    guard let outputs = json[CaptchaConstant.output] as? [[String: Any]] else {
      throw AuthError.invalidCallbackResponse(String(describing: json))
    }
    
    // parse outputs
    var outputNames = [String]()
    var outputValues = [String: Any]()
    for output in outputs {
      guard let outputName = output[CaptchaConstant.name] as? String, let outputValue = output[CaptchaConstant.value] else {
        throw AuthError.invalidCallbackResponse("Failed to parse output")
      }
      outputNames.append(outputName)
      outputValues[outputName] = outputValue
    }
    self.outputNames = outputNames
    self.outputValues = outputValues
    
    guard let recaptchaSiteKey = self.outputValues[CaptchaConstant.recaptchaSiteKey] as? String else {
      throw AuthError.invalidCallbackResponse("Missing recaptchaSiteKey")
    }
    self.recaptchaSiteKey = recaptchaSiteKey
    
    try super.init(json: json)
    
    guard let tokenKey = self.inputNames.filter({ $0.contains(CaptchaConstant.token) }).first else {
      throw AuthError.invalidCallbackResponse("Missing token")
    }
    self.tokenKey = tokenKey
    
    guard let actionKey = self.inputNames.filter({ $0.contains(CaptchaConstant.action) }).first else {
      throw AuthError.invalidCallbackResponse("Missing action")
    }
    self.actionKey = actionKey
    
    guard let clientErrorKey = self.inputNames.filter({ $0.contains(CaptchaConstant.clientError) }).first else {
      throw AuthError.invalidCallbackResponse("Missing clientError")
    }
    self.clientErrorKey = clientErrorKey
    
    guard let payloadKey = self.inputNames.filter({ $0.contains(CaptchaConstant.payload) }).first else {
      throw AuthError.invalidCallbackResponse("Missing payload")
    }
    self.payloadKey = payloadKey
    
  }
  
  
  /// Executes ReCAPTCHA action with given action and timeout
  /// - Parameter action: String value of action
  /// - Parameter timeout: Double value of timeout
  @available(iOS 13, *)
  public func execute(action: String = "login",
                      timeoutInMillis: Double = 15000, recaptchaProvider: RecaptchaClientProvider = DefaultRecaptchaClientProvider()) async throws {
    do {
      let recaptchaClient: RecaptchaClient? = try await recaptchaProvider.fetchClient(withSiteKey: recaptchaSiteKey)
      let recaptchaAction = RecaptchaAction(customAction: action)
      let token: String? = try await recaptchaProvider.execute(recaptchaClient: recaptchaClient, action: recaptchaAction, timeout: timeoutInMillis)
      guard let result = token else {
        throw NSError(domain: CaptchaConstant.domain, code: 1, userInfo: [NSLocalizedDescriptionKey: CaptchaConstant.invalidToken])
      }
      self.setAction(action)
      self.tokenResult = result
      self.setToken(result)
    }
    catch {
      FRLog.e(error.localizedDescription)
      self.setClientError("\(error.localizedDescription)")
      throw error
    }
  }
  
  /// Converts a given value to a JSON string representation
  /// - Parameters:
  ///   - value: The object to be converted to JSON string
  ///   - prettyPrinted: Indicates whether the JSON string should be pretty-printed
  /// - Returns: A JSON string representation of the object, or an empty string if conversion fails
  internal func JSONStringify(value: Any, prettyPrinted: Bool = false) -> String {
    let options: JSONSerialization.WritingOptions = prettyPrinted ? .prettyPrinted : []
    guard JSONSerialization.isValidJSONObject(value),
          let data = try? JSONSerialization.data(withJSONObject: value, options: options),
          let jsonString = String(data: data, encoding: .utf8) else {
      return ""
    }
    return jsonString
  }
  
  /// Sets `token` value for the ReCAPTCHA in callback response
  /// - Parameter value: String value of `token`
  public func setToken(_ value: String) {
    self.inputValues[self.tokenKey] = value
  }
  
  /// Sets `action` value for the ReCAPTCHA in callback response
  /// - Parameter value: String value of `action`
  internal func setAction(_ value: String) {
    self.inputValues[self.actionKey] = value
  }
  
  /// Sets `clientError` value for the ReCAPTCHA in callback response
  /// - Parameter value: String value of `clientError`
  public func setClientError(_ value: String) {
    self.inputValues[self.clientErrorKey] = value
  }
  
  /// Sets additional payload value for the ReCAPTCHA in callback response
  /// - Parameter value: Dictionary value of `additionalJson`
  public func setPayload(_ value: [String: Any]? = nil) {
    if let payload = value, !payload.isEmpty {
      self.inputValues[self.payloadKey] = JSONStringify(value: payload)
    }
  }
  
}

// MARK: - RecaptchaClientProvider
@available(iOS 13, *)
public protocol RecaptchaClientProvider {
  /// Fetch RecaptchaClient with given siteKey
  /// - Parameter siteKey: String value of siteKey
  func fetchClient(withSiteKey siteKey: String) async throws -> RecaptchaClient?

  /// Execute RecaptchaClient with given action and timeout
  /// - Parameter recaptchaClient: RecaptchaClient instance
  /// - Parameter action: RecaptchaAction instance
  func execute(recaptchaClient: RecaptchaClient?, action: RecaptchaAction, timeout: Double) async throws -> String?
}

// MARK: - DefaultRecaptchaClientProvider
@available(iOS 13, *)
public struct DefaultRecaptchaClientProvider: RecaptchaClientProvider {
    public init(){}
  /// Fetch RecaptchaClient with given siteKey and timeout
  /// - Parameter siteKey: String value of siteKey
  public func fetchClient(withSiteKey siteKey: String) async throws -> RecaptchaClient? {
    return try await Recaptcha.fetchClient(withSiteKey: siteKey)
  }
  
    /// Execute RecaptchaClient with given action and timeout
  /// - Parameter recaptchaClient: RecaptchaClient instance
  /// - Parameter action: RecaptchaAction instance
  public func execute(recaptchaClient: RecaptchaClient?, action: RecaptchaAction, timeout: Double) async throws -> String? {
    return try await recaptchaClient?.execute(withAction: action, withTimeout: timeout)
  }
}

