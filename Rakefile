# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

file 'lib/kql/kql.tab.rb' => ['lib/kql/kql.yy'] do
  raise "racc command failed" unless system 'bin/racc lib/kql/kql.yy'
end
task :racc => 'lib/kql/kql.tab.rb'

Rake::TestTask.new(:test => :racc) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: :test
