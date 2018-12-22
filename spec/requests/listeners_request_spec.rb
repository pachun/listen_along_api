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

      expect(JSON.parse(response.body)).to eq([
        { "display_name" => "Alfred Mosley", "username" => "spotify user 3", "broadcaster" => nil, "is_me" => false},
        { "display_name" => "Zenrique Soup", "username" => "spotify user 2", "broadcaster" => nil, "is_me" => false },
      ])
    end

    it "returns listeners in between songs, listening along with a broadcaster" do
      broadcaster = create :spotify_user,
        username: "broadcaster",
        is_listening: true

      create :spotify_user,
        username: "listener",
        is_listening: false,
        broadcaster: broadcaster

      get "/listeners"

      expect(JSON.parse(response.body)).to eq([
        { "display_name" => nil, "username" => "broadcaster", "broadcaster" => nil, "is_me" => false },
        { "display_name" => nil, "username" => "listener", "broadcaster" => "broadcaster", "is_me" => false},
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
        { "display_name" => nil, "username" => "broadcaster", "broadcaster" => nil, "is_me" => false },
        { "display_name" => nil, "username" => "listener", "broadcaster" => "broadcaster", "is_me" => false },
      ])
    end

    it "indicates which listener is me" do
      create :spotify_user,
        username: "a",
        is_listening: true,
        listen_along_token: "my_token"

      create :spotify_user,
        username: "b",
        is_listening: true

      get "/listeners?token=my_token"

      expect(JSON.parse(response.body)).to eq([
        { "display_name" => nil, "username" => "a", "broadcaster" => nil, "is_me" => true },
        { "display_name" => nil, "username" => "b", "broadcaster" => nil, "is_me" => false },
      ])
    end
  end
end
