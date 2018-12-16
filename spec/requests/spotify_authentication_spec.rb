require "rails_helper"

describe "Spotify authentication" do
  describe "GET #index with a ?code=auth_code parameter" do
    context "with a ?state=broadcaster url parameter" do
      it "redirects to /listen_along?broadcaster=spotify_username&listener=spotify_username" do
        auth_code = "auth_code"
        listener = create :spotify_user,
          listen_along_token: "listener_token"

        allow(SpotifyService).to receive(:authenticate)
          .with(using_authorization_code: auth_code)
          .and_return(listener)

        get "/spotify_authentication?code=#{auth_code}&state=broadcaster_username"

        redirect_params = Rack::Utils.parse_query(
          URI.parse(response.location).query
        )

        expect(response).to redirect_to %r(/listen_along)
        expect(redirect_params).to eq(
          "broadcaster" => "broadcaster_username",
          "listener_token" => "listener_token",
          "authenticating" => "true",
        )
      end
    end
  end
end
