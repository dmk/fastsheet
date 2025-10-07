# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gemspec

group :development, :test do
  gem 'pry',  '~>0.14.0'
  gem 'rake', '~>13.0.1'
  gem 'rspec', '~>3.13'
  gem 'rubocop', '~>1.80'
  gem 'rubocop-rake', '~>0.7'
  gem 'rubocop-rspec', '~>3.7'
end

group :test do
  # Generate XLSX files in tests to avoid relying on fixture files
  gem 'caxlsx', '~> 4.2'
end
