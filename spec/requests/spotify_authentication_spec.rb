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

    it "redirects back to the client react app" do
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

      get "/spotify_authentication?state=abcde&code=12345"

      expect(response).to redirect_to("#{ENV["CLIENT_URL"]}?token=#{SpotifyUser.last.listen_along_token}")
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
  end
end
