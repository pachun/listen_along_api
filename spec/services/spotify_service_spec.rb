require "rails_helper"

describe SpotifyService do
  describe "self.authenticate(using_authorization_code:)" do
    it "finishes authenticating the spotify user and saves their credentials" do
      access_token_request = stub_get_access_token_request(
        authorization_code: "auth_code",
        access_token: "access token 1",
        refresh_token: "refresh token 1",
      )

      stub_spotify_username_request(
        access_token: "access token 1",
        spotify_username: "spotify_guy",
      )

      spotify_user_1 = SpotifyService.authenticate(
        using_authorization_code: "auth_code",
      )

      expect(access_token_request).to have_been_requested
      expect(spotify_user_1.access_token).to eq("access token 1")
      expect(spotify_user_1.refresh_token).to eq("refresh token 1")
      expect(spotify_user_1.listen_along_token.length).to eq(32)

      access_token_request = stub_get_access_token_request(
        authorization_code: "auth_code_2",
        access_token: "access token 2",
        refresh_token: "refresh token 2",
      )

      stub_spotify_username_request(
        access_token: "access token 2",
        spotify_username: "spotify_guy",
      )

      spotify_user_2 = SpotifyService.authenticate(
        using_authorization_code: "auth_code_2",
      )

      expect(access_token_request).to have_been_requested
      expect(spotify_user_2.access_token).to eq("access token 2")
      expect(spotify_user_2.refresh_token).to eq("refresh token 2")
      expect(spotify_user_2.listen_along_token.length).to eq(32)

      expect(spotify_user_1.listen_along_token).not_to(
        eq(spotify_user_2.listen_along_token)
      )
    end

    it "creates only one spotify credential per spotify user" do
      spotify_authentication_token_request = stub_get_access_token_request(
        authorization_code: "auth_code",
        access_token: "access token",
        refresh_token: "refresh token",
      )
      spotify_username_request = stub_spotify_username_request(
        access_token: "access token",
        spotify_username: "spotify_username",
      )

      SpotifyService.authenticate(using_authorization_code: "auth_code")

      expect(spotify_username_request).to have_been_requested
      expect(spotify_authentication_token_request).to have_been_requested
      expect(SpotifyUser.last.access_token).to eq("access token")
      expect(SpotifyUser.last.refresh_token).to eq("refresh token")
      expect(SpotifyUser.last.username).to eq("spotify_username")
      expect(SpotifyUser.count).to eq(1)

      spotify_authentication_token_request_2 = stub_get_access_token_request(
        authorization_code: "auth_code_2",
        access_token: "access token 2",
        refresh_token: "refresh token 2",
      )
      spotify_username_request = stub_spotify_username_request(
        access_token: "access token 2",
        spotify_username: "spotify_username",
      )

      SpotifyService.authenticate(using_authorization_code: "auth_code_2")

      expect(spotify_authentication_token_request_2).to have_been_requested
      expect(SpotifyUser.last.access_token).to eq("access token 2")
      expect(SpotifyUser.last.refresh_token).to eq("refresh token 2")
      expect(SpotifyUser.last.username).to eq("spotify_username")
      expect(SpotifyUser.count).to eq(1)
    end
  end

  describe "#current_playback_state" do
    it "sets [:last_song_uri] to the previous song uri" do
      spotify_user = create :spotify_user,
        access_token: "t1",
        song_uri: "last song uri"

      stub_get_playback_request(spotify_user)

      expect(
        SpotifyService.new(spotify_user).current_playback_state[:last_song_uri]
      ).to eq("last song uri")
    end

    context "the song 'Bone Dry' is playing" do
      context "the spotify access token has expired" do
        it "gets a new access token then returns the song name" do
          refreshed_access_token = "refreshed access token"
          spotify_user = build :spotify_user,
            access_token: "expired token",
            refresh_token: "refresh token"
          stub_currently_playing_request(
            access_token: spotify_user.access_token,
            expired_access_token: true,
          )
          stub_refresh_access_token_request(
            refresh_token: spotify_user.refresh_token,
            refreshed_access_token: refreshed_access_token,
          )
          stub_currently_playing_request(
            access_token: refreshed_access_token,
            song_name: "Bone Dry",
          )

          playback_state = SpotifyService
            .new(spotify_user)
            .current_playback_state

          expect(spotify_user.reload.access_token).to(
            eq("refreshed access token")
          )
          expect(playback_state[:song_name]).to eq("Bone Dry")
        end
      end

      it "returns 'Bone Dry'" do
        stub_currently_playing_request(
          access_token: "access token",
          song_name: "Bone Dry",
        )
        spotify_user = build :spotify_user,
          access_token: "access token"

        expect(
          SpotifyService
            .new(spotify_user)
            .current_playback_state[:song_name]
        ).to eq("Bone Dry")
      end
    end

    context "the song 'Aerials' is playing" do
      it "returns 'Aerials'" do
        stub_currently_playing_request(
          access_token: "access token",
          song_name: "Aerials",
        )

        spotify_user = create :spotify_user,
          access_token: "access token"

        expect(
          SpotifyService
            .new(spotify_user)
            .current_playback_state[:song_name]
        ).to eq("Aerials")
      end
    end

    context "there is no song playing" do
      context "currently playing api call returns a 200 & is_playing=false" do
        it "returns is_listening: false" do
          stub_currently_playing_request(
            access_token: "access token",
            is_playing: false,
          )

          spotify_user = create :spotify_user,
            access_token: "access token"

          expect(
            SpotifyService
              .new(spotify_user)
              .current_playback_state[:is_listening]
          ).to eq(false)
        end
      end

      context "currently playing api call returns a 204 'no content' status" do
        it "returns is_listening: false" do
          stub_currently_playing_request(
            access_token: "access token",
            nothing_playing_response: true,
          )

          spotify_user = create :spotify_user,
            access_token: "access token"

          expect(
            SpotifyService
              .new(spotify_user)
              .current_playback_state[:is_listening]
          ).to eq(false)
        end
      end
    end
  end

  describe "#listen_along" do
    it "sets the listeners broadcaster and playback" do
      listener = create :spotify_user,
        access_token: "listener access token"
      broadcaster = create :spotify_user,
        access_token: "broadcaster access token",
        song_name: "name",
        song_uri: "uri",
        millisecond_progress_into_song: "1000"
      stub_currently_playing_request(access_token: broadcaster.access_token)
      stub_play_request(access_token: listener.access_token)

      SpotifyService.new(listener).listen_along(broadcaster: broadcaster)

      expect(listener.broadcaster).to eq(broadcaster)
      expect(listener.song_name).to eq("name")
      expect(listener.song_uri).to eq("uri")
      expect(listener.millisecond_progress_into_song).to eq("1000")
    end

    context "the listener's spotify access token is expired" do
      it "gets a new access token and then listens along" do
        refreshed_access_token = "refreshed access token"
        listener = create :spotify_user,
          access_token: "listener expired token",
          refresh_token: "listener refresh token"
        broadcaster = create :spotify_user,
          access_token: "broadcaster access token"
        stub_currently_playing_request(
          access_token: broadcaster.access_token,
          millisecond_progress: 20000,
          song_name: "Fourth of July",
          song_uri: "spotify:track:5k8ljvF1AoEXmdHxll7ReL",
        )
        stub_play_request(
          expired_access_token: true,
          access_token: listener.access_token,
          song_uri: "spotify:track:5k8ljvF1AoEXmdHxll7ReL",
          millisecond_progress: 20000,
        )
        stub_refresh_access_token_request(
          refresh_token: listener.refresh_token,
          refreshed_access_token: refreshed_access_token,
        )
        listen_along_request = stub_play_request(
          access_token: refreshed_access_token,
          song_uri: "spotify:track:5k8ljvF1AoEXmdHxll7ReL",
          millisecond_progress: 20000,
        )

        SpotifyService.new(listener).listen_along(broadcaster: broadcaster)

        expect(listen_along_request).to have_been_requested
        expect(listener.reload.access_token).to eq(refreshed_access_token)
      end
    end

    context "ListenWithDude is 20 seconds into the song 'Fourth of July'" do
      it "starts play 'Fourth of July' at 20 seconds in on pachun91's Spotify account" do
        broadcaster = create :spotify_user,
          access_token: "access token"
        stub_currently_playing_request(
          access_token: broadcaster.access_token,
          millisecond_progress: 20000,
          song_name: "Fourth of July",
          song_uri: "spotify:track:5k8ljvF1AoEXmdHxll7ReL",
        )
        listener = create :spotify_user,
          access_token: "access token"
        sync_request = stub_play_request(
          song_uri: "spotify:track:5k8ljvF1AoEXmdHxll7ReL",
          millisecond_progress: 20000,
          access_token: listener.access_token,
        )

        SpotifyService.new(listener).listen_along(broadcaster: broadcaster)

        expect(sync_request).to have_been_requested
      end
    end

    context "ListenWithDude is 5 seconds into the song 'Queen'" do
      it "starts play 'Queen' at 5 seconds in on pachun91's Spotify account" do
        broadcaster = create :spotify_user,
          access_token: "access token"
        stub_currently_playing_request(
          access_token: broadcaster.access_token,
          millisecond_progress: 5000,
          song_name: "Queen",
          song_uri: "spotify:track:2lxW8vQ9Qjv0qeSQiIBOKJ",
        )
        listener = create :spotify_user,
          access_token: "access token"
        sync_request = stub_play_request(
          access_token: listener.access_token,
          song_uri: "spotify:track:2lxW8vQ9Qjv0qeSQiIBOKJ",
          millisecond_progress: 5000,
        )

        SpotifyService.new(listener).listen_along(broadcaster: broadcaster)

        expect(sync_request).to have_been_requested
      end
    end
  end
end
