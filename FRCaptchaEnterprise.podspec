#
# Be sure to run `pod lib lint FRCaptchaEnterprise.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FRCaptchaEnterprise'
  s.version          = '4.7.0'
  s.summary          = 'ForgeRock Captcha Enterprise SDK for iOS'
  s.description      = <<-DESC
    FRCaptchaEnterprise is a SDK that adds support for the Captcha Enterprise feature. FRCaptchaEnterprise depends on RecaptchaEnterprise.
                       DESC
  s.homepage         = 'https://www.forgerock.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'ForgeRock'
  s.static_framework = true

  s.source           = {
      :git => 'https://github.com/ForgeRock/forgerock-ios-sdk.git',
      :tag => s.version.to_s
  }

  s.module_name   = 'FRCaptchaEnterprise'
  s.swift_versions = ['5.0', '5.1']

  s.ios.deployment_target = '12.0'

  base_dir = "FRCaptchaEnterprise/FRCaptchaEnterprise"
  s.source_files = base_dir + '/**/*.swift', base_dir + '/**/*.c', base_dir + '/**/*.h'
  s.resource_bundles = {
    'FRCaptchaEnterprise' => [base_dir + '/*.xcprivacy']
  }
  s.ios.dependency 'FRAuth', '~> 4.7.0'
  s.ios.dependency 'RecaptchaEnterprise', '~> 18.6.0'
end
