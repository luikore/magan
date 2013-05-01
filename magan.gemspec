Gem::Specification.new do |s|
  s.name = "magan"
  s.version = "0.1"
  s.author = "Zete Lui"
  s.homepage = "https://github.com/luikore/magan"
  s.platform = Gem::Platform::RUBY
  s.summary = ""
  s.description = ""
  s.required_ruby_version = ">=2.0.0"
  s.license = 'BSD'

  s.files = Dir.glob("{readme.md,{lib,spec}/**/*.rb,Gemfile,rakefile}")
  s.require_paths = ["lib"]
  s.rubygems_version = '2.0.3'
  s.has_rdoc = false
end
