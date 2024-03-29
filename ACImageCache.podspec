#
# Be sure to run `pod lib lint ACImageCache.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ACImageCache'
  s.version          = '1.0.9'
  s.summary          = 'ImageCache for iOS.'

  s.description      = <<-DESC
ImageCache for iOS.
                       DESC

  s.homepage         = 'https://github.com/acastano/ImageCache'
  s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author           = { 'Andrés Castaño' => 'acastano@gmail.com' }
  s.source           = { :git => 'https://github.com/acastano/ImageCache.git', :tag => s.version }

  s.ios.deployment_target = '9.0'

  s.source_files = 'Sources/ACImageCache/**/*'
  s.swift_version = '5.5'
end
