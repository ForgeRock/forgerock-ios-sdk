// 
//  RemoteWebAuthnRepository.swift
//  FRAuth
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import FRCore

internal class RemoteWebAuthnRepository {
    
    private var options: FROptions?
    
    init(options: FROptions? = FRAuth.shared?.options){
        self.options = options
    }
    
    func deleteCredential(with publicKeyCredentialSource: PublicKeyCredentialSource) throws {
        guard let options = options else {
            throw AuthApiError.apiFailureWithMessage("Bad Request", "No Configuration found", 400, nil)
        }
        
        if let userHandle = publicKeyCredentialSource.userHandle, let userIdBase64 = Base64.encodeBase64(userHandle) as String?, let userIdCoded = userIdBase64.base64Decoded() {
            
            // decode userId and credentialId
            if let userId = userIdCoded.base64Decoded(), let credentialId = Base64.encodeBase64URL(publicKeyCredentialSource.id) as String? {
                
                // retrieve UUID
                let findResponse = try find(userId: userId, credentialId: credentialId)
                
                // call delete API passing UUID
                if let resourceId = findResponse["uuid"] as? String {
                    let url = try getUrl(userId: userId, resourceId: resourceId )
                    var headers: [String: String] = [:]
                    headers["accept-api-version"] = "resource=1.0"
                    
                    let request =  Request(url: url, method: .DELETE, headers: headers, requestType: .json, responseType: nil, timeoutInterval: Double(options.timeout) ?? 60)
                    
                    let result = FRRestClient.invokeSync(request: request, action: nil)
                    
                    switch result {
                    case .success:
                        // all good, do nothing
                        break
                    case .failure(error: let apiError):
                        FRLog.e(apiError.localizedDescription)
                        throw apiError
                    }
                }
            }
        }

    }
    
    private func find(userId: String, credentialId: String) throws -> [String: Any] {
        guard let options = options else {
            throw AuthApiError.apiFailureWithMessage("Bad Request", "No Configuration found", 400, nil)
        }
        
        let url = try getUrl(userId: userId, resourceId: credentialId)
        
        var headers: [String: String] = [:]
        headers["accept-api-version"] = "resource=1.0"
        
        let request =  Request(url: url, method: .GET, headers: headers, requestType: .json, responseType: nil, timeoutInterval: Double(options.timeout) ?? 60)
        
        let result = FRRestClient.invokeSync(request: request, action: nil)
        
        switch result {
        case .success(let response, _ ):
            return response
        case .failure(error: let apiError):
            FRLog.e(apiError.localizedDescription)
            throw apiError
        }
    }
    
    private func getUrl(userId: String, resourceId:String) throws -> String {
        guard let options = options else {
            throw AuthApiError.apiFailureWithMessage("Bad Request", "No Configuration found", 400, nil)
        }
        
        return options.url + "/json/realms/\(options.realm)/users/\(userId)/devices/2fa/webauthn/\(resourceId)"
    }
    
}
