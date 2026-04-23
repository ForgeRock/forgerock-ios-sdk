# Contribution Guidelines for Ping SDK for iOS

Welcome! We are excited that you are interested in contributing to the **Ping SDK for iOS**. 
This document will guide you through the steps required to contribute to the project.

We appreciate your help in making the Ping SDK for iOS better for everyone.

## 1. Setting Up Your Development Environment

Before you can contribute to the Ping SDK for iOS, you'll need to set up your development 
environment. This section describes the prerequisites and steps needed to start using the project 
in your local machine.

### Prerequisites

1. GitHub account.
2. Git installed.
3. Latest version of [XCode](https://developer.apple.com/xcode/).
4. iOS 12 and above
5. Setup an Advanced Identity Cloud tenant or PingAM instance, as described in the **[Documentation](https://docs.pingidentity.com/sdks/latest/sdks/tutorials/ios/00_before-you-begin.html#server_configuration)**.

### Fork and Clone the Repository

1. Fork the repository to your own GitHub account by clicking the "Fork" button at the top-right of the repository page.
 
2. Clone your forked repository to your local machine:
   ```bash
   git clone https://github.com/your-username/forgerock-ios-sdk.git
   ```

3. Navigate into the project folder:
   ```bash
    cd forgerock-ios-sdk
   ```
   
4. Open the project and build it to make sure it works:

   ```bash
    open e2e/FRExample.xcworkspace
   ```

### Understanding the Project Structure

The Ping SDK for iOS is organized in a modular way. This section is designed to help you 
understand the layout of the project. We will break down each of the folders and what modules you 
will find there. Getting familiar with the project structure will make contributing easier and 
more efficient.

    forgerock-ios-sdk
     |── e2e                    # Contains the sample app for end-to-end tests
     |── FRAuth                 # Provides the OIDC client and integrates with Journey
     |── FRAuthenticator        # Allows to add Push and OATH mechanisms to the app
     |── FRCaptchaEnterprise    # Adds support for the Captcha Enterprise feature     
     |── FRCore                 # Provide common functions for all modules
     |── FRDeviceBinding        # Adds support for the Device Binding feature
     |── FRFacebookSignIn       # Enables a user to sign-in through Facebook
     |── FRGoogleSignIn         # Enables a user to sign-in through Google     
     |── FRProximity            # Provides subset of tools and functionalities related to proximity features (such as location, and BLE) in the device           
     |── FRTestHost             # Includes tests for the SDK
     |── FRUI*                  # Contains UI components for rapid prototype apps with Journey     
     |── PingProtect            # Provide access to the Ping Protect API
     ├── ...
     └── ...

***Note***: * Module deprecated

* **e2e** : This folder houses the sample application used for end-to-end (E2E) testing of the SDK. E2E tests 
verify that the entire system works as expected from the user's perspective, covering interactions 
across multiple SDK components. This sample application provides a practical example of how to 
integrate and utilize the SDK's various functionalities in a real-world scenario.

* **FRAuth**: This module is at the core of the SDK's authentication capabilities. It provides a 
robust OpenID Connect (OIDC) client implementation, enabling seamless user authentication and 
authorization. This module also integrates with ForgeRock's Journey framework, allowing developers
to implement complex authentication flows and user journeys. Some features such as WebAuthn, 
Social Login and many others are also included in this module.

* **FRAuthenticator**: This module empowers you to add powerful multi-factor authentication (MFA) capabilities to an 
application. It includes support for Push notifications and Time-based One-Time Passwords (TOTP) 
mechanisms (OATH), enabling you to enhance security and protect users' accounts.

* **FRCaptchaEnterprise**: This module adds support to Google ReCAPTCHA Enterprise, which uses advanced risk analysis techniques to distinguish between humans and bots. reCAPTCHA Enterprise is useful when you want to detect automated attacks or threats against your website or mobile apps.

* **FRCore**: The FRCore module acts as the foundational layer for all other modules within the SDK. It 
provides a set of common functions and utilities that are shared across the SDK, ensuring 
consistency and reducing code duplication.

* **FRDeviceBinding**: This module allows developers to cryptographically bind a mobile device to a user account. Registered devices generate a key pair and a key ID. The SDK sends the public key and key ID to AM for storage in the user’s profile. With this capability, developers using FRAuth module with authentication journeys can verify ownership of the bound device by requesting that it signs a challenge using the private key.

* **FRFacebookSignIn**: This module is part of the Social Login feature. It allows developers to enable sign-in through Facebook. FRFacebookSignIn depends on FBSDKLoginKit, and uses Facebook's SDK to perform authorization following Facebook's protocol

* **FRGoogleSignIn**: This module is part of the Social Login feature that allows a user to sign-in through Google. FRGoogleSignIn depends on GoogleSignIn, and uses Google's SDK to perform authorization following Google's protocol.

* **FRProximity**: FRProximity is the module that allows developers to additionally collect device information with FRDeviceCollector in FRAuth. It provides a subset of tools and functionalities related to proximity features (such as location, and BLE) in the device. Some functionalities requires user's consent.

* **FRTestHost**: This module is dedicated to the SDK's tests. It provides the host app and shared test resources to enable execution of tests within the SDK.

* **FRUI**: The FRUI module provides a collection of pre-built UI components designed to expedite 
the development of prototype applications. These UI elements integrate directly with the 
forgerock-auth module and are specifically designed to facilitate rapid prototyping with the 
Journey framework. This module is deprecated.

### Running Tests

Unit testing is essential for software development. It ensures individual code components work 
correctly, catches bugs early, and improves code reliability. This section explains how to run  
tests for all SDK modules.

#### Execute tests

   ```bash
          xcodebuild test \
          -scheme FRTestHost \
          -workspace e2e/FRExample.xcworkspace \
          -configuration Debug \
          -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.1' \
          -derivedDataPath DerivedData \
          TEST_TARGET_SIGNING=YES \
          -enableCodeCoverage YES \
          -resultBundlePath TestResults
   ```

The `destination` should reflect the target device/emulator and iOS version available.


### Build API Reference Documentation

Comprehensive and accurate API reference documentation is essential for developers working with the
Ping SDK for iOS. It serves as the definitive guide to the SDK's classes, methods, and
functions, enabling you to quickly understand how to utilize its capabilities effectively.
This section outlines the process for generating API reference documentation directly from the
source code.

You can build the API reference documentation, which uses Jazzy to generate HTML 
output, using the following steps:

1) Install Jazzy
Follow the instructions in https://github.com/realm/jazzy, or in your Terminal:
```bash
[sudo] gem install jazzy
```

2) Move to SDK repo directory
```bash
cd <forgerock-ios-sdk directory>
```

