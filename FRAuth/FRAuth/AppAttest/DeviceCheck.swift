// 
//  DeviceCheck.swift
//  FRAuth
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import DeviceCheck

public class DeviceCheck {
    
    public init() {}
    
    public func loginWithDeviceCheck(twobits: Bool) {
        if DCDevice.current.isSupported {
            // A unique token will be generated for every call to this method
            DCDevice.current.generateToken(completionHandler: { token, error in
                guard let token = token else {
                    print("error generating token: \(error!)")
                    return
                }
                if twobits {
                    self.twobits(token: token)
                } else {
                    self.validate(token: token)
                }
                
            })
        }
    }
    
    public func twobits(token: Data) {
        let session = URLSession.shared
        let url = URL(string: "http://192.168.1.93:3000/updatedevice")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let model = Model(
            token: token.base64EncodedString(),
            bit0: false,
            bit1: true
        )

        var jsonData: Data?
        do {
            jsonData = try JSONEncoder().encode(model)
        } catch {
            return
        }

        let task = session.uploadTask(with: request, from: jsonData) { data, response, error in
           
            if let responseJSONData = try? JSONSerialization.jsonObject(with: data ?? Data(), options: .allowFragments) {
                        print("Response JSON data = \(responseJSONData)")
                    }
        }
        task.resume()
    }
    
    public func validate(token: Data) {
        let session = URLSession.shared
        let url = URL(string: "http://192.168.1.93:3000/devicecheck")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let model = Model(
            token: token.base64EncodedString(),
            bit0: false,
            bit1: true
        )

        var jsonData: Data?
        do {
            jsonData = try JSONEncoder().encode(model)
        } catch {
            return
        }

        let task = session.uploadTask(with: request, from: jsonData) { data, response, error in
           
            if let responseJSONData = try? JSONSerialization.jsonObject(with: data ?? Data(), options: .allowFragments) {
                        print("Response JSON data = \(responseJSONData)")
                    }
        }
        task.resume()
    }
    
}

struct Model: Codable {
    let token: String
    let bit0: Bool
    let bit1: Bool
}
