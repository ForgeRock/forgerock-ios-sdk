//
//  DeviceClientTests.swift
//  FRAuthTests
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

@available(iOS 13.0.0, *)
final class DeviceClientTests: FRAuthBaseTest {
    
    private var deviceClient: DeviceClient!
    
    override func setUp() {
        self.configFileName = "Config"
        let options = FROptions(url: "https://openam-forgerock-sdks/am",
                                realm: "alpha",
                                cookieName: "5421aeddf91aa20",
                                authServiceName: "Login",
                                registrationServiceName: "Register",
                                oauthClientId: "iosClient",
                                oauthRedirectUri: "frauth://com.forgerock.ios.frexample",
                                oauthScope: "openid profile email address")
        deviceClient = DeviceClient(options: options, ssoTokenBlock: { Token("ssoTokenValue")})
        super.setUp()
    }
    
    override func tearDown() {
        SuspendedRequestInterceptor.actions = []
        SuspendedRequestInterceptor.requests = []
        super.tearDown()
    }
    ///
    func testOathDeviceReturnsListOfOathDevices() async throws {
        
        self.loadMockResponses(["sessionInfo",
                                "successOath"])
        let devices = try await deviceClient.oath.get()
        
        let request = FRTestNetworkStubProtocol.requestHistory.last!
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(request.url!.absoluteString.contains( "/json/realms/alpha/users/c49e9f78-0193-402e-b8d1-be70da3c3d17/devices/2fa/oath?_queryFilter=true"))
        XCTAssertEqual(request.value(forHTTPHeaderField: "5421aeddf91aa20"), "ssoTokenValue")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-API-Version"), "resource=1.0")
        
        XCTAssertTrue(!devices.isEmpty)
        XCTAssertEqual(devices[0].deviceName, "OATH Device")
        XCTAssertEqual(devices[0].id, "76c0337a-0d61-4e67-bf59-d87417403a91")
        XCTAssertEqual(devices[0].createdDate, 1728415537308)
        XCTAssertEqual(devices[0].lastAccessDate, 1728415537308)
        XCTAssertEqual(devices[0].uuid, "76c0337a-0d61-4e67-bf59-d87417403a91")
    }
    
    func testPushDeviceReturnsListOfPushDevices() async throws {
        
        self.loadMockResponses(["sessionInfo",
                                "successPush"])
        
        let devices = try await deviceClient.push.get()
        
        let request = FRTestNetworkStubProtocol.requestHistory.last!
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(request.url!.absoluteString.contains( "/json/realms/alpha/users/c49e9f78-0193-402e-b8d1-be70da3c3d17/devices/2fa/push?_queryFilter=true"))
        XCTAssertEqual(request.value(forHTTPHeaderField: "5421aeddf91aa20"), "ssoTokenValue")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-API-Version"), "resource=1.0")
        
        XCTAssertTrue(!devices.isEmpty)
        XCTAssertEqual(devices[0].deviceName, "Push Device")
        XCTAssertEqual(devices[0].id, "8e569eb8-1eb8-4459-88a4-2151b7e4ba91")
        XCTAssertEqual(devices[0].createdDate, 1728415625836)
        XCTAssertEqual(devices[0].lastAccessDate, 1728415625836)
        XCTAssertEqual(devices[0].uuid, "8e569eb8-1eb8-4459-88a4-2151b7e4ba91")
    }
    
