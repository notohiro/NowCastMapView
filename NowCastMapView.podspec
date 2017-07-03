Pod::Spec.new do |s|
  s.name = 'NowCastMapView'
  s.version = '3.1.1'
  s.license = 'MIT'
  s.summary = 'library for High-resolution Precipitation Nowcasts provided by Japan Meteorological Agency'
  s.homepage = 'https://github.com/notohiro/NowCastMapView'
  s.authors = { 'Hiroshi Noto' => 'notohiro@gmail.com' }
  s.source = { :git => 'https://github.com/notohiro/NowCastMapView.git', :tag => s.version }

  s.ios.deployment_target = :ios, '8.0'

  s.requires_arc     = true
  s.source_files     = 'NowCastMapView/*'
end
