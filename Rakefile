# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
	gem.name = "be_taskable"
	gem.homepage = "http://github.com/sporto/gbg_tasks"
	gem.license = "MIT"
	gem.summary = %Q{Mini framework for creating and maintaining user tasks}
	gem.description = %Q{BeTaskable is a small framework for creating and maintaining tasks / chores / assignments. Meaning something that someone has to do.}
	gem.email = "sebasporto@gmail.com"
	gem.authors = ["Sebastian Porto"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
	version = File.exist?('VERSION') ? File.read('VERSION') : ""
	
	rdoc.rdoc_dir = 'rdoc'
	rdoc.title = "be_taskable #{version}"
	rdoc.rdoc_files.include('README*')
	rdoc.rdoc_files.include('lib/**/*.rb')
end
