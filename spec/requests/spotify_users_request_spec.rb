require "rails_helper"

describe SpotifyUsersController do
  describe "GET #index" do
    it "returns the names of the current listeners in alphabetical order" do
      create :spotify_user,
        username: "spotify user 1",
        is_listening: false

      get "/spotify_users"

      expect(JSON.parse(response.body)).to eq([])

      create :spotify_user,
        username: "spotify user 2",
        display_name: "Zenrique Soup",
        is_listening: true
      create :spotify_user,
        username: "spotify user 3",
        display_name: "Alfred Mosley",
        is_listening: true

      get "/spotify_users"

      listeners = JSON.parse(response.body)
      first_listener = listeners.first["display_name"]
      second_listener = listeners.last["display_name"]

      expect(first_listener).to eq("Alfred Mosley")
      expect(second_listener).to eq("Zenrique Soup")
    end

    it "indicates which listener is me" do
      my_token = "my_token"

      create :spotify_user,
        username: "me",
        is_listening: false,
        listen_along_token: my_token

      create :spotify_user,
        username: "someone_else",
        is_listening: true

      get "/spotify_users",
        headers: { "Authorization": "Bearer #{my_token}"}

      me = JSON.parse(response.body).select do |listener|
        listener["is_me"] == true
      end

      expect(me).to be_present
      expect(me.length).to eq(1)
      expect(me.first["username"]).to eq("me")
    end

    it "indicates who I am listening along with" do
      broadcaster_1 = create :spotify_user,
        is_listening: true,
        username: "broadcaster_1"

      create :spotify_user,
        is_listening: true,
        username: "broadcaster_2"

      my_token = "my_token"
      create :spotify_user,
        is_listening: true,
        username: "me",
        listen_along_token: my_token,
        broadcaster: broadcaster_1

      get "/spotify_users",
        headers: { "Authorization": "Bearer #{my_token}"}

      broadcaster_json = JSON.parse(response.body).detect do |listener|
        listener["is_me"] == true
      end["broadcaster"]

      expect(broadcaster_json).to be_present
      expect(broadcaster_json["username"]).to eq("broadcaster_1")
    end
  end

  describe "PUT /add_song_to_my_library" do
    it "adds the song to my library" do
      token = "9999"
      song_id = "song_id"
      spotify_user = create :spotify_user,
        listen_along_token: token

      spotify_service_double = instance_double(SpotifyService)
      allow(SpotifyService).to receive(:new)
        .with(spotify_user)
        .and_return(spotify_service_double)
      allow(spotify_service_double).to receive(:add_to_library)

      put "/add_to_library",
        headers: { "Authorization": "Bearer #{token}"},
        params: { song_id: song_id }

      expect(spotify_service_double).to have_received(:add_to_library)
        .with(song_id: song_id)
    end

    context "without a listen along token" do
      it "doesn't add a song to anyones library and returns 401 unauthorized" do
        song_id = "song_id"
        spotify_user = create :spotify_user

        spotify_service_double = instance_double(SpotifyService)
        allow(SpotifyService).to receive(:new)
          .with(spotify_user)
          .and_return(spotify_service_double)
        allow(spotify_service_double).to receive(:add_to_library)

        put "/add_to_library",
          params: { song_id: song_id }

        expect(SpotifyService).not_to have_received(:new)
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /listen_along" do
    it "syncs the listener's Spotify playback with the broadcaster's" do
      broadcaster = create :spotify_user,
        username: "broadcaster"
      listeners_token = "listeners_token"
      listener = create :spotify_user,
        listen_along_token: listeners_token

      spotify_service_double = instance_double(SpotifyService)
      allow(SpotifyService).to receive(:new)
        .with(listener)
        .and_return(spotify_service_double)
      allow(spotify_service_double).to receive(:listen_along)

      post "/listen_along",
        headers: { "Authorization": "Bearer #{listeners_token}"},
        params: { broadcaster_username: broadcaster.username }

      expect(spotify_service_double).to have_received(:listen_along).with(
        broadcaster: broadcaster,
      )
      expect(response).to have_http_status(:no_content)
    end

    context "without a listen along token" do
      it "does not sync the listener's Spotify playback with the broadcaster's" do
        broadcaster = create :spotify_user,
          username: "broadcaster"
        listener = create :spotify_user,
          username: "listener",
          listen_along_token: "1234"

        spotify_service_double = instance_double(SpotifyService)
        allow(SpotifyService).to receive(:new)
          .with(listener)
          .and_return(spotify_service_double)
        allow(spotify_service_double).to receive(:listen_along)

        post "/listen_along",
          params: {
            broadcaster_username: broadcaster.username,
          }

        expect(spotify_service_double).not_to have_received(:listen_along).with(
          broadcaster: broadcaster,
        )
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
