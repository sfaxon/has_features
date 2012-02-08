require 'rake'
require 'rake/testtask'

desc 'Default: run has_features unit tests.'
task :default => :test

desc 'Test the has_features gem.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end
