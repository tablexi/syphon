require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

Spork.prefork do

  # simplecov goes first
  unless ENV['DRB']
    require 'simplecov'
    SimpleCov.start
  end

  RSpec.configure do |config|
    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.filter_run :focus => true
    config.filter_run_excluding :off => true
    config.run_all_when_everything_filtered = true
  end

  require_relative 'mock_app'
  require 'rspec/rails'
end

Spork.each_run do
  if ENV['DRB']
    require 'simplecov'
    SimpleCov.start
  end

  require_relative 'support'
  require_relative 'factories'
  require 'syphon/api'
  require 'syphon/client'
end
