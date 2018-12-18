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
        username: "spotify user 3",
        is_listening: true
      create :spotify_user,
        username: "spotify user 2",
        is_listening: true

      get "/listeners"

      expect(JSON.parse(response.body)).to eq([
        { "username" => "spotify user 2", "broadcaster" => nil },
        { "username" => "spotify user 3", "broadcaster" => nil },
      ])
    end

    it "includes listener's broadcasters" do
      broadcaster = create :spotify_user,
        username: "broadcaster",
        is_listening: true

      create :spotify_user,
        username: "listener",
        is_listening: true,
        broadcaster: broadcaster

      get "/listeners"

      expect(JSON.parse(response.body)).to match_array([
        { "username" => "broadcaster", "broadcaster" => nil },
        { "username" => "listener", "broadcaster" => "broadcaster" },
      ])
    end
  end
end
