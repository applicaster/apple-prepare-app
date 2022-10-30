# frozen_string_literal: true

# Gemfile
source 'https://rubygems.org'

gem 'colorize'
gem 'fastlane', '= 2.210.1'
gem 'faraday', '~> 1.0'
gem 'securerandom', '= 0.2.0'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
