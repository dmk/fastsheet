# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/clean'
require 'rake/testtask'
require 'bundler/setup'
require 'thermite/tasks'

Thermite::Tasks.new(cargo_project_path: 'ext/fastsheet')

task default: 'thermite:build'
