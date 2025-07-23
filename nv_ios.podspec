Pod::Spec.new do |spec|
  spec.name         = "nv_ios"
  spec.version      = "0.0.1"
  spec.summary      = "A utility library for testing local CocoaPods integration."
  spec.description  = "nv_ios is a small library demonstrating local CocoaPods setup."
  spec.homepage     = "https://github.com/sureshsehrawatt/nv_ios"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Suresh Sehrawat" => "jaisehrawat11@gmail.com" }
  spec.source       = { :path => "." }
  spec.platform     = :ios, "12.0"
  spec.swift_version = "5.0"
  spec.source_files  = "nv_ios/**/*.{h,m,swift}"
end
