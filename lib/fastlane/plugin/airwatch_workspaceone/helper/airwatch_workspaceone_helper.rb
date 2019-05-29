require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class AirwatchWorkspaceoneHelper
      # class methods that you define here become available in your action
      # as `Helper::AirwatchWorkspaceoneHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the airwatch_workspaceone plugin helper!")
      end
    end
  end
end
