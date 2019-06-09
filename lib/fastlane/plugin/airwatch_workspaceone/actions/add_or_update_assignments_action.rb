require 'fastlane/action'
require_relative '../helper/airwatch_workspaceone_helper'

module Fastlane
  module Actions
    class AddOrUpdateAssignmentsAction < Action

      APP_VERSIONS_LIST_SUFFIX      = "/API/mam/apps/search?bundleid=%s"
      ADD_UPDATE_ASSIGNMENT_SUFFIX  = "/API/mam/apps/internal/%d/assignments"
      SEARCH_SMART_GROUP_SUFFIX     = "/API/mdm/smartgroups/search?name=%s&organizationgroupid=%d"

      $is_debug = false
      $app_id_int

      def self.run(params)
        UI.message("The airwatch_workspaceone plugin is working!")

        # check if debug is enabled
        $is_debug = params[:debug]

        if debug
          UI.message("----------------------------------------------")
          UI.message("AddOrUpdateAssignmentsAction debug information")
          UI.message("----------------------------------------------")
          UI.message(" host_url: #{params[:host_url]}")
          UI.message(" aw_tenant_code: #{params[:aw_tenant_code]}")
          UI.message(" b64_encoded_auth: #{params[:b64_encoded_auth]}")
          UI.message(" organization_group_id: #{params[:org_group_id]}")
          UI.message(" app_identifier: #{params[:app_identifier]}")
          UI.message(" smart_groups_to_assign: #{params[:smart_groups_to_assign]}")
          UI.message(" assignment_parameters: #{params[:assignment_parameters]}")
        end

        $host_url               = params[:host_url]
        $aw_tenant_code         = params[:aw_tenant_code]
        $b64_encoded_auth       = params[:b64_encoded_auth]
        $org_group_id           = params[:org_group_id]
        app_identifier          = params[:app_identifier]
        smart_groups_to_assign  = params[:smart_groups_to_assign]
        assignment_parameters   = params[:assignment_parameters]

        # step 1: find app
        UI.message("-----------------------------")
        UI.message("1. Finding app's smart groups")
        UI.message("-----------------------------")

        app_smart_groups = find_app_smart_groups(app_identifier)
        UI.success("Found %d smart group(s) assigned to the app." % [app_smart_groups.count])
        UI.success("Smart Group(s): %s" % [app_smart_groups.map {|smart_group| smart_group.values[1]}])

        # step 2: separate smart groups into need to add and need to update
        UI.message("-----------------------------------------------")
        UI.message("2. Separating smart groups to add and to update")
        UI.message("-----------------------------------------------")

        update_smart_group_ids = Array.new
        update_smart_group_names = Array.new
        add_smart_group_ids = Array.new
        add_smart_group_names = Array.new

        smart_groups_to_assign.each do |smart_group|
          UI.message("Fetching details for %s smart group" % [smart_group])
          smart_group_id = find_smart_group_id(smart_group)
          if smart_group_id == -1
            UI.important("Could not find smart group named %s in the given organization group. Skipping this smart group assignment." % [smart_group])
          else
            if app_smart_groups.map {|smart_group| smart_group.values[0]}.include? smart_group_id
              UI.message("Assignment to the smart group %s needs to be updated" % [smart_group])
              update_smart_group_ids << smart_group_id
              update_smart_group_names << smart_group
            else
              UI.message("Assignment to the smart group %s needs to be added" % [smart_group])
              add_smart_group_ids << smart_group_id
              add_smart_group_names << smart_group
            end
          end
        end

        # step 3: update smart group assignments
        UI.message("--------------------------------------------")
        UI.message("3. Updating existing smart group assignments")
        UI.message("--------------------------------------------")

        if update_smart_group_ids.count <= 0
          UI.success("No existing smart groups assignment needs to be updated")
        else
          add_update_smart_group_assignment(update_smart_group_ids, assignment_parameters, true)
          UI.success("Assignment for smart group(s): %s successfully updated" % [update_smart_group_names])
        end

        # step 4: add smart group assignments
        UI.message("-------------------------------------")
        UI.message("4. Adding new smart group assignments")
        UI.message("-------------------------------------")

        if add_smart_group_ids.count <= 0
          UI.success("No new groups assignment needs to be added")
        else
          add_update_smart_group_assignment(add_smart_group_ids, assignment_parameters, false)
          UI.success("Assignment for smart group(s): %s successfully added" % [add_smart_group_names])
        end
      end

      def self.find_app_smart_groups(app_identifier)
        # get the list of apps 
        data = list_app_versions(app_identifier)
        app_versions = data['Application']

        if app_versions.count <= 0
          UI.user_error!("No app found on the console having bundle identifier: %s" % [app_identifier])
          UI.user_error!("Please provide an existing app identifier")
          exit
        end

        latest_app_version = app_versions.last
        $app_id_int = latest_app_version['Id']['Value']
        app_smart_groups = latest_app_version['SmartGroups']
        return app_smart_groups
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

        if response.code != 200
          UI.user_error!("There was an error in finding app versions. One possible reason is that an app with the bundle identifier given does not exist on Console.")
          exit
        end

        json = JSON.parse(response.body)
        return json
      end

      def self.find_smart_group_id(smart_group_name)
        data = fetch_smart_group_details(smart_group_name)
        smart_group_id = -1
        if data.empty?
          return smart_group_id
        end

        data['SmartGroups'].each do |smart_group|
          smart_group_id = smart_group['SmartGroupID']
        end

        return smart_group_id
      end

      def self.fetch_smart_group_details(smart_group_name)
        require 'rest-client'
        require 'json'

        response = RestClient.get($host_url + SEARCH_SMART_GROUP_SUFFIX % [smart_group_name, $org_group_id], {accept: :json, 'aw-tenant-code': $aw_tenant_code, 'Authorization': "Basic " + $b64_encoded_auth})

        if debug
          UI.message("Response code: %d" % [response.code])
          UI.message("Response body:")
          UI.message(response.body)
        end

        if response.code != 200
          return Hash.new
        end

        json = JSON.parse(response.body)
        return json
      end

      def self.add_update_smart_group_assignment(smart_group_ids, assignment_parameters, update)
        require 'rest-client'
        require 'json'

        body = {
          "SmartGroupIds" => smart_group_ids,
          "DeploymentParameters" => assignment_parameters
        }

        if debug
          UI.message("Deploy Request JSON:")
          UI.message(body.to_json)
        end

        if update
          response = RestClient.put($host_url + ADD_UPDATE_ASSIGNMENT_SUFFIX % [$app_id_int], body.to_json, {content_type: :json, accept: :json, 'aw-tenant-code': $aw_tenant_code, 'Authorization': "Basic " + $b64_encoded_auth})
        else
          response = RestClient.post($host_url + ADD_UPDATE_ASSIGNMENT_SUFFIX % [$app_id_int], body.to_json, {content_type: :json, accept: :json, 'aw-tenant-code': $aw_tenant_code, 'Authorization': "Basic " + $b64_encoded_auth})
        end

        if debug
          UI.message("Response code: %d" % [response.code])
          UI.message("Response body:")
          UI.message(response.body)
        end
      end

      def self.description
        "The main purpose of this action is to add a new smart group assignment to an application or to update an existing smart group assignment of an application with a given dictionary of deployment/assignment parameters. If a smart group name is provided which does not exist yet on Console, assignment for that smart group is ignored."
      end

      def self.authors
        ["Ram Awadhesh Sharan"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "add_or_update_assignments - To add or update smart group assignments with given deployment parameters."
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
                               description: "API key or the tenant code to access AirWatch Rest APIs",
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

          FastlaneCore::ConfigItem.new(key: :org_group_id,
                                  env_name: "AIRWATCH_ORGANIZATION_GROUP_ID",
                               description: "Organization Group ID integer identifying the customer or container",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No Organization Group ID integer given, pass using `org_group_id: MyOrgGroupId`") unless value and !value.empty?
                                            end),

          FastlaneCore::ConfigItem.new(key: :app_identifier,
                                  env_name: "APP_IDENTIFIER",
                               description: "Bundle identifier of your app",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No app identifier given, pass using `app_identifier: 'com.example.app'`") unless value and !value.empty?
                                            end),

          FastlaneCore::ConfigItem.new(key: :smart_groups_to_assign,
                                  env_name: "AIRWATCH_SMART_GROUPS_TO_ASSIGN",
                               description: "Name of the smart group to assign to",
                                  optional: false,
                                      type: Array,
                              verify_block: proc do |value|
                                              UI.user_error!("No smart group given, pass using `smart_group_to_assign: 'MyAppDevTeam'`") unless value and !value.empty?
                                            end),

          FastlaneCore::ConfigItem.new(key: :assignment_parameters,
                                  env_name: "AIRWATCH_ASSIGNMENT_PARAMETERS",
                               description: "Deployment parameters for the smart group assignment",
                                  optional: false,
                                 is_string: false,
                              verify_block: proc do |value|
                                              UI.user_error!("No deployment parameters given, pass using `assignment_parameters: '{key1: value1, key2: value2}'`") unless value and !value.empty?
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
        #
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