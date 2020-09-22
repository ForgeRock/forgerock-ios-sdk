# Version 2.1.1

## [2.1.1]
#### Added

#### Changed
- Fix Secure Enclave availability validation using `CryptoKit` for iOS 13 and above. [SDKS-673]

#### Deprecated

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
- `MetadataCallback` is now supported in `FRAuth` SDK. For AM 6.5.2, when `MetadataCallback` is returned with `stage` value, SDK automatically parses `MetadataCallback` into `Node`'s `stage` property. Please refer [this blog post](https://forum.forgerock.com/2020/02/using-an-authentication-tree-stage-to-build-a-custom-ui-with-the-forgerock-javascript-sdk/) for more details. [SDKS-304]
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
