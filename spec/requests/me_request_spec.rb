require "rails_helper"

describe MeController do
  describe "GET #index" do
    context "without an authentication token" do
      it "returns a 403 'not authorized' http response status" do
        get "/me"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    it "returns a 200 'ok' http response status" do
      token = "token"
      spotify_user = create :spotify_user,
        listen_along_token: token
      stub_get_playback_request(spotify_user)

      get "/me", headers: { "Authorization": "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
    end

    it "returns whether or not the logged in user is listening to Spotify" do
      token = "token"

      spotify_user = create :spotify_user,
        is_listening: false,
        listen_along_token: token

      stub_get_playback_request(
        spotify_user,
        is_listening: true,
      )

      get "/me", headers: { "Authorization": "Bearer #{token}" }

      expect(JSON.parse(response.body)).to eq(
        "is_listening" => true,
      )

      stub_get_playback_request(
        spotify_user,
        is_listening: false,
      )

      get "/me", headers: { "Authorization": "Bearer #{token}" }

      expect(JSON.parse(response.body)).to eq(
        "is_listening" => false,
      )
    end
  end
end
