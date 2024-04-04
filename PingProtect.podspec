#
# Be sure to run `pod lib lint PingProtect.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PingProtect'
  s.version          = '4.4.0-beta1'
  s.summary          = 'Ping Protect SDK for iOS'
  s.description      = <<-DESC
    PingProtect is an SDK that adds support for the PingOne Protect feature. PingProtect depends on PingOneSignals.
                       DESC
  s.homepage         = 'https://www.forgerock.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'ForgeRock'

  s.source           = {
      :git => 'https://github.com/ForgeRock/forgerock-ios-sdk.git',
      :tag => s.version.to_s
  }

  s.module_name   = 'PingProtect'
  s.swift_versions = ['5.0', '5.1']

  s.ios.deployment_target = '12.0'

  base_dir = "PingProtect/PingProtect"
  s.source_files = base_dir + '/**/*.swift', base_dir + '/**/*.c', base_dir + '/**/*.h'
  s.ios.dependency 'FRAuth', '~> 4.4.0'
  s.ios.dependency 'PingOneSignals', { :podspec => 'https://assets.pingone.com/signals/ios-sdk/5.2.1/PingOneSignals.podspec' }
end
