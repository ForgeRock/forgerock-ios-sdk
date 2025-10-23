## [4.8.2]

#### Fixed
- Renamed Data extension `bytes` property to `bytesArray` to avoid Xcode26 issues [SDKS-4299]
- Fixed decoding logic in `Address` and `UserInfo` to prevent CWE-502 vulnerability [SDKS-4346]
- Removed redundant completion call when using `ASWebAuthentication` [SDKS-4345]
- Updated Token Manager to revoke mismatched SSO sessions before storing a new token and fetching a fresh Access Token [TRIAGE-29185]
- Fixed `DeviceProfileCallback` response structure on iOS to match Android behavior, preventing Device Match Node failures [TRIAGE-28582]

## [4.8.1]

#### Fixed
- Resolved an issue where the new push device token was not being stored correctly on the device [SDKS-4182]

## [4.8.0]
#### Added
- Support for updating APNs device tokens of existing push mechanisms [SDKS-3684]
- Support for new response payloads in WebAuthn authentication and registration flows [SDKS-3842]

#### Fixed
 - Upgraded ReCAPTCHA Enterprise to version 18.7.0 (from 18.6.0) [SDKS-3927]
 - Resolved issue where updating device biometrics did not enforce device re-binding as expected [SDKS-3963]
 - Added missing `PingProtect` scheme [SDKS-3856]
 - Resolved race condition in the device network collector that prevented `NetworkReachabilityMonitor` from completing [SDKS-3827]

## [4.7.0]
#### Added
- Support for Sign-out with ID Token in the PingOne Platform. [SDKS-3424]
- Support for Self-Service [SDKS-3409]

#### Fixed
 - Prevent duplicate PUSH notifications in the Authenticator module. [SDKS-3533]
 - Updated jailbreak detectors to prevent false-positive detections. [SDKS-3693]

## [4.6.0]
#### Added
- Support PingOne Protect Marketplace Nodes [SDKS-3296]
- Support new ReCaptcha Enterprise node [SDKS-3324]
- Expose realm, Success and Failure URL in SessionToken [SDKS-3352]
#### Fixed
- Missing UIKit import issue for SPM [SDKS-3348]
- SSL pinning not working with root certificates [SDKS-3334]
- Build failed because FRCore.swiftmodule is not built for arm64 [SDKS-3347]
- Skip Type 4 TextOutputCallback [SDKS-3226]
- Make PolicyAdviceCreator public [SDKS-3349]

## [4.5.0]
#### Added
- Added SDK support for deleting registered WebAuthn devices from the server. [SDKS-1753]
- Added support for signing off from PingOne to the centralized login flow. [SDKS-3021]
- Added the ability to dynamically configure the SDK by collecting values from the server's OpenID Connect `.well-known` endpoint. [SDKS-3023]

#### Fixed
- SSL pinning configuration was ignored in `FRURLProtocol` class. [SDKS-3239]
- Removed scope validation from `AccessToken` initialization. [SDKS-3305]

## [4.4.1]
#### Added
- Added privacy manifest files to the SDK's modules [SDKS-3086]

#### Fixed
- Removed `storage` field from the `HardwareCollector` [SDKS-3086]
- Updated Google SDK version to 7.1.0 [SDKS-3086]
- Updated PingOneSignals SDK version to 5.2.3 [SDKS-3086]

## [4.4.0]
#### Added
- Added a new module for integration with `PingOne Protect` [SDKS-2901]
- Added support for the `TextInput` callback [SDKS-546]
- Added an interface for customizing the biometric UI prompts when device binding or signing [SDKS-2990]
- Added `x-requested-with: forgerock-sdk` and `x-requested-platform: ios` immutable HTTP headers to each outgoing request [SDKS-2997]

#### Fixed
- Blocked the device binding and signing features on simulators [SDKS-2995]

## [4.3.0]
#### Added
- AppIntegrity Callback support [SDKS-2630] [SDKS-2761]
- New ephemeralAuthSession browser type (iOS13+) [SDKS-2707]
- `iat` and `nbf` claims to Device Binding jws payload [SDKS-2748]
- Custom claims to device signing verifier [SDKS-2788]

