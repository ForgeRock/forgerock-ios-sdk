#
# Be sure to run `pod lib lint FRProximity.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FRProximity'
  s.version          = '4.4.1-beta3'
  s.summary          = 'ForgeRock Auth Proximity SDK for iOS'
  s.description      = <<-DESC
  FRProximity is a SDK that allows you to additionally collect device information with FRDeviceCollector in FRAuth. FRProximity SDK leverages functionalities in iOS that requires user's consent. You must properly set privacy consent in the application's Info.plist.
                       DESC
  s.homepage         = 'https://www.forgerock.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'ForgeRock'

  s.source           = {
      :git => 'https://github.com/ForgeRock/forgerock-ios-sdk.git',
      :tag => s.version.to_s
  }

  s.module_name   = 'FRProximity'
  s.swift_versions = ['5.0', '5.1']

  s.ios.deployment_target = '12.0'

  base_dir = "FRProximity/FRProximity"
  s.source_files = base_dir + '/**/*.swift', base_dir + '/**/*.c', base_dir + '/**/*.h'
  s.resource_bundles = {
    'FRProximity' => [base_dir + '/*.xcprivacy']
  }
  s.ios.dependency 'FRAuth', '~> 4.4.1-beta3'
end
