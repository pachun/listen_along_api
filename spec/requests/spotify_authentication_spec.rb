require "rails_helper"

describe "Spotify authentication" do
  describe "GET #index with a ?code=param&state=broadcaster" do
    it "redirects to /listen_along?broadcaster=spotify_username&listener=spotify_username" do
      listener = create :spotify_user,
        username: "listener_username"

      allow(SpotifyService).to receive(:authenticate)
        .with(using_authorization_code: "auth_code")
        .and_return(listener)

      get "/spotify_authentication?code=auth_code&state=broadcaster_username"

      redirect_params = Rack::Utils.parse_query(
        URI.parse(response.location).query
      )

      expect(response).to redirect_to %r(/listen_along)
      expect(redirect_params).to eq(
        "broadcaster" => "broadcaster_username",
        "listener" => "listener_username",
      )
    end
  end
end
