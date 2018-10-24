
Pod::Spec.new do |s|
  s.name         = "JXPopupView"
  s.version      = "0.0.3"
  s.summary      = "一个轻量级的自定义视图弹出框架，可灵活配置动画、背景风格。"
  s.homepage     = "https://github.com/pujiaxin33/JXPopupView"
  s.license      = "MIT"
  s.author       = { "pujiaxin33" => "317437084@qq.com" }
  s.platform     = :ios, "9.0"
  s.swift_version = "4.2"
  s.source       = { :git => "https://github.com/pujiaxin33/JXPopupView.git", :tag => "#{s.version}" }
  s.framework    = "UIKit"
  s.source_files  = "Sources", "Sources/*.{swift}"
  s.requires_arc = true
end
