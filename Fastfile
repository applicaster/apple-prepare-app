# frozen_string_literal: true

require 'spaceship'
require 'json'

import 'FaslaneUpload.rb'
import 'Base/Helpers/BaseHelper.rb'
import 'Store/Store.rb'

platform :ios do
  lane :prepare_environment do |options|
    env_helper = EnvironmentHelper.new
    unless env_helper.bundle_identifier.to_s.strip.empty?
      BuildTypeFactory.new(fastlane: self).prepare_environment(options)
    end
end
