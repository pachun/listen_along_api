require "rails_helper"

describe UpdatePlaybackService do
  describe "self.update" do
    context "a broadcaster skips to the next song" do
      it "resyncs listeners" do
        broadcasted_uri = "spotify:track:1S4FHBl24uLTzJ37VMBjut"
        broadcaster = create :spotify_user,
          access_token: "t1",
          is_listening: true,
          song_name: "Beam Me Up",
          song_uri: broadcasted_uri,
          millisecond_progress_into_song: "10000"

        unsynced_listener = create :spotify_user,
          access_token: "t2",
          is_listening: true,
          song_uri: "spotify:track:1xyt3kmjrV3o9kbiAdwdXb",
          broadcaster: broadcaster

        synced_listener = create :spotify_user,
          access_token: "t3",
          is_listening: true,
          song_uri: broadcasted_uri,
          broadcaster: broadcaster

        stub_get_playback_request(broadcaster)
        stub_get_playback_request(synced_listener)
        stub_get_playback_request(unsynced_listener)
        stub_set_playback_request(
          listener: unsynced_listener,
          broadcaster: broadcaster,
        )

        UpdatePlaybackService.update

        unsynced_listener.reload

        expect(unsynced_listener.reload.song_name).to eq("Beam Me Up")
        expect(unsynced_listener.song_uri).to eq("spotify:track:1S4FHBl24uLTzJ37VMBjut")
        expect(unsynced_listener.millisecond_progress_into_song).to eq("10000")

        expect(synced_listener.reload.song_name).to eq(nil)
        expect(synced_listener.song_uri).to eq("spotify:track:1S4FHBl24uLTzJ37VMBjut")
        expect(synced_listener.millisecond_progress_into_song).to eq(nil)
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

    context "listeners playbacks have ended" do
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
