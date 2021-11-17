#
# Be sure to run `pod lib lint FRAuth.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FRFacebookSignIn'
  s.version          = '3.1.1'
  s.summary          = 'ForgeRock Auth Facebook Sign-in SDK for iOS'
  s.description      = <<-DESC
  FRFacebookSignIn is a SDK that allows a user to sign-in through Facebook. FRFacebookSignIn depends on FBSDKLoginKit, and uses Facebook's SDK to perform authorization following Facebook's protocol.
                       DESC
  s.homepage         = 'https://www.forgerock.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'ForgeRock'

  s.source           = {
      :git => 'https://github.com/ForgeRock/forgerock-ios-sdk.git',
      :tag => s.version.to_s
  }

  s.module_name   = 'FRFacebookSignIn'
  s.swift_versions = ['5.0', '5.1']

  s.ios.deployment_target = '10.0'

  base_dir = "FRFacebookSignIn/FRFacebookSignIn"
  s.source_files = base_dir + '/**/*.swift', base_dir + '/**/*.c', base_dir + '/**/*.h'
  s.ios.dependency 'FRAuth', '~> 3.1.1'
  s.ios.dependency 'FBSDKLoginKit', '~> 9.1.0'
end
