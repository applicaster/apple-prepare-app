# frozen_string_literal: true
require 'fastlane/action'
require 'fastlane_core'
require 'fastlane'
require 'openssl'
require 'date'
require 'colorize'
require 'plist'
require 'json'
require 'io/console'
require 'colorize'

import 'Base/Models/AppInfo.rb'
import 'Base/Models/UserCredentials.rb'

class Testflight < BaseHelper
  attr_accessor :app_extensions_helper, :user_credentials, :app_info

  def initialize(options = {})
    super
    @app_extensions_helper = TestflightAppExtensions.new(fastlane: @fastlane)
  end

  def prepare_environment(options)
    current(__callee__.to_s)

    puts("---------------------------------------------------------".colorize(:green))
    puts("Obtaining distribution certificate and provisioning profiles required for the new app and its extensions".colorize(:green))
    puts("Please enter required parameters in order to continue with the process".colorize(:green))
    puts("(entered details are required only to complete the process and will not be stored locally)".colorize(:yellow))
    puts("---------------------------------------------------------".colorize(:green))

    prepare_app_info
    prepare_credentials

    unless @app_info.nil? && @user_credentials.nil?
      prepare_app_on_dev_portal
      prepare_app_on_itc
    end
  end

  def prepare_app_info
    puts("App name (ex. Test app): ")
    app_name = STDIN.gets.chomp

    puts("App bundle identifier (ex. com.applicaster.testpp): ")
    bundle_identifier = STDIN.gets.chomp

    puts("Developer account team id (can be found here: https://developer.apple.com/account): ")
    team_id = STDIN.gets.chomp

    begin
      raise unable_to_proceed_without_requried_parameters if app_name.empty? && bundle_identifier.empty? && team_id.empty?
      @app_info = AppInfo.new(app_name, bundle_identifier, team_id)
    rescue StandardError => e
      UI.user_error! e.message
    end
  end

  def prepare_credentials
    puts("AppleID associated with the Developer account: ")
    username = STDIN.gets.chomp

    puts("Password: ")
    password = STDIN.noecho(&:gets).chomp

    begin
      raise unable_to_proceed_without_requried_parameters if username.empty? && password.empty?
      @user_credentials = UserCredentials.new(username, password)
      sh("bundle exec fastlane fastlane-credentials add --username '#{@user_credentials.username}' --password '#{@user_credentials.password}'")
      ENV['FASTLANE_PASSWORD'] = @user_credentials.password
    rescue StandardError => e
      UI.user_error! e.message
    end
  end

  def prepare_app_on_dev_portal
    create_certificate(
      username: @user_credentials.username,
      team_id: @app_info.team_id,
      generate_apple_certs: true
    )

    # create main app on developer portal with new identifier
    create_app_on_dev_portal(
      username: @user_credentials.username,
      team_id: @app_info.team_id,
      name: @app_info.name,
      bundle_identifier: @app_info.bundle_identifier,
      index: @app_info.index
    )

    prepare_app_group

    # create provisioning profile per platform
    @app_info.platforms.each do |platform|
      create_provisioning_profile(
        username: @user_credentials.username,
        team_id: @app_info.team_id,
        name: @app_info.name,
        bundle_identifier: @app_info.bundle_identifier,
        platform: platform
      )

      if platform == 'ios'
        # prepare provisioning profiles for app extensions
        prepare_extensions
      end
    end

    
  end

  def prepare_app_group
    current(__callee__.to_s)

    # create group for app
    sh("bundle exec fastlane produce group -g #{group_name(@app_info.bundle_identifier)} -n '#{@app_info.bundle_identifier} Group' -u #{@user_credentials.username} ")
    # add the app to the created group
    sh("bundle exec fastlane produce associate_group #{group_name(@app_info.bundle_identifier)} -a #{@app_info.bundle_identifier} -u #{@user_credentials.username} ")
  end

  def prepare_extensions
    current(__callee__.to_s)
    prepare_notification_content_extension
    prepare_notification_service_extension
    prepare_widget_extension
  end

  def prepare_app_on_itc
    create_app_on_itc(      
      username: @user_credentials.username,
      team_id: @app_info.team_id,
      name: @app_info.name,
      bundle_identifier: @app_info.bundle_identifier,
      index: @app_info.index,
      platforms: @app_info.platforms,
      language: @app_info.language
    )
  end

  def prepare_notification_content_extension
    current(__callee__.to_s)
    @app_extensions_helper.prepare_extension(
      username: @user_credentials.username,
      team_id: @app_info.team_id,
      app_bundle_identifier: @app_info.bundle_identifier,
      extension_type: @app_extensions_helper.notification_content_extension_key,
      extension_target_name: @app_extensions_helper.notification_content_extension_target_name,
      extension_app_name: notification_content_extension_app_name,
      extension_bundle_identifier: notification_content_extension_bundle_identifier
    )
  end

  def prepare_notification_service_extension
    current(__callee__.to_s)
    @app_extensions_helper.prepare_extension(
      username: @user_credentials.username,
      team_id: @app_info.team_id,
      app_bundle_identifier: @app_info.bundle_identifier,
      extension_type: @app_extensions_helper.notification_service_extension_key,
      extension_target_name: @app_extensions_helper.notification_service_extension_target_name,
      extension_app_name: notification_service_extension_app_name,
      extension_bundle_identifier: notification_service_extension_bundle_identifier
    )
  end

  def prepare_widget_extension
    current(__callee__.to_s)
    @app_extensions_helper.prepare_extension(
      username: @user_credentials.username,
      team_id: @app_info.team_id,
      app_bundle_identifier: @app_info.bundle_identifier,
      extension_type: @app_extensions_helper.widget_extension_key,
      extension_target_name: @app_extensions_helper.widget_extension_target_name,
      extension_app_name: widget_extension_app_name,
      extension_bundle_identifier: widget_extension_bundle_identifier
    )
  end

  def notification_service_extension_app_name
    "#{@app_info.name} - #{@app_extensions_helper.notification_service_extension_target_name}"
  end

  def notification_content_extension_app_name
    "#{@app_info.name} - #{@app_extensions_helper.notification_content_extension_target_name}"
  end

  def widget_extension_app_name
    "#{@app_info.name} - #{@app_extensions_helper.widget_extension_target_name}"
  end

  def notification_service_extension_bundle_identifier
    "#{@app_info.bundle_identifier}.#{@app_extensions_helper.notification_service_extension_target_name}"
  end

  def notification_content_extension_bundle_identifier
    "#{@app_info.bundle_identifier}.#{@app_extensions_helper.notification_content_extension_target_name}"
  end

  def widget_extension_bundle_identifier
    "#{@app_info.bundle_identifier}.#{@app_extensions_helper.widget_extension_target_name}"
  end

  def unable_to_proceed_without_requried_parameters
    "Unable to proceed without required parameters"
  end
end
