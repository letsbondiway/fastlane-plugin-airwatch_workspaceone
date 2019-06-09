require 'fastlane/action'
require_relative '../helper/airwatch_workspaceone_helper'

module Fastlane
  module Actions
    class RetirePreviousVersionsAction < Action
      
      APP_VERSIONS_LIST_SUFFIX    = "/API/mam/apps/search?bundleid=%s"
      INTERNAL_APP_RETIRE_SUFFIX  = "/API/mam/apps/internal/%d/retire"
      
      $is_debug = false

      def self.run(params)
        UI.message("The airwatch_workspaceone plugin is working!")

        # check if debug is enabled
        $is_debug = params[:debug]

        if debug
          UI.message("---------------------------------")
          UI.message("AirWatch plugin debug information")
          UI.message("---------------------------------")
          UI.message(" host_url: #{params[:host_url]}")
          UI.message(" aw_tenant_code: #{params[:aw_tenant_code]}")
          UI.message(" b64_encoded_auth: #{params[:b64_encoded_auth]}")
          UI.message(" app_identifier: #{params[:app_identifier]}")
          UI.message(" app_name: #{params[:app_name]}")
          UI.message(" keep_latest_versions_count: #{params[:keep_latest_versions_count]}")
        end

        $host_url                   = params[:host_url]
        $aw_tenant_code             = params[:aw_tenant_code]
        $b64_encoded_auth           = params[:b64_encoded_auth]
        app_identifier              = params[:app_identifier]
        app_name                    = params[:app_name]
        keep_latest_versions_count  = params[:keep_latest_versions_count]

        # step 1: find app
        UI.message("------------------------------")
        UI.message("1. Finding active app versions")
        UI.message("------------------------------")

        app_versions = find_app(app_identifier)
        UI.success("Found %d active app versions" % [app_versions.count])
        UI.success("Version numbers: %s" % [app_versions.map {|app_version| app_version.values[1]}])

        # step 2: retire previous versions
        UI.message("-------------------------------")
        UI.message("2. Retiring active app versions")
        UI.message("-------------------------------")

        keep_latest_versions_count_int = keep_latest_versions_count.to_i
        if appVersions.count < keep_latest_versions_count_int
          UI.important("Given number of latest versions to keep is greater than available number of versions on the store.")
          UI.important("Will retire all versions excpet the most latest version.")
          keep_latest_versions_count_int = 1
        end

        app_versions.pop(keep_latest_versions_count_int)
        app_versions.each do |app_version|
          retire_app(app_version)
        end

        UI.success("Requested active app versions successfully retired")
      end

      def self.find_app(app_identifier)
        # get the list of apps 
        data = list_app_versions(app_identifier)
        active_app_versions = Array.new

        data['Application'].each do |app|
          if app['Status'] == "Active"
            active_app_version = Hash.new
            active_app_version['Id'] = app['Id']['Value']
            active_app_version['Version'] = app['AppVersion']
            active_app_versions << active_app_version
          end
        end

        return active_app_versions
      end

      def self.list_app_versions(app_identifier)
        require 'rest-client'
        require 'json'
        
        response = RestClient.get($host_url + APP_VERSIONS_LIST_SUFFIX % [app_identifier], {accept: :json, 'aw-tenant-code': $aw_tenant_code, 'Authorization': "Basic " + $b64_encoded_auth})

        if debug
          UI.message("Response code: %d" % [response.code])
          UI.message("Response body:")
          UI.message(response.body)
        end

        json = JSON.parse(response.body)
        return json
      end

      def self.retire_app(app_version)
        require 'rest-client'
        require 'json'

        body = {
          "applicationid" => app_version['Id']
        }

        UI.message("Starting to retire app version: %s" % [app_version['Version']])
        response = RestClient.post($host_url + INTERNAL_APP_RETIRE_SUFFIX % [app_version['Id']], body.to_json,  {accept: :json, 'aw-tenant-code': $aw_tenant_code, 'Authorization': "Basic " + $b64_encoded_auth})

        if debug
          UI.message("Response code: %d" % [response.code])
        end

        if response.code == 202
          UI.message("Successfully retired app version: %s" % [app_version['Version']])
        else
          json = JSON.parse(response.body)
          UI.message("Failed to retire app version: %s" % [app_version['Version']])
        end
      end

      def self.description
        "The main purpose of this action is to retire previous active versions of an application. This action takes a string parameter where you can specify the number of latest versions to keep if you do not want to retire all the previous active versions."
      end

      def self.authors
        ["Ram Awadhesh Sharan"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "retire_previous_versions - To retire previous active versions of an application on the AirWatch console except the latest version."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :host_url,
                                  env_name: "AIRWATCH_HOST_API_URL",
                               description: "Host API URL of the AirWatch instance",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No AirWatch Host API URl given.") unless value and !value.empty?
                                            end),

          FastlaneCore::ConfigItem.new(key: :aw_tenant_code,
                                  env_name: "AIRWATCH_API_KEY",
                               description: "API key to access AirWatch Rest APIs",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("Api tenant code header is missing.") unless value and !value.empty?
                                            end),

          FastlaneCore::ConfigItem.new(key: :b64_encoded_auth,
                                  env_name: "AIRWATCH_BASE64_ENCODED_BASIC_AUTH_STRING",
                               description: "The base64 encoded Basic Auth string generated by authorizing username and password to the AirWatch instance",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("The authorization header is empty or the scheme is not basic") unless value and !value.empty?
                                            end),

          FastlaneCore::ConfigItem.new(key: :app_identifier,
                                  env_name: "APP_IDENTIFIER",
                               description: "Bundle identifier of your app",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No app identifier given, pass using `app_identifier: 'com.example.app'`") unless value and !value.empty?
                                            end),

          FastlaneCore::ConfigItem.new(key: :app_name,
                                  env_name: "AIRWATCH_APPLICATION_NAME",
                               description: "Name of the application",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No app name given, pass using `app_name: 'My sample app'`") unless value and !value.empty?
                                            end),

          FastlaneCore::ConfigItem.new(key: :keep_latest_versions_count,
                                  env_name: "AIRWATCH_KEEP_LATEST_VERSIONS_COUNT",
                               description: "Name of the application",
                                  optional: true,
                                      type: String,
                             default_value: "1",
                              verify_block: proc do |value|
                                              UI.user_error!("The number of latest versions to keep can not be zero or negative") unless value.to_i > 0
                                            end),

          FastlaneCore::ConfigItem.new(key: :debug,
                                  env_name: "AIRWATCH_DEBUG",
                               description: "Debug flag, set to true to show extended output. default: false",
                                  optional: true,
                                 is_string: false,
                             default_value: false)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform

        [:ios, :android].include?(platform)
        true
      end

      # helpers
      
      def self.debug
        $is_debug
      end

    end
  end
end
