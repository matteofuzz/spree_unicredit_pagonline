Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_unicredit_pagonline'
  s.version     = '1.0.0'
  s.summary     = 'Add gem summary here'
  s.description = 'Spree commerce extension for Unicredit PagOnline'
  s.required_ruby_version = '>= 1.8.7'

  s.author            = 'Matteo Folin'
  s.email             = 'mfolin@f5lab.com'
  s.homepage          = 'http://f5lab.com'
  # s.rubyforge_project = 'actionmailer'

  s.files        = Dir['CHANGELOG', 'README.md', 'LICENSE', 'lib/**/*', 'app/**/*']
  s.require_path = 'lib'
  s.requirements << 'none'

  s.has_rdoc = true

  s.add_dependency('spree_core', '>= 0.50.4')
end