Pod::Spec.new do |s|
  s.name         = "VVRoutes"
  s.version      = "0.0.2"
  s.summary      = "URL routing library for iOS"
  s.homepage     = "https://github.com/chinaxxren/VVRoutes.git"
  s.license      = "BSD 3-Clause \"New\" License"
  s.author       = { "jiangmingz" => "jiangmingz@qq.com" }
  s.source       = { :git => "https://github.com/chinaxxren/VVRoutes.git", :tag => "0.0.2" }
  s.framework    = 'Foundation'
  s.requires_arc = true
  s.swift_version = "5"

  s.source_files = 'VVRoutes', 'VVRoutes/*.{swift}', 'VVRoutes/Classes/*.{swift}'

  s.ios.deployment_target = '10.0'
end
