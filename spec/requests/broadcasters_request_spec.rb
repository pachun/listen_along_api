require "rails_helper"

describe "broadcasters controller" do
  describe "GET #index" do
    it "returns the names of the current broadcasters" do
      create :spotify_user,
        username: "spotify user 1",
        is_listening: false

      get "/broadcasters"

      expect(JSON.parse(response.body)).to eq([])

      create :spotify_user,
        username: "spotify user 2",
        is_listening: true
      create :spotify_user,
        username: "spotify user 3",
        is_listening: true

      get "/broadcasters"

      expect(JSON.parse(response.body)).to match_array([
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

      get "/broadcasters"

      expect(JSON.parse(response.body)).to match_array([
        { "username" => "broadcaster", "broadcaster" => nil },
        { "username" => "listener", "broadcaster" => "broadcaster" },
      ])
    end
  end
end
