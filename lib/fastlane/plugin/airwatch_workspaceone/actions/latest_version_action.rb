require 'fastlane/action'
require_relative '../helper/airwatch_workspaceone_helper'

module Fastlane
  module Actions
    module SharedValues
      LATEST_VERSION_NUMBER ||= :LATEST_VERSION_NUMBER
      ACTIVE_VERSION_NUMBERS ||= :ACTIVE_VERSION_NUMBERS
      RETIRED_VERSION_NUMEBRS ||= :RETIRED_VERSION_NUMEBRS
    end

    class LatestVersionAction < Action      
      
      $is_debug = false

      def self.run(params)
        UI.message("The airwatch_workspaceone plugin is working!")

        # check if debug is enabled
        $is_debug = params[:debug]

        if debug
          UI.message("-------------------------------------")
          UI.message("LatestVersionAction debug information")
          UI.message("-------------------------------------")
          UI.message(" host_url: #{params[:host_url]}")
          UI.message(" aw_tenant_code: #{params[:aw_tenant_code]}")
          UI.message(" b64_encoded_auth: #{params[:b64_encoded_auth]}")
          UI.message(" organization_group_id: #{params[:org_group_id]}")
          UI.message(" app_identifier: #{params[:app_identifier]}")
        end

        $host_url         = params[:host_url]
        $aw_tenant_code   = params[:aw_tenant_code]
        $b64_encoded_auth = params[:b64_encoded_auth]
        $org_group_id     = params[:org_group_id]
        app_identifier    = params[:app_identifier]

        # step 1: find app
        UI.message("-----------------------")
        UI.message("1. Finding app versions")
        UI.message("-----------------------")

        app_versions = Helper::AirwatchWorkspaceoneHelper.find_app_versions(app_identifier, 'None', $host_url, $aw_tenant_code, $b64_encoded_auth, $org_group_id, debug)
        app_version_numbers = app_versions.map {|app_version| app_version.values[1]}
        UI.success("Found %d app version(s)" % [app_versions.count])
        UI.success("Version number(s): %s" % [app_version_numbers])
        UI.success("Latest version: %s" % [app_version_numbers.last])

        # step 2: find active versions of app
        if debug
          UI.message("------------------------------")
          UI.message("2. Finding Active app versions")
          UI.message("------------------------------")
        end

        active_app_versions = Helper::AirwatchWorkspaceoneHelper.find_app_versions(app_identifier, 'Active', $host_url, $aw_tenant_code, $b64_encoded_auth, $org_group_id, debug)
        active_app_version_numbers = active_app_versions.map {|active_app_version| active_app_version.values[1]}
        Actions.lane_context[SharedValues::ACTIVE_VERSION_NUMBERS] = active_app_version_numbers

        if debug
          UI.success("Found %d Active app version(s)" % [active_app_versions.count])
          UI.success("Active app Version number(s): %s" % [active_app_version_numbers])
        end

        # step 3: find retired versions of app
        if debug
          UI.message("-------------------------------")
          UI.message("2. Finding Retired app versions")
          UI.message("-------------------------------")
        end

        retired_app_versions = Helper::AirwatchWorkspaceoneHelper.find_app_versions(app_identifier, 'Retired', $host_url, $aw_tenant_code, $b64_encoded_auth, $org_group_id, debug)
        retired_app_version_numbers = retired_app_versions.map {|retired_app_version| retired_app_version.values[1]}
        Actions.lane_context[SharedValues::RETIRED_VERSION_NUMEBRS] = retired_app_version_numbers

        if debug
          UI.success("Found %d Retired app version(s)" % [retired_app_versions.count])
          UI.success("Retired app Version number(s): %s" % [retired_app_version_numbers])
        end

        return Actions.lane_context[SharedValues::LATEST_VERSION_NUMBER] = app_version_numbers.last
      end

      def self.description
        "The main purpose of this action is to find the version number of the latest version of the app on the console and output the same. It also finds and outputs arrays of active app version numbers and retired app version numbers of the app."
      end

      def self.authors
        ["Ram Awadhesh Sharan"]
      end

      def self.output
        [
          ['LATEST_VERSION_NUMBER', 'Version number of the latest version of app on the console'],
          ['ACTIVE_VERSION_NUMBERS', 'An array of version numbers of active versions of the app on the console'],
          ['RETIRED_VERSION_NUMEBRS', 'An array of version numbers of retired versions of the app on the console']
        ]
      end

      def self.return_value
        "Version number of the latest version of app on the console"
      end

      def self.details
        # Optional:
        "latest_version - To find the version number of the latest version of the app on the Workspace One console."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :host_url,
                                  env_name: "AIRWATCH_HOST_API_URL",
                               description: "Host API URL of the AirWatch/Workspace ONE instance without /API/ at the end",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No AirWatch/Workspace ONE Host API URl given, pass using `host_url: 'https://yourhost.com'`") unless value and !value.empty?
                                            end),

          FastlaneCore::ConfigItem.new(key: :aw_tenant_code,
                                  env_name: "AIRWATCH_API_KEY",
                               description: "API key or the tenant code to access AirWatch/Workspace ONE Rest APIs",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("Api tenant code header is missing, pass using `aw_tenant_code: 'yourapikey'`") unless value and !value.empty?
                                            end),

          FastlaneCore::ConfigItem.new(key: :b64_encoded_auth,
                                  env_name: "AIRWATCH_BASE64_ENCODED_BASIC_AUTH_STRING",
                               description: "The base64 encoded Basic Auth string generated by authorizing username and password to the AirWatch/Workspace ONE instance",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("The authorization header is empty or the scheme is not basic, pass using `b64_encoded_auth: 'yourb64encodedauthstring'`") unless value and !value.empty?
                                            end),

          FastlaneCore::ConfigItem.new(key: :org_group_id,
                                  env_name: "AIRWATCH_ORGANIZATION_GROUP_ID",
                               description: "Organization Group ID integer identifying the customer or container",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No Organization Group ID integer given, pass using `org_group_id: 'yourorggrpintid'`") unless value and !value.empty?
                                            end),

          FastlaneCore::ConfigItem.new(key: :app_identifier,
                                  env_name: "APP_IDENTIFIER",
                               description: "Bundle identifier of your app",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No app identifier given, pass using `app_identifier: 'com.example.app'`") unless value and !value.empty?
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