# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

if RUBY_VERSION.to_f >= 3.0
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
  task default: %i[spec rubocop]
else
  task default: %i[spec]
end
