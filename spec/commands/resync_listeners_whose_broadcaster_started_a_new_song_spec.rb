require "rails_helper"

describe ResyncListenersWhoseBroadcasterStartedANewSong do
  describe "self.resync" do
    context "a broadcaster changes their song" do
      it "resyncs the broadcaster's listeners" do
        last_broadcasted_uri = "spotify:track:1S4FHBl24uLTzJ37VMBjut"
        broadcasted_uri = "spotify:track:60UMIuct0ii0DJ3CReWIMr"
        a_different_uri = "spotify:track:1xyt3kmjrV3o9kbiAdwdXb"

        broadcaster = create :spotify_user,
          is_listening: true,
          song_name: "Beam Me Up",
          last_song_uri: last_broadcasted_uri,
          song_uri: broadcasted_uri,
          millisecond_progress_into_song: "10000"

        unsynced_listener = create :spotify_user,
          is_listening: true,
          song_uri: a_different_uri,
          broadcaster: broadcaster

        synced_listener = create :spotify_user,
          is_listening: true,
          song_uri: broadcasted_uri,
          broadcaster: broadcaster

        allow(synced_listener).to receive(:update)
        stub_get_playback_request(
          broadcaster,
          song_uri: broadcasted_uri,
        )
        stub_start_playback_loop_request(spotify_user: unsynced_listener)
        stub_set_playback_request(
          listener: unsynced_listener,
          broadcaster: broadcaster,
          overwrites: { song_uri: broadcasted_uri },
        )

        ResyncListenersWhoseBroadcasterStartedANewSong.resync

        unsynced_listener.reload

        expect(unsynced_listener.song_name).to eq("Beam Me Up")
        expect(unsynced_listener.song_uri).to eq(broadcasted_uri)
        expect(unsynced_listener.millisecond_progress_into_song).to eq("10000")
        expect(synced_listener).not_to have_received(:update)
      end
    end

    context "a listeners playback has ended" do
      it "does not reset the listener's playback with their broadcaster's" do
        broadcaster = create :spotify_user,
          song_uri: "new song",
          last_song_uri: "old song"
        listener = create :spotify_user,
          is_listening: false,
          broadcaster: broadcaster

        listener_spotify_service = instance_double(SpotifyService)
        allow(SpotifyService).to receive(:new).with(listener)
          .and_return(listener_spotify_service)
        allow(listener_spotify_service).to receive(:listen_along)

        ResyncListenersWhoseBroadcasterStartedANewSong.resync

        expect(listener_spotify_service).not_to have_received(:listen_along)
      end
    end
  end

  def not_listening_state
    {
      is_listening: false,
      song_name: nil,
      song_uri: nil,
      millisecond_progress_into_song: nil,
    }
  end
end
