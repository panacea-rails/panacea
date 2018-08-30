# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "sdoc"
require "rdoc/task"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = "doc/rdoc"
  rdoc.rdoc_files.include("lib/**/*.rb")
  rdoc.options << "--format=sdoc"
  rdoc.template = "rails"
end

task default: :test
