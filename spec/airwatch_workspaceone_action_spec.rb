describe Fastlane::Actions::AirwatchWorkspaceoneAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The airwatch_workspaceone plugin is working!")

      Fastlane::Actions::AirwatchWorkspaceoneAction.run(nil)
    end
  end
end
