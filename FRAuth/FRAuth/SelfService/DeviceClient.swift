//
//  DeviceClient.swift
//  FRAuth
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
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

/// Implementation of `DeviceRepository` for managing user devices
@available(iOS 13.0.0, *)
public class DeviceClient {
    private var options: FROptions?
    private let ssoTokenBlock: () async throws -> Token
    
    /// Initializes the `DeviceClient` with the given options and SSO token block.
    /// - Parameters:
    ///   - options: The `FROptions`server configuration
    ///   - ssoTokenBlock: The closure to retrieve the SSO token.
    public init(options: FROptions? = FRAuth.shared?.options,
                ssoTokenBlock: @escaping () async throws -> Token = { ssoToken() }) {
        self.options = options
        self.ssoTokenBlock = ssoTokenBlock
    }
  
    /// Provides access to Oath devices, supporting deletions.
    public lazy var oath: any ImmutableDevice<OathDevice> = ImmutableDeviceImplementation<OathDevice>(endpoint: "devices/2fa/oath", deviceClient: self)

    /// Provides access to Push devices, supporting deletions.
    public lazy var push: any ImmutableDevice<PushDevice> = ImmutableDeviceImplementation<PushDevice>(endpoint: "devices/2fa/push", deviceClient: self)

    /// Provides access to Bound devices, supporting updates and deletions.
    public lazy var bound: any MutableDevice<BoundDevice> = MutableDeviceImplementation<BoundDevice>(endpoint: "devices/2fa/binding", deviceClient: self)

    /// Provides access to Profile devices, supporting updates and deletions.
    public lazy var profile: any MutableDevice<ProfileDevice> =  MutableDeviceImplementation<ProfileDevice>(endpoint: "devices/profile", deviceClient: self)

    /// Provides access to WebAuthn devices, supporting updates and deletions.
    public lazy var webAuthn: any MutableDevice<WebAuthnDevice> = MutableDeviceImplementation<WebAuthnDevice>(endpoint: "devices/2fa/webauthn", deviceClient: self)
    
    /// Updates the given device.
    /// - Parameter device: The `Device` to update.
    internal func update(device: Device) async throws {
        let request = try await createPutRequest(for: device)
        let (_, response) = try await FRRestClient.invoke(request: request)
        try validateResponse(response)
    }
    
