Pod::Spec.new do |s|

  s.name         = "ActionLabel"
  s.version      = "1.0"
  s.summary      = "Custom drop-in UILabel replacement that recognize and handle Hashtags (#), Mentions (@) and URLs (http://) written in Swift."
  s.homepage     = "https://github.com/devcarlos/ActionLabel"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Carlos Alcala" => "carlos.alcala@icloud.com" }
  s.social_media_url   = "http://twitter.com/carlosalcala"
  s.platform     = :ios, "8.0"
  s.source      = { :git => 'https://github.com/devcarlos/ActionLabel.git', :tag => s.version.to_s }
  s.source_files = 'ActionLabel/*.swift'
  s.requires_arc  = true
end
