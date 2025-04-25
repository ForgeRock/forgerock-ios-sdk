//
//  Device.swift
//  FRAuth
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// Protocol defining immutable device operations.
@available(iOS 13.0.0, *)
public protocol ImmutableDevice<T> {
    associatedtype T
    
    /// Retrieves a list of devices.
    /// - Returns: A list of devices of type `T`.
    func get() async throws -> [T]
    
    /// Deletes the specified device.
    /// - Parameter device: The device to delete.
    func delete(_ device: T) async throws
}

/// Protocol defining mutable device operations.
@available(iOS 13.0.0, *)
public protocol MutableDevice<T>: ImmutableDevice {
    /// Updates the specified device.
    /// - Parameter device: The device to update.
    func update(_ device: T) async throws
}

/// Protocol representing a device.
public protocol Device: Codable {
    var id: String { get }
    var deviceName: String { get }
    var urlSuffix: String { get }
}

/// Struct representing a BoundDevice
public struct BoundDevice: Device {
    /// The ID of the device.
    public let id: String
    /// The name of the device.
    public var deviceName: String
    /// The URL suffix for the device.
    public let urlSuffix: String
    /// The device ID.
    public let deviceId: String
    /// The UUID of the device.
    public let uuid: String
    /// The creation date of the device.
    public let createdDate: TimeInterval
    /// The last access date of the device.
    public let lastAccessDate: TimeInterval
    
    /// Creates a new instance by decoding from the given decoder.
    /// This initializer throws an error if reading from the decoder fails, or
    /// if the data read is corrupted or otherwise invalid.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try values.decode(String.self, forKey: .id)
        deviceId = try values.decode(String.self, forKey: .deviceId)
        deviceName = try values.decode(String.self, forKey: .deviceName)
        uuid = try values.decode(String.self, forKey: .uuid)
        createdDate = try values.decode(TimeInterval.self, forKey: .createdDate)
        lastAccessDate = try values.decode(TimeInterval.self, forKey: .lastAccessDate)
        urlSuffix = "devices/2fa/binding"
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case deviceId, deviceName, uuid, createdDate, lastAccessDate
    }
}

/// Struct representing an Oath device.
public struct OathDevice: Device {
    /// The ID of the device.
    public let id: String
    /// The name of the device.
    public let deviceName: String
    /// The URL suffix for the device.
    public let urlSuffix: String
    /// The UUID of the device.
    public let uuid: String
    /// The creation date of the device.
    public let createdDate: TimeInterval
    /// The last access date of the device.
    public let lastAccessDate: TimeInterval
    
    /// Creates a new instance by decoding from the given decoder.
    /// This initializer throws an error if reading from the decoder fails, or
    /// if the data read is corrupted or otherwise invalid.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try values.decode(String.self, forKey: .id)
        deviceName = try values.decode(String.self, forKey: .deviceName)
        uuid = try values.decode(String.self, forKey: .uuid)
        createdDate = try values.decode(TimeInterval.self, forKey: .createdDate)
        lastAccessDate = try values.decode(TimeInterval.self, forKey: .lastAccessDate)
        urlSuffix = "devices/2fa/oath"
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case deviceName, uuid, createdDate, lastAccessDate
    }
}

/// Struct representing a Push device.
public struct PushDevice: Device {
    /// The ID of the device.
    public let id: String
    /// The name of the device.
    public let deviceName: String
    /// The URL suffix for the device.
    public let urlSuffix: String
    /// The UUID of the device.
    public let uuid: String
    /// The creation date of the device.
    public let createdDate: TimeInterval
    /// The last access date of the device.
    public let lastAccessDate: TimeInterval
    
    /// Creates a new instance by decoding from the given decoder.
    /// This initializer throws an error if reading from the decoder fails, or
    /// if the data read is corrupted or otherwise invalid.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try values.decode(String.self, forKey: .id)
        deviceName = try values.decode(String.self, forKey: .deviceName)
        uuid = try values.decode(String.self, forKey: .uuid)
        createdDate = try values.decode(TimeInterval.self, forKey: .createdDate)
        lastAccessDate = try values.decode(TimeInterval.self, forKey: .lastAccessDate)
        urlSuffix = "devices/2fa/push"
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case deviceName, uuid, createdDate, lastAccessDate
    }
}

/// Struct representing a WebAuthn device.
public struct WebAuthnDevice: Device {
    /// The ID of the device.
    public let id: String
    /// The name of the device.
    public var deviceName: String
    /// The URL suffix for the device.
    public let urlSuffix: String
    /// The UUID of the device.
    public let uuid: String
    /// The credential ID of the device.
    public let credentialId: String
    /// The creation date of the device.
    public let createdDate: TimeInterval
    /// The last access date of the device.
    public let lastAccessDate: TimeInterval
    
    /// Creates a new instance by decoding from the given decoder.
    /// This initializer throws an error if reading from the decoder fails, or
    /// if the data read is corrupted or otherwise invalid.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try values.decode(String.self, forKey: .id)
        credentialId = try values.decode(String.self, forKey: .credentialId)
        deviceName = try values.decode(String.self, forKey: .deviceName)
        uuid = try values.decode(String.self, forKey: .uuid)
        createdDate = try values.decode(TimeInterval.self, forKey: .createdDate)
        lastAccessDate = try values.decode(TimeInterval.self, forKey: .lastAccessDate)
        urlSuffix = "devices/2fa/webauthn"
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case deviceName, uuid, credentialId, createdDate, lastAccessDate
    }
}

/// Struct representing a Profile device.
public struct ProfileDevice: Device {
    /// The ID of the device.
    public let id: String
    /// The name of the device.
    public var deviceName: String
    /// The URL suffix for the device.
    public let urlSuffix: String
    /// The identifier of the device.
    public let identifier: String
    /// The metadata of the device.
    public let metadata: [String: Any]
    /// The location of the device.
    public let location: Location?
    /// The last selected date of the device.
    public let lastSelectedDate: TimeInterval
    
    /// Creates a new instance by decoding from the given decoder.
    /// This initializer throws an error if reading from the decoder fails, or
    /// if the data read is corrupted or otherwise invalid.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try values.decode(String.self, forKey: .id)
        deviceName = try values.decode(String.self, forKey: .deviceName)
        identifier = try values.decode(String.self, forKey: .identifier)
        location = try values.decodeIfPresent(Location.self, forKey: .location)
        lastSelectedDate = try values.decode(TimeInterval.self, forKey: .lastSelectedDate)
        metadata = try values.decode([String: Any].self, forKey: .metadata)
        urlSuffix = "devices/profile"
    }
    
    /// Encodes this value into the given encoder.
    /// If the value fails to encode anything, `encoder` will encode an empty
    /// keyed container in its place.
    /// This function throws an error if any values are invalid for the given
    /// encoder's format.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encodeIfPresent(id, forKey: .id)
        try? container.encodeIfPresent(deviceName, forKey: .deviceName)
        try? container.encodeIfPresent(identifier, forKey: .identifier)
        try? container.encodeIfPresent(location, forKey: .location)
        try? container.encodeIfPresent(lastSelectedDate, forKey: .lastSelectedDate)
        try? container.encodeIfPresent(metadata, forKey: .metadata)
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case deviceName = "alias"
        case identifier, location, lastSelectedDate, metadata
    }
}

/// Struct representing a location.
public struct Location: Codable {
    /// The latitude of the location.
    public let latitude: Double
    /// The longitude of the location.
    public let longitude: Double
}
