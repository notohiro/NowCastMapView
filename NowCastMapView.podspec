Pod::Spec.new do |s|
  s.name             = "NowCastMapView"
  s.version          = "2.3.2"
  s.summary          = "library for High-resolution Precipitation Nowcasts provided by Japan Meteorological Agency"
  s.homepage         = "https://github.com/notohiro/NowCastMapView"
  s.license          = 'MIT'
  s.author           = { "Hiroshi Noto" => "notohiro@gmail.com" }
  s.source           = { :git => "https://github.com/notohiro/NowCastMapView.git", :tag => s.version.to_s }
  s.platform         = :ios, '8.0'
  s.requires_arc     = true
  s.source_files     = 'NowCastMapView/*'
end
