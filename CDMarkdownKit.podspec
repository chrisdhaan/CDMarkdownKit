Pod::Spec.new do |s|
  s.name             = 'CDMarkdownKit'
  s.version          = '0.9.7'
  s.summary          = 'An extensive Swift framework providing simple and customizable markdown parsing.'
  s.description      = <<-DESC
This Swift framework handles standard markdown parsing along with the ability to parse custom elements.
                       DESC
  s.homepage         = 'https://github.com/chrisdhaan/CDMarkdownKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Christopher de Haan' => 'contact@christopherdehaan.me' }
  s.source           = { :git => 'https://github.com/chrisdhaan/CDMarkdownKit.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/dehaan_solo'

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'
  s.requires_arc = true

  s.source_files = 'Source/*.swift'
end