#### Fixed
- Fixed an issue where the `issuer` parameter was not properly parsed when using AM 7.2.x [SDKS-2653]
- Updated Jailbreak Detectors [SDKS-2796]
- Fixed an issue related to Inadequate Cache Control [SDKS-2700]
- Fixed the issue when sfViewController setting in Centralized login had the "entersReaderIfAvailable" as true [SDKS-2746] 
- Fixed the issue with DeviceProfile Collector affecting phones with dual sim cards in iOS 16.3 and earlier [SDKS-2776]
- Improved unit and e2e tests [SDKS-2637]
- Fixed the issue with device binding api access level [SDKS-2886]
- Fixed the issue with removing userkey from local device repo [SDKS-2887]

## [4.1.0]
#### Added
- Interceptor support for the Authenticator module [SDKS-2545]
- Deep link support for `mfauth` scheme in Authenticator sample app [SDKS-2524]
- Interface for access_token refresh [SDKS-2563]
- Ability to process new JSON format of IG policy advice [SDKS-2239]

#### Fixed
- Fixed an issue on parsing `issuer` from combined MFA registration uri [SDKS-2542]
- Added error message about duplicated accounts while performing combined MFA registration [SDKS-2627]

## [4.0.0]
#### Added
- Support for passkeys [SDKS-2140]
- `DeviceBinding` callback support [SDKS-1748]
- `DeviceSigningVerifier` callback support [SDKS-2023]
- Support for combined MFA in the Authenticator SDK [SDKS-1972]
- Support for policy enforcement in the Authenticator SDK [SDKS-2166]
- Interface for listing and deleting WebAuthn credentials from the device [SDKS-2279]
- Interface for assigning device name during the WebAuthn registration process [SDKS-2297]
- SwiftUI QuickStart Example [SDKS-2405]

#### Fixed
- Added error message description to the `WebAuthnError` enum [SDKS-2226]
- Updated the order of presenting the registered WebAuthn keys on the device [SDKS-2251]
- Updated Facebook SDK Version to 16.0.1 [SDKS-1839]
- Updated Google SDK Version to 7.0.0 [SDKS-2426]

#### Changed
- In **WebAuthnRegistrationCallback**: `public func register(node: Node? = nil, onSuccess: @escaping StringCompletionCallback, onError: @escaping ErrorCallback)` to `public func register(node: Node? = nil, window: UIWindow? = UIApplication.shared.windows.first, deviceName: String? = nil, usePasskeysIfAvailable: Bool = false, onSuccess: @escaping StringCompletionCallback, onError: @escaping ErrorCallback)`
- In **WebAuthnAuthenticationCallback**: `public func authenticate(node: Node? = nil, onSuccess: @escaping StringCompletionCallback, onError: @escaping ErrorCallback)` to `public func authenticate(node: Node? = nil, window: UIWindow? = UIApplication.shared.windows.first, preferImmediatelyAvailableCredentials: Bool = false, usePasskeysIfAvailable: Bool = false, onSuccess: @escaping StringCompletionCallback, onError: @escaping ErrorCallback)`
- In **FacebookSignInHandler**: `public static func handle(_ application: UIApplication, _ url: URL, _ options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool` to `public static func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool`.
It should now be called from `application(_ application:, didFinishLaunchingWithOptions launchOptions: )` instead of `application(_ app:, open url:, options:)`.
- **FRAClient.updateAccount()** now throws `AccountError.accountLocked` upon attempt to update a locked account [SDKS-2166]
- **HOTPMechanism.generateCode()** and **TOTPMechanism.generateCode()** now throws `AccountError.accountLocked` upon attempt to get an OATH token for a locked account [SDKS-2166]

## [3.4.1]
#### Changed
- Updated legacy encryption algorithm for iOS SE [SDKS-1994]
- Fixed an issue related to push notifications timeout [SDKS-2164]
- Fixed an unexpected error occurring during the decoding of some push notifications [SDKS-2199]

## [3.4.0]
#### Added
- Dynamic SDK Configuration [SDKS-1760]
- iOS 16 Support [SDKS-1932]

#### Changed
- Fixed build errors on Xcode 14 [SDKS-2073]
- Fixed bug where the `state` parameter value was not verified upon calling the `Authorize` endpoint [SDKS-2077]

