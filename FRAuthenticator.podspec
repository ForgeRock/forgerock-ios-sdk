#
# Be sure to run `pod lib lint FRAuthenticator.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FRAuthenticator'
  s.version          = '3.1.1'
  s.summary          = 'ForgeRock OTP/Push Authentication SDK for iOS'
  s.description      = <<-DESC
  FRAuthenticator is a SDK that allows you easily and quickly develop an application with ForgeRock Platform for OATH and Push Authentication with AM. FRAuthenticator SDK provides interfaces and functionalities of HMAC-based OTP, Time-based OTP, Push Registration and Authentication with AM.
                       DESC
  s.homepage         = 'https://www.forgerock.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'ForgeRock'

  s.source           = {
      :git => 'https://github.com/ForgeRock/forgerock-ios-sdk.git',
      :tag => s.version.to_s
  }

  s.module_name   = 'FRAuthenticator'
  s.swift_versions = ['5.0', '5.1']

  s.ios.deployment_target = '10.0'

  base_dir = "FRAuthenticator/FRAuthenticator"
  s.source_files = base_dir + '/**/*.swift', base_dir + '/**/*.c', base_dir + '/**/*.h'
  s.ios.dependency 'FRCore', '~> 3.1.1'
end