    /// Deletes the given device.
    /// - Parameter device: The `Device` to delete.
    internal func delete(device: Device) async throws {
        let request = try await createDeleteRequest(for: device)
        let (_, response) = try await FRRestClient.invoke(request: request)
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
    internal func fetchDevices<T: Decodable>(endpoint: String) async throws -> [T] {
        let request = try await createGetRequest(for: endpoint)
        let (result, response) = try await FRRestClient.invoke(request: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthApiError.apiFailureWithMessage("Bad Request", "Failed to fetch devices", (response as? HTTPURLResponse)?.statusCode, nil)
        }
        
        do {
            if let resultArray = result["result"] as? [[String: Any]] {
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
    /// - Returns: A `Request` for the given suffix.
    private func createGetRequest(for suffix: String) async throws -> Request {
        let urlPrefix = try await urlPrefix()
        
        var components = URLComponents(url: urlPrefix, resolvingAgainstBaseURL: false)
        components?.percentEncodedPath.append(suffix)
        components?.queryItems = [URLQueryItem(name: "_queryFilter", value: "true")]
        
        guard let url = components?.url else {
            throw AuthApiError.apiFailureWithMessage("Invalid URL", "URL is malformed", nil, nil)
        }
        
        let request = try await request(url: url, method: .GET)
        return request
    }
    
    /// Creates a PUT request for the given device.
    /// - Parameter device: The `Device` to build the request for.
    /// - Returns: A `Request` to update the device.
    private func createPutRequest(for device: Device) async throws -> Request {
        let url = try await urlPrefix().appendingPathComponent(device.urlSuffix).appendingPathComponent(device.id)
        
        let data = try JSONEncoder().encode(device)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw AuthApiError.apiFailureWithMessage("Invalid device json", "Device json is malformed", nil, nil)
        }
        let request = try await request(url: url, method: .PUT, bodyParams: dictionary)
        return request
    }
    
    /// Creates a DELETE request for the given device.
    /// - Parameter device: The `Device` to build the request for.
    /// - Returns: A `Request` to delete the device.
    private func createDeleteRequest(for device: Device) async throws -> Request {
        let url = try await urlPrefix().appendingPathComponent(device.urlSuffix).appendingPathComponent(device.id)
        let request = try await request(url: url, method: .DELETE)
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
    /// - Parameter method: HTTP method for the request
    /// - Parameter bodyParams: HTTP body in dictionary
    /// - Parameter acceptAPIVersion: API version to accept
    /// - Returns: A `URequest` for the given URL.
    private func request(url: URL, method: Request.HTTPMethod, bodyParams: [String: Any] = [:], acceptAPIVersion: String = OpenAM.apiResource10) async throws -> Request {
        guard let options = options else {
            throw AuthApiError.apiFailureWithMessage("Bad Request", "No Configuration found", 400, nil)
        }
        let token = try await ssoTokenBlock()
        
        var headers: [String: String] = [:]
        headers[options.cookieName] = token.value
        headers[OpenAM.acceptAPIVersion] = acceptAPIVersion
        
        let request =  Request(url: url.absoluteString, method: method, headers: headers, bodyParams: bodyParams, requestType: .json, responseType: nil, timeoutInterval: Double(options.timeout) ?? 60)
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
    private func validateResponse(_ response: URLResponse?) throws {
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
        
        let request = try await request(url: url, method: .POST, acceptAPIVersion: OpenAM.apiResource21)
        let (result, response) = try await FRRestClient.invoke(request: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthApiError.apiFailureWithMessage("Bad Request", "Failed to retrieve user", (response as? HTTPURLResponse)?.statusCode, nil)
        }
        let data = try JSONSerialization.data(withJSONObject: result, options: [])
        return try JSONDecoder().decode(Session.self, from: data)
    }
}


/// Implementation of the `ImmutableDevice` protocol for managing devices that only support retrieval and deletion.
@available(iOS 13.0.0, *)
public struct ImmutableDeviceImplementation<R>: ImmutableDevice where R: Device {
  /// The endpoint for device-related requests.
  var endpoint: String
  /// The `DeviceClient` used to perform network operations.
  var deviceClient: DeviceClient

  /// Initializes a new instance of `ImmutableDeviceImplementation`.
  /// - Parameters:
  ///   - endpoint: The endpoint for retrieving and managing devices.
  ///   - deviceClient: The `DeviceClient` instance used for performing network operations.
  public init(endpoint: String, deviceClient: DeviceClient) {
    self.endpoint = endpoint
    self.deviceClient = deviceClient
  }
  
  /// Retrieves a list of devices from the server.
  /// - Returns: An array of devices of type `R`.
  /// - Throws: An error if the request fails or the response cannot be decoded.
  public func get() async throws -> [R] {
    try await deviceClient.fetchDevices(endpoint: endpoint)
  }
  
  /// Deletes the specified device from the server.
  /// - Parameter device: The device to delete.
  /// - Throws: An error if the request fails or the server response indicates failure.
  public func delete(_ device: R) async throws {
    try await deviceClient.delete(device: device)
  }
}


/// Implementation of the `MutableDevice` protocol for managing devices that support retrieval, deletion, and updates.
@available(iOS 13.0.0, *)
public struct MutableDeviceImplementation<R>: MutableDevice where R: Device {
  /// The endpoint for device-related requests.
  var endpoint: String
  /// The `DeviceClient` used to perform network operations.
  var deviceClient: DeviceClient

  /// Initializes a new instance of `MutableDeviceImplementation`.
  /// - Parameters:
  ///   - endpoint: The endpoint for retrieving and managing devices.
  ///   - deviceClient: The `DeviceClient` instance used for performing network operations.
  public init(endpoint: String, deviceClient: DeviceClient) {
    self.endpoint = endpoint
    self.deviceClient = deviceClient
  }
  
  /// Retrieves a list of devices from the server.
  /// - Returns: An array of devices of type `R`.
  /// - Throws: An error if the request fails or the response cannot be decoded.
  public func get() async throws -> [R] {
    try await deviceClient.fetchDevices(endpoint: endpoint)
  }
  
  /// Deletes the specified device from the server.
  /// - Parameter device: The device to delete.
  /// - Throws: An error if the request fails or the server response indicates failure.
  public func delete(_ device: R) async throws {
    try await deviceClient.delete(device: device)
  }
  
  /// Updates the specified device on the server.
  /// - Parameter device: The device to update.
  /// - Throws: An error if the request fails or the server response indicates failure.
  public func update(_ device: R) async throws {
    try await deviceClient.update(device: device)
  }
}

extension FRRestClient {
    /// Invokes REST API Request with `Request` object
    /// - Parameters:
    ///   - request: request: `Request` object for API request which should contain all information regarding the request
    ///   - action: action: `Action` object for API request which should contain all information regarding the action
    /// - Returns: tuple of response data as `[String: Any]` and `URLResponse` object
    @available(iOS 13.0, *)
    static func invoke(request: Request, action: Action? = nil) async throws -> (result: [String: Any], httpResponse: URLResponse?) {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<([String: Any], URLResponse?), Error>) -> Void in
            FRRestClient.invoke(request: request, action: action) { result in
                switch result {
                case .success(let result, let response):
                    continuation.resume(returning: (result, response))
                case .failure(error: let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
}
