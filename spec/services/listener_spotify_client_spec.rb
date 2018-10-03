require "rails_helper"

describe ListenerSpotifyClient do
  describe "#listen_along" do
    context "the listener's spotify access token is expired" do
      it "gets a new access token then returns the song name" do
        broadcaster_credentials = create :spotify_credential,
          access_token: "broadcaster access token"

        refreshed_access_token = "refreshed access token"
        listener_credentials = create :spotify_credential,
          access_token: "expired token",
          refresh_token: "refresh token"

        refresh_token_request_header = Base64.urlsafe_encode64(
          "#{ENV["SPOTIFY_CLIENT_ID"]}:#{ENV["SPOTIFY_CLIENT_SECRET"]}"
        )

        stub_request(
          :put,
          "https://api.spotify.com/v1/me/player/play"
        ).with(
          body: {
            "uris": ["spotify:track:5k8ljvF1AoEXmdHxll7ReL"],
            "position_ms": 20000
          }.to_json,
          headers: {
            "Authorization": "Bearer #{listener_credentials.access_token}",
          },
        ).to_return(
          status: 401,
        )

        stub_request(
          :post,
          "https://accounts.spotify.com/api/token"
        ).with(
          body: {
            "grant_type": "refresh_token",
            "refresh_token": listener_credentials.refresh_token,
          },
          headers: {
            "Authorization": "Basic #{refresh_token_request_header}",
            "Content-Type": "application/x-www-form-urlencoded",
          }
        ).to_return(
          status: 200,
          body: { "access_token": refreshed_access_token }.to_json,
        )

        sync_request = stub_request(
          :put,
          "https://api.spotify.com/v1/me/player/play"
        ).with(
          body: {
            "uris": ["spotify:track:5k8ljvF1AoEXmdHxll7ReL"],
            "position_ms": 20000
          }.to_json,
          headers: {
            "Authorization": "Bearer #{refreshed_access_token}",
          },
        )

        stub_request(
          :get,
          "https://api.spotify.com/v1/me/player/currently-playing"
        ).with(
          headers: {
            "Authorization": "Bearer #{broadcaster_credentials.access_token}",
          },
        ).to_return(
          status: 200,
          body: {
            progress_ms: 20000,
            item: {
              name: "Fourth of July",
              uri: "spotify:track:5k8ljvF1AoEXmdHxll7ReL",
            }
          }.to_json,
        )

        ListenerSpotifyClient.new.listen_along

        expect(sync_request).to have_been_requested
        expect(
          listener_credentials.reload.access_token
        ).to eq(refreshed_access_token)
      end
    end

    context "ListenWithDude is 20 seconds into the song 'Fourth of July'" do
      it "starts play 'Fourth of July' at 20 seconds in on pachun91's Spotify account" do
        broadcaster_credentials = create :spotify_credential,
          access_token: "access token"

        stub_request(
          :get,
          "https://api.spotify.com/v1/me/player/currently-playing"
        ).with(
          headers: {
            "Authorization": "Bearer #{broadcaster_credentials.access_token}"
          },
        ).to_return(
          status: 200,
          body: {
            progress_ms: 20000,
            item: {
              name: "Fourth of July",
              uri: "spotify:track:5k8ljvF1AoEXmdHxll7ReL",
            }
          }.to_json,
        )

        listener_credentials = create :spotify_credential,
          access_token: "access token"

        sync_request = stub_request(
          :put,
          "https://api.spotify.com/v1/me/player/play"
        ).with(
          body: {
            "uris": ["spotify:track:5k8ljvF1AoEXmdHxll7ReL"],
            "position_ms": 20000
          }.to_json,
          headers: {
            "Authorization": "Bearer #{listener_credentials.access_token}",
          },
        )

        ListenerSpotifyClient.new.listen_along

        expect(sync_request).to have_been_requested
      end
    end

    context "ListenWithDude is 5 seconds into the song 'Queen'" do
      it "starts play 'Queen' at 5 seconds in on pachun91's Spotify account" do
        broadcaster_credentials = create :spotify_credential,
          access_token: "access token"

        stub_request(
          :get,
          "https://api.spotify.com/v1/me/player/currently-playing"
        ).with(
          headers: {
            "Authorization": "Bearer #{broadcaster_credentials.access_token}"
          },
        ).to_return(
          status: 200,
          body: {
            progress_ms: 5000,
            item: {
              name: "Queen",
              uri: "spotify:track:2lxW8vQ9Qjv0qeSQiIBOKJ",
            }
          }.to_json,
        )

        listener_credentials = create :spotify_credential,
          access_token: "access token"

        sync_request = stub_request(
          :put,
          "https://api.spotify.com/v1/me/player/play"
        ).with(
          body: {
            "uris": ["spotify:track:2lxW8vQ9Qjv0qeSQiIBOKJ"],
            "position_ms": 5000
          }.to_json,
          headers: {
            "Authorization": "Bearer #{listener_credentials.access_token}",
          },
        )

        ListenerSpotifyClient.new.listen_along

        expect(sync_request).to have_been_requested
      end
    end
  end
end
