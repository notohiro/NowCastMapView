Pod::Spec.new do |s|
  s.name = 'NowCastMapView'
  s.version = '4.2.0.1'
  s.license = 'MIT'
  s.summary = 'library for High-resolution Precipitation Nowcasts provided by Japan Meteorological Agency'
  s.homepage = 'https://github.com/notohiro/NowCastMapView'
  s.authors = { 'Hiroshi Noto' => 'notohiro@gmail.com' }
  s.source = { :git => 'https://github.com/notohiro/NowCastMapView.git', :tag => s.version }

  s.ios.deployment_target = '8.0'
  s.swift_version = '4.2'

  s.requires_arc     = true
  s.source_files     = 'NowCastMapView/*'
end
