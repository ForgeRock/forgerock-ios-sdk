#
# Be sure to run `pod lib lint FRAuth.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FRAuth'
  s.version          = '4.8.1'
  s.summary          = 'ForgeRock Auth SDK for iOS'
  s.description      = <<-DESC
  FRAuth is a SDK that allows you easily and quickly develop an application with ForgeRock Platform or ForgeRock Identity Cloud. FRAuth SDK provides interfaces and functionalities of user authentication, registration, and identity and access management against ForgeRock solutions.
                       DESC
  s.homepage         = 'https://www.forgerock.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'ForgeRock'

  s.source           = {
      :git => 'https://github.com/ForgeRock/forgerock-ios-sdk.git',
      :tag => s.version.to_s
  }

  s.module_name   = 'FRAuth'
  s.swift_versions = ['5.0', '5.1']

  s.ios.deployment_target = '12.0'

  base_dir = "FRAuth/FRAuth"
  s.source_files = base_dir + '/**/*.swift', base_dir + '/**/*.c', base_dir + '/**/*.h'
  s.resource_bundles = {
    'FRAuth' => [base_dir + '/*.xcprivacy']
  }
  s.ios.dependency 'FRCore', '~> 4.8.1'
end
