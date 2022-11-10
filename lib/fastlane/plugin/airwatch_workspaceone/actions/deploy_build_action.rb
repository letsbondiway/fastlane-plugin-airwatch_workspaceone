require 'fastlane/action'
require_relative '../helper/airwatch_workspaceone_helper'

module Fastlane
  module Actions
    module SharedValues
      DEPLOYED_APP_UUID ||= :SIGH_PROFILE_PATH
    end

    class DeployBuildAction < Action

      UPLOAD_BLOB_SUFFIX    = "/API/mam/blobs/uploadblob?fileName=%s&organizationGroupId=%s"
      BEGIN_INSTALL_SUFFIX  = "/API/mam/apps/internal/begininstall"
      DELETE_BLOB_SUFFIX    = "/API/mam/blobs/blob/%d"

      $is_debug                 = false
      $device_type              = "Apple"
      $supported_device_models  = Hash.new

      def self.run(params)
        UI.message("The airwatch_workspaceone plugin is working!")

        # check if debug is enabled
        $is_debug = params[:debug]

        if debug
          UI.message("-----------------------------------")
          UI.message("DeployBuildAction debug information")
          UI.message("-----------------------------------")
          UI.message(" host_url: #{params[:host_url]}")
          UI.message(" aw_tenant_code: #{params[:aw_tenant_code]}")
          UI.message(" b64_encoded_auth: #{params[:b64_encoded_auth]}")
          UI.message(" organization_group_id: #{params[:org_group_id]}")
          UI.message(" carry_over_assignments: #{params[:carry_over_assignments]}")
          UI.message(" app_name: #{params[:app_name]}")
          UI.message(" app_version: #{params[:app_version]}")
          UI.message(" file_name: #{params[:file_name]}")
          UI.message(" path_to_file: #{params[:path_to_file]}")
          UI.message(" push_mode: #{params[:push_mode]}")
        end

        $host_url               = params[:host_url]
        $aw_tenant_code         = params[:aw_tenant_code]
        $b64_encoded_auth       = params[:b64_encoded_auth]
        $org_group_id           = params[:org_group_id]
        $carry_over_assignments = params[:carry_over_assignments]
        app_name                = params[:app_name]
        app_version             = params[:app_version]
        file_name               = params[:file_name]
        path_to_file            = params[:path_to_file]
        push_mode               = params[:push_mode]

        # step 1: determining device type
        UI.message("----------------------")
        UI.message("1. Finding device type")
        UI.message("----------------------")
        $device_type = find_device_type(file_name)
        UI.success("Device Type identified is: %s" % [$device_type])

        # step 2: determining device type
        UI.message("----------------------------------")
        UI.message("2. Setting supported device models")
        UI.message("----------------------------------")
        $supported_device_models = find_supported_device_models(path_to_file)
        UI.success("Supported Device Model(s): %s" % [$supported_device_models.to_json])

        # step 3: uploading app blob file
        UI.message("---------------------")
        if $device_type == "Android"
          UI.message("3. Uploading APK file")
        else
          UI.message("3. Uploading IPA file")
        end
        UI.message("---------------------")
        blobID = upload_blob(file_name, path_to_file)

        if $device_type == "Android"
          UI.success("Successfully uploaded apk blob")
        else
          UI.success("Successfully uploaded ipa blob")
        end

        if debug
          UI.success("Blob Id: %d" % [blobID])
        end

        # step 4: deploying app version
        UI.message("-----------------------------------")
        UI.message("4. Deploying app version on console")
        UI.message("-----------------------------------")
        deploy_app(blobID, app_name, app_version, push_mode)
        UI.success("Successfully deployed the app version")
      end

      def self.find_device_type(file_name)
        if file_name.include? ".ipa"
          return "Apple"
        elsif file_name.include? ".apk"
          return "Android"
        else
          UI.user_error!("Wrong file type provided. Please provide an IPA or APK file.")
          exit
        end
      end

      def self.find_supported_device_models(path_to_file)
        require 'app_info'
        device_models = Array.new

        if $device_type == "Android"
          model = create_model_for(5, "Android")
          device_models << model
        else
          ipa = AppInfo.parse(path_to_file)
          if ipa.universal?
            model_iPhone = create_model_for(1, "iPhone")
            device_models << model_iPhone
            model_iPad = create_model_for(2, "iPad")
            device_models << model_iPad
            model_iPodTouch = create_model_for(3, "iPod Touch")
            device_models << model_iPodTouch
          elsif ipa.iphone?
            model_iPhone = create_model_for(1, "iPhone")
            device_models << model_iPhone
            model_iPodTouch = create_model_for(3, "iPod Touch")
            device_models << model_iPodTouch
          else
            model_iPad = create_model_for(2, "iPad")
            device_models << model_iPad
          end
        end

        $supported_device_models['Model'] = device_models
        return $supported_device_models
      end

      def self.create_model_for(model_id, model_name)
        model_hash = Hash.new
        model_hash['ModelId'] = model_id
        model_hash['ModelName'] = model_name
        return model_hash
      end

      def self.upload_blob(file_name, path_to_file)
        require 'rest-client'
        require 'json'

        response = RestClient::Request.execute(
          :url      => $host_url + UPLOAD_BLOB_SUFFIX % [file_name, $org_group_id],
          :method   => :post,
          :headers  => {
            'Authorization'   => "Basic " + $b64_encoded_auth,
            'aw-tenant-code'  => $aw_tenant_code,
            'Accept'          => 'application/json',
            'Content-Type'    => 'application/octet-stream',
            'Expect'          => '100-continue'
          },
          :payload  => File.open(path_to_file, "rb")
        )

        if debug
          UI.message("Response code: %d" % [response.code])
          UI.message("Response body:")
          UI.message(response.body)
        end

        json = JSON.parse(response.body)
        return json['Value']
      end

      def self.deploy_app(blobID, app_name, app_version, push_mode)
        require 'rest-client'
        require 'json'

        body = {
          "BlobId"               => blobID.to_s,
          "DeviceType"           => $device_type, 
          "ApplicationName"      => app_name,
          "AppVersion"           => app_version,
          "SupportedModels"      => $supported_device_models,
          "PushMode"             => push_mode,
          "LocationGroupId"      => $org_group_id,
          "CarryOverAssignments" => $carry_over_assignments
        }

        if debug
          UI.message("Deploy Request JSON:")
          UI.message(body.to_json)
        end

        begin
          response = RestClient.post($host_url + BEGIN_INSTALL_SUFFIX, body.to_json, {content_type: :json, accept: :json, 'aw-tenant-code': $aw_tenant_code, 'Authorization': "Basic " + $b64_encoded_auth})
        rescue RestClient::ExceptionWithResponse => e
          UI.error("ERROR! Response code: %d" % [e.response.code])
          UI.error("Response body:")
          UI.error(e.response.body)
          delete_blob(blobID)
          raise
        end

        if debug
          UI.message("Response code: %d" % [response.code])
          UI.message("Response body:")
          UI.message(response.body)
        end

        json = JSON.parse(response.body)
        Actions.lane_context[SharedValues::DEPLOYED_APP_UUID] = json['Uuid']
        return json
      end

      def self.delete_blob(blobID)
        require 'rest-client'
        require 'json'

        if debug
          UI.message("Deleting Blob with ID: %d" % [blobID])
        end

        begin
          response = RestClient.delete($host_url + DELETE_BLOB_SUFFIX % [blobID],  {accept: :json, 'aw-tenant-code': $aw_tenant_code, 'Authorization': "Basic " + $b64_encoded_auth})
        rescue RestClient::ExceptionWithResponse => e
          UI.error("ERROR! Response code: %d" % [e.response.code])
          UI.error("Response body:")
          UI.error(e.response.body)
          raise
        end

        if debug
          UI.message("Response code: %d" % [response.code])
        end

        if response.code == 200
          UI.message("Successfully deleted blob")
        else
          UI.message("Failed to delete blob")
        end
      end

      def self.description
        "The main purpose of this action is to upload an IPA or an APK file to an AirWatch or Workspace ONE enterprise console."
      end

      def self.authors
        ["Ram Awadhesh Sharan"]
      end

      def self.output
        [
          ['DEPLOYED_APP_UUID', 'The unique identifier of the deployed application in uuid format']
        ]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "deploy_build - To upload an iOS ipa OR Android APK to AirWatch/Workspace One console."
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

          FastlaneCore::ConfigItem.new(key: :carry_over_assignments,
                                  env_name: "CARRY_OVER_ASSIGNMENTS",
                               description: "Carry over assignments flag, set to false to prevent assignments from carrying over between application deployments. default: true",
                                  optional: true,
                                 is_string: false,
                             default_value: true),

          FastlaneCore::ConfigItem.new(key: :app_name,
                                  env_name: "AIRWATCH_APPLICATION_NAME",
                               description: "Name of the application",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No app name given, pass using `app_name: 'My sample app'`") unless value and !value.empty?
                                            end),
                                            
          FastlaneCore::ConfigItem.new(key: :app_version,
                                  env_name: "AIRWATCH_APPLICATION_VERSION",
                               description: "Airwatch Internal App Version",
                                  optional: true,
                                      type: String,
                             default_value: nil),                                         

          FastlaneCore::ConfigItem.new(key: :file_name,
                                  env_name: "AIRWATCH_FILE_NAME",
                               description: "Name of the file to upload including the extension",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No file name given, pass using `file_name: 'MySampleApp.ipa'` or `file_name: 'MySampleApp.apk'`") unless value and !value.empty?
                                            end),

          FastlaneCore::ConfigItem.new(key: :path_to_file,
                                  env_name: "AIRWATCH_PATH_TO_FILE",
                               description: "Path to the file to upload including the extension",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("Path to the file not given, pass using `path_to_file: '/path/to/the/file/on/disk'`") unless value and !value.empty?
                                            end),

          FastlaneCore::ConfigItem.new(key: :push_mode,
                                  env_name: "AIRWATCH_APP_PUSH_MODE",
                               description: "Push mode for the application. Values are Auto or On demand",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No push mode given, pass using `push_mode: 'Auto'` or `push_mode: 'On demand'`") unless value and !value.empty?
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