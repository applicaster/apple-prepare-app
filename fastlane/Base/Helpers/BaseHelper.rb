# frozen_string_literal: true

require 'fastlane/action'
require 'fastlane_core'
require 'fastlane'
require 'openssl'
require 'date'
require 'colorize'
require 'plist'
require 'json'
require 'securerandom'

import 'Base/Helpers/EnvironmentHelper.rb'

class BaseHelper
  @@env_helper = EnvironmentHelper.new

  attr_accessor :fastlane

  def initialize(options = {})
    @fastlane = options[:fastlane]
  end

  def sh(command)
    begin
      @fastlane.sh(command, log:false)
    rescue StandardError => e
      UI.user_error! e.message
    end
  end

  def current(name)
    # puts "#method: #{name}".colorize(:white).colorize(background: :blue)
  end

  def create_app_on_dev_portal(options)
    current(__callee__.to_s)

    username = options[:username]
    team_id = options[:team_id]
    name = options[:name]
    language = options[:language]
    version = options[:version]
    platforms = options[:platforms]
    bundle_identifier = options[:bundle_identifier]
    is_extension = options[:is_extension]

    @fastlane.produce(
      username: username,
      app_identifier: bundle_identifier,
      team_id: team_id,
      app_name: name,
      language: language,
      app_version: version,
      platforms: platforms,
      sku: "#{bundle_identifier}.#{options[:index]}",
      skip_itc: true,
      skip_devcenter: false,
      enable_services: {
        app_group: 'on',
        associated_domains: is_extension ? 'off' : 'on',
        data_protection: 'complete',
        in_app_purchase: is_extension ? 'off' : 'on',
        push_notification: 'on',
        access_wifi: is_extension ? 'off' : 'on'
      }
    )
  end

  def create_certificate(options)
    current(__callee__.to_s)

    create_temp_keychain
    
    username = options[:username]
    team_id = options[:team_id]

    puts("Printing all available `#{certificate_type_name} certificates`")

    login(username)

    locally_available_certificates = 0
    available_certificates = Spaceship::Certificate::AppleDistribution.all(mac: true)
    available_certificates.each do |certificate|
      puts(certificate)
      path = store_cer(certificate)
      puts("file path: #{path}")
      if is_certificate_exists_locally(path)
        locally_available_certificates+=1
        finger_print = FastlaneCore::CertChecker.sha1_fingerprint(path)
        puts("Certificate with id #{certificate.id} (sha1: #{finger_print}) is available locally and will be used for next operations".colorize(:green))
        puts("To obtain its p12 file, please export the certificate from the keychain".colorize(:green))
      end
    end
    if locally_available_certificates == 0
      if available_certificates.count > 0 
        puts("None of the available certificates can be used as not exists locally".colorize(:yellow))
        puts("To use one of the existing certificates, please obtain certificate's p12 file and password, and double-click on it to install on your mac".colorize(:yellow))
        puts("*** It is highly recommended to use existing certificate instead of creating new one, especially because there is a limit of number of distibution certificates can be created on developer account! ***".colorize(:yellow))
      else
        puts("There are no certificates available")
      end

      puts("Continue to create new certificate? (type `yes` to continue)".colorize(:red))
      continue_with_creation = STDIN.gets.chomp
  
      if continue_with_creation == "yes"
        @fastlane.get_certificates(
          development: false,
          username: username,
          team_id: team_id,
          output_path: @@env_helper.files_output_path,
          keychain_path: keychain_path,
          keychain_password: keychain_password
        )
      
        begin 
          p12_cert_path = File.join(@@env_helper.files_output_path, "#{certificate_id}.p12")
          p12_password_path = File.join(@@env_helper.files_output_path, "#{certificate_id}.txt")
  
          cer_cert_path = File.join(@@env_helper.files_output_path, "#{certificate_id}.cer")
          pkey_cert_path = File.join(@@env_helper.files_output_path, "#{certificate_id}.pkey")
  
          # rename private key file if exists
          File.rename(p12_cert_path, pkey_cert_path)  
          # get private key content
          pkey_raw = File.read(pkey_cert_path)
          # load private key from content
          pkey = OpenSSL::PKey::RSA.new(pkey_raw)
          # get cer file content
          cer_raw = File.read(cer_cert_path)
          # load certificate from content
          cer = OpenSSL::X509::Certificate.new(cer_raw)
          # set p12 random password
          certificate_password = SecureRandom.urlsafe_base64(9)
          # create p12 file
          p12 = OpenSSL::PKCS12.create(certificate_password, certificate_type_name, pkey, cer)
          # save p12 file
          File.write(p12_cert_path, p12.to_der)
          # save p12 password file
          File.write(p12_password_path, certificate_password)
  
          puts("p12 certificate: #{Pathname.new(p12_cert_path).realpath.to_s}".colorize(:blue).colorize(background: :white))
          puts("Password for generated p12 certificate: #{certificate_password}".colorize(:blue).colorize(background: :white))
        rescue Exception => e  
          puts("No new p12 certificate was generated, please export existing certificate from your keychain".colorize(:red).colorize(background: :white))
        end
      else
        UI.user_error! "Unable to continue without having existing distribution certificate in keychain or creating new one"
      end
    end
  end

  def store_cer(certificate)
    cer_cert_path = File.join(@@env_helper.files_output_path, "#{certificate.id}.cer")
    raw_data = certificate.download_raw
    File.write(cer_cert_path, raw_data)
    return cer_cert_path
  end

  def is_certificate_exists_locally(path)
    finger_print = FastlaneCore::CertChecker.sha1_fingerprint(path)
    available = FastlaneCore::CertChecker.list_available_identities(in_keychain: nil)
    ids = []
    available.split("\n").each do |current|
      next if current.include?("REVOKED")
      begin
        (ids << current.match(/.*\) ([[:xdigit:]]*) \".*/)[1])
      rescue
        # the last line does not match
      end
    end

    return ids.include?(finger_print)
  end

  def create_app_on_itc(options)
    current(__callee__.to_s)

    username = options[:username]
    name = options[:name]
    team_id = options[:team_id]
    bundle_identifier = options[:bundle_identifier]
    sku = "#{bundle_identifier}.#{options[:index]}"
    language = options[:language]
    app_version = options[:version]
    platforms = options[:platforms]

    @fastlane.produce(
      username: username,
      app_identifier: bundle_identifier,
      team_id: team_id,
      app_name: name,
      language: language,
      app_version: app_version,
      platforms: platforms,
      sku: sku,
      skip_itc: false,
      skip_devcenter: true
    )
  end

  def create_provisioning_profile(options)
    current(__callee__.to_s)

    username = options[:username]
    name = options[:name]
    team_id = options[:team_id]
    bundle_identifier = options[:bundle_identifier]
    platform = options[:platform]

    @fastlane.sigh(
      username: username,
      app_identifier: bundle_identifier,
      team_id: team_id,
      provisioning_name: "#{name} #{platform} provisioning profile",
      filename: "#{bundle_identifier}-#{platform}.mobileprovision",
      platform: platform,
      output_path: @@env_helper.files_output_path
    )

    delete_invalid_provisioning_profiles(options)
  end

  def delete_invalid_provisioning_profiles(options)
    current(__callee__.to_s)
    username = options[:username]
    team_id = options[:team_id]
    bundle_identifier = options[:bundle_identifier]

    login(username)
    Spaceship::Portal.client.team_id = team_id

    profiles = Spaceship::Portal::ProvisioningProfile.all.find_all do |profile|
      ((profile.status == 'Invalid') || (profile.status == 'Expired')) && profile.app.bundle_id == bundle_identifier
    end

    profiles.each do |profile|
      sh("echo 'Deleting #{profile.name}, status: #{profile.status}'")
      profile.delete!
    end
  end

  def group_name(app_bundle_identifier)
    "group.#{app_bundle_identifier}"
  end

  def create_temp_keychain
    @fastlane.create_keychain(
      name: keychain_name,
      password: keychain_password,
      unlock: true,
      timeout: 0
    )
  end
  
  def keychain_name
    'zapp-apple-build.keychain'
  end

  def keychain_path
    "~/Library/Keychains/#{keychain_name}-db"
  end

  def certificate_id
    ENV["CER_CERTIFICATE_ID"]
  end

  def certificate_type_name
    'Distribution'
  end

  def keychain_password
    'circle'
  end

  def login(username)
    password = ENV['FASTLANE_PASSWORD']
    Spaceship::Portal.login(username, password)
  end
end
