//
//  DeviceClient.swift
//  FRAuth
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore

enum UserRepoConstants {
    static let contentType = "Content-Type"
    static let json = "application/json"
}

/// Protocol defining the repository for user devices
@available(iOS 13.0.0, *)
public protocol DeviceRepository {
    /// Retrieves a list of Oath devices.
    /// - Returns: A list of `OathDevice`.
    func oathDevices() async throws -> [OathDevice]
    /// Retrieves a list of Push devices.
    /// - Returns: A list of `PushDevice`.
    func pushDevices() async throws -> [PushDevice]
    /// Retrieves a list of Binding devices.
    /// - Returns: A list of `BindingDevice`.
    func bindingDevices() async throws -> [BindingDevice]
    /// Retrieves a list of WebAuthn devices.
    /// - Returns: A list of `WebAuthnDevice`.
    func webAuthnDevices() async throws -> [WebAuthnDevice]
    /// Retrieves a list of Profile devices.
    /// - Returns: A list of `ProfileDevice`.
    func profileDevices() async throws -> [ProfileDevice]
    /// Updates the given device.
    /// - Parameter device: The `Device` to update.
    func update(device: Device) async throws
    /// Deletes the given device.
    /// - Parameter device: The `Device` to delete.
    func delete(device: Device) async throws
}

/// Implementation of `DeviceRepository` for managing user devices
@available(iOS 13.0.0, *)
public class DeviceClient: DeviceRepository {
    private var options: FROptions?
    private let ssoTokenBlock: () async throws -> Token
    private let httpClient: URLSession
    
    /// Initializes the `DeviceClient` with the given options and SSO token block.
    /// - Parameters:
    ///   - options: The `FROptions`server configuration
    ///   - ssoTokenBlock: The closure to retrieve the SSO token.
    public init(options: FROptions? = FRAuth.shared?.options,
                ssoTokenBlock: @escaping () async throws -> Token = { ssoToken() }) {
        self.options = options
        self.ssoTokenBlock = ssoTokenBlock
        self.httpClient = URLSession.shared
    }
    
    /// Retrieves a list of Oath devices.
    /// - Returns: A list of `OathDevice`.
    public func oathDevices() async throws -> [OathDevice] {
        return try await fetchDevices(endpoint: "devices/2fa/oath")
    }
    
    /// Retrieves a list of Push devices.
    /// - Returns: A list of `PushDevice`.
    public func pushDevices() async throws -> [PushDevice] {
        return try await fetchDevices(endpoint: "devices/2fa/push")
    }
    
    /// Retrieves a list of Binding devices.
    /// - Returns: A list of `BindingDevice`.
    public func bindingDevices() async throws -> [BindingDevice] {
        return try await fetchDevices(endpoint: "devices/2fa/binding")
    }
    
    /// Retrieves a list of WebAuthn devices.
    /// - Returns: A list of `WebAuthnDevice`.
    public func webAuthnDevices() async throws -> [WebAuthnDevice] {
        return try await fetchDevices(endpoint: "devices/2fa/webauthn")
    }
    
    /// Retrieves a list of Profile devices.
    /// - Returns: A list of `ProfileDevice`.
    public func profileDevices() async throws -> [ProfileDevice] {
        return try await fetchDevices(endpoint: "devices/profile")
    }
    
    /// Updates the given device.
    /// - Parameter device: The `Device` to update.
    public func update(device: Device) async throws {
        let request = try await createPutRequest(for: device)
        let (_, response) = try await httpClient.data(for: request)
        try validateResponse(response)
    }
    
    /// Deletes the given device.
    /// - Parameter device: The `Device` to delete.
    public func delete(device: Device) async throws {
        let request = try await createDeleteRequest(for: device)
        let (_, response) = try await httpClient.data(for: request)
        try validateResponse(response)
    }
    
    /// Retrieves the current SSO token.
    /// - Returns: the current `Token` or an empty token if no session is available.
    public static func ssoToken() -> Token {
        return FRSession.currentSession?.sessionToken ?? Token("")
    }
    
    // MARK: - Private Methods
    
    /// Fetches a list of devices from the server.
    /// - Parameter endpoint: The endpoint to fetch devices from.
    /// - Returns: A list of devices.
    private func fetchDevices<T: Decodable>(endpoint: String) async throws -> [T] {
        let request = try await createGetRequest(for: endpoint)
        let (data, response) = try await httpClient.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthApiError.apiFailureWithMessage("Bad Request", "Failed to fetch devices", (response as? HTTPURLResponse)?.statusCode, nil)
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            if let resultArray = jsonObject?["result"] as? [[String: Any]] {
                let resultData = try JSONSerialization.data(withJSONObject: resultArray, options: [])
                return try JSONDecoder().decode([T].self, from: resultData)
            }
        } catch {
            throw AuthApiError.apiFailureWithMessage("Bad Result", "Failed to decode JSON.", (response as? HTTPURLResponse)?.statusCode, nil)
        }
        
