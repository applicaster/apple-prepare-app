# frozen_string_literal: true

class TestflightAppExtensions < BaseHelper
  def prepare_extension(options)
    username = options[:username]
    team_id = options[:team_id]
    team_name = options[:team_name]
    app_bundle_identifier = options[:app_bundle_identifier]
    extension_type = options[:extension_type]
    extension_target_name = options[:extension_target_name]
    extension_app_name = options[:extension_app_name]
    extension_bundle_identifier = options[:extension_bundle_identifier]
    extension_platform = options[:extension_platform]

    # create app for the notifications
    create_app_on_dev_portal(
      username: username,
      team_id: team_id,
      name: extension_app_name,
      bundle_identifier: extension_bundle_identifier,
      index: extension_type,
      is_extension: true
    )

    # add extension to the app group
    sh("bundle exec fastlane produce associate_group #{group_name(app_bundle_identifier)} -a #{extension_bundle_identifier} -u #{username} -i 1")

    # create provisioning profile for the notifications app
    create_provisioning_profile(
      username: username,
      team_id: team_id,
      name: extension_app_name,
      bundle_identifier: extension_bundle_identifier,
      platform: extension_platform
    )
  end


  # notification service extension
  def notification_service_extension_key
    'NOTIFICATION_SERVICE_EXTENSION'
  end

  def notification_service_extension_target_name
    'NotificationServiceExtension'
  end

  # notification content extension
  def notification_content_extension_key
    'NOTIFICATION_CONTENT_EXTENSION'
  end

  def notification_content_extension_target_name
    'NotificationContentExtension'
  end

  # widget extension
  def widget_extension_key
    'WIDGET_EXTENSION'
  end

  def widget_extension_target_name
    'AppWidgetExtension'
  end
end
