# ForgeRock iOS SDK

## Release Status

| Version       | Status        |
|:-------------:|:-------------:|
| 1.0.0   | General Availability  |

## Software Requirements
* iOS 10.0 or later
* Xcode 11.0 or later
* Swift 5.x or Objective-C
* CocoaPods dependency manager
* ForgeRock Access Manager
* ForgeRock Identity Manager
* ForgeRock Directory Services

## Issues

Even though we do our best to cover many different use cases while developing the SDKs, you might find some issues. Please file an issue report via [https://backstage.forgerock.com/support](https://backstage.forgerock.com/support).


## Before You Begin

You'll need your ForgeRock Identity Cloud credentials to access your tenant. If you don't know your tenant credentials, contact your ForgeRock partner or technical consultant.

---

## Step 1: Install CocoaPods ##

[Cocoapods](https://cocoapods.org/) is a dependency manager for iOS projects.
Using Cocoapods with the iOS SDK is the simplest way to the integrate ForgeRock
iOS SDK into your project.

1. Install the latest version of [CocoaPods](https://guides.cocoapods.org/using/getting-started.html).
2. If you don't have [Podfile](https://guides.cocoapods.org/syntax/podfile.html) for your project, to create a new [Podfile](https://guides.cocoapods.org/syntax/podfile.html), run this command:
```
pod init
```
3. Add following line to your Podfile:
```
pod 'FRAuth'
pod 'FRUI'
pod 'FRProximity'
```
4. To install pods, run this command:
```
pod install
```
5. Make sure to use `.xcworkspace` file to open your project.
6. If you intend to use `FRExample` project, `FRExample` already includes all SDKs as project reference. You do not need to perform `pod` instructions above.
7. If you connect to your local environment or connect through HTTP, you need to configure [Application Transport Security](https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity) setting in application's `Info.plist`. 

<br>

##  Step 2: Create a Configuration File

Create a file named `FRAuthConfig.plist` that contains the following information:

| Attribute        | Description           | Default Value  |
| -----------------|---------------------| -----:|
| forgerock_oauth_client_id     | OAuth2 client's `client_id` registered in AM| None  |
| forgerock_oauth_redirect_uri     | OAuth2 client's `redirect_uri` registered in AM      | None     |
| forgerock_oauth_scope |   OAuth2 client's `scope` registered in AM   |  None  
| forgerock_oauth_threshold | Optional. Threshold in seconds to refresh OAuth2 token set before `access_token` expires through FRAuth SDK token management. | 30 |
| forgerock_url | AM base URL |  None   |
| forgerock_realm | AM `realm` | root |
| forgerock_timeout | Optional. Timeout in seconds of each request that FRAuth SDK communicates to AM. | 30 |
| forgerock_keychain_access_group | Keychain Access Group Identifier in Xcode's Capabilities tab in the application's target. This is used to share some credentials across multiple applications that are developed under same Apple's Developer Program, and FRAuth SDK utilizes this for SingleSignOn feature. (optional) |  None   |
| forgerock_auth_service | Authentication Tree name registered in AM for user authentication. |  None   |
| forgerock_registration_service | Authentication tree name registered in OpenAM for user registration. |  None   |
| forgerock_enable_cookie | Boolean value for SDK to manage and persist Cookies from AM. |  true   |


<br>

#### Using Multiple Configuration Files

If you need to run the SDK with multiple environments, before you initialize the SDK, change the default configuration file name using following code:
```
FRAuth.configPlistFileName = <.plist Configuration File Name>
```

#### FRAuthConfig.plist Example

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>forgerock_oauth_client_id</key>
	<string>iosclient</string>
	<key>forgerock_oauth_redirect_uri</key>
	<string>http://openam.example.com/redirecturi</string>
	<key>forgerock_oauth_scope</key>
	<string>openid profile email address</string>
	<key>forgerock_oauth_url</key>
	<string>http://openam.example.com/openam</string>
	<key>forgerock_oauth_threshold</key>
	<string>60</string>
	<key>forgerock_url</key>
	<string>http://openam.example.com/openam</string>
	<key>forgerock_realm</key>
	<string>root</string>
	<key>forgerock_timeout</key>
	<string>60</string>
	<key>forgerock_keychain_access_group</key>
	<string>com.forgerock.sso</string>
	<key>forgerock_auth_service_name</key>
	<string>UsernamePassword</string>
	<key>forgerock_registration_service_name</key>
	<string>UserSignUp</string>
	<key>forgerock_enable_cookie</key>
	<true/>
</dict>
</plist>
```

## Step 3: Start the SDK

To initialize the SDK, invoke the following code:

```swift
do {
  try FRAuth.start()
}
catch {
  print(error)
}
```

**NOTE:** The SDK validates the configuration file.  `FRAuth.start()` throws an error if a  mandatory value is missing or misconfigured.
 


## Using the iOS SDK Modules
The iOS APIs are grouped into three modules: FRAuth, FRUI, and FRProximity.

#### FRAuth
Use the FRAuth module to integrate ForgeRock Identity Platform authentication and authorization into your mobile app. The FRAuth module currently supports these ForgeRock Access Management (AM) features:
+ Authentication trees
+ Select OAuth2 scopes
+ Device profile
+ Jailbreak Detection

#### FRUI
Use the FRUI module to demonstrate FRAuth functionalityy using pre-defined Express UI elements. FRUI lets you quickly connect your app to the ForgeRock Identity Cloud for user authentication and registration.

#### FRProximity
Use the FRProximity module to collect device geo-location data and BLE data.  through FRAuth module's Device Profile feature. FRProximity is an add-on to FRAuth module. The add-on
lets the FRAuth module collect information for the AM device profile.


## Developer Documentation
For more detail usage of iOS SDK, and API Reference documentation, please refer to [ForgeRock Developer Site](https://developer.forgerock.com).

## License
ForgeRock iOS SDK is released under the MIT license. See [LICENSE](https://github.com/ForgeRock/forgerock-ios-sdk/blob/master/LICENSE) file for details.
