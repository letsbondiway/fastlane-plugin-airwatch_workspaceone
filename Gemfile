source('https://rubygems.org')

gemspec

gem 'rest-client'
gem 'app-info'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
