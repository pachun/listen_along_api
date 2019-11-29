require "rails_helper"

describe UpdateInactiveUsersPlayback do
  describe "self.update" do
    it "updates inactive user's playback states" do
      allow(UpdatePlaybackStates).to receive(:update)

      UpdateInactiveUsersPlayback.update

      expect(UpdatePlaybackStates).to have_received(:update)
        .with(listening: false)
    end
  end
end
