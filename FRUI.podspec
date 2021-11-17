#
# Be sure to run `pod lib lint FRAuth.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FRUI'
  s.version          = '3.1.1'
  s.summary          = 'ForgeRock UI SDK for FRAuth iOS'
  s.description      = <<-DESC
  FRUI is a SDK that allows you easily and quickly develop an application with ForgeRock Platform or ForgeRock Identity Cloud, and FRAuth SDK with pre-built UI components. FRUI SDK demonstrates most of functionalities available in FRAuth SDK which includes user authentication, registration, and identity and access management against ForgeRock solutions.
                       DESC
  s.homepage         = 'https://www.forgerock.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'ForgeRock'

  s.source           = {
      :git => 'https://github.com/ForgeRock/forgerock-ios-sdk.git',
      :tag => s.version.to_s
  }

  s.module_name   = 'FRUI'
  s.swift_versions = ['5.0', '5.1']

  s.ios.deployment_target = '10.0'

  base_dir = "FRUI/FRUI"
  s.source_files = base_dir + '/**/*.swift', base_dir + '/**/*.c', base_dir + '/**/*.h'
  s.resources = [base_dir + '/**/*.xib', base_dir + '/Assets/*']
  s.ios.dependency 'FRAuth', '~> 3.1.1'
end
