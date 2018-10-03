require "rails_helper"

describe "Spotify authentication" do
  describe "GET #index with a ?code= param" do
    it "redirects to /listen_along" do
      stub_request(:post, "https://accounts.spotify.com/api/token").to_return(
        status: 200,
        body: { access_token: "", refresh_token: "" }.to_json
      )

      get "/spotify_authentication"

      expect(response).to redirect_to("/listen_along")
    end

    it "finishes authenticating the spotify user and saves their credentials" do
      client_id_and_secret = Base64.urlsafe_encode64(
        "#{ENV["SPOTIFY_CLIENT_ID"]}:#{ENV["SPOTIFY_CLIENT_SECRET"]}"
      )
      spotify_authentication_token_request = stub_request(
        :post,
        "https://accounts.spotify.com/api/token"
      ).with(
        headers: {
          "Authorization": "Basic #{client_id_and_secret}",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "grant_type": "authorization_code",
          "code": "auth_code",
          "redirect_uri": "#{ENV["API_URL"]}/spotify_authentication",
        }
      ).to_return(
        status: 200,
        body: {
          access_token: "access token",
          refresh_token: "refresh token",
        }.to_json
      )

      get "/spotify_authentication?code=auth_code"

      expect(spotify_authentication_token_request).to have_been_requested
      expect(SpotifyCredential.last.access_token).to eq("access token")
      expect(SpotifyCredential.last.refresh_token).to eq("refresh token")

      spotify_authentication_token_request_2 = stub_request(
        :post,
        "https://accounts.spotify.com/api/token"
      ).with(
        headers: {
          "Authorization": "Basic #{client_id_and_secret}",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "grant_type": "authorization_code",
          "code": "auth_code_2",
          "redirect_uri": "#{ENV["API_URL"]}/spotify_authentication",
        }
      ).to_return(
        status: 200,
        body: {
          access_token: "access token 2",
          refresh_token: "refresh token 2",
        }.to_json
      )

      get "/spotify_authentication?code=auth_code_2"

      expect(spotify_authentication_token_request_2).to have_been_requested
      expect(SpotifyCredential.last.access_token).to eq("access token 2")
      expect(SpotifyCredential.last.refresh_token).to eq("refresh token 2")
    end
  end
end
