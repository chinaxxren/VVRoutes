Pod::Spec.new do |s|
  s.name         = "VVRoutes"
  s.version      = "0.0.1"
  s.summary      = "URL routing library for iOS with a simple API written in Swift 5."
  s.homepage     = "https://github.com/wangwanjie/HDRoutes"
  s.license      = "BSD 3-Clause \"New\" License"
  s.author       = { "VanJay" => "wangwanjie1993@gmail.com" }
  s.source       = { :git => "https://github.com/wangwanjie/HDRoutes.git", :tag => "0.4.0" }
  s.framework    = 'Foundation'
  s.requires_arc = true
  s.swift_version = "5"

  s.source_files = 'VVRoutes', 'VVRoutes/*.{swift}', 'VVRoutes/Classes/*.{swift}'

  s.ios.deployment_target = '10.0'
end
