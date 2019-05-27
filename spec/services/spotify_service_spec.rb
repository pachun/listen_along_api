require "rails_helper"

describe SpotifyService do
  describe "#add_to_library(song_uri:)" do
    it "adds the song to the spotify user's library" do
      song_id = "15vzANxN8G9wWfwAJLLMCg"
      spotify_user = create :spotify_user,
        access_token: "token"
      add_song_to_library_request = stub_add_song_to_library_request(
        access_token: spotify_user.access_token,
        song_id: song_id,
      )

      SpotifyService.new(spotify_user).add_to_library(song_id: song_id)

      expect(add_song_to_library_request).to have_been_requested
    end
  end

  describe "self.authenticate(using_authorization_code:)" do
    context "the spotify user has authenticated using another device before" do
      it "updates their spotify_app if a new spotify_app was chosen for them" do
        spotify_app_1 = create :spotify_app,
          client_identifier: "client_id_1",
          client_secret: "client_secret_1"

        spotify_app_2 = create :spotify_app,
          client_identifier: "client_id_2",
          client_secret: "client_secret_2"

        registering_spotify_user = create :registering_spotify_user,
          spotify_app: spotify_app_1

        original_token = "original_token"

        spotify_user = create :spotify_user,
          username: "spotify_guy",
          listen_along_token: original_token,
          spotify_app: spotify_app_2

        stub_get_access_token_request(
          registering_spotify_user: registering_spotify_user,
          authorization_code: "auth_code",
          access_token: "t1"
        )

        stub_spotify_username_request(
          access_token: "t1",
          spotify_username: "spotify_guy",
        )

        SpotifyService.authenticate(
          registering_spotify_user: registering_spotify_user,
          using_authorization_code: "auth_code",
        )

        expect(spotify_user.reload.spotify_app).to eq(spotify_app_1)
      end

      it "does not reset their listen along token" do
        registering_spotify_user = create :registering_spotify_user

        original_token = "original_token"

        spotify_user = create :spotify_user,
          username: "spotify_guy",
          listen_along_token: original_token

        stub_get_access_token_request(
          registering_spotify_user: registering_spotify_user,
          authorization_code: "auth_code",
          access_token: "t1"
        )

        stub_spotify_username_request(
          access_token: "t1",
          spotify_username: "spotify_guy",
        )

        SpotifyService.authenticate(
          registering_spotify_user: registering_spotify_user,
          using_authorization_code: "auth_code",
        )

        expect(spotify_user.reload.listen_along_token).to eq(original_token)
      end
    end

    it "finishes authenticating the spotify user and saves their credentials" do
      spotify_app_1 = create :spotify_app,
        client_identifier: "client_id_1",
        client_secret: "client_secret_1"

      registering_spotify_user_1 = create :registering_spotify_user,
        spotify_app: spotify_app_1

      access_token_request = stub_get_access_token_request(
        registering_spotify_user: registering_spotify_user_1,
        authorization_code: "auth_code",
        access_token: "access token 1",
        refresh_token: "refresh token 1",
      )

      stub_spotify_username_request(
        access_token: "access token 1",
        spotify_username: "spotify_guy",
      )

      spotify_user_1 = SpotifyService.authenticate(
        registering_spotify_user: registering_spotify_user_1,
        using_authorization_code: "auth_code",
      )

      expect(access_token_request).to have_been_requested
      expect(spotify_user_1.access_token).to eq("access token 1")
      expect(spotify_user_1.refresh_token).to eq("refresh token 1")
      expect(spotify_user_1.listen_along_token.length).to eq(32)
      expect(spotify_user_1.spotify_app).to eq(spotify_app_1)

      spotify_app_2 = create :spotify_app,
        client_identifier: "client_id_2",
        client_secret: "client_secret_2"

      registering_spotify_user_2 = create :registering_spotify_user,
        spotify_app: spotify_app_2

      access_token_request = stub_get_access_token_request(
        registering_spotify_user: registering_spotify_user_2,
        authorization_code: "auth_code_2",
        access_token: "access token 2",
        refresh_token: "refresh token 2",
      )

      stub_spotify_username_request(
        access_token: "access token 2",
        spotify_username: "spotify_guy_2",
      )

      spotify_user_2 = SpotifyService.authenticate(
        registering_spotify_user: registering_spotify_user_2,
        using_authorization_code: "auth_code_2",
      )

      expect(access_token_request).to have_been_requested
      expect(spotify_user_2.username).to eq("spotify_guy_2")
      expect(spotify_user_2.access_token).to eq("access token 2")
      expect(spotify_user_2.refresh_token).to eq("refresh token 2")
      expect(spotify_user_2.listen_along_token.length).to eq(32)
      expect(spotify_user_2.spotify_app).to eq(spotify_app_2)

      expect(spotify_user_1.listen_along_token).not_to(
        eq(spotify_user_2.listen_along_token)
      )
    end

    it "saves the spotify user's email address" do
      registering_spotify_user = create :registering_spotify_user
      spotify_authentication_token_request = stub_get_access_token_request(
        registering_spotify_user: registering_spotify_user,
        authorization_code: "auth_code",
        access_token: "access token",
        refresh_token: "refresh token",
      )
      spotify_username_request = stub_spotify_username_request(
        access_token: "access token",
        spotify_username: "121613941",
        email: "a@b.c",
      )

      SpotifyService.authenticate(
        registering_spotify_user: registering_spotify_user,
        using_authorization_code: "auth_code",
      )

      expect(spotify_username_request).to have_been_requested
      expect(spotify_authentication_token_request).to have_been_requested
      expect(SpotifyUser.last.email).to eq("a@b.c")
    end

    it "saves the spotify user's avatar url" do
      registering_spotify_user = create :registering_spotify_user
      spotify_authentication_token_request = stub_get_access_token_request(
        registering_spotify_user: registering_spotify_user,
        authorization_code: "auth_code",
        access_token: "access token",
        refresh_token: "refresh token",
      )
      spotify_username_request = stub_spotify_username_request(
        access_token: "access token",
        spotify_username: "121613941",
        avatar_url: "http://x.y.z.jpg",
      )

      SpotifyService.authenticate(
        registering_spotify_user: registering_spotify_user,
        using_authorization_code: "auth_code",
      )

      expect(spotify_username_request).to have_been_requested
      expect(spotify_authentication_token_request).to have_been_requested
      expect(SpotifyUser.last.avatar_url).to eq("http://x.y.z.jpg")
    end

    context "the spotify user has no avatar" do
      it "users a gravatar based on their email address" do
        registering_spotify_user = create :registering_spotify_user
        spotify_authentication_token_request = stub_get_access_token_request(
          registering_spotify_user: registering_spotify_user,
          authorization_code: "auth_code",
          access_token: "access token",
          refresh_token: "refresh token",
        )
        spotify_username_request = stub_spotify_username_request(
          access_token: "access token",
          spotify_username: "121613941",
          email: " Nick@pachulski.me  ",
        )

        SpotifyService.authenticate(
          registering_spotify_user: registering_spotify_user,
          using_authorization_code: "auth_code",
        )

        expected_avatar_url = \
          "https://www.gravatar.com/avatar/8ff7ad98849179025c718cf54a4c0f39?d=robohash&size=400"

        expect(spotify_username_request).to have_been_requested
        expect(spotify_authentication_token_request).to have_been_requested
        expect(SpotifyUser.last.avatar_url).to eq(expected_avatar_url)
      end
    end

    it "saves the spotify user's real full name" do
      registering_spotify_user = create :registering_spotify_user
      stub_get_access_token_request(
        registering_spotify_user: registering_spotify_user,
        authorization_code: "auth_code",
        access_token: "access token",
        refresh_token: "refresh token",
      )
      stub_spotify_username_request(
        access_token: "access token",
        spotify_username: "121613941",
        full_name: "Brian Voskerijian",
      )

      SpotifyService.authenticate(
        registering_spotify_user: registering_spotify_user,
        using_authorization_code: "auth_code",
      )

      expect(SpotifyUser.last.display_name).to eq("Brian Voskerijian")
    end

    it "creates only one spotify credential per spotify user" do
      registering_spotify_user = create :registering_spotify_user
      spotify_authentication_token_request = stub_get_access_token_request(
        registering_spotify_user: registering_spotify_user,
        authorization_code: "auth_code",
        access_token: "access token",
        refresh_token: "refresh token",
      )
      spotify_username_request = stub_spotify_username_request(
        access_token: "access token",
        spotify_username: "spotify_username",
      )

      SpotifyService.authenticate(
        registering_spotify_user: registering_spotify_user,
        using_authorization_code: "auth_code",
      )

      expect(spotify_username_request).to have_been_requested
      expect(spotify_authentication_token_request).to have_been_requested
      expect(SpotifyUser.last.access_token).to eq("access token")
      expect(SpotifyUser.last.refresh_token).to eq("refresh token")
      expect(SpotifyUser.last.username).to eq("spotify_username")
      expect(SpotifyUser.count).to eq(1)

      spotify_authentication_token_request_2 = stub_get_access_token_request(
        registering_spotify_user: registering_spotify_user,
        authorization_code: "auth_code_2",
        access_token: "access token 2",
        refresh_token: "refresh token 2",
      )
      spotify_username_request = stub_spotify_username_request(
        access_token: "access token 2",
        spotify_username: "spotify_username",
      )

      SpotifyService.authenticate(
        registering_spotify_user: registering_spotify_user,
        using_authorization_code: "auth_code_2",
      )

      expect(spotify_authentication_token_request_2).to have_been_requested
      expect(SpotifyUser.last.access_token).to eq("access token 2")
      expect(SpotifyUser.last.refresh_token).to eq("refresh token 2")
      expect(SpotifyUser.last.username).to eq("spotify_username")
      expect(SpotifyUser.count).to eq(1)
    end
  end

  describe "#current_playback_state" do
    it "sets [:last_song_uri] to the previous song uri" do
      spotify_user_1 = create :spotify_user,
        song_uri: "a"
      stub_get_playback_request(spotify_user_1)

      spotify_user_2 = create :spotify_user,
        song_uri: "x"
      stub_get_playback_request(spotify_user_2)

      expect(
        SpotifyService
          .new(spotify_user_1)
          .current_playback_state[:last_song_uri]
      ).to eq("a")

      expect(
        SpotifyService
          .new(spotify_user_2)
          .current_playback_state[:last_song_uri]
      ).to eq("x")
    end

    it "sets [:song_artists] to the song artists" do
      spotify_user = create :spotify_user,
        is_listening: true

      stub_get_playback_request(spotify_user, song_artists: ["one", "two"])

      expect(
        SpotifyService
          .new(spotify_user)
          .current_playback_state[:song_artists]
      ).to eq(["one", "two"])

      stub_get_playback_request(spotify_user, song_artists: ["three", "four"])

      expect(
        SpotifyService
          .new(spotify_user)
          .current_playback_state[:song_artists]
      ).to eq(["three", "four"])
    end

    it "sets [:song_album_cover_url] to the song album cover url" do
      spotify_user = create :spotify_user,
        is_listening: true

      stub_get_playback_request(spotify_user, album_url: "http://x.y.z.jpg")

      expect(
        SpotifyService
          .new(spotify_user)
          .current_playback_state[:song_album_cover_url]
      ).to eq("http://x.y.z.jpg")

      stub_get_playback_request(spotify_user, album_url: "another_url")

      expect(
        SpotifyService
          .new(spotify_user)
          .current_playback_state[:song_album_cover_url]
      ).to eq("another_url")
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
            spotify_app: spotify_user.spotify_app,
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
    it "turns on the listener's playback loop" do
      listener = create :spotify_user,
        broadcaster: nil
      broadcaster = create :spotify_user
      stub_currently_playing_request(access_token: broadcaster.access_token)
      stub_set_playback_request(
        listener: listener,
        broadcaster: broadcaster,
      )
      start_playback_loop_request = stub_start_playback_loop_request(listener)

      SpotifyService.new(listener).listen_along(broadcaster: broadcaster)

      expect(start_playback_loop_request).to have_been_requested
    end

    it "sets the listeners broadcaster and playback" do
      listener = create :spotify_user,
        access_token: "listener access token"
      broadcaster = create :spotify_user,
        access_token: "broadcaster access token",
        song_name: "name",
        song_uri: "uri",
        millisecond_progress_into_song: "1000"
      stub_currently_playing_request(access_token: broadcaster.access_token)
      stub_start_playback_loop_request(listener)
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
        old_broadcaster = create :spotify_user
        listener = create :spotify_user,
          broadcaster: old_broadcaster,
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
        stub_start_playback_loop_request(access_token: refreshed_access_token)
        stub_refresh_access_token_request(
          spotify_app: listener.spotify_app,
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
        stub_start_playback_loop_request(listener)
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
        stub_start_playback_loop_request(listener)
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
