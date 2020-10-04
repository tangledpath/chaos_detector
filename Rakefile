require 'rake'
require 'rake/extensiontask'
require 'rspec/core/rake_task'
require 'rubygems'

NAME = 'chaos_detector'.freeze
DESCRIPTION = 'Discover and graph dependencies for ruby and RoR apps'.freeze
gemfiles = FileList['lib/**/*.rb']
gemspec = Gem::Specification.new do |s|
  # s.extensions = FileList["ext/**/extconf.rb"]
  s.name = NAME
  s.summary = DESCRIPTION
  s.description = DESCRIPTION
  s.email = 'steven.miers@gmail.com'
  s.homepage = 'http://github.com/tangledpath/chaos_detector'
  s.authors = ['Steven Miers']
  s.executables = ['detect_chaos']
  s.licenses = ['MIT']
  s.add_development_dependency('rake-compiler', ['~> 1.1'])
  s.add_development_dependency('rspec', ['~> 3.9'])
  s.add_dependency('ruby-graphviz', ['~> 1.2.5'])
  s.add_dependency('thor', ['~> 0.20.3'])
  s.version = File.read('VERSION')
  s.files = gemfiles # `git ls-files`.split
end

gemspec_name = "#{NAME}.gemspec"
desc "Write gemspec to #{gemspec_name}"
task :write_gemspec do
  File.write(gemspec_name, gemspec.to_ruby)
end

Gem::PackageTask.new(gemspec) do |pkg|
end

task gem: :write_gemspec

RSpec::Core::RakeTask.new(:spec)

task default: :spec

# task :gemspec => :compile
# task :default => :gemspec
