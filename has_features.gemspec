# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'has_features/version'

Gem::Specification.new do |s|

  # Description Meta...
  s.name        = 'has_features'
  s.version     = ActiveRecord::Has::Features::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Seth Faxon']
  s.email       = ['seth.faxon@gmail.com']
  s.homepage    = 'http://github.com/sfaxon/has_features'
  s.summary     = %q{A gem allowing a active_record model to have an ordered list of featured items.}
  s.description = %q{Based on acts_as_list, but allows nil elements to be not a part of the featuerd list.}
  s.rubyforge_project = 'has_features'


  # Load Paths...
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']


  # Dependencies (installed via 'bundle install')...
  s.add_development_dependency("bundler", ["~> 1.0.0"])
  s.add_development_dependency("activerecord", [">= 3.0.0"])
  s.add_development_dependency("rdoc")
  s.add_development_dependency("sqlite3")
end
