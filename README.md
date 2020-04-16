[![Cocoapods](https://img.shields.io/cocoapods/v/FRAuth?color=%23f46200&label=Version&style=flat-square)](CHANGELOG.md)


<p align="center">
  <a href="https://github.com/ForgeRock">
    <img src="https://www.forgerock.com/themes/custom/forgerock/images/fr-logo-horz-color.svg" alt="Logo">
  </a>
  <h2 align="center">ForgeRock SDK for iOS</h2>
  <p align="center">
    <a href="./blob/master/CHANGELOG.md">Change Log</a>
    ·
    <a href="#support">Support</a>
    ·
    <a href="#documentation" target="_blank">Docs</a>
  </p>
  <hr/>
</p>

The ForgeRock iOS SDK enables you to quickly integrate the [ForgeRock Identity Platform](https://www.forgerock.com/digital-identity-and-access-management-platform) into your iOS apps.

Use the SDKs to leverage _[Intelligent Authentication](https://www.forgerock.com/platform/access-management/intelligent-authentication)_ in [ForgeRock's Access Management (AM)](https://www.forgerock.com/platform/access-management) product, to easily step through each stage of an authentication tree by using callbacks.

<!------------------------------------------------------------------------------------------------------------------------------------>
<!-- REQUIREMENTS - Supported AM versions, API versions, any other requirements. -->

## Requirements

* ForgeRock Identity Platform
    * Access Management (AM) 6.5.2+

* iOS 10, 11, 12, 13   
* Xcode 11.0 or later
* Swift 5.x or Objective-C
* CocoaPods dependency manager 

<!------------------------------------------------------------------------------------------------------------------------------------>
<!-- INSTALLATION -->

## Installation

```
pod 'FRAuth'
pod 'FRUI'
pod 'FRProximity'
```

<!------------------------------------------------------------------------------------------------------------------------------------>
<!-- QUICK START - Get one of the included samples up and running in as few steps as possible. -->

## Getting Started

To try out the ForgeRock iOS SDK sample, perform these steps:

1. Setup an Access Management (AM) instance, as described in the [documentation](https://sdks.forgerock.com/ios/01_prepare-am/).
2. Clone this repo:

    ```
    git clone https://github.com/ForgeRock/forgerock-ios-sdk.git
    ```
3. Open the `/SampleApps/FRExample.xcworkspace` file in [Xcode](https://developer.apple.com/xcode/).
4. Open `/FRExample/FRExample/Configs/FRAuthConfig.plist` and edit the values to match your AM instance.
5. Ensure the active scheme is "_FRExample-Swift_", and then click the **Run** button.

<!------------------------------------------------------------------------------------------------------------------------------------>
<!-- SAMPLES - List the samples we include with the SDKs, where they are, briefly what they show. -->

## Samples

ForgeRock provides these samples to help demonstrate SDK functionality:

- **Swift Sample - `/FRExample/`**

    This sample Swift app demonstrates authenticating to an AM instance, both with and without the `FRUser` automatic user interface. 
    
    Other features include:

    - OAuth 2.0 access tokens
    - Logout
    - Collecting device information
    - Get the current user's details
    - Jailbreak detection

    Configure your AM instance settings in the `/FRexampleObjC/FRexampleObjC/Configs/FRAuthConfig.plist` file to use this sample application.

- **Objective-C Sample - `/FRexampleObjC/`**

    This sample Objective-C app demonstrates authenticating to an AM instance, both with and without the `FRUser` automatic user interface. 
    
    Other features include:

    - Logout
    - Collecting device information
    - Get the current user's details
    - Jailbreak detection

    Configure your AM instance settings in the `/FRExample/FRExample/Configs/FRAuthConfig.plist` file to use this sample application.

<!------------------------------------------------------------------------------------------------------------------------------------>
<!-- DOCS - Link off to the AM-centric documentation at sdks.forgerock.com. -->

## Documentation

Documentation for the SDKs is provided at **<https://sdks.forgerock.com>**, and includes topics such as:

* Introducting the SDK Features
* Preparing AM for use with the SDKS
* API Reference documentation

<!------------------------------------------------------------------------------------------------------------------------------------>
<!-- SUPPORT -->

## Support

If you encounter any issues, be sure to check our **[Troubleshooting](https://backstage.forgerock.com/knowledge/kb/article/a79362752)** pages.

Support tickets can be raised whenever you need our assistance; here are some examples of when it is appropriate to open a ticket (but not limited to):

* Suspected bugs or problems with ForgeRock software.
* Requests for assistance - please look at the **[Documentation](https://sdks.forgerock.com)** and **[Knowledge Base](https://backstage.forgerock.com/knowledge/kb/home/g32324668)** first.

You can raise a ticket using **[BackStage](https://backstage.forgerock.com/support/tickets)**, our customer support portal that provides one stop access to ForgeRock services. 

BackStage shows all currently open support tickets and allows you to raise a new one by clicking **New Ticket**.

<!------------------------------------------------------------------------------------------------------------------------------------>
<!-- COLLABORATION -->

## Contributing

If you would like to contribute to this project you can fork the repository, clone it to your machine and get started.

<!------------------------------------------------------------------------------------------------------------------------------------>
<!-- LEGAL -->

## Disclaimer

> This code is provided on an “as is” basis, without warranty of any kind, to the fullest extent permitted by law.
>
> ForgeRock does not warrant or guarantee the individual success developers may have in implementing the code on their development platforms or in production configurations.
>
> ForgeRock does not warrant, guarantee or make any representations regarding the use, results of use, accuracy, timeliness or completeness of any data or information relating to this code.
>
> ForgeRock disclaims all warranties, expressed or implied, and in particular, disclaims all warranties of merchantability, and warranties related to the code, or any service or software related thereto.
>
> ForgeRock shall not be liable for any direct, indirect or consequential damages or costs of any type arising out of any action taken by you or others related to the code.

<!------------------------------------------------------------------------------------------------------------------------------------>
<!-- LICENSE -->

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

---

&copy; Copyright 2020 ForgeRock AS. All Rights Reserved

[forgerock-logo]: https://www.forgerock.com/themes/custom/forgerock/images/fr-logo-horz-color.svg "ForgeRock Logo"
