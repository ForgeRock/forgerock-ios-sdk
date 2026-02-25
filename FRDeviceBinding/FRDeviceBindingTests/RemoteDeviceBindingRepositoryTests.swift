// 
//  RemoteDeviceBindingRepositoryTests.swift
//  FRDeviceBindingTests
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRCore
@testable import FRAuth
@testable import FRDeviceBinding


/// Tests for ``RemoteDeviceBindingRepository``, focusing on the fix that ensures the
/// device-binding delete request flows through the ``RequestInterceptor`` pipeline by
/// using ``ActionType.DELETE_BINDING`` instead of passing `nil` for the action.
class RemoteDeviceBindingRepositoryTests: FRAuthBaseTest {

    /// Tracks the action type seen by the capturing interceptor in test_03.
    static var capturedActionType: String? = nil
    /// Tracks whether the capturing interceptor was invoked in test_03.
    static var capturedHeaderValue: String? = nil

    // MARK: - Action type

    /// Verifies that the ``ActionType.DELETE_BINDING`` case exists and carries the
    /// expected raw string value used to identify the request in ``RequestInterceptor``
    /// implementations.
    func test_01_delete_binding_action_type_has_correct_raw_value() {
        XCTAssertEqual(ActionType.DELETE_BINDING.rawValue, "DELETE_BINDING")
    }


    // MARK: - Interceptor integration

    /// Regression test for the iOS-vs-Android parity bug:
    ///
    /// Previously ``RemoteDeviceBindingRepository.delete(userKey:)`` called
    /// `FRRestClient.invokeSync(request:action:nil)`, which skipped the entire
    /// ``RequestInterceptor`` pipeline because ``RestClient.interceptRequest`` only
    /// processes interceptors when `action` is non-nil. As a result customers could
    /// not add the AM session cookie (or any other header) to the DELETE request.
    ///
    /// After the fix, the call passes `Action(type: .DELETE_BINDING)` so every
    /// registered ``RequestInterceptor`` is invoked exactly as it is for login/logout.
    ///
    /// This test confirms the fix by asserting that the ``InternalRequestInterceptor``
    /// (registered automatically by ``FRBaseTestCase.setUp()``) captures a
    /// ``DELETE_BINDING`` action when `delete(userKey:)` is called.
    func test_02_delete_request_is_processed_by_request_interceptors() {
        // Arrange: initialize SDK so FRAuth.shared?.options is available
        self.config.configPlistFileName = "FRAuthConfig"
        FRAuth.configPlistFileName = "FRAuthConfig"
        self.startSDK()

        // Provide a mock 200 response so the synchronous network call completes
        self.loadMockResponses(["successDeleteDeviceBinding"])

        let userKey = UserKey(
            id: "test-binding-id",
            userId: "testuser",
            userName: "testuser",
            kid: "test-kid-123",
            authType: .none,
            createdAt: Date().timeIntervalSince1970
        )

        // Act
        let repo = RemoteDeviceBindingRepository()
        try? repo.delete(userKey: userKey)

        // Assert: FRBaseTestCase.setUp() registers InternalRequestInterceptor which
        // appends every (request, action) pair it receives to actionHistory.
        // With the fix in place, action is DELETE_BINDING, so the interceptor fires
        // and the action appears in actionHistory.
        let capturedDeleteBindingActions = self.actionHistory.filter {
            $0.type == ActionType.DELETE_BINDING.rawValue
        }
        XCTAssertFalse(
            capturedDeleteBindingActions.isEmpty,
            "Expected a DELETE_BINDING action to be captured by RequestInterceptors, " +
            "but actionHistory only contained: \(self.actionHistory.map { $0.type }). " +
            "This indicates the delete request is not flowing through the interceptor pipeline."
        )
    }


