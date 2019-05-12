require "rails_helper"

describe UpdatePlaybackService do
  describe "self.update" do
    it "updates users playback states" do
      allow(UpdatePlaybackStates).to receive(:update)

      UpdatePlaybackService.update

      expect(UpdatePlaybackStates).to have_received(:update)
    end

    it "unsyncs listeners whose broadcaster stopped broadcasting" do
      allow(UnsyncListenersWhoseBroadcasterStoppedBroadcasting).to receive(:unsync)

      UpdatePlaybackService.update

      expect(UnsyncListenersWhoseBroadcasterStoppedBroadcasting).to have_received(:unsync)
    end

    it "resyncs listeners whose listener/broadcaster playback discrepancy > 3 seconds" do
      allow(ResyncOutOfSyncListeners).to receive(:resync)

      UpdatePlaybackService.update

      expect(ResyncOutOfSyncListeners).to have_received(:resync)
    end

    it "unsyncs listeners who started a new song" do
      allow(UnsyncListenersWhoStartedANewSong).to receive(:unsync)

      UpdatePlaybackService.update

      expect(UnsyncListenersWhoStartedANewSong).to have_received(:unsync)
    end

    it "resyncs listeners whose broadcaster started a new song" do
      allow(ResyncListenersWhoseBroadcasterStartedANewSong).to receive(:resync)

      UpdatePlaybackService.update

      expect(ResyncListenersWhoseBroadcasterStartedANewSong).to have_received(:resync)
    end

    it "updates paused listener's playbacks" do
      allow(UpdatePausedListenersPlayback).to receive(:update)

      UpdatePlaybackService.update

      expect(UpdatePausedListenersPlayback).to have_received(:update)
    end

    it "carries listeners to new broadcasters" do
      allow(CarryListenersToNewBroadcasters).to receive(:carry)

      UpdatePlaybackService.update

      expect(CarryListenersToNewBroadcasters).to have_received(:carry)
    end

    it "tells clients to refresh their listener list" do
      allow(TellClientsToRefreshTheirListenerList).to receive(:tell)

      UpdatePlaybackService.update

      expect(TellClientsToRefreshTheirListenerList).to have_received(:tell)
    end
  end
end
