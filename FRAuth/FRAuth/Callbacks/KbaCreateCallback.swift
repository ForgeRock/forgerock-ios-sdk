//
//  KbaCreateCallback.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/**
 KbaCreateCallback is a representation of OpenAM's KbaCreateCallback which is responsible to define, and create Knowledge Based Authentication question and answer for a user.
 */
@objc(FRKbaCreateCallback)
public class KbaCreateCallback: MultipleValuesCallback {

    //  MARK: - Property
    
    /// An array of predefined knowledge based authentication questions
    @objc
    public var predefinedQuestions: [String]
    /// A string value of inputValue for the given question from the user interaction
    @objc
    private var questionInputKey: String?
    /// A string value of inputValue for the given answer from the user interaction
    @objc
    private var answerInputKey: String?
    
    
    //  MARK: - Init
    
    /// Designated initialization method for KbaCreateCallback
    ///
    /// - Parameter json: JSON object of KbaCreateCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    required init(json: [String : Any]) throws {
        
        self.predefinedQuestions = []
        
        guard let outputs = json[CBConstants.output] as? [[String: Any]], let inputs = json[CBConstants.input] as? [[String: Any]] else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        for output in outputs {
            if let name = output[CBConstants.name] as? String, name == CBConstants.predefinedQuestions, let questions = output[CBConstants.value] as? [String] {
                self.predefinedQuestions = questions
            }
        }
        
        for input in inputs {
            if let name = input[CBConstants.name] as? String, name.contains(CBConstants.question) {
                self.questionInputKey = name
            } else if let name = input[CBConstants.name] as? String, name.contains(CBConstants.answer) {
                self.answerInputKey = name
            }
        }
        
        guard self.predefinedQuestions.count > 0 else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        try super.init(json: json)
    }
    
    
    /// Sets a question for the user's Knowledge Based Authentication from *predefinedQuestions* property in the instance property
    ///
    /// - Parameter question: String value of selected question from *predefinedQuestions* property
    @objc
    public func setQuestion(_ question: String) {
        
        if let questionKey = self.questionInputKey {
            self.inputValues[questionKey] = question
        }
    }
    
    /// Sets an aswer for the user's Knowledge Based Authentication
    ///
    /// - Parameter answer: String value of the user input answer to the selected question
    @objc
    public func setAnswer(_ answer: String) {
        if let answerKey = self.answerInputKey {
            self.inputValues[answerKey] = answer
        }
    }
}
