Gem::Specification.new do |s|
  s.name             = "cpee-history"
  s.version          = "1.0.0"
  s.platform         = Gem::Platform::RUBY
  s.license          = "GPL-3.0-or-later"
  s.summary          = "History (versioned instance models) service for the cloud process execution engine (cpee.org)"

  s.description      = "see http://cpee.org"

  s.files            = Dir['{server/**/*,tools/**/*,lib/**/*}'] + %w(LICENSE Rakefile cpee-history.gemspec README.md AUTHORS)
  s.require_path     = 'lib'
  s.extra_rdoc_files = ['README.md']
  s.bindir           = 'tools'
  s.executables      = ['cpee-history']

  s.required_ruby_version = '>=2.4.0'

  s.authors          = ['Juergen eTM Mangler']

  s.email            = 'juergen.mangler@gmail.com'
  s.homepage         = 'http://cpee.org/'

  s.add_runtime_dependency 'riddl', '~> 1.0'
  s.add_runtime_dependency 'xml-smart', '~> 0.4'
  s.add_runtime_dependency 'systemu'
end
