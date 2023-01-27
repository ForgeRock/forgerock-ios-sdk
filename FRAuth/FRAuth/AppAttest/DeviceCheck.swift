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
    
    public func loginWithDeviceCheck() {
        if DCDevice.current.isSupported {
            // A unique token will be generated for every call to this method
            DCDevice.current.generateToken(completionHandler: { token, error in
                guard let token = token else {
                    print("error generating token: \(error!)")
                    return
                }
                self.validate(token: token)
            })
        }
    }
    
    public func validate(token: Data) {
        let session = URLSession.shared
        let url = URL(string: "http://192.168.1.30:5000/devicecheck")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let dict = [
            "token": token.base64EncodedString(),
        ]

        var jsonData: Data?
        do {
            jsonData = try JSONEncoder().encode(dict)
        } catch {
            return
        }

        let task = session.uploadTask(with: request, from: jsonData) { data, response, error in
            // response handling
        }
        task.resume()
    }
    
}
