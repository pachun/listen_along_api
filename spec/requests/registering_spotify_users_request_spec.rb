require "rails_helper"

describe RegisteringSpotifyUsersController, type: :request do
  describe "GET #new" do
    context "with a broadcaster_username specified"
    it "creates a registering spotify user with the specified broadcaster" do
      create :spotify_app

      expect {
        get "/registering_spotify_users/new?broadcaster_username=broadcaster_username_1"
      }.to change { RegisteringSpotifyUser.count }.from(0).to(1)

      expect(RegisteringSpotifyUser.last.broadcaster_username).to(
        eq("broadcaster_username_1")
      )

      get "/registering_spotify_users/new?broadcaster_username=broadcaster_username_2"

      expect(RegisteringSpotifyUser.last.broadcaster_username).to(
        eq("broadcaster_username_2")
      )
    end

    it "creates a registering spotify user with a random identifier" do
      create :spotify_app

      get "/registering_spotify_users/new"

      first_created_user = RegisteringSpotifyUser.last

      expect(first_created_user.identifier.length).to eq(32)

      get "/registering_spotify_users/new"

      second_created_user = RegisteringSpotifyUser.last

      expect(second_created_user.identifier.length).to eq(32)
      expect(first_created_user.identifier).not_to(
        eq(second_created_user.identifier)
      )
    end

    it "creates a registering spotify user belonging to the spotify app with the fewest spotify users" do
      spotify_app_1 = create :spotify_app,
        name: "Listen Along (Zone 1)",
        client_identifier: "client_id_1",
        client_secret: "client_secret_1"

      spotify_app_2 = create :spotify_app,
        name: "Listen Along (Zone 2)",
        client_identifier: "client_id_2",
        client_secret: "client_secret_2"

      create :spotify_user,
        spotify_app: spotify_app_1

      get "/registering_spotify_users/new"

      expect(RegisteringSpotifyUser.last.spotify_app).to eq(spotify_app_2)

      create :spotify_user,
        spotify_app: spotify_app_2

      create :spotify_user,
        spotify_app: spotify_app_2

      get "/registering_spotify_users/new"

      expect(RegisteringSpotifyUser.last.spotify_app).to eq(spotify_app_1)
    end

    it "redirects to the spotify oauth login page with the correct client id" do
      spotify_app = create :spotify_app,
        client_identifier: "client_id_1"

      get "/registering_spotify_users/new"

      expect(response).to redirect_to("https://accounts.spotify.com/authorize?client_id=#{spotify_app.client_identifier}&response_type=code&redirect_uri=#{URI.encode(ENV["API_URL"])}/spotify_authentication&scope=user-read-currently-playing%20user-modify-playback-state%20user-read-playback-state&state=#{RegisteringSpotifyUser.last.identifier}")

      spotify_app.update(client_identifier: "client_id_2")

      get "/registering_spotify_users/new"

      expect(response).to redirect_to("https://accounts.spotify.com/authorize?client_id=#{spotify_app.client_identifier}&response_type=code&redirect_uri=#{URI.encode(ENV["API_URL"])}/spotify_authentication&scope=user-read-currently-playing%20user-modify-playback-state%20user-read-playback-state&state=#{RegisteringSpotifyUser.last.identifier}")
    end
  end
end