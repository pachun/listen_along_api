require "rails_helper"

describe ListenersController do
  describe "GET #index" do
    it "returns the names of the current listeners in alphabetical order" do
      create :spotify_user,
        username: "spotify user 1",
        is_listening: false

      get "/listeners"

      expect(JSON.parse(response.body)).to eq([])

      create :spotify_user,
        username: "spotify user 2",
        display_name: "Zenrique Soup",
        is_listening: true
      create :spotify_user,
        username: "spotify user 3",
        display_name: "Alfred Mosley",
        is_listening: true

      get "/listeners"

      listeners = JSON.parse(response.body)
      first_listener = listeners.first["display_name"]
      second_listener = listeners.last["display_name"]

      expect(first_listener).to eq("Alfred Mosley")
      expect(second_listener).to eq("Zenrique Soup")
    end

    it "does not return listeners who are listening along with someone" do
      broadcaster = create :spotify_user,
        username: "broadcaster",
        is_listening: true

      create :spotify_user,
        display_name: "listener",
        is_listening: true,
        broadcaster: broadcaster

      get "/listeners"

      listeners = JSON.parse(response.body).map do |listener|
        listener["display_name"]
      end

      expect(listeners).not_to include("listener")
    end

    it "indicates which listener is me" do
      create :spotify_user,
        username: "me",
        is_listening: true,
        listen_along_token: "my_token"

      create :spotify_user,
        username: "someone_else",
        is_listening: true

      get "/listeners?token=my_token"

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

      create :spotify_user,
        is_listening: true,
        username: "me",
        listen_along_token: "my_token",
        broadcaster: broadcaster_1

      get "/listeners?token=my_token"

      broadcaster_json = JSON.parse(response.body).select do |listener|
        listener["listening_along"] == true
      end

      expect(broadcaster_json).to be_present
      expect(broadcaster_json.length).to eq(1)
      expect(broadcaster_json.first["username"]).to eq("broadcaster_1")
    end
  end
end