    func testBindingDeviceReturnsListOfBindingDevices() async throws {
        
        self.loadMockResponses(["sessionInfo",
                                "successDeviceBinding"])
        
        let devices = try await deviceClient.bound.get()
        
        let request = FRTestNetworkStubProtocol.requestHistory.last!
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(request.url!.absoluteString.contains( "/json/realms/alpha/users/c49e9f78-0193-402e-b8d1-be70da3c3d17/devices/2fa/binding?_queryFilter=true"))
        XCTAssertEqual(request.value(forHTTPHeaderField: "5421aeddf91aa20"), "ssoTokenValue")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-API-Version"), "resource=1.0")
        
        XCTAssertTrue(!devices.isEmpty)
        XCTAssertEqual(devices.count, 4)
        XCTAssertEqual(devices[0].deviceName, "Test2")
        XCTAssertEqual(devices[0].id, "c026fcf5-633e-4d06-894f-aa23ba32bc0b")
        XCTAssertEqual(devices[0].createdDate, 1726012192353)
        XCTAssertEqual(devices[0].lastAccessDate, 1726012206459)
        XCTAssertEqual(devices[0].uuid, "c026fcf5-633e-4d06-894f-aa23ba32bc0b")
    }
    
    func testWebauthnDeviceReturnsListOfBindingDevices() async throws {
        
        self.loadMockResponses(["sessionInfo",
                                "successWebAuthn"])
        
        let devices = try await deviceClient.webAuthn.get()
        
        let request = FRTestNetworkStubProtocol.requestHistory.last!
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(request.url!.absoluteString.contains( "/json/realms/alpha/users/c49e9f78-0193-402e-b8d1-be70da3c3d17/devices/2fa/webauthn?_queryFilter=true"))
        XCTAssertEqual(request.value(forHTTPHeaderField: "5421aeddf91aa20"), "ssoTokenValue")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-API-Version"), "resource=1.0")
        
        XCTAssertTrue(!devices.isEmpty)
        
        XCTAssertEqual(devices[0].deviceName, "sdk_gphone64_arm64")
        XCTAssertEqual(devices[0].id, "4f5420a8-cfce-438b-843e-6b9ca6b738af")
        XCTAssertEqual(devices[0].createdDate, 1728415453606)
        XCTAssertEqual(devices[0].lastAccessDate, 1728415453606)
        XCTAssertEqual(devices[0].uuid, "4f5420a8-cfce-438b-843e-6b9ca6b738af")
    }
    
    func testProfileDeviceReturnsListOfBindingDevices() async throws {
        
        self.loadMockResponses(["sessionInfo",
                                "successDeviceProfile"])
        
        let devices = try await deviceClient.profile.get()
        
        let request = FRTestNetworkStubProtocol.requestHistory.last!
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(request.url!.absoluteString.contains( "/json/realms/alpha/users/c49e9f78-0193-402e-b8d1-be70da3c3d17/devices/profile?_queryFilter=true"))
        XCTAssertEqual(request.value(forHTTPHeaderField: "5421aeddf91aa20"), "ssoTokenValue")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-API-Version"), "resource=1.0")
        
        XCTAssertTrue(!devices.isEmpty)
        
        XCTAssertEqual(devices[0].deviceName, "test")
        XCTAssertEqual(devices[0].id, "ce0677ca57da8b38-5bfaa23e9a8ddc7899638da7cccbfe6a8879b6cf")
        XCTAssertEqual(devices[0].identifier, "ce0677ca57da8b38-5bfaa23e9a8ddc7899638da7cccbfe6a8879b6cf")
        XCTAssertEqual(devices[0].lastSelectedDate, 1727110785783)
    }
    
    func testUpdateDeviceSuccessfully() async throws {
        
        self.loadMockResponses(["sessionInfo",
                                "successDeviceBinding",
                                "sessionInfo",
                                "successUpdateDeviceBinding"])
        
        let devices = try await deviceClient.bound.get()
        XCTAssertTrue(!devices.isEmpty)
        XCTAssertEqual(devices.count, 4)
        try await deviceClient.update(device: devices[0])
        
        let request = FRTestNetworkStubProtocol.requestHistory.last!
        XCTAssertEqual(request.httpMethod, "PUT")
        XCTAssertTrue(request.url!.absoluteString.contains( "/json/realms/alpha/users/c49e9f78-0193-402e-b8d1-be70da3c3d17/devices/2fa/binding/c026fcf5-633e-4d06-894f-aa23ba32bc0b"))
        XCTAssertEqual(request.value(forHTTPHeaderField: "5421aeddf91aa20"), "ssoTokenValue")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-API-Version"), "resource=1.0")
    }
    