    /// Verifies that a custom ``RequestInterceptor`` registered for ``DELETE_BINDING``
    /// can modify the outgoing request — for example, injecting a session cookie header.
    /// This mirrors the documented customer use-case of adding `iPlanetDirectoryPro`
    /// before the request reaches AM.
    ///
    /// The assertion uses static tracking vars populated inside the interceptor itself
    /// (the same pattern used in ``RequestInterceptorTests``), which is more reliable
    /// than inspecting the final URLRequest at the URLProtocol layer for synchronous calls.
    func test_03_custom_interceptor_can_inject_header_for_delete_binding_action() {
        // Arrange
        self.config.configPlistFileName = "FRAuthConfig"
        FRAuth.configPlistFileName = "FRAuthConfig"
        self.startSDK()
        self.loadMockResponses(["successDeleteDeviceBinding"])

        RemoteDeviceBindingRepositoryTests.capturedActionType = nil
        RemoteDeviceBindingRepositoryTests.capturedHeaderValue = nil

        // Register the capturing interceptor AFTER the InternalRequestInterceptor set up
        // by FRBaseTestCase.setUp(), so both run for every request.
        let sentinelValue = "test-session-token-\(UUID().uuidString)"
        FRRequestInterceptorRegistry.shared.registerInterceptors(
            interceptors: [SessionCookieInjectionInterceptor(sessionToken: sentinelValue)],
            shouldOverride: false
        )

        let userKey = UserKey(
            id: "test-binding-id-2",
            userId: "testuser2",
            userName: "testuser2",
            kid: "test-kid-456",
            authType: .none,
            createdAt: Date().timeIntervalSince1970
        )

        // Act
        let repo = RemoteDeviceBindingRepository()
        try? repo.delete(userKey: userKey)

        // Assert: the interceptor was invoked with DELETE_BINDING and injected the header.
        XCTAssertEqual(
            RemoteDeviceBindingRepositoryTests.capturedActionType,
            ActionType.DELETE_BINDING.rawValue,
            "Expected the interceptor to be called with a DELETE_BINDING action."
        )
        XCTAssertEqual(
            RemoteDeviceBindingRepositoryTests.capturedHeaderValue,
            sentinelValue,
            "Expected the interceptor to inject the iPlanetDirectoryPro header with the session token."
        )
    }


    // MARK: - Error handling

    /// When no SDK configuration is available (`FRAuth.shared` is nil), the repository
    /// should throw an error rather than silently failing.
    func test_04_delete_throws_when_no_configuration_is_available() {
        let userKey = UserKey(
            id: "test-id",
            userId: "testuser",
            userName: "testuser",
            kid: "test-kid",
            authType: .none,
            createdAt: Date().timeIntervalSince1970
        )
        // Explicitly pass nil options to simulate missing configuration
        let repo = RemoteDeviceBindingRepository(options: nil)
        XCTAssertThrowsError(
            try repo.delete(userKey: userKey),
            "Expected RemoteDeviceBindingRepository.delete to throw when no configuration is present"
        )
    }
}


// MARK: - Test helpers

/// A ``RequestInterceptor`` that injects a session token as the `iPlanetDirectoryPro`
/// header for every ``ActionType.DELETE_BINDING`` request. Used in test_03 to validate
/// that customers can intercept unbind calls via the public SDK API.
///
/// Records the action type and injected value into ``RemoteDeviceBindingRepositoryTests``
/// static vars so the test can assert without relying on URLProtocol request history.
private class SessionCookieInjectionInterceptor: RequestInterceptor {
    let sessionToken: String

    init(sessionToken: String) {
        self.sessionToken = sessionToken
    }

    func intercept(request: Request, action: Action) -> Request {
        guard action.type == ActionType.DELETE_BINDING.rawValue else {
            return request
        }
        // Record that this interceptor was invoked for the DELETE_BINDING action.
        RemoteDeviceBindingRepositoryTests.capturedActionType = action.type
        RemoteDeviceBindingRepositoryTests.capturedHeaderValue = sessionToken

        var headers = request.headers
        headers["iPlanetDirectoryPro"] = sessionToken
        return Request(
            url: request.url,
            method: request.method,
            headers: headers,
            bodyParams: request.bodyParams,
            urlParams: request.urlParams,
            requestType: request.requestType,
            responseType: request.responseType,
            timeoutInterval: request.timeoutInterval
        )
    }
}