## [3.3.2]
#### Added
- Interface for log management [SDKS-1863]

#### Changed
- Fixed memory leak in NetworkCollector [SDKS-1931]

## [3.3.1]
#### Added
- Add PushType.biometric support and BiometricAuthentication class for biometric authentication. Updated sample app to handle new Push types [SDKS-1865]

#### Changed
- Fixed the bug when refreshing the access token we return the old token [SDKS-1824]
- Fixed bug when multiple threads are trying to access the same resource in the deviceCollector and ProfileCollector [SDKS-1912]

## [3.3.0]
#### Added
- SSL Pinning Support [SDKS-1627]
- Obtain timestamp from new Push Notification payload [SDKS-1665]
- Add new payload attributes in the Push Notification [SDKS-1775]
- Apple Sign In enhancements to get user profile info [SDKS-1632]

#### Changed
- Remove "Accept: application/x-www-form-urlencoded" header from /authorize endpoint for GET requests [SDKS-1729]
- Remove iPlanetDirectoryPro (or session cookie name) from the query parameter and inject it to the header instead [SDKS-1708]
- Fix issue when expired push notification displayed as "Approved" in the notification history list [SDKS-1491]
- Fix Issues with registering TOTP accounts with invalid period [SDKS-1405]

## [3.2.0]
#### Changed
- Updated GoogleSignIn library to the latest version '6.1.0'
- Made FRGoogleSignIn available through SPM

## [3.1.1]
#### Changed
- Added custom implementation for `HTTPCookie` for iOS 11+ devices, in order to support NSSecureCoding for storing cookies. [SDKS-1366]
- Changed all instances of Archiving/Unarchiving to use NSSecureCoding. [SDKS-1366]
- `SecuredKey` initializer supports passing a Keychain accessibility flag. [SDKS-1334]
- `SecuredKey` now has the same default Keychain accessibility flag as the KeychainService ".afterFirstUnlock". [SDKS-1334]

## [3.1.0]
#### Changed
- Fixed an issue where the `MetadataCallback` was overriding the stage property of a node [SDKS-1209]
- Fixed an issue which was affecting the Centralized Login feature [SDKS-1157]
- Various bug-fixes and enhancements for the Authenticator SDK [SDKS-1186], [SDKS-1238], [SDKS-1241]

## [3.0.0]
#### Added
- ForgeRock iOS SDK now supports and available through Swift Package Manager. [SDKS-912]
- ForgeRock iOS SDK now supports Social Login for `Sign in with Apple`, `Google Sign-In`, and `Facebook Login`.  [SDKS-879]
- New SDK modules, `FRGoogleSignIn` and `FRFacebookSignIn`, are now available to enable Social Login with AM using providers' native SDKs. [SDKS-879]
- `WebAuthnRegistrationCallback`, and `WebAuthnAuthenticationCallback` are introduced to support AM's `WebAuthn Registration Node` and `WebAuthn Authentication Node`. [SDKS-782]
- `FRUser.revokeAccessToken()` is introduced to revoke OAuth2 token only, and keep existing SSO token. [SDKS-979]
- `Account`, `OathTokenCode`, `PushNotification` and all `Mechanism` classes now conform to `Codable` protocol, and introduce new method `toJson()` to return serialized JSON String value of the object. [SDKS-1004]
- `FRAClient.getAllNotifications()` is introduced to retrieve all notifications across all mechanisms. [SDKS-1009]

#### Changed
- SDK now persists SSO Token through `FRSession` instance without OAuth2 configuration. [SDKS-873]
- All `JailbreakDetector` and `DeviceCollector`'s initialization methods are now exposed as public methods to help developers more easily customize and utilize existing implementation. [SDKS-836]
- `PlatformCollector`'s attribute names were changed from `timezone` and `jailbreakScore` to `timeZone` and `jailBreakScore` respectively to align with AM and Android SDK. [SDKS-908]
- `Browser.validateBrowserLogin()` is now available in Objective-c as well. [SDKS-975]
- Jailbreak detection logic was updated to prevent Jailbreak detection bypass. [SDKS-840]


