# Version 1.0.2

## [1.0.2]
#### Added
- `FRSession` is now added to replace `SessionManager`. Use `FRSession` to authenticate against Authentication Tree in AM, persist and manage Session Token. [SDKS-174]
- `FRSession.authenticate` retrieves Session Token, and creates `FRUser.currentUser` without OAuth2 token set. Use `FRUser.currentUser.getAccessToken` to obtain OAuth2 token set if needed. [SDKS-174]

#### Changed
- `FRUser.login` now returns `AuthError.userAlreadyAuthenticated` when there is already authenticated user session. [SDKS-174]
- When Session Token is updated, or changed through `FRSession.authenticate`, or `FRUser.login`, previously granted OAuth2 token set will be automatically revoked. [SDKS-174]

#### Deprecated
- `FRAuth.next` is now deprecated; use `FRSession.authenticate` instead.
- `SessionManager` is now deprecated and will become internal class. Use `FRSession` and `FRUser` instead.

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
