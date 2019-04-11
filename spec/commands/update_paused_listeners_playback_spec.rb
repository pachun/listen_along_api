require "rails_helper"

describe UpdatePausedListenersPlayback do
  describe "self.update" do
    context "listeners playbacks have ended because they intentionally paused" do
      it "does not resync listener's playback with their broadcaster's" do
        beam_me_up_uri = "spotify:track:1S4FHBl24uLTzJ37VMBjut"
        broadcaster = create :spotify_user,
          is_listening: true,
          millisecond_progress_into_song: "10000",
          song_name: "Beam Me Up",
          last_song_uri: beam_me_up_uri,
          song_uri: beam_me_up_uri
        listener = create :spotify_user,
          broadcaster: broadcaster,
          is_listening: false

        listener_spotify_service = instance_double(SpotifyService)
        allow(SpotifyService).to receive(:new).with(listener)
          .and_return(listener_spotify_service)
        allow(listener_spotify_service).to receive(:turn_off_repeat)

        UpdatePausedListenersPlayback.update

        listener.reload

        expect(listener.maybe_intentionally_paused).to eq(true)

        UpdatePausedListenersPlayback.update

        listener.reload

        expect(listener.broadcaster).not_to be_present
        expect(listener.maybe_intentionally_paused).to eq(false)
      end
    end
    context "listeners playbacks have ended because broadcaster started new song" do
      it "resets each listener's playbacks with their broadcasters' playbacks" do
        broadcaster = create :spotify_user,
          last_song_uri: "something_different",
          is_listening: true,
          song_name: "Beam Me Up",
          song_uri: "spotify:track:1S4FHBl24uLTzJ37VMBjut",
          millisecond_progress_into_song: "10000"
        listener = create :spotify_user,
          broadcaster: broadcaster,
          is_listening: false
        stub_get_playback_request(broadcaster)
        listener_spotify_service = instance_double(SpotifyService)
        allow(SpotifyService).to receive(:new).with(listener)
          .and_return(listener_spotify_service)
        allow(listener_spotify_service).to receive(:listen_along)

        UpdatePausedListenersPlayback.update

        expect(listener_spotify_service).to(
          have_received(:listen_along).with(broadcaster: broadcaster)
        )
      end
    end

    context "it looks like a listener intentionally paused due to listen along playback latency" do
      it "keeps the listener in sync with their broadcaster" do
        same_song_uri = "spotify:track:1S4FHBl24uLTzJ37VMBjut"
        broadcaster = create :spotify_user,
          last_song_uri: same_song_uri,
          is_listening: true,
          song_name: "Beam Me Up",
          song_uri: same_song_uri,
          millisecond_progress_into_song: "10000"
        listener = create :spotify_user,
          is_listening: false,
          broadcaster: broadcaster

        UpdatePausedListenersPlayback.update

        listener.reload

        expect(listener.maybe_intentionally_paused).to eq(true)

        next_song = {
          is_listening: true,
          song_name: "Next Song",
          song_uri: "next_song_uri",
          millisecond_progress_into_song: "10000",
        }

        broadcaster.update(
          last_song_uri: broadcaster.song_uri,
          **next_song,
        )

        stub_get_playback_request(broadcaster)
        stub_currently_playing_request(
          access_token: listener.access_token,
          nothing_playing_response: true,
        )
        stub_set_playback_request(
          listener: listener,
          broadcaster: broadcaster,
          overwrites: next_song,
        )
        stub_start_playback_loop_request(spotify_user: listener)

        UpdatePausedListenersPlayback.update

        listener.reload

        expect(listener.broadcaster).to eq(broadcaster)
        expect(listener.maybe_intentionally_paused).to eq(false)
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
