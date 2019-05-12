require "rails_helper"

describe ResyncOutOfSyncListeners do
  describe "self.resync" do
    it "resyncs listeners whose broadcaster playback discrepancy is >= 3 seconds" do
      resync_double = instance_double(ResyncOutOfSyncListeners)
      allow(ResyncOutOfSyncListeners).to receive(:new).and_return(resync_double)
      allow(resync_double).to receive(:resync)

      ResyncOutOfSyncListeners.resync

      expect(resync_double).to have_received(:resync)
    end
  end

  describe "#resync" do
    it "resyncs listeners whose broadcaster playback discrepancy is >= 3 seconds" do
      fake_out_of_sync_listeners = [
        instance_double(SpotifyUser),
        instance_double(SpotifyUser),
      ]
      fake_out_of_sync_listeners.each do |listener|
        allow(listener).to receive(:resync_with_broadcaster!)
      end
      resync_command = ResyncOutOfSyncListeners.new
      allow(resync_command).to(
        receive(:listeners_who_are_out_of_sync_with_their_broadcasters)
        .and_return(fake_out_of_sync_listeners)
      )

      resync_command.resync

      expect(fake_out_of_sync_listeners).to(
        all have_received(:resync_with_broadcaster!)
      )
    end
  end

  describe "#listeners_who_are_out_of_sync_with_their_broadcasters" do
    it "returns listeners whose playback progress is >= 3 second apart from their broadcaster's progress" do
      broadcaster = create :spotify_user,
        millisecond_progress_into_song: 10000
      in_sync_listener = create :spotify_user,
        broadcaster: broadcaster,
        millisecond_progress_into_song: 12999
      out_of_sync_listener = create :spotify_user,
        broadcaster: broadcaster,
        millisecond_progress_into_song: 13000

      out_of_sync_listeners = ResyncOutOfSyncListeners.new
        .listeners_who_are_out_of_sync_with_their_broadcasters

      expect(
        out_of_sync_listeners
      ).not_to include(in_sync_listener)
      expect(
        out_of_sync_listeners
      ).to match_array([out_of_sync_listener])
    end
  end
end
