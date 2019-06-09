require 'fastlane/action'
require_relative '../helper/airwatch_workspaceone_helper'

module Fastlane
  module Actions
    class DeployBuildAction < Action

      UPLOAD_BLOB_SUFFIX    = "/API/mam/blobs/uploadblob?fileName=%s&organizationGroupId=%s"
      BEGIN_INSTALL_SUFFIX  = "/API/mam/apps/internal/begininstall"

      $is_debug                 = false
      $device_type              = "Apple"
      $supported_device_models  = Hash.new

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
          UI.message(" organization_group_id: #{params[:org_group_id]}")
          UI.message(" app_name: #{params[:app_name]}")
          UI.message(" file_name: #{params[:file_name]}")
          UI.message(" path_to_file: #{params[:path_to_file]}")
          UI.message(" push_mode: #{params[:push_mode]}")
        end

        $host_url         = params[:host_url]
        $aw_tenant_code   = params[:aw_tenant_code]
        $b64_encoded_auth = params[:b64_encoded_auth]
        $org_group_id     = params[:org_group_id]
        app_name          = params[:app_name]
        file_name         = params[:file_name]
        path_to_file      = params[:path_to_file]
        push_mode         = params[:push_mode]

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
        UI.success("Supported Device Models are: %s" % [$supported_device_models.to_json])

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
        UI.message("------------------------------------")
        UI.message("4. Deploying app version on console")
        UI.message("------------------------------------")
        deploy_app(blobID, app_name, push_mode)
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

      def self.deploy_app(blobID, app_name, push_mode)
        require 'rest-client'
        require 'json'

        body = {
          "BlobId"          => blobID.to_s,
          "DeviceType"      => $device_type, 
          "ApplicationName" => app_name,
          "SupportedModels" => $supported_device_models,
          "PushMode"        => push_mode,
          "LocationGroupId" => $org_group_id
        }

        if debug
          UI.message("Deploy Request JSON:")
          UI.message(body.to_json)
        end

        response = RestClient.post($host_url + BEGIN_INSTALL_SUFFIX, body.to_json, {content_type: :json, accept: :json, 'aw-tenant-code': $aw_tenant_code, 'Authorization': "Basic " + $b64_encoded_auth})

        if debug
          UI.message("Response code: %d" % [response.code])
          UI.message("Response body:")
          UI.message(response.body)
        end

        json = JSON.parse(response.body)
        return json
      end

      def self.description
        "The main purpose of this action is to upload an IPA or an APK file to an AirWatch or Workspace ONE enterprise instance/console."
      end

      def self.authors
        ["Ram Awadhesh Sharan"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "deploy_build - To upload an iOS ipa OR Android APK to AirWatch/WorkspaceOne console."
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

          FastlaneCore::ConfigItem.new(key: :app_name,
                                  env_name: "AIRWATCH_APPLICATION_NAME",
                               description: "Name of the application",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No app name given, pass using `app_name: 'My sample app'`") unless value and !value.empty?
                                            end),

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
                               description: "Push mode for the application",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("No push mode given, pass using `push_mode: 'Auto'` or pass using `push_mode: 'On demand'`") unless value and !value.empty?
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