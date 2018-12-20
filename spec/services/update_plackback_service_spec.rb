require "rails_helper"

describe UpdatePlaybackService do
  describe "self.update" do
    it "moves song_uri into last_song_uri" do
      spotify_user_1 = create :spotify_user,
        access_token: "t1",
        song_uri: "a"
      stub_get_playback_request(spotify_user_1)

      spotify_user_2 = create :spotify_user,
        access_token: "t1",
        song_uri: "x"
      stub_get_playback_request(spotify_user_2)

      UpdatePlaybackService.update

      spotify_user_1.reload
      spotify_user_2.reload

      expect(spotify_user_1.last_song_uri).to eq("a")
      expect(spotify_user_2.last_song_uri).to eq("x")
    end

    context "a listener skips to the next song" do
      it "stops syncing them with their broadcaster" do
        broadcasted_uri = "spotify:track:1S4FHBl24uLTzJ37VMBjut"
        a_different_uri = "spotify:track:1xyt3kmjrV3o9kbiAdwdXb"

        broadcaster = create :spotify_user,
          access_token: "t1",
          is_listening: true,
          song_name: "Beam Me Up",
          last_song_uri: broadcasted_uri,
          song_uri: broadcasted_uri,
          millisecond_progress_into_song: "10000"

        listener_who_played_new_song = create :spotify_user,
          access_token: "t2",
          is_listening: true,
          song_uri: a_different_uri,
          broadcaster: broadcaster

        stub_get_playback_request(broadcaster)
        stub_get_playback_request(listener_who_played_new_song)

        UpdatePlaybackService.update

        expect(
          listener_who_played_new_song.reload.broadcaster
        ).not_to be_present
      end
    end

    context "a broadcaster skips to the next song" do
      it "resyncs listeners" do
        last_broadcasted_uri = "spotify:track:1S4FHBl24uLTzJ37VMBjut"
        broadcasted_uri = "spotify:track:60UMIuct0ii0DJ3CReWIMr"
        a_different_uri = "spotify:track:1xyt3kmjrV3o9kbiAdwdXb"

        broadcaster = create :spotify_user,
          access_token: "t1",
          is_listening: true,
          song_name: "Beam Me Up",
          song_uri: last_broadcasted_uri,
          millisecond_progress_into_song: "10000"

        unsynced_listener = create :spotify_user,
          access_token: "t2",
          is_listening: true,
          song_uri: a_different_uri,
          broadcaster: broadcaster

        synced_listener = create :spotify_user,
          access_token: "t3",
          is_listening: true,
          song_uri: broadcasted_uri,
          broadcaster: broadcaster

        allow(synced_listener).to receive(:update)
        stub_get_playback_request(
          broadcaster,
          song_uri: broadcasted_uri,
        )
        stub_get_playback_request(synced_listener)
        stub_get_playback_request(unsynced_listener)
        stub_set_playback_request(
          listener: unsynced_listener,
          broadcaster: broadcaster,
          overwrites: { song_uri: broadcasted_uri },
        )

        UpdatePlaybackService.update

        unsynced_listener.reload

        expect(unsynced_listener.song_name).to eq("Beam Me Up")
        expect(unsynced_listener.song_uri).to eq(broadcasted_uri)
        expect(unsynced_listener.millisecond_progress_into_song).to eq("10000")
        expect(synced_listener).not_to have_received(:update)
      end
    end

    context "a broadcasters playback has ended" do
      it "stops syncing their listeners with their playback" do
        broadcaster = create :spotify_user,
          is_listening: false

        listener = create :spotify_user,
          is_listening: false,
          broadcaster: broadcaster

        spotify_service_double = instance_double(SpotifyService)
        allow(SpotifyService).to receive(:new)
          .with(listener)
          .and_return(spotify_service_double)
        allow(SpotifyService).to receive(:new)
          .with(broadcaster)
          .and_return(spotify_service_double)
        allow(spotify_service_double).to receive(:current_playback_state)
          .and_return(not_listening_state)

        UpdatePlaybackService.update

        expect(listener.reload.broadcaster).not_to be_present
      end
    end

    context "listeners playbacks have ended because broadcaster started new song" do
      it "updates spotify user's playback state" do
        spotify_user_1 = create :spotify_user,
          is_listening: true,
          song_name: "On a Tuesday",
          song_uri: "spotify:track:1xyt3kmjrV3o9kbiAdwdXb",
          millisecond_progress_into_song: "5000"

        spotify_service_double = instance_double(SpotifyService)
        allow(SpotifyService).to receive(:new)
          .with(spotify_user_1)
          .and_return(spotify_service_double)
        allow(spotify_service_double).to receive(:current_playback_state)
          .and_return(not_listening_state)

        spotify_user_2 = create :spotify_user
        beam_me_up = {
          is_listening: true,
          song_name: "Beam Me Up",
          song_uri: "spotify:track:1S4FHBl24uLTzJ37VMBjut",
          millisecond_progress_into_song: "10000",
        }
        spotify_service_double_2 = instance_double(SpotifyService)
        allow(SpotifyService).to receive(:new)
          .with(spotify_user_2)
          .and_return(spotify_service_double_2)
        allow(spotify_service_double_2).to receive(:current_playback_state)
          .and_return(beam_me_up)

        UpdatePlaybackService.update

        spotify_user_1.reload

        expect(spotify_user_1).not_to be_listening
        expect(spotify_user_1.song_name).to eq(nil)
        expect(spotify_user_1.song_uri).to eq(nil)
        expect(spotify_user_1.millisecond_progress_into_song).to eq(nil)

        spotify_user_2.reload

        expect(spotify_user_2).to be_listening
        expect(spotify_user_2.song_name).to eq("Beam Me Up")
        expect(spotify_user_2.song_uri).to eq("spotify:track:1S4FHBl24uLTzJ37VMBjut")
        expect(spotify_user_2.millisecond_progress_into_song).to eq("10000")
      end

      it "resets each listener's playbacks with their broadcasters' playbacks" do
        beam_me_up = {
          is_listening: true,
          song_name: "Beam Me Up",
          song_uri: "spotify:track:1S4FHBl24uLTzJ37VMBjut",
          millisecond_progress_into_song: "10000",
        }

        broadcaster = create :spotify_user,
          song_uri: "something_different",
          is_listening: true
        listener = create :spotify_user,
          broadcaster: broadcaster

        broadcaster_spotify_service = instance_double(SpotifyService)
        allow(SpotifyService).to receive(:new).with(broadcaster)
          .and_return(broadcaster_spotify_service)
        allow(broadcaster_spotify_service).to receive(:current_playback_state)
          .and_return(beam_me_up)

        listener_spotify_service = instance_double(SpotifyService)
        allow(SpotifyService).to receive(:new).with(listener)
          .and_return(listener_spotify_service)
        allow(listener_spotify_service).to receive(:current_playback_state)
          .and_return(not_listening_state)
        allow(listener_spotify_service).to receive(:listen_along)

        UpdatePlaybackService.update

        expect(listener_spotify_service).to(
          have_received(:listen_along).with(broadcaster: broadcaster)
        )
      end
    end

    context "listeners playback has ended because they intentionally paused" do
      it "does not resync listener's playback with their broadcaster's" do
        beam_me_up = {
          is_listening: true,
          song_name: "Beam Me Up",
          song_uri: "spotify:track:1S4FHBl24uLTzJ37VMBjut",
          millisecond_progress_into_song: "10000",
        }

        broadcaster = create :spotify_user,
          last_song_uri: beam_me_up[:song_uri],
          is_listening: true
        listener = create :spotify_user,
          broadcaster: broadcaster

        broadcaster_spotify_service = instance_double(SpotifyService)
        allow(SpotifyService).to receive(:new).with(broadcaster)
          .and_return(broadcaster_spotify_service)
        allow(broadcaster_spotify_service).to receive(:current_playback_state)
          .and_return(beam_me_up)

        listener_spotify_service = instance_double(SpotifyService)
        allow(SpotifyService).to receive(:new).with(listener)
          .and_return(listener_spotify_service)
        allow(listener_spotify_service).to receive(:current_playback_state)
          .and_return(not_listening_state)
        allow(listener_spotify_service).to receive(:listen_along)

        UpdatePlaybackService.update

        expect(listener_spotify_service).not_to(
          have_received(:listen_along).with(broadcaster: broadcaster)
        )
        expect(listener.reload.broadcaster).not_to be_present
      end
    end

    context "a listeners playback has not ended" do
      it "does not reset the listener's playback with their broadcaster's" do
        spotify_service_double = instance_double(SpotifyService)
        allow(SpotifyService).to receive(:new)
          .and_return(spotify_service_double)
        allow(spotify_service_double).to receive(:current_playback_state)
          .and_return(not_listening_state)

        broadcaster = create :spotify_user
        listener = create :spotify_user,
          is_listening: true,
          broadcaster: broadcaster

        broadcaster_spotify_service = instance_double(SpotifyService)
        allow(SpotifyService).to receive(:new).with(broadcaster)
          .and_return(broadcaster_spotify_service)
        allow(broadcaster_spotify_service).to receive(:current_playback_state)
          .and_return(not_listening_state)

        listener_spotify_service = instance_double(SpotifyService)
        allow(SpotifyService).to receive(:new).with(listener)
          .and_return(listener_spotify_service)
        allow(listener_spotify_service).to receive(:current_playback_state)
          .and_return(not_listening_state)
        allow(listener_spotify_service).to receive(:listen_along)

        UpdatePlaybackService.update

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
