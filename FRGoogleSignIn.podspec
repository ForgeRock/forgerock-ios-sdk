#
# Be sure to run `pod lib lint FRGoogleSignIn.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FRGoogleSignIn'
  s.version          = '4.8.1'
  s.summary          = 'ForgeRock Auth Google Sign-in SDK for iOS'
  s.description      = <<-DESC
  FRGoogleSignIn is a SDK that allows a user to sign-in through Google. FRGoogleSignIn depends on GoogleSignIn, and uses Google's SDK to perform authorization following Google's protocol.
                       DESC
  s.homepage         = 'https://www.forgerock.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'ForgeRock'

  s.source           = {
      :git => 'https://github.com/ForgeRock/forgerock-ios-sdk.git',
      :tag => s.version.to_s
  }

  s.static_framework = true
  s.module_name   = 'FRGoogleSignIn'
  s.swift_versions = ['5.0', '5.1']

  s.ios.deployment_target = '12.0'

  base_dir = "FRGoogleSignIn/FRGoogleSignIn"
  s.source_files = base_dir + '/**/*.swift', base_dir + '/**/*.c', base_dir + '/**/*.h'
  s.resource_bundles = {
    'FRGoogleSignIn' => [base_dir + '/*.xcprivacy']
  }

  s.ios.dependency 'FRAuth', '~> 4.8.1'
  s.ios.dependency 'GoogleSignIn', '~> 7.1.0'
end
