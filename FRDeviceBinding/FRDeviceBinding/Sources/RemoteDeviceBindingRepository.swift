// 
//  RemoteDeviceBindingRepository.swift
//  FRDeviceBinding
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import FRCore
import FRAuth

internal class RemoteDeviceBindingRepository: DeviceBindingRepository {
    
    private var options: FROptions?
    
    init(options: FROptions? = FRAuth.shared?.options){
        self.options = options
    }
    
    func persist(userKey: UserKey) throws {
        fatalError("unsupported operation")
    }
    
    func getAllKeys() -> [UserKey]  {
        fatalError("unsupported operation")
    }
    
    func delete(userKey: UserKey) throws {
        guard let options = options else {
            throw AuthApiError.apiFailureWithMessage("Bad Request", "No Configuration found", 400, nil)
        }
        
        let url = options.url + "/json/realms/\(options.realm)/users/\(userKey.userId)/devices/2fa/binding/\(userKey.kid)"
        
        var headers: [String: String] = [:]
        headers["accept-api-version"] = "resource=1.0"
        
        let request =  Request(url: url, method: .DELETE, headers: headers, requestType: .json, responseType: nil, timeoutInterval: Double(options.timeout) ?? 60)
        
        let result = FRRestClient.invokeSync(request: request, action: nil)
        
        switch result {
        case .success:
            //all good, do nothing
            break
        case .failure(error: let apiError):
            FRLog.e(apiError.localizedDescription)
            throw apiError
        }
    }
    
}
