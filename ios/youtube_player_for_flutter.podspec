#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint youtube_player_for_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'youtube_player_for_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Native YouTube player for Flutter using the YouTube IFrame Player API.'
  s.description      = <<-DESC
A Flutter plugin that embeds YouTube videos using WKWebView and the YouTube IFrame Player API.
Supports playback controls, fullscreen, Shorts detection, and quality management.
                       DESC
  s.homepage         = 'https://github.com/gabrielventodev/youtube_player_for_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Gabriel Vento' => 'gabrielventodev@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.resource_bundles = {'youtube_player_for_flutter_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
