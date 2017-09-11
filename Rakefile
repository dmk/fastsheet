require 'bundler/setup'

desc 'Build native extension'
task :build do
  ruby 'extconf.rb'
end

# TODO
desc 'Run tests'
task :test do
  puts "no tests"
end

task default: [:build, :test]
