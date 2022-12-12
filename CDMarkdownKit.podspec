Pod::Spec.new do |s|
  s.name = 'CDMarkdownKit'
  s.version = '2.5.0'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.summary = 'An extensive Swift framework providing simple and customizable markdown parsing.'
  s.description = <<-DESC
  This Swift framework handles standard markdown parsing along with the ability to parse custom elements.
                         DESC
  s.homepage = 'https://github.com/chrisdhaan/CDMarkdownKit'
  s.author = { 'Christopher de Haan' => 'contact@christopherdehaan.me' }
  s.source = { :git => 'https://github.com/chrisdhaan/CDMarkdownKit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.12'
  s.tvos.deployment_target = '10.0'
  s.watchos.deployment_target = '3.0'

  s.swift_versions = ['5.3', '5.4', '5.5']
  
  s.source_files = 'Source/*.swift'
end
