Pod::Spec.new do |s|
  s.name             = 'native_player'
  s.version          = '0.1.0'
  s.summary          = 'AVPlayer + Now Playing für Pounce.'
  s.homepage         = 'https://github.com/'
  s.license          = { :type => 'GPL-3.0' }
  s.author           = { 'Pounce' => 'pounce@users.noreply.github.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'native_player/Sources/native_player/**/*.swift'
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.9'
end
