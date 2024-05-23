#
# Be sure to run `pod lib lint FRDeviceBinding.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FRDeviceBinding'
  s.version          = '4.4.2-beta1'
  s.summary          = 'ForgeRock Device Binding SDK for iOS'
  s.description      = <<-DESC
    FRDeviceBinding is a SDK that adds support for the Device Binding feature. FRDeviceBinding depends on JOSESwift.
                       DESC
  s.homepage         = 'https://www.forgerock.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'ForgeRock'

  s.source           = {
      :git => 'https://github.com/ForgeRock/forgerock-ios-sdk.git',
      :tag => s.version.to_s
  }

  s.module_name   = 'FRDeviceBinding'
  s.swift_versions = ['5.0', '5.1']

  s.ios.deployment_target = '12.0'

  base_dir = "FRDeviceBinding/FRDeviceBinding"
  s.source_files = base_dir + '/**/*.swift', base_dir + '/**/*.c', base_dir + '/**/*.h'
  s.resource_bundles = {
    'FRDeviceBinding' => [base_dir + '/*.xcprivacy']
  }
  s.ios.dependency 'FRAuth', '~> 4.4.2-beta1'
  s.ios.dependency 'JOSESwift', '~> 2.4.0'
end