        return []
    }
    
    /// Creates a GET request for the given suffix.
    /// - Parameter suffix: The suffix to append to the URL.
    /// - Returns: A `URLRequest` for the given suffix.
    private func createGetRequest(for suffix: String) async throws -> URLRequest {
        let urlPrefix = try await urlPrefix()
        
        var components = URLComponents(url: urlPrefix, resolvingAgainstBaseURL: false)
        components?.percentEncodedPath.append(suffix)
        components?.queryItems = [URLQueryItem(name: "_queryFilter", value: "true")]
        
        guard let url = components?.url else {
            throw AuthApiError.apiFailureWithMessage("Invalid URL", "URL is malformed", nil, nil)
        }
        
        let request = try await request(url: url)
        return request
    }
    
    /// Creates a PUT request for the given device.
    /// - Parameter device: The `Device` to build the request for.
    /// - Returns: A `URLRequest` to update the device.
    private func createPutRequest(for device: Device) async throws -> URLRequest {
        let url = try await urlPrefix().appendingPathComponent(device.urlSuffix).appendingPathComponent(device.id)
        var request = try await request(url: url)
        request.httpMethod = Request.HTTPMethod.PUT.rawValue
        request.httpBody = try JSONEncoder().encode(device)
        return request
    }
    
    /// Creates a DELETE request for the given device.
    /// - Parameter device: The `Device` to build the request for.
    /// - Returns: A `URLRequest` to delete the device.
    private func createDeleteRequest(for device: Device) async throws -> URLRequest {
        let url = try await urlPrefix().appendingPathComponent(device.urlSuffix).appendingPathComponent(device.id)
        var request = try await request(url: url)
        request.httpMethod = Request.HTTPMethod.DELETE.rawValue
        return request
    }
    
    /// Retrieves the URL prefix for the requests
    /// - Returns: The URL prefix
    private func urlPrefix() async throws -> URL {
        guard let options = options else {
            throw AuthApiError.apiFailureWithMessage("Bad Request", "No Configuration found", 400, nil)
        }
        let urlString = options.url + "/json/realms/\(options.realm)/users/\(try await sessionUsername(options: options))/"
        guard let url = URL(string: urlString) else {
            throw AuthApiError.apiFailureWithMessage("Invalid URL", "URL is malformed", nil, nil)
        }
        return url
    }
    
    /// Creates a request for the given URL.
    /// - Parameter url: The URL to create the request for.
    /// - Returns: A `URLRequest` for the given URL.
    private func request(url: URL) async throws -> URLRequest {
        guard let options = options else {
            throw AuthApiError.apiFailureWithMessage("Bad Request", "No Configuration found", 400, nil)
        }
        let token = try await ssoTokenBlock()
        var request = URLRequest(url: url)
        request.setValue(token.value, forHTTPHeaderField: options.cookieName)
        request.setValue(OpenAM.apiResource10, forHTTPHeaderField: OpenAM.acceptAPIVersion)
        request.setValue(UserRepoConstants.json, forHTTPHeaderField: UserRepoConstants.contentType)
        return request
    }
    
    /// Retrieves the session username.
    /// - Parameter options: The `FROptions` server configuration.
    /// - Returns: The session username.
    private func sessionUsername(options: FROptions) async throws -> String {
        let session = try await session(options: options, ssoTokenBlock: ssoTokenBlock)
        return session.username
    }
    
    /// Validates the given response.
    /// - Parameter response: The response to validate.
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthApiError.apiFailureWithMessage("Bad Request", "Failed to perform the request", (response as? HTTPURLResponse)?.statusCode, nil)
        }
    }
    
    /// Retrieves the session information from the server.
    /// - Parameters:
    ///   - options: The `FROptions` server configuration.
    ///   - ssoTokenBlock: A closure to retrieve the SSO token asynchronously.
    /// - Returns: The Session information.
    private func session(options: FROptions, ssoTokenBlock: @escaping () async throws -> Token) async throws -> Session {
        guard let url = URL(string: options.url) else {
            throw AuthApiError.apiFailureWithMessage("Invalid URL", "URL is malformed", nil, nil)
        }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.path.append("/json/realms/\(options.realm)/sessions")
        components?.queryItems = [URLQueryItem(name: "_action", value: "getSessionInfo")]
        
        guard let url = components?.url else {
            throw AuthApiError.apiFailureWithMessage("Invalid URL", "URL is malformed", nil, nil)
        }
        
        let token = try await ssoTokenBlock()
        var request = URLRequest(url: url)
        request.httpMethod = Request.HTTPMethod.POST.rawValue
        request.setValue(UserRepoConstants.json, forHTTPHeaderField: UserRepoConstants.contentType)
        request.setValue(token.value, forHTTPHeaderField: options.cookieName)
        request.setValue(OpenAM.apiResource21, forHTTPHeaderField: OpenAM.acceptAPIVersion)
        
        let (data, response) = try await httpClient.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthApiError.apiFailureWithMessage("Bad Request", "Failed to retrieve user", (response as? HTTPURLResponse)?.statusCode, nil)
        }
        
        return try JSONDecoder().decode(Session.self, from: data)
    }
}
