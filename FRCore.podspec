#
# Be sure to run `pod lib lint FRCore.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FRCore'
  s.version          = '3.1.1'
  s.summary          = 'ForgeRock Core SDK for iOS'
  s.description      = <<-DESC
  FRCore is a SDK that allows you to consume some of core functionalities and security features built for FRAuth SDK.
                       DESC
  s.homepage         = 'https://www.forgerock.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'ForgeRock'

  s.source           = {
      :git => 'https://github.com/ForgeRock/forgerock-ios-sdk.git',
      :tag => s.version.to_s
  }

  s.module_name   = 'FRCore'
  s.swift_versions = ['5.0', '5.1']

  s.ios.deployment_target = '10.0'

  base_dir = "FRCore/FRCore"
  s.source_files = base_dir + '/**/*.swift', base_dir + '/**/*.c', base_dir + '/**/*.h'
end