#### Deprecated
- Removed public var value from SingleValueCallback [SDKS-910]
- Removed FRURLProtocolResponseEvaluationCallback [SDKS-910]
- Removed FRURLProtocol.validatedURLs [SDKS-910]
- Removed deprecated FRAuth.shared.next() (public func next<T>) method [SDKS-910]


## [2.2.0]
#### Added
- `FRUser.browser()` is introduced to support external user-agent authorization. `Browser` object can be constructed through `BrowserBuilder`, and `BrowserBuilder` allows to customize URL query parameter, and to choose which external user-agent to be used. [SDKS-328]

#### Changed
- `FRUser.logout()` now also invalidates `id_token`, if exists, using OIDC end session endpoint after it invalidates SSO Token (using `/sessions` endpoint), and OAuth2 token(s) (using `/token/revoke` endpoint). [SDKS-328]
- Fix Secure Enclave availability validation using `CryptoKit` for iOS 13 and above. [SDKS-673]
- Fix inconsistent font size for TextField in login screen. [SDKS-675]
- `AuthorizationPolicy`'s `validatingURL` and `delegate` properties are now public properties. [SDKS-696]
- Fix the issue that `refresh_token` is not persisted when refresh_token grant type does not return new `refresh_token`. [SDKS-648]
- Change `FRUser.getAccessToken` to clear OAuth2 tokens and handle error more percisely to reflect the user authentication status. If `refresh_token` grant returns `invalid_grant`, SDK will resume with `/authorize` flow with SSO Token (other errors with `refresh_token` grant will throw an exception), and if the `/authorize` request fails with current SSO Token, SDK will clear all credentials and states assuming that there is no more valid credentials. [SDKS-700]
- `FRUser.currentUser.getAccessToken` method will now validate SSO Token associated with `AccessToken`, and make sure that it is same as current `FRSession.currentSession.sessionToken` value. If two values are different, SDK will invalidate OAuth2 token, and try to authorize new OAuth2 token(s) with current SSO Token. [SDKS-700]
- `FRUser.currentUser.getUserInfo` no longer thorws an exception for session renewal failure; instead SDK now invokes API without `Authorization` header if token renewal failed. [SDKS-644]

#### Deprecated
-

## [2.1.0]
#### Added
- `SuspendedTextOutputCallback`is now supported in iOS SDK for `Email Suspend Node` in AM. [SDKS-504]
- `Node` now supports `pageHeader`, and `pageDescription` attributes from `Page Node`. [SDKS-517]
- `NumberAttributeInputCallback`, and `BooleanAttributeInputCallback` are now supported for IDM integration `Callback`. [SDKS-494]
- `AbstractValidatedCallback` supports updated `Policies` structures. [SDKS-460]
- `FRProximity.setLocationAccuracy` is added to specify `CLLocationManager.desiredAccuracy` configuration used in `LocationCollector`. [SDKS-617]

#### Changed
- `FRUI` no longer asks for user's consent when `DeviceProfileCallback` is the only `Callback` in the `Node`. [SDKS-436]
- `FRAuth` was mistakenly allowing other app's private Keychain Access storage when .entitlement is misconfigured. [SDKS-552]
- `FRProximity` SDK's `LocationCollector` now requests for Location Authorization while collecting Device Profile information if the authorization has not been asked yet. [SDKS-617]

#### Deprecated

## [2.0.0]
#### Added
- `FRAuth` introduces new dependency, `FRCore` which contains generic core functionalities that can be shared across other ForgeRock iOS SDK. [SDKS-241]
- `FRCore` has been added to iOS SDK suite. `FRCore` is responsible to handle generic iOS tools and functionalities that are not relevant to ForgeRock products.
- `FRAuth` is now able to handle AM's Transactional Authorization requests out of box for IG integration, and with a little bit of customization for custom REST Apps. `FRAuth` SDK can support `Authentication by Service` and `Transaction - Authenticate to Tree` in Policy environment. [SDKS-87]
- `MetadataCallback` is now supported in `FRAuth` SDK. For AM 6.5.2, when `MetadataCallback` is returned with `stage` value, SDK automatically parses `MetadataCallback` into `Node`'s `stage` property. [SDKS-304]
- `FRAuth` now allows more flexible customization on server infomration. Custom URL paths can be configured through `.plist` config file, or `ServerConfigBuilder`. [SDKS-302]
- `FRAuth` now supports `Device Profile Node` in AM 7.0.0. [SDKS-294]
- `FRCore` introduces an ability to customize internal SDK requests through `RequestInterceptor`. Use `FRCore.RequestInterceptor` to implement the interceptor, and `FRAuth.FRRequestInterceptorRegistry`to register interceptors. [SDKS-250]
- `FRAuth` now supports customizable cookie name to align with AM. Use `.plist` config file, or `ServerConfigBuilder` to change `cookieName`. [SDKS-382]
- `FRAuthenticator` SDK is now available; use `FRAuthenticator` to implement OATH, and Push Authentication with AM in the application.


