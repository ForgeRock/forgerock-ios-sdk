// 
//  RemoteDeviceBindingRepository.swift
//  FRAuth
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import FRCore

internal class RemoteDeviceBindingRepository: DeviceBindingRepository {
    
    private var serverConfig: ServerConfig?
    
    init(serverConfig: ServerConfig? = FRAuth.shared?.serverConfig){
        self.serverConfig = serverConfig
    }
    
    func persist(userKey: UserKey) throws {
        fatalError("unsupported operation")
    }
    
    func getAllKeys() -> [UserKey]  {
        fatalError("unsupported operation")
    }
    
    func delete(userKey: UserKey) throws {
        guard let serverConfig = serverConfig else {
            throw AuthApiError.apiFailureWithMessage("Bad Request", "No Configuration found", 400, nil)
        }
        
        let url = serverConfig.baseURL.absoluteString + "/json/realms/\(serverConfig.realm)/users/\(userKey.userId)/devices/2fa/binding/\(userKey.kid)"
        
        var headers: [String: String] = [:]
        headers[OpenAM.acceptAPIVersion] = "resource=1.0"
        
        let request =  Request(url: url, method: .DELETE, headers: headers, requestType: .json, responseType: nil, timeoutInterval: serverConfig.timeout)
        
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
