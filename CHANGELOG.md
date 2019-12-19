# Version 0.9.0

## [1.0.1]

#### Added
- `SessionManager` is now publicly accessible to retrieve `SSO Token` / `AccessToken` / `FRUser` object, and to revoke `SSO Token`
- `SessionManager` is now accessible through `SessionManager.currentManager` singleton object after SDK initialization

#### Changed
- `FRAuth.start()` stops validating OAuth2 value(s) in configuration and make `OAuth2Client` and `TokenManager` become optional properties

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
