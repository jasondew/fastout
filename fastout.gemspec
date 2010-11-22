# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "fastout/version"

Gem::Specification.new do |s|
  s.name        = "fastout"
  s.version     = Fastout::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jason Dew"]
  s.email       = ["jason.dew@gmail.com"]
  s.homepage    = "http://rubygems.org/gems/fastout"
  s.summary     = %q{Detect outliers in high-dimension data sets}
  s.description = %q{Detect outliers in high-dimension data sets using the FASTOUT algorithm by Foss et. al}

  s.rubyforge_project = "fastout"

  s.add_development_dependency "rspec", "~>2.0"
  s.add_development_dependency "rr"
  s.add_development_dependency "autotest"
  s.add_development_dependency "autotest-fsevent"
  s.add_development_dependency "autotest-growl"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