3) Move to a specific module directory
```bash
cd FRCore
```

4) Run the following command
```bash
jazzy \
--author ForgeRock \
--author_url https://www.forgerock.com \
--github_url https://github.com/ForgeRock/forgerock-ios-sdk \
--output ../docs/FRCore \
--theme fullwidth \
--disable-search \
--hide-documentation-coverage \
--build-tool-arguments -project,FRCore.xcodeproj,-scheme,FRCore,-sdk,iphoneos18.1
```

> **TIP**: Make sure to make the following changes for each module:
>
>- Change "../docs/FRCore" and "-project,FRCore.xcodeproj,-scheme,FRCore" to appropriate module name
>- Change "-sdk,iphoneos18.1" to appropriate sdk in xcodebuild in your local computer; to find this out, run "xcodebuild -showsdks"

5) Move to ../docs directory and validate all documentations are correctly generated

6) Repeat steps 3 to 5 for ALL modules

## 2. Standards of Practice

We ask that all contributors to this project adhere to our engineering Standard for team culture, practices and code of conduct. We expect everyone to be respectful, inclusive, and collaborative. Any violations will be handled according to the project's guidelines.

For more details on our Standards of Practice, please refer to the [SDK Standards of Practice](https://github.com/ForgeRock/sdk-standards-of-practice) documentation.

## 3. Creating a Pull Request (PR)

This section covers how to create your changes, and submit them for review by Ping Identity engineers 
by using a Pull Request. A PR is a formal request to merge your changes from your forked repository into 
the main project. The following steps will guide you on creating a well-structured PR that 
facilitates efficient review and integration of your contributions.

### 1. Create a New Branch
   Always create a new branch to work on your changes. Avoid making changes directly on the `develop` or `master` branch.

   ```bash
   git checkout -b feature/my-new-feature
   ```
   
### 2. Make Your Changes
Implement the required changes or new features. Make sure to write clean, well-commented, and readable code. If applicable, include tests and documentation for the new functionality.

### 3. Commit Your Changes
Once you’ve made your changes, commit them with a clear and descriptive message. Note that our 
repository requires all commits to be signed. For more information on signing commits, please refer to
the [GitHub Docs](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits)

The commit message should follow this structure:

```
[TYPE] Short description of the changes
```
Types:

* `feat`: A new feature
* `fix`: A bug fix
* `docs`: Documentation changes
* `refactor`: Code refactoring (no feature change)
* `test`: Adding or modifying tests

Example:

   ```bash
   git commit -S -m "feat: add login functionality"
   ```

### 4. Push Your Changes
After committing your changes, push them to your fork:

   ```bash
    git push origin feature/my-new-feature
   ```

### 5. Create a Pull Request

1. Go to your fork on GitHub.

2. Click on the "New Pull Request" button.

3. Select the base repository and base branch (usually `develop`), then select the branch you just pushed.

4. Fill out the PR Template

   Make sure to fill out the PR template provided. The template helps us better understand your change. Typically, a PR will require the following information:

   * Add a title and description for the PR. The description should include:
     * What was changed and why.
     * Any related issues.
     * Any additional context if necessary, for example relevant screenshots or breaking changes. 
   
   Once everything looks good, submit the PR for review.

### 6. PR Review and Feedback

Once the PR is submitted, the team will review it. Be prepared to:

* Address any feedback or requested changes.
* Keep your branch up to date with the base branch by rebasing or merging.

## 4. Additional Notes

* **Testing:** Please ensure that your code is well-tested. If your changes introduce new features or bug fixes, add appropriate tests to verify the behavior.

* **Documentation**: Update relevant API documentation to reflect any new features or changes to existing functionality.

* **Style Guide**: Please follow the [coding style guide](https://github.com/ForgeRock/sdk-standards-of-practice/blob/main/code-style/ios-styleguide.md) for the language you are working with.

Thank you for contributing to Ping SDK for iOS! Your contributions help make the project better for everyone.

If you have any questions, feel free to reach out via the Issues or Discussions section of the repository.

&copy; Copyright 2025 Ping Identity Corporation. All Rights Reserved