#### Changed
- `FRAuth` now supports `noSession` parameter in Authentication Tree. If no SSO Token is returned with 200 status code, `NodeCompletion` returns `nil` for all three parameters. [SDKS-433]
- `ConfirmationCallback` and `TextOutputCallback`'s invalid `MessageType` error is fixed. SDK should now be able to support those callbacks received from AM.
- Single Sign-On issue where it fails to decrypt the data from other applications is fixed. SDK should now be able to encrypt/decrypt and share the data across the apps within SSO group.


#### Deprecated
- `FRURLProtocol.validatedURLs` and `FRURLProtocol.refreshTokenPolicy` are now deprecated; use `TokenManagementPolicy` and `TokenManagementPolicyDelegate` to perform Token Management feature. [SDKS-386]
- `ServerConfig(url:realm:timeout:)` is now deprecated; use `ServerConfigBuilder` to construct `ServerConfig`. [SDKS-302]

## [1.0.2]
#### Added
- `FRSession` is now added to replace `SessionManager`. Use `FRSession` to authenticate against Authentication Tree in AM, persist and manage Session Token. [SDKS-174]
- `FRSession.authenticate` retrieves Session Token, and creates `FRUser.currentUser` without OAuth2 token set. Use `FRUser.currentUser.getAccessToken` to obtain OAuth2 token set if needed. [SDKS-174]
- `forgerock_enable_cookie` option is now available; you can set Boolean value to indicate whether or not SDK to persist and manage Cookies from AM. [SDKS-183]
- FRAuth iOS SDK adds security layer on Keychain Service to encrypt all stored data with `SecuredKey` (using Secure Enclave when available). [SDKS-192]

#### Changed
- `FRUser.login` now returns `AuthError.userAlreadyAuthenticated` when there is already authenticated user session. [SDKS-174]
- When Session Token is updated, or changed through `FRSession.authenticate`, or `FRUser.login`, previously granted OAuth2 token set will automatically be revoked. [SDKS-174]

#### Deprecated
- `FRAuth.next` is now deprecated; use `FRSession.authenticate` instead. [SDKS-174]
- `SessionManager` is now deprecated and will become internal class. Use `FRSession` and `FRUser` instead. [SDKS-174]

## [1.0.1]

#### Added
- `SessionManager` is now publicly accessible to retrieve `SSO Token` / `AccessToken` / `FRUser` object, and to revoke `SSO Token` [SDKS-174]
- `SessionManager` is now accessible through `SessionManager.currentManager` singleton object after SDK initialization [SDKS-174]

#### Changed
- `FRAuth.start()` stops validating OAuth2 value(s) in configuration and make `OAuth2Client` and `TokenManager` become optional properties [SDKS-174]

## [1.0.0]

#### Added
- General Availability release for SDKs

## [0.9.1]

#### Fixed
- Changed OAuth2 authorization request to POST [SDKS-125]
- Added iOS 13 Dark Mode support to FRUI [SDKS-130]
- Fixed CPU usage issue [SDKS-131]
- Fixed FRProximity location collector issue [SDKS-124, SDKS-151]
- Fixed cosmetic issues on sample apps [SDKS-124, SDKS-132]
- Changed DropDown UI component in FRUI [SDKS-134]

## [0.9.0]

#### Added
- Initial release for FRAuth SDK
- Initial release for FRUI SDK
- Initial release for FRProximity SDK
- Initial Cocoapods deployment for beta version
