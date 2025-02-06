[![Cocoapods](https://img.shields.io/cocoapods/v/FRAuth?color=%23f46200&label=Version&style=flat-square)](CHANGELOG.md)
[![Build and Test](https://github.com/ForgeRock/forgerock-ios-sdk/actions/workflows/ci.yaml/badge.svg)](https://github.com/ForgeRock/forgerock-ios-sdk/actions/workflows/ci.yaml)


<p align="center">
  <a href="https://github.com/ForgeRock">
    <img src="https://cdn-docs.pingidentity.com/navbar/ping-logo-horizontal.svg" alt="Logo">
  </a>
  <h2 align="center">Ping SDK for iOS</h2>
  <p align="center">
    <a href="./CHANGELOG.md">Change Log</a>
    ·
    <a href="#support">Support</a>
    ·
    <a href="#documentation" target="_blank">Docs</a>
  </p>
  <hr />
</p>

The Ping SDk for iOS enables you to quickly integrate Ping products into your iOS apps.

Use the SDKs to leverage _[Intelligent Access](https://www.pingidentity.com/en/platform/capabilities/intelligent-access.html)_ to easily step through each stage of an authentication tree by using callbacks.

<!------------------------------------------------------------------------------------------------------------------------------------>
<!-- REQUIREMENTS - Supported AM versions, API versions, any other requirements. -->

## Requirements

* ForgeRock Identity Platform
  * Ping Advanced Identity Cloud
  * PingAM 6.5.2+
* iOS 12 and above
* Xcode
* Swift 5.x
* CocoaPods or Swift Package Manager (optional)

<!------------------------------------------------------------------------------------------------------------------------------------>
<!-- INSTALLATION -->

## Installation

### Cocoapods
Use the following pods in your `Podfile` to install FR iOS SDK module(s) if you want to install the latest version.

```
pod 'FRAuth' // Authentication module
pod 'FRUI' // UI SDK demonstrates FRAuth SDK functionalities
pod 'FRProximity' // Add-on for FRAuth's Device Profile feature related to location, and BLE
pod 'FRAuthenticator' // Authenticator module that generates HOTP, TOTP, and Push registration/authentication
pod 'FRGoogleSignIn' // Social Login module for Google Sign In
pod 'FRFacebookSignIn' // Social Login module for Facebook Login
pod 'FRDeviceBinding' // Add-on for Device Binding feature
pod 'PingProtect' // Add-on for Ping Protect feature
pod 'FRCaptchaEnterprise' // Add-on for the ReCaptcha Enterprise feature
```

### Swift Package Manager
> * The ForgeRock iOS SDK is available via Swift Package Manager from 3.0.0 and above. Any older versions (2.2.0 and below) are only available via Cocoapods.
> * `FRGoogleSignIn` module is currently not available in Swift Package Manager; use Cocoapods instead to integrate `FRGoogleSignIn` module.

1. In Xcode menus, `File` -> `Swift Packages` -> `Add Package Dependencies...`
2. Select the project to integrate the Ping SDK for iOS
3. Enter the url of the repo: `https://github.com/ForgeRock/forgerock-ios-sdk`
4. Select module(s) to integrate into the project

<!------------------------------------------------------------------------------------------------------------------------------------>
<!-- QUICK START - Get one of the included samples up and running in as few steps as possible. -->

## Getting Started

To try out the Ping SDK for iOS sample, perform these steps:

1. Setup your server as described in the [documentation](https://docs.pingidentity.com/sdks/latest/sdks/tutorials/ios/00_before-you-begin.html#server_configuration)
2. Clone the sample apps repo:
    ```
    git clone https://github.com/ForgeRock/sdk-sample-apps
    ```
3. Open the `iOS/swiftui-quickstart/Quickstart.xcodeproj` file in [Xcode](https://developer.apple.com/xcode/).
4. Open `/Quickstart/Resources/FRAuthConfig` and edit the values to match your server.
5. Ensure the active scheme is "_QuickStart_", and then click the **Run** button.

<!------------------------------------------------------------------------------------------------------------------------------------>
<!-- SAMPLES - List the samples we include with the SDKs, where they are, briefly what they show. -->

## Samples

We provide a [sample repo](https://github.com/ForgeRock/sdk-sample-apps) to help demonstrate SDK functionality.

<!------------------------------------------------------------------------------------------------------------------------------------>
<!-- DOCS - Link off to the AM-centric documentation at sdks.forgerock.com. -->

## Documentation

Documentation for the SDKs is provided at **<https://docs.pingidentity.com/sdks>**, and includes topics such as:

* Introducing SDK features
* Preparing AM for use with the SDKS
* API Reference documentation

<!------------------------------------------------------------------------------------------------------------------------------------>
<!-- SUPPORT -->

## Support

If you encounter any issues, be sure to check our **[Troubleshooting](https://support.pingidentity.com/s/article/How-do-I-troubleshoot-the-ForgeRock-SDK-for-iOS)** pages.

Support tickets can be raised whenever you need our assistance; here are some examples of when it is appropriate to open a ticket (but not limited to):

* Suspected bugs or problems with ForgeRock software.
* Requests for assistance - please look at the **[Documentation](https://docs.pingidentity.com/sdks)** and **[Knowledge Base](https://support.pingidentity.com/s/knowledge-base)** first.

You can raise a ticket using the **[Ping Identity Support Portal](https://support.pingidentity.com/s/)** that provides one stop access to support services.

The support portal shows all currently open support tickets and allows you to raise a new one by clicking **New Ticket**.

<!------------------------------------------------------------------------------------------------------------------------------------>
<!-- COLLABORATION -->

## Contributing

If you would like to contribute to this project you can fork the repository, clone it to your machine and get started.

<!------------------------------------------------------------------------------------------------------------------------------------>
<!-- LEGAL -->

## Disclaimer

> **This code is provided by Ping Identity Corporation ("Ping") on an "as is" basis, without warranty of any kind, to the fullest extent permitted by law.
> Ping Identity Corporation does not represent or warrant or make any guarantee regarding the use of this code or the accuracy, timeliness or completeness of any data or information relating to this code, and Ping Identity Corporation hereby disclaims all warranties whether express, or implied or statutory, including without limitation the implied warranties of merchantability, fitness for a particular purpose, and any warranty of non-infringement.
> Ping Identity Corporation shall not have any liability arising out of or related to any use, implementation or configuration of this code, including but not limited to use for any commercial purpose.
> Any action or suit relating to the use of the code may be brought only in the courts of a jurisdiction wherein Ping Identity Corporation resides or in which Ping Identity Corporation conducts its primary business, and under the laws of that jurisdiction excluding its conflict-of-law provisions.**

<!------------------------------------------------------------------------------------------------------------------------------------>
<!-- LICENSE -->

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

---

&copy; Copyright 2020-2025 Ping Identity. All Rights Reserved
