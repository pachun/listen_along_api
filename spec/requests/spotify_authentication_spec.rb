require "rails_helper"

describe "Spotify authentication" do
  describe "GET #index with a ?code=auth_code parameter" do
    it "authenticates the registering user" do
      allow(SpotifyService).to receive(:authenticate).and_call_original
      registering_spotify_user = create :registering_spotify_user,
        identifier: "abcde"
      stub_get_access_token_request(
        registering_spotify_user: registering_spotify_user,
        authorization_code: "12345",
        access_token: "access_token",
        refresh_token: "refresh_token",
      )
      stub_spotify_username_request(
        access_token: "access_token",
        spotify_username: "nick",
      )

      get "/spotify_authentication?state=abcde&code=12345"

      expect(SpotifyService).to have_received(:authenticate).with(
        registering_spotify_user: registering_spotify_user,
        using_authorization_code: "12345",
      )
    end

    it "deletes the registering user" do
      allow(SpotifyService).to receive(:authenticate).and_call_original
      registering_spotify_user = create :registering_spotify_user,
        identifier: "abcde"
      stub_get_access_token_request(
        registering_spotify_user: registering_spotify_user,
        authorization_code: "12345",
        access_token: "access_token",
        refresh_token: "refresh_token",
      )
      stub_spotify_username_request(
        access_token: "access_token",
        spotify_username: "nick",
      )
      stub_currently_playing_request(access_token: "access_token")

      expect {
        get "/spotify_authentication?state=abcde&code=12345"
      }.to change { RegisteringSpotifyUser.count }.from(1).to(0)
    end

    context "when a user is authenticating from the mobile app" do
      it "redirects back to the client mobile app" do
        broadcaster = create :spotify_user,
          username: "broadcaster_username"
        registering_spotify_user = create :registering_spotify_user,
          identifier: "abcde",
          mobile: true,
          broadcaster_username: broadcaster.username
        stub_get_access_token_request(
          registering_spotify_user: registering_spotify_user,
          authorization_code: "12345",
          access_token: "access_token",
          refresh_token: "refresh_token",
        )
        stub_spotify_username_request(
          access_token: "access_token",
          spotify_username: "nick",
        )
        stub_currently_playing_request(access_token: "access_token")
        stub_currently_playing_request(access_token: broadcaster.access_token)
        stub_spotify_service_listen_alongs

        get "/spotify_authentication?state=abcde&code=12345"

        expect(response).to redirect_to("#{
            ENV["MOBILE_CLIENT_URL"]
          }?token=#{
            SpotifyUser.last.listen_along_token
          }&broadcaster_username=#{
            broadcaster.username
        }")
      end
    end

    context "when a user is authenticating from the web app" do
      it "redirects back to the client web app" do
        registering_spotify_user = create :registering_spotify_user,
          identifier: "abcde",
          mobile: false
        stub_get_access_token_request(
          registering_spotify_user: registering_spotify_user,
          authorization_code: "12345",
          access_token: "access_token",
          refresh_token: "refresh_token",
        )
        stub_spotify_username_request(
          access_token: "access_token",
          spotify_username: "nick",
        )
        stub_currently_playing_request(access_token: "access_token")

        get "/spotify_authentication?state=abcde&code=12345"

        expect(response).to redirect_to("#{ENV["WEB_CLIENT_URL"]}?token=#{SpotifyUser.last.listen_along_token}")
      end
    end

    context "when the registering spotify user has a broadcaster" do
      it "starts listening along with the broadcaster" do
        allow(SpotifyService).to receive(:authenticate).and_call_original
        broadcaster = create :spotify_user,
          is_listening: true,
          username: "broadcaster"
        registering_spotify_user = create :registering_spotify_user,
          identifier: "abcde",
          broadcaster_username: "broadcaster"
        stub_get_access_token_request(
          registering_spotify_user: registering_spotify_user,
          authorization_code: "12345",
          access_token: "access_token",
          refresh_token: "refresh_token",
        )
        stub_spotify_username_request(
          access_token: "access_token",
          spotify_username: "nick",
        )
        stub_currently_playing_request(access_token: "access_token")
        stub_get_playback_request(broadcaster)

        stub_start_playback_loop_request(access_token: "access_token")

        listen_along_request = stub_request(:put, "https://api.spotify.com/v1/me/player/play")
          .with(headers: { 'Authorization'=>'Bearer access_token' })

        get "/spotify_authentication?state=abcde&code=12345"

        expect(listen_along_request).to have_been_requested
      end
    end

    context "when the registering spotify user tried to listen along with themself" do
      it "does not start listening along with the 'broadcaster' (themself)" do
        allow(SpotifyService).to receive(:authenticate).and_call_original
        broadcaster = create :spotify_user,
          is_listening: true,
          username: "SELF"
        registering_spotify_user = create :registering_spotify_user,
          identifier: "abcde",
          broadcaster_username: "SELF"
        stub_get_access_token_request(
          registering_spotify_user: registering_spotify_user,
          authorization_code: "12345",
          access_token: "access_token",
          refresh_token: "refresh_token",
        )
        stub_spotify_username_request(
          access_token: "access_token",
          spotify_username: "SELF",
        )
        stub_currently_playing_request(access_token: "access_token")
        stub_get_playback_request(broadcaster)

        stub_start_playback_loop_request(access_token: "access_token")

        listen_along_request = stub_request(:put, "https://api.spotify.com/v1/me/player/play")
          .with(headers: { 'Authorization'=>'Bearer access_token' })

        get "/spotify_authentication?state=abcde&code=12345"

        expect(listen_along_request).not_to have_been_requested
      end
    end
  end
end