    func testDeleteDeviceSuccessfully() async throws {
        
        self.loadMockResponses(["sessionInfo",
                                "successDeviceBinding",
                                "sessionInfo",
                                "successUpdateDeviceBinding"])
        
        let devices = try await deviceClient.bound.get()
        XCTAssertTrue(!devices.isEmpty)
        XCTAssertEqual(devices.count, 4)
        try await deviceClient.delete(device: devices[0])
        
        let request = FRTestNetworkStubProtocol.requestHistory.last!
        XCTAssertEqual(request.httpMethod, "DELETE")
        XCTAssertTrue(request.url!.absoluteString.contains( "/json/realms/alpha/users/c49e9f78-0193-402e-b8d1-be70da3c3d17/devices/2fa/binding/c026fcf5-633e-4d06-894f-aa23ba32bc0b"))
        XCTAssertEqual(request.value(forHTTPHeaderField: "5421aeddf91aa20"), "ssoTokenValue")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-API-Version"), "resource=1.0")
    }
    
    func testAccessDenied() async throws {
        
        self.loadMockResponses(["sessionInfo",
                                "successDeviceBinding",
                                "sessionInfo",
                                "accessDenied"])
        
        let devices = try await deviceClient.bound.get()
        XCTAssertTrue(!devices.isEmpty)
        
        do {
            try await deviceClient.delete(device: devices[0])
            XCTFail("Should have failed")
        } catch AuthApiError.apiFailureWithMessage {
            let response = FRTestNetworkStubProtocol.mockedResponses.last!
            XCTAssertEqual((response.response as? HTTPURLResponse)?.statusCode, 401)
            let responsePayload = response.jsonContent["responsePayload"] as! [String: Any]
            XCTAssertEqual(responsePayload["code"] as? Int, 401)
            XCTAssertEqual(responsePayload["reason"] as? String, "Unauthorized")
            XCTAssertEqual(responsePayload["message"] as? String, "Access Denied")
        } catch {
            XCTFail("Failed for unknown reason")
        }
    }
    
    func testForbidden() async throws {
        
        self.loadMockResponses(["sessionInfo",
                                "successDeviceBinding",
                                "sessionInfo",
                                "forbidden"])
        
        let devices = try await deviceClient.bound.get()
        XCTAssertTrue(!devices.isEmpty)
        
        do {
            try await deviceClient.delete(device: devices[0])
            XCTFail("Should have failed")
        } catch AuthApiError.apiFailureWithMessage {
            let response = FRTestNetworkStubProtocol.mockedResponses.last!
            XCTAssertEqual((response.response as? HTTPURLResponse)?.statusCode, 403)
            let responsePayload = response.jsonContent["responsePayload"] as! [String: Any]
            XCTAssertEqual(responsePayload["code"] as? Int, 403)
            XCTAssertEqual(responsePayload["reason"] as? String, "Forbidden")
            XCTAssertEqual(responsePayload["message"] as? String, "User not permitted.")
        } catch {
            XCTFail("Failed for unknown reason")
        }
    }
    
    func testSessionExpired() async throws {
        
        self.loadMockResponses(["accessDenied"])
        
        do {
            _ = try await deviceClient.bound.get()
            XCTFail("Should have failed")
        } catch AuthApiError.apiFailureWithMessage {
            let response = FRTestNetworkStubProtocol.mockedResponses.last!
            XCTAssertEqual((response.response as? HTTPURLResponse)?.statusCode, 401)
            let responsePayload = response.jsonContent["responsePayload"] as! [String: Any]
            XCTAssertEqual(responsePayload["code"] as? Int, 401)
            XCTAssertEqual(responsePayload["reason"] as? String, "Unauthorized")
            XCTAssertEqual(responsePayload["message"] as? String, "Access Denied")
        } catch {
            XCTFail("Failed for unknown reason")
        }
    }
}
