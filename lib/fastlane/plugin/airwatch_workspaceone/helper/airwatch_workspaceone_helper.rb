require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class AirwatchWorkspaceoneHelper
      # class methods that you define here become available in your action
      # as `Helper::AirwatchWorkspaceoneHelper.your_method`
      #

      APP_VERSIONS_LIST_SUFFIX      = "/API/mam/apps/search?applicationtype=Internal&includeAppsFromChildOgs=false&IncludeAppsFromParentOgs=false&bundleid=%s&locationgroupid=%d"
      INTERNAL_APP_DELETE_SUFFIX    = "/API/mam/apps/internal/%d"
      INTERNAL_APP_RETIRE_SUFFIX    = "/API/mam/apps/internal/%d/retire"
      INTERNAL_APP_UNRETIRE_SUFFIX  = "/API/mam/apps/internal/%d/unretire"

      def self.show_message
        UI.message("Hello from the airwatch_workspaceone plugin helper!")
      end

      def self.construct_app_version(app)
        app_version = Hash.new
        app_version['Id'] = app['Id']['Value']
        app_version['Version'] = app['AppVersion']
        return app_version
      end

      def self.find_app_versions(app_identifier, app_status, host_url, aw_tenant_code, b64_encoded_auth, locationGrpId, debug)
        # get the list of apps 
        apps = list_app_versions(app_identifier, host_url, aw_tenant_code, b64_encoded_auth, locationGrpId, debug)
        app_versions = Array.new
        
        apps['Application'].each do |app|
          
          case app_status
          when 'Active'
            if app['Status'] == "Active"
              app_version = construct_app_version(app)
              app_versions << app_version
            end

          when 'Retired'
            if app['Status'] == "Retired"
              app_version = construct_app_version(app)
              app_versions << app_version
            end

          else
            app_version = construct_app_version(app)
            app_versions << app_version
          end
        end

        app_versions.sort_by! { |app_version| app_version["Id"] }
        return app_versions
      end

      def self.list_app_versions(app_identifier, host_url, aw_tenant_code, b64_encoded_auth, locationGrpId, debug)
        require 'rest-client'
        require 'json'
        
        response = RestClient.get(host_url + APP_VERSIONS_LIST_SUFFIX % [app_identifier, locationGrpId], {accept: :json, 'aw-tenant-code': aw_tenant_code, 'Authorization': "Basic " + b64_encoded_auth})

        if debug
          UI.message("Response code: %d" % [response.code])
          UI.message("Response body:")
          UI.message(JSON.pretty_generate(response.body))
        end

        if response.code != 200
          UI.user_error!("There was an error in finding app versions. One possible reason is that an app with the bundle identifier given does not exist on Console.")
          exit
        end

        json = JSON.parse(response.body)
        return json
      end

      def self.delete_app(app_version, host_url, aw_tenant_code, b64_encoded_auth, debug)
        require 'rest-client'
        require 'json'

        UI.message("Starting to delete app version: %s" % [app_version['Version']])
        response = RestClient.delete(host_url + INTERNAL_APP_DELETE_SUFFIX % [app_version['Id']],  {accept: :json, 'aw-tenant-code': aw_tenant_code, 'Authorization': "Basic " + b64_encoded_auth})

        if debug
          UI.message("Response code: %d" % [response.code])
        end

        if response.code == 204
          UI.message("Successfully deleted app version: %s" % [app_version['Version']])
        else
          UI.message("Failed to delete app version: %s" % [app_version['Version']])
        end
      end

      def self.retire_app(app_version, host_url, aw_tenant_code, b64_encoded_auth, debug)
        require 'rest-client'
        require 'json'

        body = {
          "applicationid" => app_version['Id']
        }

        UI.message("Starting to retire app version: %s" % [app_version['Version']])
        response = RestClient.post(host_url + INTERNAL_APP_RETIRE_SUFFIX % [app_version['Id']], body.to_json,  {accept: :json, 'aw-tenant-code': aw_tenant_code, 'Authorization': "Basic " + b64_encoded_auth})

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

      def self.unretire_app(app_version, host_url, aw_tenant_code, b64_encoded_auth, debug)
        require 'rest-client'
        require 'json'

        body = {
          "applicationid" => app_version['Id']
        }

        UI.message("Starting to unretire app version: %s" % [app_version['Version']])
        response = RestClient.post(host_url + INTERNAL_APP_UNRETIRE_SUFFIX % [app_version['Id']], body.to_json,  {accept: :json, 'aw-tenant-code': aw_tenant_code, 'Authorization': "Basic " + b64_encoded_auth})

        if debug
          UI.message("Response code: %d" % [response.code])
        end

        if response.code == 202
          UI.message("Successfully unretired app version: %s" % [app_version['Version']])
        else
          json = JSON.parse(response.body)
          UI.message("Failed to unretire app version: %s" % [app_version['Version']])
        end
      end

    end
  end
end